= Experiment Methodology

We evaluate two ways of locating the first error in a step-by-step solution: asking a language model to judge the complete trace, and scoring each step by how much its likelihood depends on the problem and preceding steps. Both methods receive the same problem and the same released step boundaries. An annotation identifies the first incorrect step, or indicates that the trace is error-free; correctness of the final answer alone is not a substitute for this annotation. We evaluate each benchmark task separately as well as across tasks, since their subjects, step formats, and error prevalences differ.

== Benchmarks

All three benchmarks provide model-generated reasoning traces with first-error annotations. We retain each dataset's original segmentation, rather than dividing paragraphs or code-like steps into smaller units. For evaluation we normalize error positions to zero-based indices internally and represent an error-free trace by a missing index. This conversion does not change the steps shown to the judge: its displayed labels start at Step 1. No reference answer, correctness flag, or annotated error position is included in either method's input.

=== ProcessBench

ProcessBench consists of 3,400 expert-annotated mathematical solutions drawn from four problem sets: 400 GSM8K, and 1,000 each from MATH, OlympiadBench, and Omni-MATH @zheng_processbench_2025. The problems range from grade-school arithmetic to competition and Olympiad-level mathematics. Solutions originate from twelve Qwen and Llama-family generators; the released steps are coherent paragraphs produced by a separate segmentation procedure. The label is the index of the earliest erroneous paragraph, with $-1$ denoting a wholly correct solution. Importantly, a correct final answer does not guarantee an error-free derivation.

The benchmark reports separate exact first-error accuracy on erroneous traces and no-error accuracy on clean traces, then combines them using their harmonic mean. If $E$ and $C$ are the sets of erroneous and clean traces, respectively, and $hat(y)_t$ is the predicted first-error index (or NONE), we use

$ A_"error" = (sum_(t in E) 1[hat(y)_t = y_t]) / |E|, quad A_"correct" = (sum_(t in C) 1[hat(y)_t = "NONE"]) / |C|, $
$ "HM" = (2 A_"error" A_"correct") / (A_"error" + A_"correct"). $

We set HM to zero if both accuracies are zero. This quantity is called “F1” in the ProcessBench paper, but it is *not* the conventional binary F1 score. For comparison with its overall result, the four task-level harmonic means are averaged rather than pooling all traces first.

=== MR-GSM8K

MR-GSM8K contains 2,999 annotated MetaMath-7B solutions to grade-school mathematics problems derived from GSM8K @zeng_mr-gsm8k_2023. Its three subsets comprise 1,418 original problems, 222 program-of-thought problems with code-like solutions, and 1,359 reversed problems that ask for an unknown input given an output. There are 1,571 process-incorrect and 1,428 process-correct solutions. Steps already carry numbered labels in the released data; we preserve their boundaries and numbering.

The original evaluation includes a binary correctness judgement measured by @mcc, exact first-error accuracy among process-incorrect solutions, and an additional measure requiring a correct explanation of the error. Our judge predicts only a location or NONE, so we report the first two measures but do not claim to reproduce explanation accuracy or the paper's complete MR-Score. Binary correctness refers to the *solution process*, not just whether the final numerical answer matches the reference.

=== Big-Bench Mistake

BIG-Bench Mistake contains 2,186 PaLM 2 Unicorn traces from five BIG-bench reasoning tasks @tyen_llms_2024: completing bracket sequences (Dyck languages), logical deduction, multistep arithmetic, tracking shuffled objects, and sorting words. The released traces annotate the first logical mistake or no mistake. The Dyck portion contains 986 traces; each other task contains 300. Unlike the mathematics-only benchmarks, these tasks cover several kinds of symbolic and verbal reasoning. Most Dyck labels were assigned automatically, whereas the other tasks use human annotation. The distribution is strongly skewed toward erroneous traces in several tasks.

We measure exact first-error-or-NONE accuracy over all traces and distinguish error-only from clean-only performance. For binary error detection, regardless of location, we can additionally report weighted F1 to facilitate comparison with the benchmark's reporting. Our zero-shot, whole-trace judge is *not* a reproduction of the original paper's three-shot, per-step prompting; neither is evaluation on all 986 Dyck traces directly comparable to results on the paper's sampled Dyck subset.

#figure(
  table(
    columns: (auto, auto, 1fr, auto, auto),
    align: (left, left, left, right, right),
    table.header(
      [Benchmark], [Task name], [Description], [Samples], [Errors],
    ),

    table.cell(rowspan: 4)[MR-GSM8K],
    [Original], [Grade-school arithmetic], [1,418], [51.1%],
    [POT], [Program-of-thought arithmetic], [222], [49.1%],
    [Reversed], [Solve for unknown inputs], [1,359], [54.2%],
    table.cell(colspan: 2)[*Total*], [*2,999*], [*52.4%*],

    table.cell(rowspan: 6)[BIG-Bench Mistake],
    [Dyck languages], [Complete bracket sequences], [986], [65.9%],
    [Logical deduction], [Solve ordering puzzles], [300], [98.0%],
    [Multistep arithmetic], [Evaluate nested expressions], [300], [79.3%],
    [Tracking shuffled objects], [Track object swaps], [300], [86.7%],
    [Word sorting], [Sort words alphabetically], [300], [88.7%],
    table.cell(colspan: 2)[*Total*], [*2,186*], [*78.1%*],

    table.cell(rowspan: 5)[ProcessBench],
    [GSM8K], [Grade-school arithmetic], [400], [51.8%],
    [MATH], [High-school competition maths], [1,000], [59.4%],
    [OlympiadBench], [Olympiad-level mathematics], [1,000], [66.1%],
    [Omni-MATH], [Olympiad-level mathematics], [1,000], [75.9%],
    table.cell(colspan: 2)[*Total*], [*3,400*], [*65.3%*],
  ),
  caption: [Benchmark composition and proportion of traces annotated with a process error. Percentages refer to the first-error labels, not final-answer correctness.],
)

=== Models

We use the Qwen3.5 4B, 9B, and 27B models @qwen_team_qwen35_2026. This range allows us to compare a common evaluation protocol across model sizes while remaining feasible on the available accelerators. Qwen3.5 supports both thinking and non-thinking generation; our likelihood-based experiment and the direct judge runs considered here use non-thinking mode, so the comparison does not conflate contextual-relevance scores with an additional generated deliberation. The same pretrained model supplies the step likelihoods and, in the judge experiment, the error prediction. Neither method is fine-tuned on benchmark labels.

=== Technical Setup

The experiment implementation and evaluation scripts are available in the repository at #link("https://github.com/jafber/bachelor-thesis")[github.com/jafber/bachelor-thesis], under `final/`. Inference runs on the HPI high-performance cluster with two GH200 accelerators available for the jobs. Models are loaded in bfloat16; the likelihood experiment uses teacher forcing, while the non-thinking judge generates a single greedy response per trace. We cache raw model responses and token log probabilities, keeping them separate from derived scores so that metrics can be recomputed without rerunning inference. Results use the full released trace sets unless explicitly identified as sampled analyses; diagnostic samples of 100 traces per task use a fixed seed of 42. These are new experiments, not exact reproductions of the original papers' prompting and decoding protocols.

== @llm Judge experiment

=== Setup

For every trace, we give the judge a zero-shot prompt containing the problem and the complete, numbered solution. The instruction explicitly asks for the *first* mathematical, logical, or conceptual error, even if the final answer happens to be correct. It requests exactly one final line, `FINAL: NONE` for a fully correct solution or `FINAL: N` for the first erroneous Step N. Numbering starts at one for every benchmark, independent of how the released annotations encode indices. This common prompt makes performance across datasets comparable under our protocol; it deliberately does not use benchmark-specific examples or reference answers.

=== Evaluation

We generate one response for every trace and parse its final line case-insensitively. Only `FINAL: NONE` or an integer referring to an existing numbered step is a valid prediction. A missing final line, an out-of-range step, or any other unparseable response is counted as incorrect, *not* as a prediction of NONE. For an erroneous trace, success requires the annotated first error exactly; a later error is a miss. For a clean trace, only NONE is correct. Parse coverage is recorded separately so that malformed outputs cannot silently inflate accuracy.

=== Metrics <metrics>

Our primary measure is exact-match accuracy over all traces: the fraction whose predicted location or NONE equals the annotation. To expose class imbalance and different failure modes, we also report $A_"error"$ and $A_"correct"$ as defined above. In particular, a judge that always returns NONE has zero error-only accuracy regardless of its overall accuracy on a clean-heavy dataset.

For ProcessBench we report the harmonic mean of these two conditional accuracies by split. For MR-GSM8K we additionally evaluate whether the judge detects the *presence* of a process error, ignoring its position, using @mcc. @mcc accounts for all four cells of the binary confusion matrix and is informative when error prevalence is uneven. An erroneous location still counts as detection in this binary measure but not as successful localization. These distinct measures must not be read interchangeably. Invalid outputs count as errors in exact-match scoring and are penalized rather than treated as clean predictions in the all-trace binary comparison.

== Context relevance experiment

=== Setup

For each trace with question $q$ and steps $s_1, dots, s_n$, we measure how much more likely each observed step becomes when its actual context is present. We use the same non-thinking chat-template instruction to solve the problem in numbered steps in every likelihood calculation. The generic replacement question is the fixed string `A reasoning problem.`; it supplies a minimal domain cue without revealing the particular problem. The model scores the *given* trace by teacher forcing, rather than generating a fresh solution.

We evaluate four context configurations. In the full configuration the model sees $q$ followed by the entire trace; in the question-ablated configuration it sees the generic question followed by the entire trace. In the history-ablated configuration it sees $q$ followed by each step in isolation; in the fully ablated configuration it sees the generic question followed by each step in isolation. The latter two configurations require a separate likelihood evaluation for every step. The scoring target is always the text of the step itself, not the question, chat template, or earlier steps. The step's own number is included consistently in each context. We preserve the benchmark's step boundaries throughout.

=== Evaluation

For context $c$, let $L(s_i | c)$ be the *mean token log likelihood* of step $s_i$ under that context. Averaging within each configuration reduces dependence on step length and allows for tokenization differences induced by the preceding text. We subtract the ablated score from the full-context score to obtain the three variants introduced in @cr:

$ op("CR")_"fully ablated"(i) = L(s_i | q, s_(<i)) - L(s_i | q_g), $
$ op("CR")_"question ablated"(i) = L(s_i | q, s_(<i)) - L(s_i | q_g, s_(<i)), $
$ op("CR")_"history ablated"(i) = L(s_i | q, s_(<i)) - L(s_i | q). $

Here $q_g$ is the generic question. A high difference means that the omitted information increases the model's preference for the step; a low difference is treated as potential evidence of an unsupported step. The question-ablated variant isolates the contribution of the actual question given the same history, whereas the history-ablated variant isolates the contribution of earlier steps given the same question. The fully ablated variant removes both. These scores reflect model likelihood, not a proof that a step logically follows from its premises. As a likelihood-only baseline we also compute full-context perplexity from the mean token log likelihood: higher perplexity indicates a less expected step.

=== Metrics

For step-level analysis, we label exactly the annotated first erroneous step positive and every other step negative, including steps after the first error. We pool steps within each benchmark task and report @auroc using *negative* context relevance as error evidence: 0.5 corresponds to chance ranking and 1 to perfect separation. The one-sided Mann–Whitney U test asks whether error evidence is greater for first-error steps than for other steps. We report its p-value by task; it tests a directional difference in score distributions, not whether any individual prediction is correct. Since later steps are not necessarily independently verified by the annotations, treating them as negative is a limitation of this step-level analysis.

We also evaluate a trace-level localization rule: choose the step with the smallest contextual-relevance score as the candidate first error, breaking ties in favor of the earliest step. On erroneous traces, the fraction for which this candidate matches the annotated first error measures *localization conditional on predicting an error* and requires no threshold. To allow a NONE prediction, we compare the candidate's error-evidence score to a threshold and return NONE when it falls below that threshold. We report exact first-error-or-NONE accuracy over all traces for this thresholded classifier, using the same traces and labels as in the judge comparison. Thresholds in the current analysis are optimized separately by model, benchmark, and metric on the evaluation traces themselves; the resulting accuracy is therefore an optimistic *in-sample* comparison, not a cross-validated or held-out estimate. We keep it distinct from the threshold-free localization accuracy and @auroc, neither of which requires fitting a decision threshold.
