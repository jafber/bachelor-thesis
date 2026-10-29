# `final/`

Final thesis experiments on locating the first error in LLM reasoning traces across MR-GSM8K, BIG-Bench Mistake, and ProcessBench.

## Directory overview

- `llm_critic.py` — Loads benchmarks, prompts an LLM judge, caches responses, and computes evaluation statistics.
- `test_llm_critic.py` — Unit tests for prompts, parsing, caching, batching, and evaluation.
- `benchmark-overview.ipynb` — Inspects the three benchmarks and their example traces and labels.
- `llm-critic-demo.ipynb` — Runs and compares non-thinking and thinking first-error detection.
- `mr-gsm8k-issue.ipynb` — Investigates invalid reference answers in MR-GSM8K reversed examples.
- `prompts.ipynb` — Inspects a judge's full tokenized prompt and generated response.
- `BIG-Bench-Mistake/` — Bundled benchmark JSONL data, README, license, and results image; `annotate_dyck_languages.py` annotates Dyck-language trace mistakes.
- `papers/` — Benchmark paper PDFs and reading notes.
- `cache/` — Generated SQLite response cache; `__pycache__/` — generated Python bytecode.

**Update this `AGENTS.md` whenever creating new files or deleting files in this directory or its subdirectories.**

## Instructions

### Keep unit tests to a minimum

The test file should be short enough to be human-readable. Just cover the most common use cases and pitfalls. No need to cover every possible execution path.

### Break the cache when making changes

Don't bother writing migrations for the sqlite cache. Trust the user to replace the cache whenever breaking changes are made.
