# `final/`

Final thesis experiments on locating the first error in LLM reasoning traces across MR-GSM8K, BIG-Bench Mistake, and ProcessBench.

## Directory overview

- `run_experiment.py` — CLI with `llm_judge` and `dc_pmi` subcommands for cache-resumable benchmark runs and CSV results.
- `experiment_setup/__init__.py` — Python package marker.
- `experiment_setup/benchmarks.py` — Shared benchmark loading, formatting, sampling, and task selection.
- `experiment_setup/chat_templates.py` — Model-specific chat-template options and thinking-mode validation.
- `experiment_setup/experiment_cache.py` — Shared SQLite cache keys and resumable cache-first batch orchestration.
- `experiment_setup/logging_setup.py` — Shared timestamped logging configuration for judge and DC-PMI runs.
- `experiment_setup/llm_critic.py` — LLM judge prompting, generation, parsing, and evaluation statistics.
- `experiment_setup/judge_metrics.py` — Full-denominator trace accuracies and paper-comparable ProcessBench harmonic means and MR-GSM8K MCC.
- `experiment_setup/dc_pmi.py` — Teacher-forced likelihood scoring, token-step spans, DC-PMI/perplexity derivation, and AUC summaries.
- `experiment_setup/plots.py` — Per-benchmark first-error ROC curves, pooled step-level AUCs, and task AUROC bar charts for each scoring method.
- `tests/__init__.py` — Test package marker.
- `tests/test_llm_critic.py` — Judge and CLI regression tests.
- `tests/test_judge_metrics.py` — Judge paper-metric regression tests.
- `tests/test_dc_pmi.py` — DC-PMI, cache, and CLI tests.
- `start_jobs` — Submits independent SLURM batch jobs directly via `sbatch --wrap` for smoke, small (100 per task), or full runs of `llm_judge`, `dc_pmi`, or both. Defaults to Qwen3.5 (4B/9B/27B); `--family llama` uses Llama 3.2 3B and Llama 3.1 8B. No job arrays or `.slurm` files.
- `benchmark-overview.ipynb` — Inspects the three benchmarks and their example traces and labels.
- `llm-critic-demo.ipynb` — Runs and compares non-thinking and thinking first-error detection.
- `dc-pmi-demo.ipynb` — Samples four examples per task, scores with non-thinking Qwen3.5-4B, and plots per-benchmark ROC curves.
- `llm-judge-plots.ipynb` — Full-run judge accuracy table, benchmark accuracy chart, and three paper-metric comparison charts.
- `context-relevance-plots.ipynb` — Full-run plots for context relevance metrics.
- `average-vs-total-ll.ipynb` — Cache-only comparison of benchmark-level first-error AUROC and significance using total vs average log likelihood DC-PMI for all three models.
- `comparison.ipynb` — Cache-only comparison of candidate-step detection and threshold-optimized exact trace accuracy for average-LL context relevance, perplexity, and LLM judges across models and benchmarks.
- `shuffled-objects-task.ipynb` — Cache-only analysis of negative question-ablated DC-PMI first-error detection and LLM judge performance on BIG-Bench Mistake tracking-shuffled-objects traces.
- `mr-gsm8k-issue.ipynb` — Investigates invalid reference answers in MR-GSM8K reversed examples.
- `prompts.ipynb` — Inspects a judge's full tokenized prompt and generated response.
- `BIG-Bench-Mistake/` — Bundled benchmark JSONL data, README, license, and results image; `annotate_dyck_languages.py` annotates Dyck-language trace mistakes.
- `papers/` — Benchmark paper PDFs and reading notes.
- `cache/`, `final-cache/` — Generated SQLite response/likelihood caches; `__pycache__/` — generated Python bytecode.

**Update this `AGENTS.md` whenever creating new files or deleting files in this directory or its subdirectories.**

## Instructions

### Keep unit tests to a minimum

As a rule of thumb, a module's tests should not be longer than the module itself. Just cover the most common use cases and pitfalls. No need to cover every possible execution path.

### Break the cache when making changes

Don't bother writing migrations for the sqlite cache. Trust the user to replace the cache whenever breaking changes are made.

### Never use nested functions

Keep functions short. Don't nest.
