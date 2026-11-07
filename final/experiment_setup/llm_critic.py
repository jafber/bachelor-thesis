"""Zero-shot first-error localization across three reasoning-trace benchmarks.

Cache stores full decoded chat transcripts (including special tokens) and example identities,
never parsed labels. SQLite commits each transcript immediately; cache keys include the
exact prompt, model ID, mode and decoding settings.
"""
import re

import pandas as pd
from sklearn.metrics import f1_score, matthews_corrcoef

from .benchmarks import (ROOT, BBM_TASKS, PB_TASKS, Example, load_examples, sample_tasks, problem_for, solution_for)
from .chat_templates import chat_template_kwargs
from .experiment_cache import CachedExperiment, ExperimentCache, cache_key as shared_cache_key
from .logging_setup import logger

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
    text = transcript.replace("<|endoftext|>", "").strip()
    text = re.sub(r"(?:<\|[A-Za-z0-9_]+\|>\s*)+$", "", text).strip()
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


class LLMJudge:
    """Lazy GPU backend: not instantiated unless some response is missing."""
    def __init__(self, model_id, thinking, max_new_tokens, *, generation_kwargs=None):
        logger.info("Loading torch and transformers for LLM judge")
        import torch
        from transformers import AutoModelForCausalLM, AutoTokenizer
        logger.info("Torch and transformers loaded for LLM judge")

        assert torch.cuda.is_available(), "CUDA required for inference"
        logger.info("Initializing LLM judge model %s", model_id)
        self.tokenizer = AutoTokenizer.from_pretrained(model_id)
        self.tokenizer.padding_side = "left"
        if self.tokenizer.pad_token_id is None:
            self.tokenizer.pad_token = self.tokenizer.eos_token
        logger.info("Loading weights for model %s", model_id)
        self.model = AutoModelForCausalLM.from_pretrained(model_id, dtype=torch.bfloat16, device_map="auto").eval()
        logger.info("LLM judge model %s ready", model_id)
        self.device = self.model.device
        torch.cuda.reset_peak_memory_stats(self.device)
        self.model_id, self.thinking, self.max_new_tokens = model_id, thinking, max_new_tokens
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
            tokenize=True, add_generation_prompt=True,
            padding=True, return_tensors="pt", return_dict=True,
            **chat_template_kwargs(self.model_id, self.thinking),
        ).to(self.model.device)
        with torch.inference_mode():
            outputs = self.model.generate(**inputs, **self._generate_kwargs(inputs["input_ids"].shape[1]),
                                          pad_token_id=self.tokenizer.pad_token_id)
        # Keep the complete padded input and generation, including chat-template tokens.
        return self.tokenizer.batch_decode(outputs, skip_special_tokens=False)

def cache_key(e, prompt, config):
    return shared_cache_key(e, prompt, config, PROMPT_VERSION)


class JudgeExperiment(CachedExperiment):
    def __init__(self, cache, config, batch_size, cache_only):
        super().__init__(cache, config, PROMPT_VERSION, batch_size, cache_only, logger)
        self.judge = None

    def inputs(self, e):
        return prompt_for(e)

    def process(self, batch):
        if self.judge is None:
            e = batch[0][0]
            logger.info("Loading judge for first cache miss: %s/%s/%s", e.benchmark, e.task, e.uid)
            config = self.config
            self.judge = LLMJudge(config["model_id"], config["thinking"], config["max_new_tokens"],
                                  generation_kwargs=config["generation_kwargs"])
            logger.info("Judge ready")
            logger.info("Starting LLM judge inference: %s samples, batch size %s",
                        self.inference_count, self.batch_size)
        return self.judge.generate_batch([prompt for _, prompt in batch])

    def log_peak_memory(self):
        if self.judge is not None:
            self.judge.log_peak_memory()


def judge_config(model_id, thinking, max_new_tokens, generation_kwargs):
    chat_template_kwargs(model_id, thinking)
    if max_new_tokens is None:
        max_new_tokens = THINKING_MAX_NEW_TOKENS if thinking else NON_THINKING_MAX_NEW_TOKENS
    assert max_new_tokens > 0
    return dict(model_id=model_id, thinking=thinking, max_new_tokens=max_new_tokens,
                generation_kwargs=generation_kwargs_for(thinking, generation_kwargs))


def run_inference(examples, *, model_id="Qwen/Qwen3.5-4B", thinking=False,
                  max_new_tokens=None, cache_path=ROOT / "cache" / "llm_critic_v2.sqlite",
                  cache_only=False, batch_size=1, generation_kwargs=None):
    config = judge_config(model_id, thinking, max_new_tokens, generation_kwargs)
    JudgeExperiment(ExperimentCache(cache_path, "responses"), config, batch_size, cache_only).run(examples)


def load_run(examples, *, model_id="Qwen/Qwen3.5-4B", thinking=False,
             max_new_tokens=None, cache_path=ROOT / "cache" / "llm_critic_v2.sqlite",
             generation_kwargs=None):
    """Load and parse all cached responses in one query, without inference."""
    config = judge_config(model_id, thinking, max_new_tokens, generation_kwargs)
    cache = ExperimentCache(cache_path, "responses")
    try:
        records = cache.load_run(examples, prompt_for, config, PROMPT_VERSION)
    finally:
        cache.close()
    rows = []
    for e, key, transcript in records:
        prediction, error = parse_response(transcript, e)
        if error:
            logger.debug("UNPARSEABLE %s/%s/%s: %s\n%s", e.benchmark, e.task, e.uid, error, transcript)
        rows.append(dict(benchmark=e.benchmark, task=e.task, uid=e.uid, label=e.label,
                         prediction=prediction, parse_error=error, transcript=transcript, cache_key=key))
    return pd.DataFrame(rows)


def evaluate(examples, *, model_id="Qwen/Qwen3.5-4B", thinking=False,
             max_new_tokens=None, cache_path=ROOT / "cache" / "llm_critic_v2.sqlite",
             cache_only=False, batch_size=1, generation_kwargs=None):
    examples = list(examples)
    if not cache_only:
        run_inference(examples, model_id=model_id, thinking=thinking, max_new_tokens=max_new_tokens,
                      cache_path=cache_path, batch_size=batch_size, generation_kwargs=generation_kwargs)
    return load_run(examples, model_id=model_id, thinking=thinking, max_new_tokens=max_new_tokens,
                    cache_path=cache_path, generation_kwargs=generation_kwargs)


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
