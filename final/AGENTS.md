# `final/`

Final thesis experiments on locating the first error in LLM reasoning traces across MR-GSM8K, BIG-Bench Mistake, and ProcessBench.

## Directory overview

- `run_experiment.py` — CLI with `llm_judge` and `dc_pmi` subcommands for cache-resumable benchmark runs and CSV results.
- `experiment_setup/__init__.py` — Python package marker.
- `experiment_setup/benchmarks.py` — Shared benchmark loading, formatting, sampling, and task selection.
- `experiment_setup/experiment_cache.py` — Shared SQLite cache keys and resumable cache-first batch orchestration.
- `experiment_setup/logging_setup.py` — Shared timestamped logging configuration for judge and DC-PMI runs.
- `experiment_setup/llm_critic.py` — LLM judge prompting, generation, parsing, and evaluation statistics.
- `experiment_setup/dc_pmi.py` — Teacher-forced likelihood scoring, token-step spans, DC-PMI/perplexity derivation, and AUC summaries.
- `experiment_setup/plots.py` — Per-benchmark first-error ROC curves and pooled step-level AUCs.
- `tests/__init__.py` — Test package marker.
- `tests/test_llm_critic.py` — Judge and CLI regression tests.
- `tests/test_dc_pmi.py` — DC-PMI, cache, and CLI tests.
- `start_jobs` — Submits independent SLURM batch jobs directly via `sbatch --wrap` for smoke (4B, four examples per task), small (4B/9B/27B, 100 per task), or full (4B/9B/27B, all examples) runs of `llm_judge`, `dc_pmi`, or both. No job arrays or `.slurm` files.
- `benchmark-overview.ipynb` — Inspects the three benchmarks and their example traces and labels.
- `llm-critic-demo.ipynb` — Runs and compares non-thinking and thinking first-error detection.
- `dc-pmi-demo.ipynb` — Samples four examples per task, scores with non-thinking Qwen3.5-4B, and plots per-benchmark ROC curves.
- `mr-gsm8k-issue.ipynb` — Investigates invalid reference answers in MR-GSM8K reversed examples.
- `prompts.ipynb` — Inspects a judge's full tokenized prompt and generated response.
- `BIG-Bench-Mistake/` — Bundled benchmark JSONL data, README, license, and results image; `annotate_dyck_languages.py` annotates Dyck-language trace mistakes.
- `papers/` — Benchmark paper PDFs and reading notes.
- `cache/` — Generated SQLite response/likelihood caches; `__pycache__/` — generated Python bytecode.

**Update this `AGENTS.md` whenever creating new files or deleting files in this directory or its subdirectories.**

## Instructions

### Keep unit tests to a minimum

As a rule of thumb, a module's tests should not be longer than the module itself. Just cover the most common use cases and pitfalls. No need to cover every possible execution path.

### Break the cache when making changes

Don't bother writing migrations for the sqlite cache. Trust the user to replace the cache whenever breaking changes are made.

### Never use nested functions

Keep functions short. Don't nest.
