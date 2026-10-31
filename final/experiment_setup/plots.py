"""Plots for first-error detection experiments."""

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from sklearn.metrics import roc_auc_score, roc_curve

from .dc_pmi import METRICS

METRIC_LABELS = {
    "perplexity": "Perplexity",
    "dc_pmi_generic_domain": "DC-PMI (generic domain)",
    "dc_pmi_question_ablation": "DC-PMI (question ablated)",
    "dc_pmi_history_ablation": "DC-PMI (history ablated)",
}


def plot_first_error_roc(scores):
    """ROC curves and pooled step-level AUCs, separately for each benchmark.

    Use only steps up to the annotated first error (and all steps of correct
    traces). A high perplexity or a low DC-PMI predicts the first error.
    """
    benchmarks = list(scores.benchmark.unique())
    assert benchmarks, "No benchmark scores to plot"
    assert set(METRICS) <= set(scores.columns)
    fig, axes = plt.subplots(1, len(benchmarks), figsize=(6 * len(benchmarks), 5),
                             squeeze=False)
    rows = []
    for ax, benchmark in zip(axes[0], benchmarks):
        group = scores[(scores.benchmark == benchmark) & scores.verified]
        labels = group.first_error.astype(bool)
        if labels.nunique() < 2:
            ax.text(0.5, 0.5, "Both classes required for ROC", ha="center", va="center",
                    transform=ax.transAxes)
        else:
            for metric in METRICS:
                values = group[metric] * (1 if metric == "perplexity" else -1)
                fpr, tpr, _ = roc_curve(labels, values)
                auc = roc_auc_score(labels, values)
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
    """Mean per-trace scores relative to the first error, with 95% bootstrap CIs.

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
        relative = group.copy()
        relative["offset"] = relative.step - origin.step
        relative = relative[relative.offset.between(-window, window)]
        for metric in METRICS:
            assert np.isfinite(origin[metric]) and origin[metric] != 0, (
                f"Cannot normalize {metric} at the first error for {uid}")
            relative[metric] = relative[metric] / origin[metric]
        traces.append(relative)
    assert traces, "No annotated first-error traces to plot"
    aligned = pd.concat(traces, ignore_index=True)

    fig, axes = plt.subplots(1, len(METRICS), figsize=(6 * len(METRICS), 5),
                             sharex=True, squeeze=False)
    for ax, metric in zip(axes[0], METRICS):
        sns.lineplot(data=aligned, x="offset", y=metric, estimator="mean",
                     errorbar=("ci", 95), seed=42, marker="o", ax=ax)
        ax.axvline(0, color="black", linestyle="--", alpha=0.4)
        ax.axhline(1, color="black", linestyle=":", alpha=0.4)
        ax.set(title=METRIC_LABELS[metric], xlabel="Steps from first error",
               ylabel="Score relative to first error", xticks=range(-window, window + 1))
    fig.tight_layout()
    return fig
