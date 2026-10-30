# `final/`

Final thesis experiments on locating the first error in LLM reasoning traces across MR-GSM8K, BIG-Bench Mistake, and ProcessBench.

## Directory overview

- `llm_critic.py` — Loads benchmarks, prompts an LLM judge, caches responses, and computes evaluation statistics.
- `run_critic_experiment.py` — CLI for cache-resumable benchmark runs, sampling/filtering, and CSV results/statistics (usable in SLURM jobs).
- `slurm_jobs/` — SLURM scripts: `run_qwen35_4b_smoke.slurm` tests four examples per task; `run_qwen35_{4b,9b,27b}_full.slurm` run all examples in non-thinking mode.
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

As a rule of thumb, a module's tests should not be longer than the module itself. Just cover the most common use cases and pitfalls. No need to cover every possible execution path.

### Break the cache when making changes

Don't bother writing migrations for the sqlite cache. Trust the user to replace the cache whenever breaking changes are made.

### Never use nested functions

Keep functions short. Don't nest.
