= Conclusion

This thesis investigated whether contextual calibration, a technique for removing bias from @llm outputs, can be applied to multi-step reasoning tasks. We developed _context relevance_, a new scoring method based on the idea of contextual calibration. For three different variants of this metric, we tested whether they correlated with correct reasoning steps on three separate error detection benchmarks. We compared error detection performance for context relevance with zero-shot @llm judges.

The fully ablated context relevance variant was negatively associated with first errors in every benchmark-model combination, with pooled reasoning-step-level for negative fully ablated context relevance @auroc between 0.645 and 0.751. Fully and history-ablated scores generally discriminated errors better than perplexity alone; question-ablated context relevance was much less effective. Performance varied across tasks, especially among symbolic reasoning tasks. The stronger Qwen3.5 judges generally located first errors more accurately than the context relevance metrics could: for Qwen3.5-27B, the judge found 65.9% of first errors on ProcessBench, compared with 22.6% for fully ablated context relevance.

We conclude that context relevance is a reliable signal for reasoning correctness in reasoning tasks: a step with a high context relevance is more likely to be correct than a step with low context relevance. However, dedicated @llm judges generally remain more accurate at finding errors than our metric.

We believe context relevance may nevertheless offer a training-free, compute efficient signal to complement stronger judges across different task domains. We would especially like to see these questions answered:

- Whether best-of-n sampling with context relevance improves the ability of @llm:pl to produce correct reasoning
- Whether context relevance can also be used for monitoring alignment instead of mathematical correctness
- Why in some tasks, like the tracking shuffled objects task discussed in @task-domains, error steps exhibit an unusually strong correlation with context relevance
