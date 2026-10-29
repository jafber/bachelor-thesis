# CLAUDE.md

Guidance for coding agents working on this bachelor's thesis project.

## Project in one line

Evaluate **PMI / Domain-Conditional PMI (DC-PMI)** as a training-free, zero/few-shot
calibration method that debiases small decoder LLMs on **atomic logical reasoning**
(single-step entailment), then (a) diagnose *where* it helps per logical phenomenon
and (b) make it cheaper than the standard two-pass version.

- No fine-tuning. No parameter updates. Inference-only.
- Small open-weight decoders (1–4B). Single-GPU scale.

## Engineering notes for agents

### Environment

- You are working on the repo [better-nli](https://github.com/jafber/better-nli)
- The repo lives on a compute node of the Hasso Plattner Institute's HPC cluster (1 A100 GPU available)
- Dependencies are managed by the conda env `better-nli` (activated by default)
- When pip packages are missing, just install directly using `pip install ...`; pip lives inside the conda env
- If needed, install additional tooling via `conda install`, NEVER via `sudo apt install`. We do not have `sudo` rights.

### Guidelines

- Score sequences via HF `transformers` forward pass + log-softmax over target tokens.
  Do not use `.generate()` for scoring — you need teacher-forced logprobs of the
  candidate string, not sampled output.
- Use `torch.no_grad()`, bf16, batch by candidate set.
- Greedy/no-sampling for any decoding; temperature is irrelevant to scoring but
  set deterministic seeds for reproducibility.
- Always log: model checkpoint (exact), domain-premise string used, dataset split,
  per-example raw/normalized/DC-PMI scores. The domain premise is a first-class
  experimental variable — never hard-code it silently.

## Core method (read this before touching scoring code)

DC-PMI is a **scoring / re-ranking function over a closed candidate set**, from
Holtzman et al. (2021), "Surface Form Competition".

- Standard scoring: pick `argmax_i P(y_i | x)` over candidates `y_i`.
- Length-normalized: divide log-likelihood by token count (baseline b).
- **DC-PMI**: `argmax_i  P(y_i | x, domain) / P(y_i | domain)`.
  - `P(y_i | x, domain)` ≈ `P(y_i | x)` — the normal conditional.
  - `P(y_i | domain)` = score of the candidate after a short **domain premise**
    (a "null context"), NOT the raw unconditional `P(y_i)`.
  - The domain-premise division is the whole point — raw `P(y_i)` is badly
    calibrated. Do not silently substitute plain PMI.

Why it works: it factors out **surface-form competition** (frequent strings winning
on prior probability, e.g. predicting a contradiction just because a negation token
is likely). It isolates the probability shift the premise actually induces.

### Hard constraints
- DC-PMI applies **only to closed-set selection** (classification / multiple-choice).
  It does NOT apply to open-ended generation.
- ProofWriter has a generative "proof" task (CQ → proof tree). **We do not use it.**
  We use ProofWriter **only as classification**: truth-value labels
  {True, False} (CWA) or {True, False, Unknown} (OWA). Ignore proof trees entirely.
- The candidate set must be small, enumerable, and have a well-defined domain premise.

## Tasks & datasets

| Dataset | Role | How we use it |
|---|---|---|
| ProofWriter / RuleTaker | Primary, controlled logic | Truth-value classification only (CQ → label). Synthetic, clean depth control. |
| FOLIO | Primary, controlled logic | First-order-logic entailment, label classification. |
| MNLI + HANS / stress tests | Secondary, behavioral diagnosis | 3-label NLI {entail, neutral, contradiction}; bucket by perturbation type, report per-bucket accuracy. |

- C1 (diagnostic): per-perturbation accuracy — negation, lexical substitution,
  quantifier inversion, etc. Not just aggregate numbers.
- C2 (efficiency): approximate the marginal `P(y|domain)` in a single pass
  (KV-cache reuse, truncated null contexts). Measure FLOPs + wall-clock vs. accuracy.

## Known risks (do not over-promise results)

- **DC-PMI's published wins are on multiple-choice QA and text classification,
  NOT NLI.** On RTE/CB it was thin or negative. So a clean positive on MNLI is
  not guaranteed. ProofWriter truth-value scoring is untested in the original paper.
- **Domain-premise design does a lot of work** and the paper gives no recipe for
  entailment. Try 2–3 null-context formulations early. This overlaps with C2.
- **Scale matters.** Holtzman used GPT-2/3. At 1–4B the effect may be weaker/noisier
  and was non-monotonic across sizes. Don't over-read small gaps.
- Proposal §3.1 formula consistency: the intuition text writes plain PMI
  (`log P(H|P) − log P(H)`) but the method is DC-PMI (domain-conditional). Use
  DC-PMI consistently in code and writing.

## Model choice (as of 06/2026)

Pick 1–2 of the following at 1–4B. Selection criteria: clean **logprob access** via
HF `transformers`, single-GPU, and — critically — the ability to score sequences
**without any chain-of-thought / "thinking" tokens contaminating the logprobs.**

### Thinking-mode warning (applies to scoring correctness)
PMI scoring reads token-level logprobs of a fixed candidate string. Any reasoning/
"thinking" trace injected by the chat template will corrupt the score. For every
model below: **use the base or non-thinking path, disable thinking, and prefer
raw prompts over chat templates** when scoring. Verify the tokenized input contains
no `<think>` block before trusting any number.

**Gemma 3 (1B / 4B)** — Google.
- 128K context, 140+ languages, runs on a single GPU.
- Clean logprob access via HF transformers; well-documented.
- No thinking-mode toggle to worry about — simplest scoring path. Good default.

**SmolLM3-3B** — Hugging Face.
- Fully open (weights + training data + configs), Apache 2.0. Built for academic
  probing, which fits this project well.
- Competitive with / beats Llama-3.2-3B and Qwen2.5-3B at the 3–4B class.
- 64K native context, 128K via YaRN (not needed for short entailment pairs).
- **Has dual-mode reasoning (thinking toggle).** Use `SmolLM3-3B-Base` or set
  `enable_thinking=False`. Confirm no `<think>` content before scoring.

**Qwen3 (1.7B / 4B)** — Alibaba. Current-gen successor to the originally planned Qwen2.5.
- Same ecosystem/tooling as Qwen2.5; up-to-date.
- **Thinking mode caveat (version-dependent):**
  - Original Qwen3 (Apr 2025, e.g. `Qwen3-1.7B`, `Qwen3-4B`): hybrid, thinking
    **enabled by default**. Must disable via `enable_thinking=False` in
    `apply_chat_template`, or use `/no_think`.
  - Newer `*-2507` checkpoints split into separate `-Instruct` (non-thinking) and
    `-Thinking` builds — pick the **Instruct** one.
- Decide upfront: **disable thinking** for clean PMI scoring without CoT contamination.

### Recommendation
Start the pilot on **Gemma 3 (1B or 4B)** — no thinking toggle = fewest ways to get
the logprobs silently wrong. Add **SmolLM3-3B** (fully open, reproducible) as the
second model for the C1 diagnostic. Use Qwen3 only if a third comparison point is
needed; if so, pin the exact checkpoint and document the thinking-disable flag.

## Key references

- Holtzman et al. (2021), *Surface Form Competition*, EMNLP — DC-PMI source.
- Tafjord, Mishra, Clark (2021), *ProofWriter*, Findings of ACL — dataset; note we
  use only its classification labels, not the proof-generation task.
- McCoy, Pavlick, Linzen (2019), *Right for the Wrong Reasons (HANS)*, ACL.
- Naik et al. (2018), *Stress Test Evaluation for NLI*, COLING.
- Han et al. (2022), *FOLIO*, arXiv.
- Zhao et al. (2021), *Calibrate Before Use*, ICML.