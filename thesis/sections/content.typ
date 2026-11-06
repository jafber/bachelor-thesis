#import "@preview/glossarium:0.5.10": gls

= Introduction

*@llm:pl are still prone to reasoning errors.* While the capability of @llm:pl to perform long-running tasks has improved rapidly over the past years, their reliability declines when problems require extended reasoning. On LongCoT, a benchmark of problems requiring thousands of reasoning tokens, even state-of-the-art models like GPT-5.2 and Gemini 3 Pro achieve less than 10% accuracy @motwani_longcot_2026.

*Robust reasoning is essential for making agents reliable and safe.* The ability to reason is fundamental for tasks in all domains, including maths, software engineering and science. But failure to work from a given set of instructions without "going off the rails" can have consequences beyond just producing incorrect results. #cite(<wang_persona_2025>, form: "prose") demonstrate that fine tuning models on examples of incorrect reasoning increases their propensity for broadly misaligned behavior.

*@cot:long exposes intermediate steps, making it possible to examine where reasoning goes wrong.* #emph(gls("cot", first: true)) is a training method that encourages models to reason about a problem before producing a final answer @wei_chain--thought_2023. Analyzing this output, a method known as _@cot monitoring_, offers an opportunity to locate exactly where an error occurs rather than judging only the final response. @cot monitoring is commonly employed both during training, to guide models toward producing logically coherent reasoning steps @wang_math-shepherd_2024, as well as during some deployment settings, to catch models when they produce faulty or dangerous outputs @williams_how_2026.

*Existing @cot monitors face limitations.* While monitor capabilities have risen, they remain inaccurate on certain error detection benchmarks @zheng_processbench_2025. Furthermore, monitoring @llm:pl in deployment is a compute intensive task, limiting real-world adoption @williams_how_2026.

*@nli:long is the basic building block of reasoning in @llm:pl.* #emph(gls("nli", first: true)), also called _textual entailment_, describes whether one piece of text is logically implied by another piece of text. For example, the sentence "A dog is running in the park" entails "An animal is running in the park" since a dog is an animal. The ability to assess textual entailment is a fundamental task in reasoning.

*Reliance on prior biases is a common mistake in @nli.* When generating text, @llm:pl naturally gravitate toward statements that are common from their training data. This makes them prone to _attestation bias_: when judging textual entailment, models favor claims that seem familiar even when the given premises do not support them @cheng_neutralizing_2025.

*Reducing model's biases trough contextual calibration improves accuracy on short-answer tasks.* _Contextual calibration_ is a technique for reducing biases in @llm:pl. Its basic idea is to estimate a model's preference toward particular answers before seeing the actual test input, and then correct its output probabilities accordingly. Variations of this method have been shown to improve performance in a wide range of tasks that require models to give short, verifiable answers, including sentiment classification, multiple choice tests, and @nli @zhao_calibrate_2021 @holtzman_surface_2021. To the best of our knowledge, whether this method can also be used to improve performance on multi-step reasoning tasks remains an open research question. 

#figure(
  image("placeholder.webp", width: 70%),
  placement: auto,
  caption: "Context relevance on the example of a reasoning question."
)

*We investigate whether contextual calibration can provide a signal to detect errors in reasoning traces.* To apply contextual calibration to multi-step reasoning traces, we use a @llm measure how strongly each reasoning step is supported by the actual question. In mathematical terms, we are given a question $q$ and multi-step reasoning trace $s_1, s_2, dots, s_n$ and tasked with detecting whether any reasoning step contains an error. For each step $s_i$, we evaluate the ratio

$ text("CR")_i = P(s_i | q, s_(<i)) / P(s_i | q_g, s_(<i)) $

where $P$ is the likelihood the @llm assigns to a given input. We call this ratio _contextual relevance_. Low contextual relevance may signal incorrect reasoning steps that only result from internal biases instead of logically following from the question.

*Our work makes three main research contributions:*

+ We introduce _contextual relevance_ as a new method for detecting errors in reasoning traces. We evaluate its performance on three error-detection benchmarks, establishing a statistically significant correllation between low contextual relevance and reasoning errors.

+ We evaluate the existing error detection capabilities of state-of-the-art @llm:pl, achieving strong benchmark performance. This supports the strong error-detection capabilities reported by #cite(<zheng_processbench_2025>, form: "prose") while updating the picture presented by earlier studies @zeng_mr-gsm8k_2023 @tyen_llms_2024.

+ We compare or context-relevance-based error classifier with @llm judges: while our classifier outperforms the @llm judges on one benchmark category involving tracking shuffled objects, @llm judges generally perform better across the evaluated benchmarks.

*Context relevance captures information about step correctness, but its effectiveness varies across tasks.* Still, it may serve as a training-free, low compute method of improving reasoning accuracy in @llm:pl.

= Background

== Generation process of @llm:pl

== @llm Reasoning

== Existing @cot:long monitoring approaches

=== Process Reward Models

=== @llm critics

== Applying information theory to @cot:long

=== Perplexity

=== @dcpmi


= Our new method: Prior correction

- how exactly it works
- difference from original @dcpmi


= Experiment Methodology

== Benchmarks

=== ProcessBench

@zheng_processbench_2025

Benchmark setup:

- 3400 traces (~26k steps) generated by 12 different models from Llama / Qwen families
- Questions come from a mix of 4 maths benchmarks ranging from grade school (GSM8K) to olympiad level (OlympiadBench)

Reported measurements:
- Given a full trace, ask classifiers to report whether the solution contains an error, and if so, give the first incorrect step
- Only exact first erroneous step, or correctly reporting no error, count as correct
- Report harmonic mean of accuracy for fully correct traces and accuracy for erroneous traces (inaccurately called "F1" in the paper)

$ A_"error" = "# erroneous traces with exact first error found" / "# erroneous traces" $
$ A_"correct" = "# clean traces correctly called clean" / "# clean traces" $
$ "HM" = 2 / (1/A_"error" + 1/A_"correct") $

=== MR-GSM8K

@zeng_mr-gsm8k_2023

Benchmark setup:

- 2999 traces (~25k steps)
- Questions come from GSM8K grade school maths benchmark
- Generator model MetaMath-7B
- 3 categories: original GSM8K questions, questions where model was prompted to output code instead of natural language ("Program of thought"), questions where the model had to work backwards from a given solution

Reported measurements:

+ MCC score (see @metrics) reporting whether @llm judge correctly classified the final result of the whole trace as correct / incorrect

+ Accuracy whether correct first error step was found, in traces that had incorrect solutions

+ Accuracy whether correct first error step was found and correct explanation was given, in traces that had incorrect solutions 


=== Big-Bench Mistake

@tyen_llms_2024

Benchmark setup:

- 2186 traces (~30k steps)
- Google's Big-Bench benchmark questions with different problems requiring logical reasoning

Reported measurements:

+ @llm judge accuracy of finding first error step (or -1 if there is none), across ALL traces (correct and incorrect)

+ Weighted F1 of classifying between correct / incorrect solutions (irrespective of exact error step)

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
    [MATH], [High school competition maths], [1,000], [59.4%],
    [OlympiadBench], [Olympiad-level mathematics], [1,000], [66.1%],
    [Omni-MATH], [Mathematics of varying difficulty], [1,000], [75.9%],
    table.cell(colspan: 2)[*Total*], [*3,400*], [*65.3%*],
  ),
  caption: [Overview of the benchmarks used for our @llm critic and @dcpmi evaluations. Each benchmark consists of labeled reasoning traces for problems in different subcategories. The table shows the number of reasoning traces per category, and how many of these reasoning traces contain errors.]
)

=== Models

- We use Qwen3.5 @qwen_team_qwen35_2026
  - Modern (March 2026)
  - Wide range of model sizes, 0.8B to 397B
  - Thinking and non-thinking models, see @thinking
- chose 4B, 9B and 27B models to compare performance across different model sizes while keeping compute demands low enough to run inference on a single processor

=== Technical Setup

- https://github.com/jafber/bachelor-thesis
- HPI high performance cluster
- 2 GH200 processors

== @llm Judge experiment

=== Setup

- present a @llm with the question + full reasoning trace
- prompt the @llm to respond with only one line. If the reasoning trace is fully correct, report "Final: NONE", otherwise return the number of the first reasoning step containing an error

=== Evaluation

- run judge for every reasoning trace of every benchmark
- use regex to check for "Final: [NONE|i]" at end of output
- return error for every unparseable output

=== Metrics <metrics>

Accuracy:

- overall exact-match accuracy (simplest metric, uses full information)
- Overall accuracy is ignorant to class imbalance (e.g. a judge that never reports errors would get high accuracy in a benchmark containing few mistakes)
- error-only (analogous to Table 4 @tyen_llms_2024)
- clean-only

For comparability with @zheng_processbench_2025:

- Harmonic mean of error-only and clean-only accuracy

For comparability with @zeng_mr-gsm8k_2023:

- @mcc for identifying traces containing errors (irrespective of exact error location)

== Context relevance experiment

=== Setup

- For each reasoning trace, run the model on 4 inputs 
  - Full question + trace
  - Generic question + trace

= Results and Discussion

== How accurately can current @llm:pl detect reasoning errors?

== Does @dcpmi correlate with reasoning errors?

== How does @dcpmi compare to @llm critics?

== Performance in tracking shuffled objects task



= Conclusion
