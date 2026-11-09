= Results and Discussion

This chapter reports results for Qwen3.5-4B, 9B, and 27B on the three benchmarks introduced in @bench-overview. Unless stated otherwise, the context-relevance analysis covers 8,584 traces#footnote[We excluded one BIG-Bench Mistake Dyck-language trace with a length of 53KB (!) since it was causing memory issues.]. We first examine the four step-scoring methods, then evaluate the judges and finally compare the two approaches.

== Context relevance experiment

=== How do the different scoring methods compare?

We compare the three context-relevance ablations with full-context perplexity. @method-auroc shows that fully ablated and history ablated context relevance generally perform best at predicting first error steps. History ablation leads on MR-GSM8K for the three Qwen models, while full ablation leads for both Llama models. On BIG-Bench Mistake, history ablation leads only for Qwen3.5-4B; full ablation leads for the other four models. Full ablation leads on ProcessBench for all five models.

#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, center, center, center, center, center, center, center, center, center, center, center, center, center, center, center, center),
    inset: 2pt,
    table.header(
      table.cell(rowspan: 2)[*Method*],
      table.cell(colspan: 5)[*MR-GSM8K*],
      table.cell(colspan: 5)[*BIG-Bench Mistake*],
      table.cell(colspan: 5)[*ProcessBench*],
      [Q4], [Q9], [Q27], [L8], [L3], [Q4], [Q9], [Q27], [L8], [L3], [Q4], [Q9], [Q27], [L8], [L3],
    ),
    [Perplexity], [60.8], [61.1], [63.3], [60.1], [55.6], [65.4], [66.5], [67.3], [57.5], [49.4], [63.5], [64.0], [64.5], [63.4], [63.5],
    [Fully ablated], [64.8], [66.9], [69.8], [*75.1*], [*71.6*], [66.5], [*68.8*], [*67.5*], [*64.7*], [*64.5*], [*68.1*], [*68.6*], [*67.9*], [*69.4*], [*69.5*],
    [Question ablated], [51.0], [47.7], [45.8], [45.5], [41.1], [67.9], [67.8], [66.0], [63.3], [55.3], [56.7], [56.5], [54.9], [47.3], [47.5],
    [History ablated], [*71.5*], [*70.7*], [*70.7*], [71.9], [70.5], [*68.0*], [68.2], [66.7], [64.6], [64.0], [67.5], [67.2], [66.3], [67.5], [67.0],
  ),
  caption: [First-error step @auroc in percent, pooling all task types within each benchmark. Q4/Q9/Q27 denote Qwen3.5-4B/9B/27B; L8 and L3 denote Llama3.1-8B and Llama3.2-3B. The highest value in each column is bold. A value of 50 indicates chance ranking; larger values indicate better discrimination. All post-error steps are counted among the other steps.],
) <method-auroc>

Question ablated context relevance generally performs worse than the other scoring methods.

Perplexity alone shows a positive correlation with first error steps on all benchmark runs, with the exception of Llama3.2-3B on BIG-Bench Mistake. However, it is consistently outperformed by the fully and history ablated context relevance scores.

*Discussion.* Perplexity alone is a useful error signal in most model-benchmark combinations. However, history-ablated and fully ablated context relevance provide even stronger information for detecting errors. This supports our hypothesis that context relevance scoring improves reasoning performance by removing model bias. The low performance of question ablated context relevance might be attributed to the fact that its correcting factor $L(s_i | q_g, s_(<i))$ includes substantial information about the question itself in the form of prior reasoning steps, losing a lot of information about the @llm's inherent biases.

=== How does performance generalize across task domains? <task-domains>

The benchmark averages hide pronounced differences between their subtasks. @task-auroc reports step-level @auroc for fully ablated context relevance, separated into all twelve task types. 

#figure(
  image("task-method-auroc.png", width: 100%),
  caption: [First-error step @auroc by task, scoring method, and Qwen3.5 model. MR = MR-GSM8K; BBM = BIG-Bench Mistake; PB = ProcessBench. Each cell pools steps only within the named task. Scores below 0.5 indicate that the specified direction of the score ranks first errors behind other steps.],
) <task-auroc>

Fully ablated context relevance shows a robust correlation to first error steps in the mathematical reasoning tasks across all models. In more logic-based tasks, namely program of thought, dyck languages, logical deduction and word sorting, the correlation is weaker. Performance on multi-step arithmetic tasks is also relatively weak.

The "tracking shuffled objects" task stands out. Here, the correlation switches directions: errors are consistently indicated by high, not low, fully ablated context relevance. However, @tracking-shuffled-auroc shows that question ablated context relevance is an unusually strong signal here. Within the shuffled objects task, low question ablated context relevance acheives 0.84-0.90 @auroc at detecting first error steps, as opposed to 0.33-0.40 for the fully ablated context relevance.

#figure(
  image("tracking-shuffled-objects-auroc.png", width: 100%),
  caption: [First-error step @auroc by task, scoring method, and Qwen3.5 model. MR = MR-GSM8K; BBM = BIG-Bench Mistake; PB = ProcessBench. Each cell pools steps only within the named task. Scores below 0.5 indicate that the specified direction of the score ranks first errors behind other steps.],
) <tracking-shuffled-auroc>

We turn the question ablated context relevance scores into a binary classifier that, as described in @comparison-methods, maximizes first error detection accuracy. @tracking-shuffled-acc shows that on the shuffled objects task, our context relevance based classifier significantly outperforms @llm judges, correctly predicting the exact first error step (or NONE on clean traces) in 65% of all samples for Llama3.1-8B.

#figure(
  image("tracking-shuffled-objects-accuracy.png", width: 100%),
  caption: [First-error step @auroc by task, scoring method, and Qwen3.5 model. MR = MR-GSM8K; BBM = BIG-Bench Mistake; PB = ProcessBench. Each cell pools steps only within the named task. Scores below 0.5 indicate that the specified direction of the score ranks first errors behind other steps.],
) <tracking-shuffled-acc>

*Discussion.* We find that fully ablated context relevance, though weaker in some logics and arithmetic settings, generally correlates with correct reasoning across task domains. One exception is the shuffled objects task, where the erroneous steps, on average, acheive a *higher* fully ablated context relevance but a significantly *lower* question ablated context relevance than other steps. A possible explanation could be logical dependance between the reasoning steps when tracking shuffled objects: the steps leading up to an error "set the model up" to make a mistake which contradicts the original question. This difference - how much prior steps instead of the original question influence a model's decision - expresses itself as low question ablated cr.

=== Does low context relevance correlate with reasoning errors?

The bottom-line result is *yes, as a statistical step-level association, but not as a reliable standalone localization rule*. @cr-bottom-line isolates the fully ablated score: across all fifteen benchmark–model combinations, first-error discrimination is above chance, with @auroc from 0.645 (Llama3.2-3B on BIG-Bench Mistake) to 0.751 (Llama3.1-8B on MR-GSM8K). Both Llama models outperform the Qwen models on MR-GSM8K, while their results on BIG-Bench Mistake and ProcessBench are comparable. The one-sided Mann–Whitney U p-values displayed on the bars are below 0.05 in every combination. These are unadjusted tests of a directional difference in the two step-score distributions, not probabilities that a hypothesis is true, nor guarantees of good predictions for individual traces.

#figure(
  image("fully-ablated-cr-comparison.png", width: 100%),
  caption: [Pooled first-error step @auroc for fully ablated context relevance; lower raw context relevance is treated as stronger error evidence. The dashed line is chance ranking (0.5). Labels give one-sided Mann–Whitney U p-values for greater error evidence at first errors than at other steps; tests are unadjusted for multiple comparisons.],
) <cr-bottom-line>

This consistent association supports the hypothesis that context dependence contains information about reasoning errors. Its magnitude remains moderate. Moreover, the annotations identify only the *first* error; steps after it are counted as negatives here even if they inherit or introduce further mistakes. The trace-level comparison below tests the stronger, practically important claim that the signal can actually find the first wrong step.

== @llm Judge Experiment

=== How do our judges compare on MR-GSM8K?

@zeng-comparison uses binary process-error @mcc, not exact-location accuracy. Our Qwen3.5 judges reach 0.502, 0.588, and 0.737, versus 0.633 for the published GPT-4-Turbo baseline; Llama3.2-3B reaches 0.137 and Llama3.1-8B falls slightly below zero (-0.017). Binary detection can be correct even when the returned error *location* is wrong: the Qwen judges' corresponding first-error accuracies on erroneous traces are 47.3%, 43.9%, and 60.8%. The paper requests a separate binary judgement, whereas ours derives it from the returned location, so these results give context rather than a strict replication @zeng_mr-gsm8k_2023.

#figure(
  image("zeng.png", width: 80%),
  caption: [MR-GSM8K binary process-error @mcc. Published zero-shot values are from @zeng_mr-gsm8k_2023; our binary decisions are derived from judges' first-error locations. Negative @mcc is retained. Exact first-error accuracy is a different measure.],
) <zeng-comparison>

*Discussion:* The MCC scores differ substantially between the model families, with Llama3.1-8b and Llama3.2-3B ranking among the lowest, and Qwen3.5 among the highest performing models. Some of the poor performance may be explained by our evaluation setup, since we derive the judgement for overall correctness from the models' returned error locations instead of a seperate binary judgement as implemented by #cite(<zeng_mr-gsm8k_2023>, form: "prose"). Nevertheless, the Qwen3.5-27B outperforms all of the models evaluated in the original MR-GSM8K paper, suggesting a strong improvement in reasoning capabilities over the past three years.

=== How do our judges compare on BIG-Bench Mistake?

To compare with #cite(<tyen_llms_2024>, form: "prose"), we take the unweighted mean of exact first-error-or-NONE accuracy over the five tasks. @tyen-comparison shows 32.0%, 31.5%, and 49.8% for our Qwen3.5-4B, 9B, and 27B judges, but only 19.5% and 12.3% for Llama3.1-8B and Llama3.2-3B. The 27B result exceeds the published GPT-4 value of 39.8%, but this is not a controlled superiority claim: our evaluation uses 985 Dyck traces after excluding one broken example, rather than the paper's subset; prompts and model generations also differ.

#figure(
  image("tyen.png", width: 85%),
  caption: [BIG-Bench Mistake macro-average exact first-error-or-NONE accuracy by task. Gray bars reproduce direct-trace results from @tyen_llms_2024; blue bars show our five Qwen3.5 and Llama judges. The published Dyck subset and our evaluated set differ, as do the prompts.],
) <tyen-comparison>

*Discussion:* Even the best performing model only acheives around 50% on the harmonic mean score, leaving substantial room for improvement. However, the scores show that even the relatively small Qwen3.5-27B released in 2026 outperforms models like GPT-4 that were at the frontier of capability just two years ago. This is especially impressive considering that GPT-4 is estimated to have around 1.8T parameters @erdil_frontier_2024 --- more than 60 times the size of Qwen3.5-27B! It remains an open research question how well todays frontier models would perform on the benchmark.

=== How do our judges compare on ProcessBench?

The paper's headline score is the mean over four tasks of the *harmonic means* of clean-trace and erroneous-trace accuracies, rather than conventional F1 or pooled accuracy. Our Qwen3.5 judges score 44.5%, 62.1%, and 70.4% on this measure, while Llama3.1-8B and Llama3.2-3B score 0.6% and 6.3%. @zheng-comparison shows that the 27B model approaches the published QwQ-32B-Preview result (71.5%). The original open-weight critic results use eight-sample majority voting, whereas we use one response with a different prompt, so this comparison likewise does not isolate a model effect @zheng_processbench_2025.

#figure(
  image("zheng.png", width: 80%),
  caption: [ProcessBench mean of the four task-specific clean/error harmonic means. Gray bars show published open-weight LLM critic results from @zheng_processbench_2025; blue bars show our five single-response Qwen3.5 and Llama judges. The metric is called F1 in the source paper but is not conventional binary F1.],
) <zheng-comparison>

*Discussion:* Again, Qwen3.5-27B is among the highest performing models, outperforming even its 72B parameter predecessor Qwen2.5 released two years before. The true performance advantage may be even higher, since in their evaluations, #cite(<zheng_processbench_2025>, form: "author") used eight-sample majority voting as opposed to our single-shot classification.

== Comparison Between @llm Judge and Context Relevance

=== Can low context relevance signal errors as accurately as dedicated @llm judges?

For a directly comparable decision, fully ablated context relevance selects the step with the lowest score in each trace (earliest in a tie). @judge-cr-error compares the fraction of *erroneous traces* on which this candidate is the annotated first error with the judge's exact first-error accuracy on those same traces. On ProcessBench, the Qwen3.5-27B judge locates 65.9% of first errors, versus 22.6% for fully ablated context relevance. On MR-GSM8K the corresponding figures are 60.8% and 23.6%. On BIG-Bench Mistake they are 49.4% and 4.4%. Across all five models, the judges lead on BIG-Bench Mistake; on MR-GSM8K and ProcessBench, fully ablated context relevance leads only for Llama3.2-3B.

#figure(
  image("judge-vs-context-error.png", width: 100%),
  caption: [Threshold-free first-error localization accuracy on the same erroneous traces for each model and benchmark. Fully ablated context relevance selects its lowest-scoring step; judges return their predicted location. Invalid judge responses count as wrong. This is not step-level @auroc.],
) <judge-cr-error>

An error detector also needs to report NONE for clean traces. @judge-cr-overall compares exact first-error-or-NONE accuracy, allowing fully ablated context relevance to suppress its candidate using a threshold. Thresholds were optimized *and evaluated on the same labeled traces*, separately for each model and benchmark. For Qwen3.5-27B, the judge reaches 72.1% on MR-GSM8K and 68.9% on ProcessBench, versus 47.7% and 34.7% for fully ablated context relevance. On BIG-Bench Mistake, the judge reaches 43.4% versus 21.9%; for both smaller Qwen models the judge scores 24.6% versus 21.9%. The fully ablated method exceeds both Llama judges on MR-GSM8K and ProcessBench under this in-sample comparison.

#figure(
  image("judge-vs-context-overall.png", width: 100%),
  caption: [Exact first-error-or-NONE accuracy on all matched traces. Fully ablated context relevance uses separately optimized, in-sample thresholds to choose between its candidate step and NONE; judge predictions are not threshold-tuned. The context-relevance bars must not be interpreted as held-out performance.],
) <judge-cr-overall>

*Discussion.* The above-chance step-level @auroc of fully ablated context relevance does not reliably translate into finding the first wrong step in an entire trace, particularly on BIG-Bench Mistake. Selecting a single lowest-scoring step is a harder decision than ranking first-error steps against other steps pooled across traces. Even the thresholded context-relevance results are optimistic in-sample scores, not held-out generalization estimates. The Llama comparisons also show that a weak judge can be beaten by this simple rule, but the stronger Qwen judges generally remain the better complete-trace error detectors. Held-out threshold tuning would be needed before claiming practical accuracy for the likelihood-based classifier.
