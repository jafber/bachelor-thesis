"""Teacher-forced per-step likelihoods and CPU-only DC-PMI evaluation."""
import math

import numpy as np
import pandas as pd
from sklearn.base import BaseEstimator, ClassifierMixin
from sklearn.metrics import make_scorer, f1_score, matthews_corrcoef, roc_auc_score
from sklearn.model_selection import TunedThresholdClassifierCV
from scipy.stats import mannwhitneyu

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
f1_scorer = make_scorer(f1_score, zero_division=0)
mcc_scorer = make_scorer(matthews_corrcoef)


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

    def log_peak_memory(self):
        if self.backend is not None:
            self.backend.log_peak_memory()


def derive_scores(records):
    """Reduce variable-length token spans per trace, then derive metrics by column."""
    columns = {name: [] for name in ("benchmark", "task", "uid", "label", "step", "cache_key",
                                     "tokens", *CONTEXTS)}
    for e, key, payload in records:
        validate_payload(payload, len(e.steps))
        n = len(e.steps)
        for name, value in (("benchmark", e.benchmark), ("task", e.task), ("uid", e.uid),
                            ("label", e.label), ("cache_key", key)):
            columns[name].extend([value] * n)
        columns["step"].extend(range(n))
        for context in CONTEXTS:
            entry = payload[context]
            spans = np.asarray(entry["step_spans"])
            cumulative = np.r_[0., np.cumsum(entry["token_logprobs"], dtype=float)]
            columns[context].extend(cumulative[spans[:, 1]] - cumulative[spans[:, 0]])
            if context == "full":
                columns["tokens"].extend(spans[:, 1] - spans[:, 0])
    scores = pd.DataFrame(columns)
    scores["first_error"] = scores.label.eq(scores.step)
    scores["verified"] = scores.label.isna() | scores.step.le(scores.label)
    scores["average_log_likelihood"] = scores.full / scores.tokens
    scores["perplexity"] = np.exp(-scores.average_log_likelihood)
    for metric, denominator in DENOMINATORS.items():
        scores[metric] = scores.full - scores[denominator]
    return scores.drop(columns=list(CONTEXTS))[[
        "benchmark", "task", "uid", "label", "step", "first_error", "verified", "cache_key",
        "tokens", "average_log_likelihood", *METRICS]]


class RawScoreClassifier(ClassifierMixin, BaseEstimator):
    """Expose a metric's raw value as a classifier decision score."""

    def fit(self, X, y):
        self.classes_ = np.unique(y)
        return self

    def decision_function(self, X):
        return np.asarray(X)[:, 0]

    def predict(self, X):
        return self.classes_[(self.decision_function(X) >= 0).astype(int)]


def error_evidence_score(scores, metric):
    """Higher perplexity or lower DC-PMI indicates stronger error evidence."""
    return scores[metric] if metric == "perplexity" else -scores[metric]


def tuned_binary_score(group, metric, scoring):
    labels = group.first_error.astype(int)
    values = error_evidence_score(group, metric).to_numpy().reshape(-1, 1)
    classifier = RawScoreClassifier().fit(values, labels)
    tuned = TunedThresholdClassifierCV(classifier, scoring=scoring, cv="prefit", refit=False)
    tuned.fit(values, labels)
    return scoring(tuned, values, labels)


def statistics(scores):
    """Directional AUC/p-value and in-sample threshold-tuned F1/MCC on all steps.

    Low DC-PMI and high perplexity predict first errors. For DC-PMI only,
    the one-sided Mann–Whitney test asks whether negated scores are higher
    at first-error steps.
    """
    rows = []
    for (benchmark, task), group in scores.groupby(["benchmark", "task"], sort=False):
        has_both_classes = group.first_error.nunique() == 2
        for metric in METRICS:
            evidence = error_evidence_score(group, metric)
            positives = evidence.loc[group.first_error]
            negatives = evidence.loc[~group.first_error]
            rows.append(dict(benchmark=benchmark, task=task, metric=metric,
                             n_examples=group.uid.nunique(), n_steps=len(group),
                             first_errors=int(group.first_error.sum()),
                             coverage=1.0,
                             auc=roc_auc_score(group.first_error, evidence)
                             if has_both_classes else float("nan"),
                             p_value=(1.0 if evidence.nunique() == 1 else
                                      mannwhitneyu(positives, negatives, alternative="greater").pvalue)
                             if has_both_classes and metric != "perplexity" else float("nan"),
                             f1=tuned_binary_score(group, metric, f1_scorer)
                             if has_both_classes and group[metric].nunique() > 1 else float("nan"),
                             mcc=tuned_binary_score(group, metric, mcc_scorer)
                             if has_both_classes and group[metric].nunique() > 1 else float("nan")))
    return pd.DataFrame(rows)


def scoring_config(model_id, inference_batch_size):
    assert inference_batch_size > 0
    return dict(model_id=model_id, inference_batch_size=inference_batch_size,
                instruction=INSTRUCTION, domain_question=DOMAIN_QUESTION)


def run_inference(examples, *, model_id="Qwen/Qwen3.5-4B", cache_path=ROOT / "cache" / "dc_pmi.sqlite",
                  cache_only=False, batch_size=1, inference_batch_size=1):
    """Score missing traces and persist raw logprobs, without computing metrics."""
    config = scoring_config(model_id, inference_batch_size)
    DCExperiment(ExperimentCache(cache_path, "likelihoods"), config, batch_size, cache_only).run(examples)


def load_run(examples, *, model_id="Qwen/Qwen3.5-4B", cache_path=ROOT / "cache" / "dc_pmi.sqlite",
             inference_batch_size=1):
    """Fetch all logprobs in one query and derive step scores without a GPU."""
    config = scoring_config(model_id, inference_batch_size)
    cache = ExperimentCache(cache_path, "likelihoods")
    try:
        logger.info(f"Loading {len(examples)} records from {cache_path}")
        records = cache.load_run(examples, scoring_inputs, config, PROMPT_VERSION)
        logger.info(f"Loaded records")
    finally:
        cache.close()
    return derive_scores(records)


def evaluate(examples, *, model_id="Qwen/Qwen3.5-4B", cache_path=ROOT / "cache" / "dc_pmi.sqlite",
             cache_only=False, batch_size=1, inference_batch_size=1):
    examples = list(examples)
    if not cache_only:
        run_inference(examples, model_id=model_id, cache_path=cache_path, batch_size=batch_size,
                      inference_batch_size=inference_batch_size)
    return load_run(examples, model_id=model_id, cache_path=cache_path,
                    inference_batch_size=inference_batch_size)
