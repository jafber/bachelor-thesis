"""Teacher-forced per-step likelihoods and CPU-only DC-PMI evaluation."""
import math

import numpy as np
import pandas as pd
from sklearn.metrics import roc_auc_score

from .benchmarks import ROOT, numbered_steps, problem_for
from .experiment_cache import CachedExperiment, ExperimentCache
from .logging_setup import logger

PROMPT_VERSION = 1
DOMAIN_QUESTION = "A reasoning problem."
INSTRUCTION = "Solve the following problem. Write the solution in logical steps labeled 'Step 1:', 'Step 2:', and so on."
CONTEXTS = ("full", "generic_domain", "question_ablated", "history_ablated")
DENOMINATORS = {"dc_pmi_generic_domain": "generic_domain",
                "dc_pmi_question_ablation": "question_ablated",
                "dc_pmi_history_ablation": "history_ablated"}
METRICS = ("perplexity", *DENOMINATORS)


def scoring_inputs(e):
    """All four contexts: two histories and two sets of isolated steps."""
    steps = numbered_steps(e)
    assert steps
    return dict(question=problem_for(e), domain=DOMAIN_QUESTION, steps=steps)


def step_offsets(prompt, steps):
    text = prompt + "\n" + "\n".join(steps)
    cursor = len(prompt) + 1
    spans = []
    for step in steps:
        spans.append((cursor, cursor + len(step)))
        cursor += len(step) + 1
    assert cursor - 1 == len(text)
    return text, spans


def token_span(offsets, start, end):
    # Assign boundary-crossing tokens to the step in which they END. Newline-only
    # tokens are excluded; indices address the logprob array (token position - 1).
    positions = [i - 1 for i, (a, b) in enumerate(offsets)
                 if i > 0 and b > start and b <= end and b > a]
    assert positions and positions == list(range(positions[0], positions[-1] + 1)), (
        f"No contiguous tokens for step [{start}, {end})")
    return [positions[0], positions[-1] + 1]


def validate_payload(payload, steps):
    assert set(payload) == set(CONTEXTS)
    for name in CONTEXTS:
        entry = payload[name]
        assert set(entry) == {"token_ids", "token_logprobs", "step_spans"}
        assert len(entry["token_ids"]) == len(entry["token_logprobs"])
        assert len(entry["step_spans"]) == steps
        assert all(math.isfinite(value) for value in entry["token_logprobs"])
        assert all(0 <= a < b <= len(entry["token_logprobs"])
                   for a, b in entry["step_spans"])
        assert all(left[1] <= right[0] for left, right in zip(entry["step_spans"], entry["step_spans"][1:]))


class LikelihoodBackend:
    def __init__(self, model_id, inference_batch_size):
        logger.info("Loading torch and transformers for DC-PMI")
        import torch
        from transformers import AutoModelForCausalLM, AutoTokenizer
        logger.info("Torch and transformers loaded for DC-PMI")

        assert torch.cuda.is_available(), "CUDA required for inference"
        logger.info("Initializing DC-PMI model %s", model_id)
        self.tokenizer = AutoTokenizer.from_pretrained(model_id, use_fast=True)
        assert self.tokenizer.is_fast, "Fast tokenizer required for step offsets"
        if self.tokenizer.pad_token_id is None:
            self.tokenizer.pad_token = self.tokenizer.eos_token
        self.tokenizer.padding_side = "right"
        logger.info("Loading weights for model %s", model_id)
        self.model = AutoModelForCausalLM.from_pretrained(model_id, dtype=torch.bfloat16,
                                                          device_map="auto").eval()
        logger.info("DC-PMI model %s ready", model_id)
        self.device = self.model.get_input_embeddings().weight.device
        self.inference_batch_size = inference_batch_size
        torch.cuda.reset_peak_memory_stats(self.device)

    def prompt(self, question):
        return self.tokenizer.apply_chat_template(
            [{"role": "user", "content": f"{INSTRUCTION}\n\nQuestion:\n{question}"}],
            tokenize=False, add_generation_prompt=True, enable_thinking=False)

    def score_texts(self, texts):
        import torch
        import torch.nn.functional as F

        results = []
        for start in range(0, len(texts), self.inference_batch_size):
            batch = texts[start:start + self.inference_batch_size]
            encoded = self.tokenizer(batch, add_special_tokens=False, padding=True,
                                     return_offsets_mapping=True, return_tensors="pt")
            offsets = encoded.pop("offset_mapping").tolist()
            input_ids = encoded["input_ids"]
            lengths = encoded["attention_mask"].sum(dim=1).tolist()
            assert max(lengths) <= self.model.config.max_position_embeddings
            with torch.inference_mode():
                model_inputs = {name: tensor.to(self.device) for name, tensor in encoded.items()}
                logits = self.model(**model_inputs, use_cache=False).logits
                logprobs = -F.cross_entropy(logits[:, :-1, :].transpose(1, 2),
                                            model_inputs["input_ids"][:, 1:], reduction="none").float().cpu()
            for row, length in enumerate(lengths):
                results.append((input_ids[row, 1:length].tolist(), logprobs[row, :length - 1].tolist(),
                                offsets[row][:length]))
        return results

    def score_batch(self, batch):
        requests = []
        descriptions = []
        for index, (_, inputs) in enumerate(batch):
            steps = inputs["steps"]
            question_prompt = self.prompt(inputs["question"])
            domain_prompt = self.prompt(inputs["domain"])
            for context, prompt in (("full", question_prompt), ("question_ablated", domain_prompt)):
                text, spans = step_offsets(prompt, steps)
                requests.append(text)
                descriptions.append((index, context, spans))
            for context, prompt in (("generic_domain", domain_prompt), ("history_ablated", question_prompt)):
                for step in steps:
                    text, spans = step_offsets(prompt, (step,))
                    requests.append(text)
                    descriptions.append((index, context, spans))
        payloads = [{context: {"token_ids": [], "token_logprobs": [], "step_spans": []}
                     for context in CONTEXTS} for _ in batch]
        for (index, context, spans), (ids, logprobs, offsets) in zip(descriptions, self.score_texts(requests)):
            entry = payloads[index][context]
            if context in {"full", "question_ablated"}:
                entry["token_ids"] = ids
                entry["token_logprobs"] = logprobs
                entry["step_spans"] = [token_span(offsets, a, b) for a, b in spans]
            else:
                a, b = token_span(offsets, *spans[0])
                shift = len(entry["token_logprobs"])
                entry["token_ids"].extend(ids[a:b])
                entry["token_logprobs"].extend(logprobs[a:b])
                entry["step_spans"].append([shift, shift + b - a])
        for (_, inputs), payload in zip(batch, payloads):
            validate_payload(payload, len(inputs["steps"]))
        return payloads

    def log_peak_memory(self):
        import torch

        torch.cuda.synchronize(self.device)
        logger.info("Peak GPU memory allocated on %s: %.2f GiB", self.device,
                    torch.cuda.max_memory_allocated(self.device) / (1024 ** 3))


class DCExperiment(CachedExperiment):
    def __init__(self, cache, config, batch_size, cache_only):
        super().__init__(cache, config, PROMPT_VERSION, batch_size, cache_only, logger)
        self.backend = None

    def inputs(self, e):
        return scoring_inputs(e)

    def process(self, batch):
        if self.backend is None:
            logger.info("Loading DC-PMI backend for first cache miss")
            self.backend = LikelihoodBackend(self.config["model_id"], self.config["inference_batch_size"])
            logger.info("Starting DC-PMI inference: %s samples, batch size %s, inference batch size %s",
                        self.inference_count, self.batch_size, self.config["inference_batch_size"])
        return self.backend.score_batch(batch)

    def record(self, e, key, payload):
        validate_payload(payload, len(e.steps))
        return (e, key, payload)

    def log_peak_memory(self):
        if self.backend is not None:
            self.backend.log_peak_memory()


def derive_scores(records):
    rows = []
    for e, key, payload in records:
        for index in range(len(e.steps)):
            totals = {}
            for context in CONTEXTS:
                entry = payload[context]
                a, b = entry["step_spans"][index]
                totals[context] = float(np.sum(entry["token_logprobs"][a:b]))
            full_tokens = payload["full"]["step_spans"][index][1] - payload["full"]["step_spans"][index][0]
            average_full = totals["full"] / full_tokens
            row = dict(benchmark=e.benchmark, task=e.task, uid=e.uid, label=e.label,
                       step=index, first_error=e.label == index,
                       verified=e.label is None or index <= e.label, cache_key=key,
                       tokens=full_tokens,
                       average_log_likelihood=average_full,
                       perplexity=math.exp(-average_full))
            row.update({metric: totals["full"] - totals[denominator]
                        for metric, denominator in DENOMINATORS.items()})
            rows.append(row)
    return pd.DataFrame(rows)


def auc_statistics(scores):
    """ROC AUC on known-correct steps and annotated first errors only."""
    rows = []
    for (benchmark, task), group in scores.groupby(["benchmark", "task"], sort=False):
        eligible = group[group.verified]
        for metric in METRICS:
            # Low DC-PMI and high perplexity indicate an error.
            values = eligible[metric] * (1 if metric == "perplexity" else -1)
            rows.append(dict(benchmark=benchmark, task=task, metric=metric,
                             n_examples=group.uid.nunique(), n_steps=len(eligible),
                             first_errors=int(eligible.first_error.sum()),
                             coverage=len(eligible) / len(group),
                             auc=roc_auc_score(eligible.first_error, values)
                             if eligible.first_error.nunique() == 2 else float("nan")))
    return pd.DataFrame(rows)


def evaluate(examples, *, model_id="Qwen/Qwen3.5-4B", cache_path=ROOT / "cache" / "dc_pmi.sqlite",
             cache_only=False, batch_size=1, inference_batch_size=1):
    assert inference_batch_size > 0
    config = dict(model_id=model_id, inference_batch_size=inference_batch_size,
                  instruction=INSTRUCTION, domain_question=DOMAIN_QUESTION)
    experiment = DCExperiment(ExperimentCache(cache_path, "likelihoods"), config,
                              batch_size, cache_only)
    return derive_scores(experiment.run(examples))
