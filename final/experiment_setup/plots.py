"""Plots for first-error detection experiments."""

import matplotlib.pyplot as plt
from matplotlib.patches import Patch
import numpy as np
import pandas as pd
import seaborn as sns
from sklearn.metrics import roc_auc_score, roc_curve

from .dc_pmi import METRICS, error_evidence_score

METRIC_LABELS = {
    "perplexity": "Perplexity",
    "dc_pmi_generic_domain": "Negative DC-PMI (generic domain)",
    "dc_pmi_question_ablation": "Negative DC-PMI (question ablated)",
    "dc_pmi_history_ablation": "Negative DC-PMI (history ablated)",
}


def plot_task_auc_bars(stats, metric, models):
    """Task-level AUROC bars for one scoring method, with one chart per model."""
    assert metric in METRICS
    subset = stats[stats.metric == metric]
    tasks = list(subset[["benchmark", "task"]].drop_duplicates().itertuples(index=False, name=None))
    assert tasks and models
    palette = {"MR-GSM8K": "tab:blue", "BIG-Bench-Mistake": "tab:orange",
               "ProcessBench": "tab:green"}
    assert {benchmark for benchmark, _ in tasks} <= palette.keys()
    fig, axes = plt.subplots(len(models), 1, figsize=(15, 4 * len(models) + 1),
                             sharex=True, sharey=True, squeeze=False)
    for ax, model in zip(axes[:, 0], models):
        values = subset[subset.model == model].set_index(["benchmark", "task"]).reindex(tasks)
        assert values.auc.notna().all(), f"Missing {metric} AUROC for {model}"
        if metric != "perplexity":
            assert values.p_value.notna().all(), f"Missing {metric} p-value for {model}"
        bars = ax.bar(range(len(tasks)), values.auc,
                      color=[palette[benchmark] for benchmark, _ in tasks])
        for bar, p_value in zip(bars, values.p_value):
            if p_value > 0.05:
                bar.set_alpha(0.35)
        ax.axhline(0.5, color="black", linestyle="--", linewidth=1, alpha=0.5)
        ax.set(title=f"Qwen3.5-{model}", ylabel="AUROC", ylim=(0, 1))
        ax.grid(axis="y", alpha=0.2)
        ax.set_axisbelow(True)
        for index in range(1, len(tasks)):
            if tasks[index][0] != tasks[index - 1][0]:
                ax.axvline(index - 0.5, color="gray", linewidth=1)
    axes[-1, 0].set_xticks(range(len(tasks)), [task for _, task in tasks], rotation=45, ha="right")
    fig.suptitle(f"{METRIC_LABELS[metric]} AUROC by task")
    fig.legend(handles=[Patch(color=palette[benchmark], label=benchmark)
                        for benchmark in dict.fromkeys(benchmark for benchmark, _ in tasks)]
               + ([Patch(color="gray", alpha=0.35, label="p > 0.05")]
                  if metric != "perplexity" else []),
               loc="upper center", ncol=4, bbox_to_anchor=(0.5, 0.96))
    fig.tight_layout(rect=(0, 0, 1, 0.91))
    return fig


def plot_matched_step_histograms(error_scores, control_scores, model="4B"):
    """Compare metric distributions at annotated errors and matched control positions.

    Both score tables use `first_error` to mark their aligned step; control
    traces are error-free, so this marks the paired error trace's position.
    """
    assert set(METRICS) <= set(error_scores.columns) & set(control_scores.columns)
    error_steps = error_scores.loc[
        error_scores.uid.str.startswith(f"{model}:") & error_scores.first_error]
    control_steps = control_scores.loc[
        control_scores.uid.str.startswith(f"{model}:") & control_scores.first_error]
    assert len(error_steps) == len(control_steps) > 0, "Expected matched error and control steps"

    fig, axes = plt.subplots(1, len(METRICS), figsize=(6 * len(METRICS), 5))
    for ax, metric in zip(axes, METRICS):
        values = pd.concat([
            pd.DataFrame({"score": error_steps[metric], "group": "First error"}),
            pd.DataFrame({"score": control_steps[metric], "group": "Matched control"}),
        ], ignore_index=True)
        sns.histplot(data=values, x="score", hue="group", bins=30, stat="density",
                     common_norm=False, element="step", ax=ax)
        ax.set(title=metric, xlabel="Step score", ylabel="Density")
    fig.suptitle(f"First-error vs matched control steps · Qwen3.5-{model}", y=1.03)
    fig.tight_layout()
    return fig


def plot_first_error_roc(scores):
    """ROC curves and pooled step-level AUCs, separately for each benchmark.

    Include every step, including steps after the first error. Use negative
    DC-PMI and positive perplexity: higher evidence predicts a first error.
    """
    benchmarks = list(scores.benchmark.unique())
    assert benchmarks, "No benchmark scores to plot"
    assert set(METRICS) <= set(scores.columns)
    fig, axes = plt.subplots(1, len(benchmarks), figsize=(6 * len(benchmarks), 5),
                             squeeze=False)
    rows = []
    for ax, benchmark in zip(axes[0], benchmarks):
        group = scores[scores.benchmark == benchmark]
        labels = group.first_error.astype(bool)
        if labels.nunique() < 2:
            ax.text(0.5, 0.5, "Both classes required for ROC", ha="center", va="center",
                    transform=ax.transAxes)
        else:
            for metric in METRICS:
                evidence = error_evidence_score(group, metric)
                fpr, tpr, _ = roc_curve(labels, evidence)
                auc = roc_auc_score(labels, evidence)
                ax.plot(fpr, tpr, label=f"{METRIC_LABELS[metric]} (AUC {auc:.2f})")
                rows.append(dict(benchmark=benchmark, metric=metric, auc=auc,
                                 n_examples=group.uid.nunique(), n_steps=len(group),
                                 first_errors=int(labels.sum())))
        ax.plot([0, 1], [0, 1], "k--", alpha=0.4)
        ax.set(title=benchmark, xlabel="False positive rate", ylabel="True positive rate",
               xlim=(0, 1), ylim=(0, 1))
        if labels.nunique() == 2:
            ax.legend(fontsize="small", loc="lower right")
    fig.tight_layout()
    return fig, pd.DataFrame(rows)


def plot_first_error_trajectories(scores, window=5):
    """Mean absolute scores with 95% bootstrap CIs, centered at the first-error mean.

    Include all annotated traces across benchmarks, including steps after the
    first error. Each trace contributes at most one observation per offset.
    """
    assert window > 0
    assert set(METRICS) <= set(scores.columns)
    traces = []
    for (benchmark, task, uid), group in scores.groupby(["benchmark", "task", "uid"], sort=False):
        errors = group.loc[group.first_error]
        if errors.empty:
            continue
        assert len(errors) == 1, f"Expected one first error for {benchmark}/{task}/{uid}"
        origin = errors.iloc[0]
        trace = group.copy()
        trace["offset"] = trace.step - origin.step
        traces.append(trace[trace.offset.between(-window, window)])
    assert traces, "No annotated first-error traces to plot"
    aligned = pd.concat(traces, ignore_index=True)

    fig, axes = plt.subplots(1, len(METRICS), figsize=(6 * len(METRICS), 5),
                             sharex=True, squeeze=False)
    for ax, metric in zip(axes[0], METRICS):
        sns.lineplot(data=aligned, x="offset", y=metric, estimator="mean",
                     errorbar=("ci", 95), seed=42, marker="o", ax=ax)
        first_error_mean = aligned.loc[aligned.offset == 0, metric].mean()
        assert np.isfinite(first_error_mean)
        ax.axvline(0, color="black", linestyle="--", alpha=0.4)
        ax.axhline(first_error_mean, color="black", linestyle=":", alpha=0.4)
        lower, upper = ax.get_ylim()
        radius = max(first_error_mean - lower, upper - first_error_mean)
        ax.set(title=METRIC_LABELS[metric], xlabel="Steps from first error",
               ylabel="Score", xticks=range(-window, window + 1),
               ylim=(first_error_mean - radius, first_error_mean + radius))
    fig.tight_layout()
    return fig
