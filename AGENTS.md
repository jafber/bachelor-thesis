# Bachelor thesis repository

You are an AI assistant inside of the repository https://github.com/jafber/bachelor-thesis containing code (`experiments/`) and writing (`thesis/`) for my bachelor thesis titled "Does the Question Support This Reasoning Step? Detecting Reasoning Errors with Contextual Calibration".

## What this thesis is about

Read @thesis/chapters/intro.typ for a two-page overview of the thesis background, motivation and contents.

## `thesis/`

Source code for the thesis written in typst.

### Directory overview

- `main.typ`: typst entry point
- `chapters/`: chapter source files (e.g. `chapters/intro.typ`)
- `figures/`: all figures
- `abstract.typ`: abstract
- `appendix.typ`: appendix

### Typst syntax

**Typst is not LaTeX. Look up syntax before writing formulas!**

Find docs [here](https://typst.app/docs/reference/math/). 

Example of a valid formula:

```
$ op("CR")_"question-ablated" (i) = L(s_i | q, s_(<i)) - L(s_i | q_g, s_(<i)) $
```

## `experiments/`

Experiments on locating the first error in LLM reasoning traces across MR-GSM8K, BIG-Bench Mistake, and ProcessBench.

### Execution environment

You are running on a windows 11 machine with git bash as its default shell.
You can run python modules and notebooks using the uv virtual environment at `~/meine/uni/ba/bachelor-thesis/.venv`. 
When packages are missing, use `uv add` to install them.
NEVER install python packages globally!

Inference is not run on the local machine but rather on a compute node of the HPI high performance cluster.

### Directory overview

- `BIG-Bench-Mistake/`: git submodule with BIG-Bench Mistake benchmark
- `experiment_setup/`: python package for the logic and functionality behind all experiments
- `tests/`: `unittest`'s for the `experiment_setup` package
- `run_experiment.py`: python CLI for starting experiment runs
- `start_jobs`: bash wrapper for scheduling `run_experiment.py` jobs on the cluster
- `check_cuda.py`: python script for checking whether CUDA is set up correctly
- `notebooks/`: jupyter notebooks for exploration and testing
- `plots/`: exported, polished plots for use in the thesis
- `generate-plots.ipynb`: single notebook that regenerates all plots

### Instructions

#### Plot style guide

- Use a cohesive, muted five-model palette in this order: `#4C72B0` (blue), `#DD8452` (orange), `#55A868` (green), `#C44E52` (red), `#8172B3` (purple). Assign each model one color consistently across all plots; do not let plotting-library defaults reorder the colors.
- Set plot text sizes explicitly: axis labels 11 pt; tick labels and legends 9 pt; numeric annotations 9 pt. Keep labels legible at the figure's final size in the thesis.
- No figure headings or chart titles, including subplot titles: the final document already captions figures. Identify groups with axis labels, legends, or the caption instead.
- Write out **“Negative fully ablated CR”**, never “-Fully ablated CR” (or “−Fully ablated CR”), in plot labels and legends.
- Always label charts with the exact numeric values represented (for example, label each bar with its value). Use the same units and precision as the reported results; do not substitute qualitative labels or approximate values.

#### Keep unit tests to a minimum

As a rule of thumb, a module's tests should not be longer than the module itself. Just cover the most common use cases and pitfalls. No need to cover every possible execution path.

#### Break the cache when making changes

Don't bother writing migrations for the sqlite cache. Trust the user to replace the cache whenever breaking changes are made.

#### Never use nested functions

Keep functions short. Don't nest.
