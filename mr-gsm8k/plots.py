"""Shared visualizations for first-error scoring experiments."""

import math

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from sklearn.metrics import roc_auc_score, roc_curve


def align_first_error_steps(frame, window):
    """Keep wrong solutions and align their steps to the annotated first error."""
    assert window >= 0
    if "first_error" in frame:
        error_mask = frame["first_error"].eq(1)
    else:
        wrong = frame["model_output_solution_correctness"].eq("wrong")
        first = pd.to_numeric(frame["model_output_solution_first_error_step"], errors="coerce")
        assert first[wrong].notna().all()
        error_mask = wrong & frame["step"].eq(first)
    errors = frame.loc[error_mask, ["uuid", "step"]]
    assert len(errors) > 0 and not errors["uuid"].duplicated().any()
    aligned = frame.loc[frame["uuid"].isin(errors["uuid"])].copy()
    aligned["relative_step"] = aligned["step"] - aligned["uuid"].map(
        errors.set_index("uuid")["step"]
    )
    return aligned.loc[aligned["relative_step"].between(-window, window)]


def first_error_histogram_groups(frame, column, seed=42):
    """Build error, step-number-matched control, and all verified-correct groups.

    Only steps with an available signal are eligible. Controls are sampled without
    replacement from verified correct steps at each absolute step number.
    """
    eligible = frame.loc[frame[column].notna()].sort_values(["step", "uuid"])
    errors = eligible.loc[eligible["first_error"].eq(1)]
    correct = eligible.loc[eligible["verified_step"] & eligible["first_error"].eq(0)]
    assert len(errors) > 0 and len(correct) > 0
    rng = np.random.default_rng(seed)
    control_indices = []
    for step, error_rows in errors.groupby("step", sort=True):
        candidates = correct.loc[correct["step"].eq(step)]
        assert len(candidates) >= len(error_rows), f"Not enough verified controls at step {step}"
        control_indices.extend(rng.choice(candidates.index.to_numpy(), size=len(error_rows), replace=False))
    controls = correct.loc[control_indices]
    assert len(controls) == len(errors)
    assert errors.groupby("step").size().equals(controls.groupby("step").size())
    return {
        "First error": errors,
        "Step-matched control": controls,
        "All verified correct": correct,
    }


def plot_first_error_histogram(
    frame, column, title=None, seed=42, bins=30, ax=None,
    show_all_verified_correct=False,
):
    """Overlay density histograms; optionally include all verified correct steps."""
    groups = first_error_histogram_groups(frame, column, seed=seed)
    visible = groups if show_all_verified_correct else {
        label: group for label, group in groups.items() if label != "All verified correct"
    }
    if ax is None:
        fig, ax = plt.subplots(figsize=(8, 5), constrained_layout=True)
    else:
        fig = ax.figure
    values = np.concatenate([group[column].to_numpy() for group in visible.values()])
    edges = np.histogram_bin_edges(values, bins=bins)
    for label, group in visible.items():
        ax.hist(group[column], bins=edges, density=True, alpha=0.35,
                label=f"{label} (n={len(group)})")
    ax.set(title=title or column, xlabel=column, ylabel="Density")
    ax.legend()
    return fig, ax, groups


def plot_first_error_roc(y_true, scores, title="First-error classification", figsize=(7, 7)):
    """Plot ROC curves; scores must increase with error likelihood.

    Scores is a mapping of display labels to pandas Series indexed like y_true.
    Missing values are removed separately for each signal.
    """
    assert len(scores) > 0
    fig, ax = plt.subplots(figsize=figsize, constrained_layout=True)
    rows = []
    for label, score in scores.items():
        valid = score.notna()
        truth = y_true.loc[valid]
        assert truth.nunique() == 2, f"Both classes required for {label}"
        fpr, tpr, _ = roc_curve(truth, score.loc[valid])
        area = roc_auc_score(truth, score.loc[valid])
        rows.append({"metric": label, "roc_auc": area})
        ax.plot(fpr, tpr, linewidth=2, label=f"{label} (AUC={area:.3f})")
    ax.plot([0, 1], [0, 1], color="black", linestyle="--", linewidth=1, label="Chance")
    ax.set(title=title, xlabel="False positive rate", ylabel="True positive rate", xlim=(0, 1), ylim=(0, 1))
    ax.legend(loc="lower right")
    return fig, ax, pd.DataFrame(rows)


def plot_first_error_trajectories(
    frame, columns, window=4, title="Scores around the first error",
    ylabels=None, ncols=2, figsize=None, zero_line=True,
):
    """Plot mean score and 95% bootstrap CI at each relative step in wrong solutions.

    columns maps score-column names to subplot titles. Missing values are omitted.
    """
    assert columns and ncols > 0
    aligned = align_first_error_steps(frame, window)
    nrows = math.ceil(len(columns) / ncols)
    if figsize is None:
        figsize = (7 * ncols, 5.5 * nrows)
    fig, axes = plt.subplots(nrows, ncols, figsize=figsize, constrained_layout=True, squeeze=False)
    for ax, (column, label) in zip(axes.flat, columns.items()):
        sns.lineplot(
            data=aligned.dropna(subset=[column]), x="relative_step", y=column,
            marker="o", errorbar=("ci", 95), ax=ax,
        )
        ax.axvline(0, color="tab:red", linestyle="--", linewidth=1.5, label="First error")
        if zero_line is True or (zero_line is not False and column in zero_line):
            ax.axhline(0, color="black", linewidth=0.8)
        ax.set_title(label)
        ax.set_xlabel("Step relative to first error")
        ax.set_ylabel(ylabels[column] if ylabels else column)
        ax.set_xticks(range(-window, window + 1))
        ax.legend()
    for ax in list(axes.flat)[len(columns):]:
        ax.set_visible(False)
    fig.suptitle(title, fontsize=15)
    return fig, axes
