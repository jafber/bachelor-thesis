= Introduction

@llm:pl have demonstrated remarkable capabilities across a wide range of tasks, including mathematical reasoning, code generation, and autonomous problem-solving. However, their reliability remains limited, particularly when tasks require extended sequences of reasoning. Even advanced models like GPT-5.2 and Gemini 3 Pro still achieve less than 10% accuracy on a benchmark suite consisting of problems that require thousands of tokens of reasoning @motwani_longcot_2026.


Similarly, the 2026 Hugging Face incident discussed by #cite(<greenblatt_brief_2026>, form: "prose") demonstrates LLMs can exhibit misaligned behavior when operating over extended periods.

As LLMs are increasingly deployed as agents with broad decision-making privileges, detecting incorrect or potentially harmful behavior becomes essential. Developing reliable and computationally efficient methods for detecting errors, both during training and at inference time, therefore remains an important challenge for making AI agents safe and effective.

Many modern LLMs employ @cot reasoning, in which intermediate reasoning steps are generated before producing a final answer @wei_chain--thought_2023. These intermediate steps provide a potential source of information about the model's reasoning process and can be analyzed to identify mistakes or undesirable behavior. This approach, commonly referred to as _chain-of-thought monitoring_, has received research attention as a tool for improving reasoning accuracy @wang_math-shepherd_2024 and alignment @williams_how_2026 in @llm:pl.

Despite progress in CoT monitoring, existing approaches face four major limitations.

+ *Monitors are expensive.* Reasoning about a @cot's correctness requires a high amount of compute. OpenAI only use @cot monitors on select training runs that were already flagged by more light-weight activation probes @williams_how_2026.

+ *Monitor accuracy remains limited.* In a 2025 error detection benchmark, researchers at Qwen only manage to demonstrate 71.5% accuracy with their highest-performing LLM judge @zheng_processbench_2025.

+ *Applicability to open-ended tasks remains limited.* @prm:pl such as Math-Shepherd @wang_math-shepherd_2024 focus on mathematical reasoning problems with verifiable, unambiguous solutions. Applying similar methods to open-ended tasks, in which individual reasoning steps may not have objectively verifiable answers, is considerably more difficult.

+ *@cot is not always faithful.* Models have been shown to obfuscate their true reasoning, especially when @cot monitors were used during the model's training phase @baker_monitoring_2025. Consequently, monitors that relies exclusively on the contents of a generated reasoning trace may fail to detect certain forms of misalignment.

These limitations have motivated us to investigate @dcpmi as an alternative, compute efficent error detection method requiring no training.

@pmi is an information-theoretic measure that quantifies how much more likely two events are to occur together compared with what would be expected if they were statistically independent.

#cite(<holtzman_surface_2021>, form: "prose") introduce @dcpmi as a method for calibrating language model predictions in multiple-choice question answering. Their approach addresses the observation that language models exhibit a _common token bias_, assigning higher probabilities to answers that are common in the training data.


The central idea of @dcpmi is to estimate this bias by evaluating candidate answers under a content-independent prompt, such as "The answer is:", before considering the actual question. The probability assigned to each answer in the context of the question is then adjusted by its probability under the content-independent prompt. In this way, @dcpmi filters out bias and emphasizes the information contributed by the question itself.

#cite(<holtzman_surface_2021>, form: "prose") demonstrate that this scoring method can substantially improve performance on multiple-choice tasks. In this work, we investigate whether its underlying principle may also be useful for evaluating intermediate steps in longer reasoning processes, specifically in the context of @cot monitoring.

The main contributions of this thesis are as follows:

+ *Evaluating the error detection capabilities of modern LLMs:* We evaluate several models from the Qwen 3.5 family on three error detection benchmarks, achieving performance above 80% on all three. These results provide further evidence for the strong error detection capabilities of modern language models reported by #cite(<zheng_processbench_2025>, form: "prose"), while offering an updated perspective on the limitations identified in earlier studies by #cite(<zeng_mr-gsm8k_2023>, form: "prose") and #cite(<tyen_llms_2024>, form: "prose").

+ *Investigating @dcpmi as an error detection signal:* We demonstrate a statistically significant correlation between low @dcpmi and errors in mathematical reasoning. This finding suggests that @dcpmi may provide a useful signal for identifying incorrect reasoning steps without requiring a separately trained process reward model.

+ *Comparing @dcpmi with LLM-based judges:* We compare DC-PMI-based error classification against LLM-based judges across different reasoning tasks. We find that DC-PMI achieves performance comparable to LLM-based judges on reasoning traces involving the tracking of shuffled objects. However, LLM-based judges generally outperform DC-PMI as error classifiers across the evaluated benchmarks.

Taken together, these findings indicate that DC-PMI captures information relevant to the correctness of intermediate reasoning steps, but its effectiveness varies across task domains. Its ability to provide an error-related signal without additional model training makes it a potentially useful component of computationally efficient CoT monitoring systems.


= Background

== Generation process of LLMs

== LLM Reasoning

== Existing @cot:long monitoring approaches

=== Process Reward Models

=== @llm critics

== Applying information theory to @cot:long

=== Perplexity

=== @dcpmi


= Our new method: Prior correction

- how exactly it works
- difference from original DC-PMI


= Experiment Methodology

== Shared setup

=== Benchmarks

- ProcessBench (Wide range of difficulties, underlying questions)
  - 3400 traces (~26k steps)
  - F1 score of accuracies for wide range of PRMs (converted to binary classifier using threshold) and critic models
  - PRM / critic model F1 at finding first error step (or -1 if there is none)
- MR-GSM8K (I already have that one)
  - 2999 traces (~25k steps)
  - tests open source models as model critics, gets MCC of solution classification
  - Accuracy of first-step error classification
  - zero-shot prompt on whole reasoning trace
- Big-Bench Mistake
  - 2186 traces (~30k steps)
  - From LLMS cannot find errors paper
  - LLM-as-a-judge Accuracy of finding first error step (or -1 if there is none)
  - zero-shot prompt on either whole trace, step-by-step, or step-by-step with CoT

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
    [MATH], [Competition-level mathematics], [1,000], [59.4%],
    [OlympiadBench], [Olympiad-level mathematics], [1,000], [66.1%],
    [Omni-MATH], [Mathematics of varying difficulty], [1,000], [75.9%],
    table.cell(colspan: 2)[*Total*], [*3,400*], [*65.3%*],
  ),
  caption: [Overview of the benchmarks used for our LLM critic and DC-PMI evaluations. Each benchmark consists of labeled reasoning traces for problems in different subcategories. The table shows the number of reasoning traces per category, and how many of these reasoning traces contain errors.]
)

=== Models

- We use Qwen3.5 @qwen_team_qwen35_2026
  - Modern (March 2026)
  - Wide range of model sizes, 0.8B to 397B
  - Thinking and non-thinking models, see @thinking
- chose 4B, 9B and 27B models to compare performance across different model sizes while keeping compute demands low enough to run inference on a single processor

=== Technical Setup

- https://github.com/jafber/dc-pmi-monitor
- HPI high performance cluster
- 2 GH200 processors

== Metrics

- F1, MCC, AUROC
- Why we use them

= Results and Discussion

== How accurately can current LLMs detect reasoning errors?

== Does DC-PMI correlate with reasoning errors?

== How does DC-PMI compare to LLM critics?

== Performance in tracking shuffled objects task



= Conclusion
