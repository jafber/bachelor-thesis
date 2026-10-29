"""Zero-shot first-error localization across three reasoning-trace benchmarks.

Cache stores full decoded chat transcripts (including special tokens) and example identities,
never parsed labels. SQLite commits each transcript immediately; cache keys include the
exact prompt, model ID, mode and decoding settings.
"""
import ast
from dataclasses import dataclass
import hashlib
import json
import logging
from pathlib import Path
import random
import re
import sqlite3
import sys

import pandas as pd
from sklearn.metrics import f1_score, matthews_corrcoef

ROOT = Path(__file__).resolve().parent
BBM_TASKS = ("dyck_languages", "logical_deduction", "multistep_arithmetic", "tracking_shuffled_objects", "word_sorting")
PB_TASKS = ("gsm8k", "math", "olympiadbench", "omnimath")
PROMPT_VERSION = 4
NON_THINKING_MAX_NEW_TOKENS = 128
THINKING_MAX_NEW_TOKENS = 4096
THINKING_GENERATION_KWARGS = dict(do_sample=True, temperature=1.0, top_p=0.95,
                                  top_k=20, min_p=0.0, presence_penalty=1.5,
                                  repetition_penalty=1.0)
NON_THINKING_GENERATION_KWARGS = dict(do_sample=False)


def generation_kwargs_for(thinking, overrides=None):
    """Resolve mode defaults and optional generation setting overrides."""
    kwargs = (THINKING_GENERATION_KWARGS if thinking else NON_THINKING_GENERATION_KWARGS).copy()
    if overrides:
        assert set(overrides) <= set(THINKING_GENERATION_KWARGS), "Unknown generation setting"
        kwargs.update(overrides)
    assert 0 <= kwargs.get("presence_penalty", 0) <= 2
    return kwargs


class PresencePenalty:
    """Penalize tokens seen in the generated continuation (not the prompt)."""
    def __init__(self, prompt_length, penalty):
        self.prompt_length, self.penalty = prompt_length, penalty

    def __call__(self, input_ids, scores):
        generated = input_ids[:, self.prompt_length:]
        if generated.numel():
            seen = scores.new_zeros(scores.shape)
            seen.scatter_(1, generated, 1.0)
            scores = scores - self.penalty * seen
        return scores



logger = logging.getLogger(__name__)
if not logger.handlers:
    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(name)s: %(message)s",
                                         datefmt="%Y-%m-%d %H:%M:%S"))
    logger.addHandler(handler)
logger.setLevel(logging.INFO)
logger.propagate = False


@dataclass(frozen=True)
class Example:
    benchmark: str
    task: str
    uid: str
    question: str
    steps: tuple[str, ...]
    label: int | None  # zero-based; None means no error
    ground_truth_answer: str | None = None  # reference answer, never shown to the judge


def load_examples():
    """Return tasks in released order, with labels normalized to zero-based."""
    from datasets import load_dataset

    tasks = {}
    mr = load_dataset("Randolphzeng/Mr-GSM8K", split="test")
    for row in mr:
        steps = ast.literal_eval(row["model_output_steps"])
        wrong = row["model_output_solution_correctness"] == "wrong"
        label = int(row["model_output_solution_first_error_step"]) - 1 if wrong else None
        e = Example("MR-GSM8K", row["question_type"], str(row["uuid"]), row["question"], tuple(steps), label, row["ground_truth_answer"])
        tasks.setdefault((e.benchmark, e.task), []).append(e)
    for task in BBM_TASKS:
        with (ROOT / "BIG-Bench-Mistake" / f"{task}.jsonl").open() as file:
            for index, line in enumerate(file):
                row = json.loads(line)
                e = Example("BIG-Bench-Mistake", task, str(index), row["input"], tuple(row["steps"]), row["mistake_index"], row["target"])
                tasks.setdefault((e.benchmark, e.task), []).append(e)
    pb = load_dataset("Qwen/ProcessBench")
    for task in PB_TASKS:
        for row in pb[task]:
            e = Example("ProcessBench", task, str(row["id"]), row["problem"], tuple(row["steps"]), None if row["label"] == -1 else int(row["label"]))
            tasks.setdefault((e.benchmark, e.task), []).append(e)
    for group in tasks.values():
        assert len({e.uid for e in group}) == len(group)
        assert all(e.steps and (e.label is None or 0 <= e.label < len(e.steps)) for e in group)
    return tasks


def sample_tasks(tasks, size=100, seed=42):
    assert size > 0
    # Separate deterministic RNG per task: adding a task does not change other samples.
    return [e for key, group in tasks.items() for e in random.Random(f"{seed}:{key}").sample(group, size)]


def problem_for(e):
    """Restore task instructions omitted from some BIG-Bench Mistake input fields."""
    if e.benchmark != "BIG-Bench-Mistake":
        return e.question
    if e.task == "word_sorting":
        return f"Sort the following words alphabetically: List: {e.question}"
    if e.task == "dyck_languages":
        return ("Complete the rest of the sequence, making sure that the parentheses "
                f"are closed properly. Input: {e.question}")
    if e.task == "multistep_arithmetic":
        return f"Evaluate the following arithmetic expression: {e.question} ?"
    assert e.task in {"logical_deduction", "tracking_shuffled_objects"}
    return e.question


def solution_for(e):
    """Display the released steps with uniform 1-based numbering."""
    if e.benchmark == "MR-GSM8K":
        # Stored steps already include Step i:; remove only that existing prefix.
        # Never split an individual released step on its internal newlines.
        steps = []
        for i, step in enumerate(e.steps, 1):
            match = re.match(r"^Step\s+(\d+):\s*", step)
            assert match and int(match[1]) == i, f"Unexpected MR-GSM8K step label: {step[:80]!r}"
            steps.append(step[match.end():])
    else:
        steps = e.steps
    return "\n".join(f"Step {i}: {step}" for i, step in enumerate(steps, 1))


def prompt_for(e):
    """
    Instruct the model to output "FINAL: <integer or NONE>" line.
    Thinking models will use <think>...</think> to reason before stating their answer.
    """
    return (
        "You are given a step-by-step solution to a reasoning problem. "
        "If the solution contains any mathematical, logical or conceptual errors, identify the FIRST incorrect step. "
        "Be careful: even if the final answer is correct, the solution path may contain errors. "
        f"Problem:\n{problem_for(e)}\n\nSolution:\n{solution_for(e)}\n\n"
        "Output the number of the first erroneous step, or NONE if the solution is fully correct. "
        "Reply with ONLY one line:\n"
        "FINAL: <integer or NONE>"
    )


def parse_response(transcript, e):
    """Parse the final answer, allowing trailing chat-template special tokens."""
    text = re.sub(r"(?:<\|[A-Za-z0-9_]+\|>\s*)+$", "", transcript.strip()).strip()
    match = re.search(r"(?i)^FINAL:\s*(NONE|-?\d+)\s*$", text.splitlines()[-1]) if text else None
    if match is None:
        return None, "missing FINAL line at end of response"
    value = match[1]
    if value.upper() == "NONE":
        return None, None
    number = int(value)
    index = number - 1
    if not 0 <= index < len(e.steps):
        return None, f"out-of-range index {number}; {len(e.steps)} steps"
    return index, None


class ResponseCache:
    def __init__(self, path):
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        self.db = sqlite3.connect(path)
        self.db.execute("CREATE TABLE IF NOT EXISTS responses (key TEXT PRIMARY KEY, benchmark TEXT NOT NULL, task TEXT NOT NULL, uid TEXT NOT NULL, transcript TEXT NOT NULL, config TEXT NOT NULL)")
        self.db.execute("CREATE INDEX IF NOT EXISTS responses_example ON responses (benchmark, task, uid)")
        self.db.commit()

    def get(self, key):
        row = self.db.execute("SELECT transcript FROM responses WHERE key=?", (key,)).fetchone()
        return row[0] if row else None

    def put(self, key, e, transcript, config):
        assert isinstance(transcript, str) and transcript, "Empty transcript: refusing to cache"
        with self.db:
            self.db.execute("INSERT OR IGNORE INTO responses VALUES (?, ?, ?, ?, ?, ?)",
                            (key, e.benchmark, e.task, e.uid, transcript, json.dumps(config, sort_keys=True)))
        assert self.get(key) == transcript, "Conflicting transcript for same cache key"

    def close(self):
        self.db.close()


def cache_key(e, prompt, config):
    payload = dict(benchmark=e.benchmark, task=e.task, uid=e.uid, prompt=prompt, config=config, prompt_version=PROMPT_VERSION)
    return hashlib.sha256(json.dumps(payload, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


class TransformersJudge:
    """Lazy GPU backend: not instantiated unless some response is missing."""
    def __init__(self, model_id, thinking, max_new_tokens, *, generation_kwargs=None):
        logger.info("Importing libraries for inference")
        import torch
        from transformers import AutoModelForCausalLM, AutoTokenizer
        logger.info("Libraries imported")

        assert torch.cuda.is_available(), "CUDA required for inference"
        self.tokenizer = AutoTokenizer.from_pretrained(model_id)
        self.tokenizer.padding_side = "left"
        if self.tokenizer.pad_token_id is None:
            self.tokenizer.pad_token = self.tokenizer.eos_token
        logger.info("Loading weights for model %s", model_id)
        self.model = AutoModelForCausalLM.from_pretrained(model_id, dtype=torch.bfloat16, device_map="auto").eval()
        logger.info("Weights loaded")
        self.device = self.model.device
        torch.cuda.reset_peak_memory_stats(self.device)
        self.thinking, self.max_new_tokens = thinking, max_new_tokens
        self.generation_kwargs = generation_kwargs_for(thinking, generation_kwargs)

    def _generate_kwargs(self, prompt_length):
        kwargs = self.generation_kwargs.copy()
        penalty = kwargs.pop("presence_penalty", 0)
        if penalty:
            kwargs["logits_processor"] = [PresencePenalty(prompt_length, penalty)]
        return dict(max_new_tokens=self.max_new_tokens, **kwargs)

    def log_peak_memory(self):
        """Report peak GPU allocation since this judge was loaded, including weights."""
        import torch

        torch.cuda.synchronize(self.device)
        gib = torch.cuda.max_memory_allocated(self.device) / (1024 ** 3)
        logger.info("Peak GPU memory allocated on %s: %.2f GiB", self.device, gib)

    def generate_batch(self, prompts):
        """Generate one raw response per prompt using a single padded GPU batch."""
        import torch

        assert prompts
        inputs = self.tokenizer.apply_chat_template(
            [[{"role": "user", "content": prompt}] for prompt in prompts],
            tokenize=True, add_generation_prompt=True, enable_thinking=self.thinking,
            padding=True, return_tensors="pt", return_dict=True,
        ).to(self.model.device)
        with torch.inference_mode():
            outputs = self.model.generate(**inputs, **self._generate_kwargs(inputs["input_ids"].shape[1]),
                                          pad_token_id=self.tokenizer.pad_token_id)
        # Keep the complete padded input and generation, including chat-template tokens.
        return self.tokenizer.batch_decode(outputs, skip_special_tokens=False)

    def __call__(self, prompt):
        return self.generate_batch([prompt])[0]


def evaluate(examples, *, model_id="Qwen/Qwen3.5-4B", thinking=False,
             max_new_tokens=None, cache_path=ROOT / "cache" / "llm_critic.sqlite", backend_factory=None,
             cache_only=False, backend_name="transformers", progress=None, batch_size=1,
             generation_kwargs=None):
    """Cache-first; missing entries cause lazy model load. No inference on complete reruns.

    backend_factory(config) may supply a callable(prompt)->transcript, optionally
    with generate_batch(prompts)->list[str]. Only cache misses are batched.
    progress=None shows a tqdm bar in notebooks only; True/False overrides this.
    """
    if max_new_tokens is None:
        max_new_tokens = THINKING_MAX_NEW_TOKENS if thinking else NON_THINKING_MAX_NEW_TOKENS
    assert max_new_tokens > 0
    assert isinstance(batch_size, int) and batch_size > 0
    effective_generation_kwargs = generation_kwargs_for(thinking, generation_kwargs)
    config = dict(model_id=model_id, thinking=thinking,
                  max_new_tokens=max_new_tokens, generation_kwargs=effective_generation_kwargs,
                  backend=backend_name)
    cache = ResponseCache(cache_path)
    judge = None
    rows = []
    pending = []  # (row index, example, prompt, cache key)
    hits = misses = 0
    completed = False
    show_progress = "ipykernel" in sys.modules if progress is None else progress
    total = len(examples) if hasattr(examples, "__len__") else None
    logger.info("Starting evaluation: model=%s examples=%s cache=%s cache_only=%s",
                model_id, total if total is not None else "unknown", cache_path, cache_only)
    def record(index, e, key, transcript):
        prediction, error = parse_response(transcript, e)
        if error:
            logger.warning("UNPARSEABLE %s/%s/%s: %s\n%s", e.benchmark, e.task, e.uid, error, transcript)
        rows[index] = dict(benchmark=e.benchmark, task=e.task, uid=e.uid, label=e.label,
                           prediction=prediction, parse_error=error, transcript=transcript, cache_key=key)

    def log_progress():
        if (hits + misses) % 100 == 0:
            logger.info("Progress: %s/%s examples (cache hits=%s, generated=%s)",
                        hits + misses, total if total is not None else "?", hits, misses)

    def flush():
        nonlocal judge, misses
        if not pending:
            return
        if judge is None:
            e = pending[0][1]
            logger.info("Loading backend for first cache miss: %s/%s/%s", e.benchmark, e.task, e.uid)
            judge = (backend_factory(config) if backend_factory else TransformersJudge(
                model_id, thinking, max_new_tokens, generation_kwargs=effective_generation_kwargs))
            logger.info("Backend ready")
        prompts = [prompt for _, _, prompt, _ in pending]
        transcripts = (judge.generate_batch(prompts) if hasattr(judge, "generate_batch")
                       else [judge(prompt) for prompt in prompts])
        assert len(transcripts) == len(pending), "Backend returned incorrect number of transcripts"
        for (index, e, _, key), transcript in zip(pending, transcripts):
            cache.put(key, e, transcript, config)
            record(index, e, key, transcript)
            misses += 1
            log_progress()
        pending.clear()

    try:
        if show_progress:
            from tqdm.auto import tqdm
            examples = tqdm(examples, total=total, desc="Evaluating", unit="example")
        for e in examples:
            prompt = prompt_for(e)
            key = cache_key(e, prompt, config)
            transcript = cache.get(key)
            index = len(rows)
            rows.append(None)
            if transcript is None:
                if cache_only:
                    raise RuntimeError(f"Cache miss: {e.benchmark}/{e.task}/{e.uid} ({key})")
                pending.append((index, e, prompt, key))
                if len(pending) == batch_size:
                    flush()
            else:
                record(index, e, key, transcript)
                hits += 1
                log_progress()
        flush()
        completed = True
    finally:
        cache.close()
        if isinstance(judge, TransformersJudge):
            judge.log_peak_memory()
        logger.info("Evaluation %s: %s examples (cache hits=%s, generated=%s)",
                    "complete" if completed else "interrupted", hits + misses, hits, misses)
    return pd.DataFrame(rows)


def get_matches(results):
    return (results.parse_error.isna() & results.label.fillna(-1).eq(results.prediction.fillna(-1)))


def statistics(results):
    """Exact localization accuracy (invalid = wrong); binary error F1/MCC on parseable rows.

    F1/MCC exclude invalid outputs, hence always report parse coverage and count alongside.
    """
    rows = []
    for (benchmark, task), group in results.groupby(["benchmark", "task"], sort=False):
        valid = group[group.parse_error.isna()]
        truth = valid.label.notna().astype(int)
        predicted = valid.prediction.notna().astype(int)
        wrong = group.label.notna()
        right = group.label.isna()
        matched = get_matches(group)
        rows.append(dict(benchmark=benchmark, task=task, n=len(group), errors=int(wrong.sum()),
                         unparseable=len(group) - len(valid), coverage=len(valid) / len(group),
                         accuracy=matched.mean(), error_accuracy=matched[wrong].mean() if wrong.any() else float("nan"),
                         no_error_accuracy=matched[right].mean() if right.any() else float("nan"),
                         f1=f1_score(truth, predicted, zero_division=0) if len(valid) else float("nan"),
                         mcc=(matthews_corrcoef(truth, predicted) if truth.nunique() == 2 or predicted.nunique() == 2 else 0.0) if len(valid) else float("nan")))
    return pd.DataFrame(rows)


def random_answers(results, examples, seed=42):
    """Print one question, numbered solution and debugging labels per task."""
    lookup = {(e.benchmark, e.task, e.uid): e for e in examples}
    assert len(lookup) == len(examples), "Duplicate example identities"
    for (benchmark, task), group in results.groupby(["benchmark", "task"], sort=False):
        sample = group.sample(n=1, random_state=seed)
        is_correct = get_matches(sample).iloc[0]
        row = sample.iloc[0]
        example = lookup[(benchmark, task, row.uid)]
        label = "NONE" if example.label is None else f"Step {example.label + 1}"
        print(f"\n=== {benchmark} / {task} / {row.uid} ===\n"
              f"Question:\n{problem_for(example)}\n\nSolution steps:\n{solution_for(example)}\n\n"
              f"Correct answer: {example.ground_truth_answer if example.ground_truth_answer is not None else 'Not provided'}\n"
              f"Ground truth first error step: {label}\nLLM judge's transcript:\n{row.transcript}\nIs match: {is_correct}\n")
