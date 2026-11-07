"""Trace-level judge scores. Unparseable responses count as wrong, never as NONE.

For binary MCC, an invalid response is assigned the opposite of its true binary
class (a false alarm on a clean trace, a miss on an erroneous trace). This makes
all denominators include every trace; unlike the benchmark prompts, our judge
returns one location rather than a separate binary judgement.
"""
import numpy as np
import pandas as pd
from sklearn.metrics import matthews_corrcoef


def score(group):
    """Score one nonempty set of judge rows; labels/predictions are zero-based or NA."""
    if group.empty:
        raise ValueError("Cannot score an empty group")
    valid = group.parse_error.isna()
    truth = group.label.notna()
    predicted = group.prediction.notna().copy()
    predicted.loc[~valid] = ~truth.loc[~valid]
    matched = valid & (truth.eq(group.prediction.notna())) & (
        ~truth | group.label.eq(group.prediction)
    )
    errors = int(truth.sum())
    clean = len(group) - errors
    error_acc = matched[truth].mean() if errors else np.nan
    clean_acc = matched[~truth].mean() if clean else np.nan
    hm = np.nan
    if errors and clean:
        hm = 2 * error_acc * clean_acc / (error_acc + clean_acc) if error_acc + clean_acc else 0.0
    return dict(n=len(group), errors=errors, unparseable=int((~valid).sum()),
                accuracy=matched.mean(), error_accuracy=error_acc,
                correct_accuracy=clean_acc, processbench_hm=hm,
                mr_mcc=matthews_corrcoef(truth, predicted))


def summarize(results, columns=("benchmark",)):
    """Aggregate raw trace rows before computing metrics (never average task MCCs)."""
    return pd.DataFrame([dict(zip(columns, key if isinstance(key, tuple) else (key,)), **score(group))
                         for key, group in results.groupby(list(columns), sort=False)])


def processbench_average(results):
    """Paper Table 3: macro mean of the four task-wise harmonic means."""
    splits = summarize(results[results.benchmark == "ProcessBench"], ("task",))
    return splits.processbench_hm.mean() if len(splits) == 4 else np.nan
