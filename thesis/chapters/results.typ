= Results and Discussion

We evaluate the five models on 8,584 traces, excluding the unusually long Dyck-language trace described in @comparison-methods. We first compare step-level scores, then judge performance, and finally trace-level predictions from both methods.

== Context Relevance as an Error Detection Signal

=== Comparison Between Scoring Methods

We compare three context-relevance ablations with full-context perplexity. In @method-auroc, fully ablated or history-ablated context relevance has the highest pooled first-error @auroc in every model–benchmark combination. History ablation leads for the three Qwen models on MR-GSM8K (70.7–71.5%), while full ablation leads for both Llama models (71.6–75.1%). Full ablation leads in four of five cases on BIG-Bench Mistake and in all five cases on ProcessBench. Question ablation ranges from 41.1% to 67.9%, compared with 64.5% to 75.1% for full ablation.

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
  caption: [First-error step @auroc in percent, pooling all task types within each benchmark. Higher perplexity and lower context relevance indicate stronger error evidence. Q4/Q9/Q27 denote Qwen3.5-4B/9B/27B; L8 and L3 denote Llama3.1-8B and Llama3.2-3B. The highest value in each column is bold. A value of 50 indicates chance ranking; larger values indicate better discrimination. All post-error steps are counted among the other steps.],
) <method-auroc>

Perplexity exceeds chance ranking in 14 of the 15 model–benchmark combinations; the exception is Llama3.2-3B on BIG-Bench Mistake (49.4%). Its @auroc is lower than both full and history ablation in every column of @method-auroc.

*Discussion.* Subtracting the generic-context or question-only log likelihood improves pooled first-error ranking over perplexity alone. Question ablation may be weaker because the retained history already conveys information about the question; replacing the question while keeping previous steps thus changes less of the context.
=== Variation Across Task Domains <task-domains>

The benchmark averages hide differences between subtasks. @task-auroc reports step-level @auroc for fully ablated context relevance across all twelve task types and five models. On the three MR-GSM8K tasks, values range from 0.61 to 0.77; the four ProcessBench tasks range from 0.66 to 0.71. On BIG-Bench Mistake, the Dyck-language task ranges from 0.47 to 0.63, whereas tracking shuffled objects ranges from 0.33 to 0.40.

#figure(
  image("../figures/task-method-auroc.png", width: 100%),
  caption: [First-error step @auroc for negative fully ablated context relevance, by task and model. MR = MR-GSM8K; BBM = BIG-Bench Mistake; PB = ProcessBench. Each cell pools steps within the named task; 0.5 is chance ranking. Values below 0.5 mean lower context relevance ranks first errors behind other steps.],
) <task-auroc>

The tracking-shuffled-objects task reverses the pattern for full ablation. In @tracking-shuffled-auroc, negative fully ablated context relevance yields 0.328–0.403 @auroc, while negative question-ablated context relevance yields 0.841–0.904 across the five models. Perplexity ranges from 0.421 to 0.559; negative history-ablated context relevance ranges from 0.337 to 0.522.

#figure(
  image("../figures/tracking-shuffled-objects-auroc.png", width: 100%),
  caption: [First-error step @auroc across all 300 BIG-Bench Mistake tracking-shuffled-objects traces, by scoring method and model. Higher perplexity and lower context relevance are treated as error evidence; the context-relevance bars therefore plot negative scores. The dashed line marks chance ranking (0.5).],
) <tracking-shuffled-auroc>

For the same 300 traces, @tracking-shuffled-acc compares exact first-error-or-NONE accuracy after five-fold out-of-fold threshold tuning of negative question-ablated context relevance with the judges' predictions. The context-relevance classifier scores 50.0–65.0% across models, versus 26.3–50.0% for the judges; for Llama3.1-8B the scores are 65.0% and 45.7%, respectively. The dashed baseline is 13.3% (always predicting NONE).

#figure(
  image("../figures/tracking-shuffled-objects-accuracy.png", width: 100%),
  caption: [Exact first-error-or-NONE accuracy (%) on 300 BIG-Bench Mistake tracking-shuffled-objects traces, by model. Negative question-ablated context relevance uses a five-fold out-of-fold threshold; the LLM judge uses its cached responses. The dashed line marks the always-NONE baseline (13.3%).],
) <tracking-shuffled-acc>

*Discussion.* The variation between tasks limits what a pooled benchmark score can tell us about a particular reasoning problem. In tracking shuffled objects, preceding swap steps may make a mistaken continuation likely given the history even when it conflicts with the original question. Keeping that history while ablating the question could isolate this discrepancy. The threshold is evaluated out of fold, but the task and scoring variant were selected during exploration. Independent evaluation is needed to confirm this task-specific advantage.

=== Association Between Low Context Relevance and First Errors

@cr-bottom-line isolates fully ablated context relevance. Across all fifteen benchmark–model combinations, first-error @auroc is above 0.5, ranging from 0.645 (Llama3.2-3B on BIG-Bench Mistake) to 0.751 (Llama3.1-8B on MR-GSM8K). The Llama models score 0.716 and 0.751 on MR-GSM8K, compared with 0.648–0.698 for Qwen. The association is statistically significant under the one-sided Mann–Whitney U test in all fifteen combinations (all p-values below 0.05, unadjusted).

#figure(
  image("../figures/fully-ablated-cr-comparison.png", width: 100%),
  caption: [Pooled first-error step @auroc for negative fully ablated context relevance by benchmark and model (higher values indicate more error evidence). The dashed line marks chance ranking (0.5). Each bar label gives @auroc and the one-sided Mann–Whitney U p-value for greater error evidence at first errors; p-values are unadjusted for multiple comparisons.],
) <cr-bottom-line>

*Discussion.* Low context relevance is significantly associated with first errors across all fifteen model–benchmark combinations. However, because Mann–Whitney U treats correlated steps within a trace as independent, its p-values may be too optimistic. The trace-level comparison below tests localization directly.

== Accuracy of LLM Judges

Judge scores include invalid responses as failures. @invalid-outputs reports their counts; these distinguish output-format failures from valid but incorrect verdicts.

#figure(
  table(
    columns: (1fr, auto, auto, auto),
    align: (left, right, right, right),
    table.header([*Model*], [*MR-GSM8K*], [*BIG-Bench Mistake*], [*ProcessBench*]),
    [Qwen3.5-4B], [7], [32], [898],
    [Qwen3.5-9B], [17], [37], [4],
    [Qwen3.5-27B], [0], [0], [11],
    [Llama3.1-8B], [1], [0], [1],
    [Llama3.2-3B], [0], [1], [2],
  ),
  caption: [Invalid judge responses out of 2,999 MR-GSM8K, 2,185 BIG-Bench Mistake, and 3,400 ProcessBench traces per model.],
) <invalid-outputs>

=== MR-GSM8K

@zeng-comparison reports binary process-error @mcc, not exact-location accuracy. Our Qwen3.5-4B, 9B, and 27B judges score 0.502, 0.588, and 0.737, respectively, compared with 0.633 for the published GPT-4-Turbo result. Llama3.1-8B scores -0.017 and Llama3.2-3B scores 0.137. The three Qwen judges' exact first-error accuracies on erroneous traces are 47.3%, 43.9%, and 60.8%, respectively.

#figure(
  image("../figures/zeng.png", width: 80%),
  caption: [MR-GSM8K binary process-error @mcc. Published zero-shot values are from @zeng_mr-gsm8k_2023; our binary decisions are derived from judges' first-error locations. Negative @mcc is retained. Exact first-error accuracy is a different measure.],
) <zeng-comparison>

*Discussion.* The Qwen judges distinguish erroneous from clean traces much better than the two Llama judges in this setup, but binary detection is easier than returning the exact error location. The published protocol requests a separate binary judgment, whereas ours derives it from the returned location @zeng_mr-gsm8k_2023. Hence the higher Qwen3.5-27B @mcc relative to the published models is a contextual comparison, not a controlled claim about model capability or progress over time.

=== BIG-Bench Mistake

For BIG-Bench Mistake, we report the unweighted mean of exact first-error-or-NONE accuracy across its five tasks. @tyen-comparison shows 32.0%, 31.5%, and 49.8% for our Qwen3.5-4B, 9B, and 27B judges, and 19.5% and 12.3% for Llama3.1-8B and Llama3.2-3B. The published GPT-4 result is 39.8% @tyen_llms_2024.

#figure(
  image("../figures/tyen.png", width: 85%),
  caption: [BIG-Bench Mistake macro-average exact first-error-or-NONE accuracy by task. Gray bars reproduce direct-trace results from @tyen_llms_2024; blue bars show our five Qwen3.5 and Llama judges. The published Dyck subset and our evaluated set differ, as do the prompts.],
) <tyen-comparison>

*Discussion.* Even the highest accuracy in our runs is below 50%, indicating substantial remaining difficulty in exact first-error localization. Our evaluation includes 985 Dyck traces after excluding one unusually long example, rather than the published subset; judge models and prompts also differ @tyen_llms_2024. The numerical difference between Qwen3.5-27B and the published GPT-4 result therefore cannot establish which model would perform better under the same protocol.

=== ProcessBench

On ProcessBench, we report the mean over four tasks of the harmonic means of clean-trace and erroneous-trace accuracies, not conventional F1 or pooled accuracy. Our Qwen3.5-4B, 9B, and 27B judges score 44.5%, 62.1%, and 70.4%, while Llama3.1-8B and Llama3.2-3B score 0.6% and 6.3%. The published QwQ-32B-Preview result is 71.5% in @zheng-comparison @zheng_processbench_2025.

#figure(
  image("../figures/zheng.png", width: 80%),
  caption: [ProcessBench mean of the four task-specific clean/error harmonic means. Gray bars show published open-weight LLM critic results from @zheng_processbench_2025; blue bars show our five single-response Qwen3.5 and Llama judges. The metric is called F1 in the source paper but is not conventional binary F1.],
) <zheng-comparison>

*Discussion.* The Llama judges rarely identify clean traces: their clean-trace accuracies are 0.3% for Llama3.1-8B and 3.8% for Llama3.2-3B across ProcessBench. This drives their low harmonic means. Qwen3.5-4B has a different limitation: 898 of its 3,400 responses (26.4%) are invalid. Its score therefore reflects substantial output-format failure as well as reasoning judgments. The original open-weight critic results use eight-sample majority voting, while ours use a single greedily decoded response with a 128-token limit and a different prompt @zheng_processbench_2025. These protocol differences prevent attributing score differences solely to model capability.

== Comparing LLM Judges and Context Relevance

For a directly comparable decision, fully ablated context relevance selects the step with the lowest score in each trace (earliest in a tie). @judge-cr-error compares the fraction of *erroneous traces* on which this candidate is the annotated first error with the judge's exact first-error accuracy on the same traces. For Qwen3.5-27B, the judge and context-relevance scores are 60.8% versus 23.6% on MR-GSM8K, 49.4% versus 4.4% on BIG-Bench Mistake, and 65.9% versus 22.6% on ProcessBench. Across all five models, the judges lead on BIG-Bench Mistake; fully ablated context relevance leads only for Llama3.2-3B on MR-GSM8K and ProcessBench.

#figure(
  image("../figures/judge-vs-context-error.png", width: 100%),
  caption: [Threshold-free first-error localization accuracy (%) on the same erroneous traces for each model and benchmark. Fully ablated context relevance selects its lowest-scoring step; judges return their predicted location. Invalid judge responses count as wrong. This is not step-level @auroc.],
) <judge-cr-error>

@judge-cr-overall compares exact first-error-or-NONE accuracy on all traces. The fully ablated method uses a threshold optimized and evaluated on the *same labeled traces*, separately for each model and benchmark. For Qwen3.5-27B, judge versus context-relevance accuracy is 72.1% versus 47.7% on MR-GSM8K, 43.4% versus 21.9% on BIG-Bench Mistake, and 68.9% versus 34.7% on ProcessBench. The context-relevance method exceeds both Llama judges on all three benchmarks in this in-sample comparison.

#figure(
  image("../figures/judge-vs-context-overall.png", width: 100%),
  caption: [Exact first-error-or-NONE accuracy (%) on all matched traces, by benchmark and model. Fully ablated context relevance uses separately optimized, in-sample thresholds to choose between its candidate step and NONE; judge predictions are not threshold-tuned. The context-relevance bars must not be interpreted as held-out performance.],
) <judge-cr-overall>

*Discussion.* Always predicting NONE achieves 47.6% on MR-GSM8K, 21.9% on BIG-Bench Mistake, and 34.7% on ProcessBench. Across the five models, thresholded fully ablated context relevance reaches only 47.6–47.7%, 21.9%, and 34.7–34.9%, respectively. Its advantage over the Llama judges therefore does not demonstrate useful error detection: even with in-sample tuning, it barely improves on reporting every trace as clean.

The pooled step-level @auroc does not translate into reliable first-error localization. It compares steps across different traces and task types, whereas localization requires ranking the annotated error above every other step in its own trace. Task, trace length, and step position can influence this pooled ranking. The matched-control trajectories in @trajectories illustrate the need to distinguish such structure from an error-specific signal.
