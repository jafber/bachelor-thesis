#!/usr/bin/env python3
import argparse
import ast
import os
import signal
from pathlib import Path

import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
from dotenv import load_dotenv
from tqdm.auto import tqdm

DEFAULT_MODEL_ID = "meta-llama/Meta-Llama-3-8B-Instruct"
DEFAULT_DATASET_ID = "Randolphzeng/Mr-GSM8K"
INSTRUCTION = (
    "Solve the following math problem. Write the solution in logical steps labeled "
    "'Step 1:', 'Step 2:', and so on. On the final step, output the numeric answer "
    "prefixed with '####'."
)
DOMAIN_QUESTION = "A grade-school math word problem."
METADATA_COLUMNS = [
    "uuid",
    "question_type",
    "ground_truth_answer",
    "model_output_answer_correctness",
    "model_output_solution_correctness",
    "model_output_solution_first_error_step",
    "model_output_solution_first_error_reason",
]
LOGPROB_CONTEXTS = {
    "full": "Question + history",
    "generic_domain": "Generic domain",
    "question_ablated": "Generic domain + history",
    "history_ablated": "Question without history",
}
STRATEGY_DENOMINATORS = {
    "dc_pmi_generic_domain": "generic_domain",
    "dc_pmi_question_ablation": "question_ablated",
    "dc_pmi_history_ablation": "history_ablated",
}
STRATEGIES = {
    "dc_pmi_generic_domain": "Generic domain",
    "dc_pmi_question_ablation": "Question contribution",
    "dc_pmi_history_ablation": "History contribution",
}
CACHE_SCHEMA = pa.schema([
    pa.field("sample_index", pa.int32(), nullable=False),
    pa.field("uuid", pa.string(), nullable=False),
    pa.field("question_type", pa.string(), nullable=False),
    pa.field("ground_truth_answer", pa.string()),
    pa.field("model_output_answer_correctness", pa.string()),
    pa.field("model_output_solution_correctness", pa.string()),
    pa.field("model_output_solution_first_error_step", pa.float64()),
    pa.field("model_output_solution_first_error_reason", pa.string()),
    pa.field("step", pa.int16(), nullable=False),
    pa.field("text", pa.string(), nullable=False),
    *[
        field
        for context in LOGPROB_CONTEXTS
        for field in (
            pa.field(f"{context}_token_ids", pa.list_(pa.int32()), nullable=False),
            pa.field(f"{context}_token_logprobs", pa.list_(pa.float32()), nullable=False),
        )
    ],
])

stop_requested = False


def request_stop(signum, _frame):
    global stop_requested
    stop_requested = True
    print(f"Received signal {signum}; checkpointing after the current example.", flush=True)


def default_cache_path(sample_size, seed):
    return Path("cache") / f"llama_3_mr_gsm8k_original_n{sample_size}_seed{seed}_token_logprobs.parquet"


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-id", default=DEFAULT_MODEL_ID)
    parser.add_argument("--dataset-id", default=DEFAULT_DATASET_ID)
    parser.add_argument("--sample-size", type=int, default=1000)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--target-batch-size", type=int, default=8)
    parser.add_argument("--checkpoint-every", type=int, default=10)
    parser.add_argument("--cache-path", type=Path)
    parser.add_argument("--bootstrap-cache", type=Path)
    args = parser.parse_args()
    if args.cache_path is None:
        args.cache_path = default_cache_path(args.sample_size, args.seed)
    if args.bootstrap_cache is None:
        args.bootstrap_cache = default_cache_path(100, args.seed)
    return args


def parse_steps(value):
    steps = ast.literal_eval(value) if isinstance(value, str) else list(value)
    assert steps and all(isinstance(step, str) and step.startswith("Step ") for step in steps)
    return steps


def load_original_sample(sample_size, seed, token, dataset_id=DEFAULT_DATASET_ID):
    from datasets import load_dataset

    dataset = load_dataset(dataset_id, split="test", token=token)
    original = dataset.filter(lambda row: row["question_type"] == "original")
    assert len(original) >= sample_size
    sample = original.shuffle(seed=seed).select(range(sample_size))
    assert len(sample) == sample_size
    assert set(sample["question_type"]) == {"original"}
    return sample, len(original)


def load_model(model_id, token):
    import torch
    from transformers import AutoModelForCausalLM, AutoTokenizer

    assert torch.cuda.is_available(), "CUDA not available"
    dtype = torch.bfloat16 if torch.cuda.is_bf16_supported() else torch.float16
    tokenizer = AutoTokenizer.from_pretrained(model_id, token=token)
    assert tokenizer.is_fast, "A fast tokenizer is required for offset mappings"
    tokenizer.pad_token = tokenizer.eos_token
    tokenizer.padding_side = "right"
    model = AutoModelForCausalLM.from_pretrained(
        model_id,
        token=token,
        torch_dtype=dtype,
        device_map="auto",
        low_cpu_mem_usage=True,
    )
    model.eval()
    input_device = model.get_input_embeddings().weight.device
    print(f"Loaded {model_id} on {input_device} using {dtype}.", flush=True)
    return model, tokenizer, input_device


def format_prompt(tokenizer, question):
    messages = [{"role": "user", "content": f"{INSTRUCTION}\n\nQuestion:\n{question}"}]
    return tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)


def selected_token_scores(input_ids, token_log_probs, positions):
    import torch

    assert positions
    values = torch.stack([token_log_probs[position - 1] for position in positions])
    return {
        "token_ids": [int(input_ids[position]) for position in positions],
        "token_logprobs": values.numpy().astype("float32").tolist(),
    }


def target_token_scores(model, tokenizer, input_device, contexts, targets, batch_size):
    import torch
    import torch.nn.functional as F

    assert len(contexts) == len(targets) and targets
    results = []
    for batch_start in range(0, len(targets), batch_size):
        batch_contexts = contexts[batch_start : batch_start + batch_size]
        batch_targets = targets[batch_start : batch_start + batch_size]
        texts = [context + "\n" + target for context, target in zip(batch_contexts, batch_targets)]
        target_starts = [len(context) + 1 for context in batch_contexts]
        encoded = tokenizer(
            texts,
            add_special_tokens=False,
            padding=True,
            return_offsets_mapping=True,
            return_tensors="pt",
        )
        offsets = encoded.pop("offset_mapping").tolist()
        input_ids = encoded["input_ids"]
        assert input_ids.shape[1] <= model.config.max_position_embeddings
        model_inputs = {name: tensor.to(input_device) for name, tensor in encoded.items()}

        with torch.inference_mode():
            logits = model(**model_inputs, use_cache=False).logits
            token_log_probs = -F.cross_entropy(
                logits[:, :-1, :].transpose(1, 2),
                model_inputs["input_ids"][:, 1:],
                reduction="none",
            ).float().cpu()

        for row, (row_offsets, target_start) in enumerate(zip(offsets, target_starts)):
            positions = [
                position
                for position, (start, end) in enumerate(row_offsets)
                if position > 0 and end > target_start and end > start
            ]
            results.append(selected_token_scores(input_ids[row], token_log_probs[row], positions))
    return results


def sequence_step_scores(model, tokenizer, input_device, prompt, steps):
    import torch
    import torch.nn.functional as F

    answer = "\n".join(steps)
    text = prompt + "\n" + answer
    encoded = tokenizer(
        text,
        add_special_tokens=False,
        return_offsets_mapping=True,
        return_tensors="pt",
    )
    offsets = encoded.pop("offset_mapping")[0].tolist()
    input_ids = encoded["input_ids"][0]
    assert encoded["input_ids"].shape[1] <= model.config.max_position_embeddings
    model_inputs = {name: tensor.to(input_device) for name, tensor in encoded.items()}

    with torch.inference_mode():
        logits = model(**model_inputs, use_cache=False).logits
        token_log_probs = -F.cross_entropy(
            logits[:, :-1, :].transpose(1, 2),
            model_inputs["input_ids"][:, 1:],
            reduction="none",
        )[0].float().cpu()

    rows = []
    cursor = len(prompt) + 1
    for step_number, step_text in enumerate(steps, start=1):
        step_end = cursor + len(step_text)
        positions = [
            position
            for position, (start, end) in enumerate(offsets)
            if position > 0 and end > cursor and start < step_end and end > start
        ]
        rows.append({
            "step": step_number,
            "text": step_text,
            **selected_token_scores(input_ids, token_log_probs, positions),
        })
        cursor = step_end + 1
    assert cursor - 1 == len(text)
    return rows


def compute_all_logprobs(model, tokenizer, input_device, question, raw_steps, target_batch_size):
    steps = parse_steps(raw_steps)
    question_prompt = format_prompt(tokenizer, question)
    domain_prompt = format_prompt(tokenizer, DOMAIN_QUESTION)
    full_scores = sequence_step_scores(model, tokenizer, input_device, question_prompt, steps)
    question_ablated_scores = sequence_step_scores(
        model, tokenizer, input_device, domain_prompt, steps
    )
    isolated_scores = target_token_scores(
        model,
        tokenizer,
        input_device,
        [domain_prompt] * len(steps) + [question_prompt] * len(steps),
        steps + steps,
        target_batch_size,
    )
    generic_scores = isolated_scores[: len(steps)]
    history_ablated_scores = isolated_scores[len(steps) :]

    rows = []
    for full, generic, no_question, no_history in zip(
        full_scores,
        generic_scores,
        question_ablated_scores,
        history_ablated_scores,
    ):
        rows.append({
            "step": full["step"],
            "text": full["text"],
            "full_token_ids": full["token_ids"],
            "full_token_logprobs": full["token_logprobs"],
            "generic_domain_token_ids": generic["token_ids"],
            "generic_domain_token_logprobs": generic["token_logprobs"],
            "question_ablated_token_ids": no_question["token_ids"],
            "question_ablated_token_logprobs": no_question["token_logprobs"],
            "history_ablated_token_ids": no_history["token_ids"],
            "history_ablated_token_logprobs": no_history["token_logprobs"],
        })
    return rows


def compute_first_differences(step_scores, metrics, drop_missing=True):
    """Return within-solution score changes from the immediately preceding step."""
    assert not step_scores.duplicated(["uuid", "step"]).any()
    assert step_scores["step"].notna().all()
    ordered = step_scores.sort_values(["uuid", "step"]).copy()
    previous_step = ordered.groupby("uuid")["step"].shift()
    assert ordered.loc[previous_step.notna(), "step"].eq(previous_step.dropna() + 1).all()
    difference_columns = [f"{metric}_first_difference" for metric in metrics]
    for metric, difference_column in zip(metrics, difference_columns):
        ordered[difference_column] = ordered.groupby("uuid")[metric].diff()
    return ordered.dropna(subset=difference_columns) if drop_missing else ordered


def load_cached_signal_scores(cache_path):
    """Derive step scores and first-error labels using only a completed Parquet cache."""
    import numpy as np

    frame = read_cache(cache_path)
    assert frame["uuid"].nunique() == 1000, "Expected the completed 1000-solution cache"
    assert len(frame) == 7012, "Expected the completed seed-42 cache"
    assert not frame.duplicated(["uuid", "step"]).any()
    for context in LOGPROB_CONTEXTS:
        frame[f"{context}_avg_ll"] = frame[f"{context}_token_logprobs"].map(np.mean)
    for metric, denominator in STRATEGY_DENOMINATORS.items():
        frame[metric] = frame["full_avg_ll"] - frame[f"{denominator}_avg_ll"]
    frame["perplexity"] = np.exp(-frame["full_avg_ll"])
    wrong = frame["model_output_solution_correctness"].eq("wrong")
    first = pd.to_numeric(frame["model_output_solution_first_error_step"], errors="coerce")
    assert first[wrong].notna().all()
    frame["first_error"] = (wrong & frame["step"].eq(first)).astype(int)
    assert frame.loc[wrong].groupby("uuid")["first_error"].sum().eq(1).all()
    # Later steps in wrong solutions have unknown correctness; this label means
    # "annotated FIRST error" versus every other step, not correct vs incorrect.
    frame["verified_step"] = ~wrong | frame["step"].le(first)
    frame["last_step"] = frame.groupby("uuid")["step"].transform("max")
    return frame


def add_signal_scores(frame):
    """Score raw generic DC-PMI, first differences, and offline peaks."""
    import numpy as np
    from scipy.signal import find_peaks

    frame = compute_first_differences(
        frame, ["dc_pmi_generic_domain", "dc_pmi_history_ablation"], drop_missing=False
    )
    frame["negative_generic_pmi"] = -frame["dc_pmi_generic_domain"]
    generic = frame["dc_pmi_generic_domain_first_difference"]
    history = frame["dc_pmi_history_ablation_first_difference"]
    frame["generic_drop"] = -generic
    frame["generic_increase_next"] = generic.groupby(frame["uuid"]).shift(-1)
    frame["history_increase_next"] = history.groupby(frame["uuid"]).shift(-1)
    for label, differences in [("generic", generic), ("history", history)]:
        mean = differences.groupby(frame["uuid"]).transform("mean")
        std = differences.groupby(frame["uuid"]).transform("std").replace(0, np.nan)
        z = ((differences - mean) / std).fillna(0)
        frame[f"{label}_z_next"] = z.groupby(frame["uuid"]).shift(-1)
        prominence = pd.Series(0.0, index=frame.index)
        for _, group in frame.groupby("uuid", sort=False):
            values = differences.loc[group.index].iloc[1:].to_numpy()
            assert np.isfinite(values).all()
            # Pad endpoints so a rebound on the final step is eligible as a peak.
            low = values.min() - 1
            peaks, properties = find_peaks(
                np.r_[low, values, low], prominence=0
            )
            prominence.loc[group.index[1:][peaks - 1]] = properties["prominences"]
        frame[f"{label}_peak_next"] = prominence.groupby(frame["uuid"]).shift(-1)
    return frame


def load_signal_cache(source_path, derived_path):
    """Reuse derived CPU-only features if the source token-logprob cache is unchanged."""
    source_path, derived_path = Path(source_path), Path(derived_path)
    assert source_path.exists(), f"Missing 1000-sample cache: {source_path}"
    if derived_path.exists() and derived_path.stat().st_mtime >= max(
        source_path.stat().st_mtime, Path(__file__).stat().st_mtime
    ):
        result = pd.read_parquet(derived_path)
    else:
        result = add_signal_scores(load_cached_signal_scores(source_path))
        keep = ["uuid", "step", "first_error", "verified_step", "last_step", *SIGNAL_TITLES]
        result = result[keep]
        derived_path.parent.mkdir(parents=True, exist_ok=True)
        temporary = derived_path.with_suffix(".tmp.parquet")
        result.to_parquet(temporary, index=False)
        temporary.replace(derived_path)
    assert result["uuid"].nunique() == 1000 and len(result) == 7012
    return result


SIGNAL_TITLES = {
    "negative_generic_pmi": "Negative generic DC-PMI (raw)",
    "generic_drop": "Generic drop (immediate)",
    "generic_increase_next": "Generic increase (one-step delay)",
    "history_increase_next": "History increase (one-step delay)",
    "generic_z_next": "Generic rebound z-score (offline)",
    "history_z_next": "History rise z-score (offline)",
    "generic_peak_next": "Generic peak prominence (offline)",
    "history_peak_next": "History peak prominence (offline)",
}


def evaluate_signal_scores(frame, columns, verified_only=False):
    """ROC AUC over all eligible steps and on the common eligible subset."""
    from sklearn.metrics import roc_auc_score

    pool = frame.loc[frame["verified_step"]] if verified_only else frame
    common = pool[list(columns)].notna().all(axis=1)
    rows = []
    for column in columns:
        for subset, mask in [("eligible", pool[column].notna()), ("common", common),
                             ("all_steps_neutral", pd.Series(True, index=pool.index))]:
            selected = pool.loc[mask]
            assert selected["first_error"].nunique() == 2
            scores = selected[column].fillna(0) if subset == "all_steps_neutral" else selected[column]
            rows.append({
                "signal": column,
                "subset": subset,
                "auc": roc_auc_score(selected["first_error"], scores),
                "steps": len(selected),
                "first_errors": int(selected["first_error"].sum()),
                "coverage": pool[column].notna().mean() if subset == "all_steps_neutral" else len(selected) / len(pool),
            })
    return pd.DataFrame(rows)


def expected_step_counts(sample):
    return {
        example["uuid"]: len(parse_steps(example["model_output_steps"])) for example in sample
    }


def validate_cache(frame, sample):
    assert set(frame.columns) == set(CACHE_SCHEMA.names), "Cache schema does not match the scorer"
    expected_steps = expected_step_counts(sample)
    assert set(frame["uuid"]) <= set(expected_steps), "Cache contains UUIDs outside this sample"
    assert not frame.duplicated(["uuid", "step"]).any(), "Cache has duplicate steps"
    counts = frame.groupby("uuid")["step"].count().to_dict()
    assert all(count == expected_steps[uuid] for uuid, count in counts.items()), (
        "Cache contains an incomplete example"
    )
    assert set(frame["question_type"]) == {"original"}
    expected_indices = {example["uuid"]: index for index, example in enumerate(sample)}
    assert all(
        expected_indices[uuid] == sample_index
        for uuid, sample_index in frame[["uuid", "sample_index"]].drop_duplicates().itertuples(index=False)
    )
    for context in LOGPROB_CONTEXTS:
        for token_ids, token_logprobs in zip(
            frame[f"{context}_token_ids"], frame[f"{context}_token_logprobs"]
        ):
            assert len(token_ids) == len(token_logprobs) > 0


def read_cache(path, sample=None):
    frame = pq.read_table(path).to_pandas()
    if sample is not None:
        validate_cache(frame, sample)
    return frame


def cache_records(frame):
    records = frame.to_dict("records")
    for record in records:
        for field in CACHE_SCHEMA:
            value = record[field.name]
            if pa.types.is_list(field.type):
                record[field.name] = value.tolist() if hasattr(value, "tolist") else value
            elif field.nullable and pd.isna(value):
                record[field.name] = None
    return records


def write_cache(frame, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path = path.with_suffix(path.suffix + ".tmp")
    table = pa.Table.from_pylist(cache_records(frame), schema=CACHE_SCHEMA)
    pq.write_table(table, temporary_path, compression="zstd")
    temporary_path.replace(path)
    print(
        f"Checkpointed {frame['uuid'].nunique()} examples and {len(frame)} steps to {path.resolve()}",
        flush=True,
    )


def score_sample_to_cache(
    sample,
    cache_path,
    token,
    model_id=DEFAULT_MODEL_ID,
    target_batch_size=8,
    checkpoint_every=10,
    bootstrap_cache=None,
):
    assert target_batch_size > 0
    assert checkpoint_every > 0
    cache_path = Path(cache_path)
    bootstrap_cache = Path(bootstrap_cache) if bootstrap_cache is not None else None
    cache_source = cache_path if cache_path.exists() else bootstrap_cache
    if cache_source is not None and cache_source.exists():
        step_logprobs = read_cache(cache_source, sample)
        print(
            f"Loaded {step_logprobs['uuid'].nunique()} completed examples from {cache_source.resolve()}",
            flush=True,
        )
    else:
        step_logprobs = pd.DataFrame(columns=CACHE_SCHEMA.names)

    completed_uuids = set(step_logprobs["uuid"])
    pending = [
        (sample_index, example)
        for sample_index, example in enumerate(sample)
        if example["uuid"] not in completed_uuids
    ]
    if not pending:
        if cache_source != cache_path:
            write_cache(step_logprobs, cache_path)
        print("All examples are already scored.", flush=True)
        return step_logprobs

    model, tokenizer, input_device = load_model(model_id, token)
    print(f"{len(pending)} examples remain.", flush=True)
    new_rows = []
    since_checkpoint = 0
    for sample_index, example in tqdm(pending, total=len(pending)):
        scored_steps = compute_all_logprobs(
            model,
            tokenizer,
            input_device,
            example["question"],
            example["model_output_steps"],
            target_batch_size,
        )
        metadata = {column: example[column] for column in METADATA_COLUMNS}
        for row in scored_steps:
            new_rows.append({"sample_index": sample_index, **metadata, **row})
        since_checkpoint += 1

        if since_checkpoint >= checkpoint_every or stop_requested:
            step_logprobs = pd.concat(
                [step_logprobs, pd.DataFrame(new_rows)], ignore_index=True
            )
            validate_cache(step_logprobs, sample)
            write_cache(step_logprobs, cache_path)
            new_rows = []
            since_checkpoint = 0
        if stop_requested:
            raise SystemExit(143)

    if new_rows:
        step_logprobs = pd.concat(
            [step_logprobs, pd.DataFrame(new_rows)], ignore_index=True
        )
        validate_cache(step_logprobs, sample)
        write_cache(step_logprobs, cache_path)
    assert step_logprobs["uuid"].nunique() == len(sample)
    print("Scoring complete.", flush=True)
    return step_logprobs


def main():
    args = parse_args()
    assert args.sample_size > 0
    repository_root = Path(__file__).resolve().parent.parent
    load_dotenv(repository_root / "secret.env")
    token = os.environ.get("HF_TOKEN", "")
    assert token.startswith("hf_"), "No HF_TOKEN configured"
    sample, original_size = load_original_sample(
        args.sample_size, args.seed, token, args.dataset_id
    )
    print(
        f"Sampled {len(sample)} of {original_size} original questions (seed={args.seed}).",
        flush=True,
    )
    score_sample_to_cache(
        sample=sample,
        cache_path=args.cache_path,
        token=token,
        model_id=args.model_id,
        target_batch_size=args.target_batch_size,
        checkpoint_every=args.checkpoint_every,
        bootstrap_cache=args.bootstrap_cache,
    )


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, request_stop)
    signal.signal(signal.SIGINT, request_stop)
    main()
