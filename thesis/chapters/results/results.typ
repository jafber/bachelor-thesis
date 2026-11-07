= Results and Discussion

This chapter reports results for Qwen3.5-4B, 9B, and 27B on the three benchmarks introduced in @bench-overview. Unless stated otherwise, the context-relevance analysis covers 8,584 traces#footnote[We excluded one BIG-Bench Mistake Dyck-language trace with a length of 53KB (!) since it was causing memory issues.]. We first examine the four step-scoring methods, then evaluate the judges and finally compare the two approaches.

== Context relevance experiment

=== How do the different scoring methods compare?

We compare the three context-relevance ablations with full-context perplexity. @method-auroc shows that fully ablated and history ablated context relevance generally perform best at predicting first error steps. Specifically, history ablated context relevance is strongest across the MR-GSM8K benchmark and on the BIG-Bench Mistake when evaluated with the 4B model, while fully ablated context relevance is the strongest predictor for all other models and benchmarks.

#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, center, center, center, center, center, center, center, center, center),
    inset: 4pt,
    table.header(
      table.cell(rowspan: 2)[*Method*],
      table.cell(colspan: 3)[*MR-GSM8K*],
      table.cell(colspan: 3)[*BIG-Bench Mistake*],
      table.cell(colspan: 3)[*ProcessBench*],
      [4B], [9B], [27B], [4B], [9B], [27B], [4B], [9B], [27B],
    ),
    [Perplexity], [60.8], [61.1], [63.3], [65.4], [66.5], [67.3], [63.5], [64.0], [64.5],
    [Fully ablated], [64.8], [66.9], [69.8], [66.5], [*68.8*], [*67.5*], [*68.1*], [*68.6*], [*67.9*],
    [Question ablated], [51.0], [47.7], [45.8], [67.9], [67.8], [66.0], [56.7], [56.5], [54.9],
    [History ablated], [*71.5*], [*70.7*], [*70.7*], [*68.0*], [68.2], [66.7], [67.5], [67.2], [66.3],
  ),
  caption: [First-error step @auroc in percent, pooling all task types within each benchmark. Columns distinguish Qwen3.5 model sizes; the highest value in each column is bold. A value of 50 indicates chance ranking; larger values indicate better discrimination. All post-error steps are counted among the other steps.],
) <method-auroc>

Question ablated context relevance generally performs worse than the other scoring methods.

Perplexity is not uniformly worse: on the BIG-Bench Mistake pooled data it reaches 65.4-67.3%, close to the strongest context-relevance variants scoring 67.5-68.0%.

*Discussion.* The data suggest that perplexety alone is a consistently strong signal for first error steps, acheiving >60% @auroc in all model benchmarks. both low history ablated and low fully ablated context relevance show a robust correlation to first error reasoning step, going beyond the information provided by the perplexity alone. The low performance of question ablated context relevance might be attributed to the fact that its correcting factor $L(s_i | q_g, s_(<i))$ includes substantial information about the question itself in the form of prior reasoning steps, losing a lot of information about the @llm's inherent biases.

=== How does performance generalize across different task domains?

The benchmark averages hide pronounced differences between their constituent tasks. @task-auroc gives the same step-level measure separately for all twelve task types, using a heatmap to make changes across methods and models visible. On BIG-Bench Mistake's tracking-shuffled-objects task, question ablation reaches approximately 0.88–0.90 @auroc, whereas fully ablated context relevance is only 0.36–0.40. For logical deduction, question ablation instead falls to 0.39–0.48. On MR-GSM8K's original and reversed problems, history ablation is consistently around 0.72–0.73, while question ablation is at or below chance. Within ProcessBench, fully ablated scores are relatively stable (roughly 0.66–0.70 across tasks and models).

#figure(
  image("task-method-auroc.png", width: 100%),
  caption: [First-error step @auroc by task, scoring method, and Qwen3.5 model. MR = MR-GSM8K; BBM = BIG-Bench Mistake; PB = ProcessBench. Each cell pools steps only within the named task. Scores below 0.5 indicate that the specified direction of the score ranks first errors behind other steps.],
) <task-auroc>

The shuffled-objects contrast is particularly informative: a step can be fluent given its local history while contradicting the particular swaps in the question, making the question-ablated difference useful where a generic surprise measure is not. This is an interpretation of the pattern, not proof of its mechanism. Conversely, the low question-ablated scores on several mathematical tasks show that question dependence is not a reliable universal proxy for correctness. Differences in trace style, step length, task prevalence, and the status of post-error steps may also affect these rankings; we therefore do not interpret pooled benchmark scores as equal-weight averages over domains.

=== Does low context relevance correlate with reasoning errors?

The bottom-line result is *yes, as a statistical step-level association, but not as a reliable standalone localization rule*. @cr-bottom-line isolates the fully ablated score: across all nine benchmark–model combinations, first-error discrimination is above chance, with @auroc from 0.648 (4B on MR-GSM8K) to 0.698 (27B on MR-GSM8K). The one-sided Mann–Whitney U p-values displayed on the bars are below 0.05 in every combination. These are unadjusted tests of a directional difference in the two step-score distributions, not probabilities that a hypothesis is true, nor guarantees of good predictions for individual traces.

#figure(
  image("fully-ablated-cr-comparison.png", width: 100%),
  caption: [Pooled first-error step @auroc for fully ablated context relevance; lower raw context relevance is treated as stronger error evidence. The dashed line is chance ranking (0.5). Labels give one-sided Mann–Whitney U p-values for greater error evidence at first errors than at other steps; tests are unadjusted for multiple comparisons.],
) <cr-bottom-line>

This consistent association supports the hypothesis that context dependence contains information about reasoning errors. Its magnitude remains moderate. Moreover, the annotations identify only the *first* error; steps after it are counted as negatives here even if they inherit or introduce further mistakes. The trace-level comparison below tests the stronger, practically important claim that the signal can actually find the first wrong step.

== @llm Judge Experiment

=== How accurately can our chosen @llm:pl detect reasoning errors?

@judge-conditional separates the two parts of the task: saying NONE for a clean trace and naming the first incorrect step in an erroneous one. All percentages use the full relevant trace denominator; invalid judge outputs count as wrong. The 27B judge achieves 72.1% overall exact accuracy on MR-GSM8K and 68.9% on ProcessBench, but 43.4% on BIG-Bench Mistake. Its error-only accuracies are 60.8%, 65.9%, and 49.4%, respectively. The 9B judge's 85.0% clean-trace accuracy on MR-GSM8K contrasts with only 43.9% first-error accuracy on erroneous traces: a single overall number would conceal this imbalance.

#figure(
  image("judge-conditional-accuracy.png", width: 100%),
  caption: [Exact judge accuracy conditional on clean or erroneous traces, using all responses, including invalid outputs. The clean-trace bar measures correct NONE responses; the error-trace bar measures correct first-error locations. These percentages are not binary error-detection F1 scores.],
) <judge-conditional>

Model size generally helps, but does not guarantee improvement on each conditional metric: for example, the 9B judge locates fewer MR-GSM8K first errors than the 4B judge (43.9% versus 47.3%). Invalid responses also matter. The 4B judge produced 898 invalid responses on ProcessBench, compared with four for 9B and eleven for 27B, depressing its full-denominator accuracy. BIG-Bench Mistake is especially difficult for the smaller judges: both achieve about 24.6% overall exact accuracy, with error-only accuracies near 25%.

=== How do our evaluations compare to results in the benchmark papers?

For each paper we recalculate *its* headline measure, rather than comparing unlike quantities. On BIG-Bench Mistake, the macro-average of five task-level exact accuracies is 32.0%, 31.5%, and 49.8% for our 4B, 9B, and 27B judges. @tyen-comparison places these next to the direct-trace results of #cite(<tyen_llms_2024>, form: "prose"). The 27B result exceeds the published GPT-4 value of 39.8%, but this is not a controlled superiority claim: our evaluation includes all 986 Dyck traces instead of the paper's subset, and prompts and model generations differ.

#figure(
  image("tyen.png", width: 85%),
  caption: [BIG-Bench Mistake macro-average exact first-error-or-NONE accuracy by task. Gray bars reproduce direct-trace results from @tyen_llms_2024; blue bars show our Qwen3.5 judges. The published Dyck subset and our full Dyck set differ, as do the prompts.],
) <tyen-comparison>

On MR-GSM8K, @zeng-comparison uses binary process-error @mcc, not exact-location accuracy. Our judges reach 0.502, 0.588, and 0.737, versus 0.633 for the GPT-4-Turbo baseline shown. Binary detection can be correct even when the returned error *location* is wrong: our corresponding first-error accuracies on erroneous traces are 47.3%, 43.9%, and 60.8%. The paper requests a separate binary judgement, whereas ours derives it from the returned location, so these results give context rather than a strict replication @zeng_mr-gsm8k_2023.

#figure(
  image("zeng.png", width: 80%),
  caption: [MR-GSM8K binary process-error @mcc. Published zero-shot values are from @zeng_mr-gsm8k_2023; our binary decisions are derived from judges' first-error locations. Exact first-error accuracy is a different measure.],
) <zeng-comparison>

On ProcessBench, the paper's headline score is the mean over four tasks of the *harmonic means* of clean-trace and erroneous-trace accuracies, rather than conventional F1 or pooled accuracy. Our judges score 44.5%, 62.1%, and 70.4% on this measure. @zheng-comparison shows that the 27B model approaches the published QwQ-32B-Preview result (71.5%). The original open-weight critic results use eight-sample majority voting, whereas we use one response with a different prompt, so this comparison likewise does not isolate a model effect @zheng_processbench_2025.

#figure(
  image("zheng.png", width: 80%),
  caption: [ProcessBench mean of the four task-specific clean/error harmonic means. Gray bars show published open-weight LLM critic results from @zheng_processbench_2025; blue bars show our single-response Qwen3.5 judges. The metric is called F1 in the source paper but is not conventional binary F1.],
) <zheng-comparison>

== Comparison Between @llm Judge and Context Relevance

=== Can low context relevance signal errors as accurately as dedicated @llm judges?

For a directly comparable decision, each likelihood-based method first selects the step with greatest error evidence in a trace (earliest in a tie). @judge-cr-error compares the fraction of *erroneous traces* on which this candidate is the annotated first error with the judge's exact first-error accuracy on those same traces. Here the Dyck exclusion applies to *both* approaches. Generally, the judge is substantially more effective: on ProcessBench the 27B judge locates 65.9% of first errors, versus 22.6% for fully ablated context relevance and 19.0% for question ablation. On MR-GSM8K the corresponding figures are 60.8%, 23.6%, and 10.1%. In these domains, above-chance step @auroc does not translate into accurate trace-level selection.

#figure(
  image("judge-vs-context-error.png", width: 100%),
  caption: [Threshold-free first-error localization accuracy on the same erroneous traces for each model and benchmark. Likelihood methods choose their most error-indicative step; judges return their predicted location. Invalid judge responses count as wrong. This is not step-level @auroc.],
) <judge-cr-error>

BIG-Bench Mistake is the important exception to the overall trend. On its tracking-shuffled-objects task, the question-ablated score selects the correct first error in 70.8%, 68.5%, and 65.8% of erroneous traces for 4B, 9B, and 27B, compared with 24.2%, 26.5%, and 44.6% for the corresponding judges (@shuffled-error). These numbers use *all 300 task traces per model* and the same exact-location metric on both sides, not the exploratory step-level F1 versus trace-level F1 comparison. Other ablations and perplexity hardly localize errors in this task. Thus the exception supports the narrower claim that the actual question can provide a particularly useful signal for some reasoning domains, not that all context-relevance scores outperform judges.

#figure(
  image("shuffled-error.png", width: 85%),
  caption: [First-error localization on erroneous tracking-shuffled-objects traces, drawn from the same 300 task examples for each model. Question-ablated context relevance outperforms the corresponding judge on this task; the other likelihood scores do not. No thresholds are fitted for this figure.],
) <shuffled-error>

Finally, an error detector also needs to report NONE for clean traces. @judge-cr-overall compares exact first-error-or-NONE accuracy, allowing likelihood methods to suppress their candidate using a threshold. These thresholds were optimized *and evaluated on the same labeled traces*, separately for each model, benchmark, and score. Their reported values are therefore optimistic upper bounds for this particular decision rule, not held-out generalization estimates. Even under this favorable procedure, the 27B judge reaches 72.1% on MR-GSM8K and 68.9% on ProcessBench, versus at most 47.8% and 34.7% for the displayed likelihood methods. On BIG-Bench Mistake, question ablation reaches 33.7% for 9B versus 24.6% for its judge, but the judge leads at 27B (43.4% versus 30.3%).

#figure(
  image("judge-vs-context-overall.png", width: 100%),
  caption: [Exact first-error-or-NONE accuracy on all matched traces. Likelihood-based scores use separately optimized, in-sample thresholds to choose between their candidate step and NONE; judge predictions are not threshold-tuned. The likelihood bars must not be interpreted as held-out performance.],
) <judge-cr-overall>

Taken together, contextual relevance is a reproducible *ranking signal* for first errors, but its effectiveness depends strongly on the task and decision rule. A prompt-based judge is generally the better complete-trace error detector in these evaluations; question ablation's shuffled-objects result identifies a domain in which the cheaper likelihood signal merits further investigation with held-out thresholds and independent benchmarks.
