= Conclusion

We adapted contextual calibration to score steps in existing reasoning traces. Our _context relevance_ metric compares a step's average token log likelihood under its full context with its likelihood after ablating the question, preceding steps, or both. We evaluated all three variants with five models on three first-error detection benchmarks and compared their predictions with zero-shot @llm judges.

Fully ablated context relevance was associated with annotated first errors in every pooled benchmark–model comparison: negative scores achieved @auroc between 0.645 and 0.751. Full and history ablation outperformed perplexity in these comparisons. Question ablation was generally weaker, but achieved 0.841–0.904 @auroc on tracking shuffled objects. On that task, its thresholded classifier also exceeded each judge's exact-match accuracy under out-of-fold threshold tuning.

We conclude that context relevance is a reliable signal for reasoning correctness in reasoning tasks: a step with a high context relevance is more likely to be correct than a step with low context relevance. However, dedicated @llm judges generally remain more accurate at finding errors than our metric. The direction of the fully ablated signal reverses on tracking shuffled objects, and pooled ranking quality does not guarantee localization within a trace. On ProcessBench, Qwen3.5-27B located 65.9% of annotated first errors as a judge, compared with 22.6% when selecting the lowest fully ablated context relevance. Allowing NONE predictions did not resolve this weakness: even optimistically tuned fully ablated classifiers barely exceeded the always-NONE baseline.

We believe context relevance may nevertheless offer a training-free, compute-efficient signal to complement stronger judges across different task domains. We would especially like to see these questions answered:

- Re-evaluate step-level associations using verified pre-error steps and clean traces, with uncertainty estimates that account for dependence within traces.
- Validate task-specific scoring choices and thresholds on independent data, especially the question-ablation result for tracking shuffled objects.
- Test whether selecting among candidate solutions using context relevance improves answer accuracy, and measure its inference cost against judge-based selection.
- Investigate whether context dependence can help detect safety violations, rather than only reasoning errors.
