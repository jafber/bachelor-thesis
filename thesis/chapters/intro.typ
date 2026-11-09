#import "@preview/glossarium:0.5.10": gls

= Introduction

@llm:pl are still prone to reasoning errors. While the capability of @llm:pl to perform long-running tasks has improved rapidly over the past years, their reliability declines when problems require extended reasoning. On LongCoT, a benchmark of problems requiring thousands of reasoning tokens, even state-of-the-art models like GPT-5.2 and Gemini 3 Pro achieve less than 10% accuracy @motwani_longcot_2026.

Many language models reason in sequences of intermediate steps called a #emph(gls("cot")), before producing a final answer @wei_chain--thought_2023. Analyzing this output, a process known as _@cot monitoring_, can give insights into how a model arrives at its answer. @cot monitors are used to provide training rewards for correct reasoning @wang_math-shepherd_2024 or for flagging dangerous outputs during deployment @williams_how_2026.

Despite improvements, @cot monitors remain inaccurate on certain error detection benchmarks @zheng_processbench_2025. Furthermore, monitoring @llm:pl in deployment is a compute-intensive task, limiting real-world adoption @williams_how_2026.

When generating text, @llm:pl naturally gravitate toward statements that are common from their training data @zhao_calibrate_2021. This can make a model prefer statements that look familiar, even when they are incorrect in the context of the task @cheng_neutralizing_2025. _Contextual calibration_ can reduce these biases by estimating a model's preference toward particular answers before seeing the actual test input, then correcting its output probabilities accordingly.

This approach has improved performance on tasks like sentiment classification and multiple choice tests, where the model only needs to produce a few tokens to give its answer @zhao_calibrate_2021 @holtzman_surface_2021. Multi-step reasoning poses a different challenge: each step can contain many tokens and depends on both the question and the preceding reasoning. We generalize the idea of contextual calibration to this setting, asking whether it can help detect errors within a reasoning trace rather than select a short answer.

#figure(
  image("../figures/contextual-relevance.png"),
  placement: auto,
  caption: [Illustration of fully ablated context relevance on a toy example. We are given an #gls("llm")-generated step-by-step solution to a maths problem. However, the generator model's bias caused it to output a wrong step. We calculate the context relevance by subtracting each step's average log likelihood under a generic context from its average log likelihood given the question and previous steps.]
) <intro-figure>

We investigate whether contextual calibration can detect errors in reasoning traces by measuring how strongly each step is supported by the question. In mathematical terms, we are given a question $q$ and multi-step reasoning trace $s_1, s_2, dots, s_n$ and tasked with detecting whether any reasoning step contains an error. For each step $s_i$, we evaluate the difference

$ op("CR")_"fully ablated" (i) = L(s_i | q, s_(<i)) - L(s_i | q_g), $

where $L$ is the average token log likelihood assigned by the @llm, $s_(<i)$ denotes the preceding steps, and $q_g$ is a generic prompt such as "A reasoning problem." We call this difference _fully ablated context relevance_: its baseline contains neither the actual question nor the previous steps. Low context relevance may signal incorrect reasoning steps that seem plausible because of internal biases rather than support from the problem and reasoning history.

Our work makes three main research contributions:

+ We introduce _context relevance_ as a new method for detecting errors in reasoning traces. We evaluate its performance on three error-detection benchmarks, finding a statistically significant association between low fully ablated context relevance and annotated first errors in all fifteen model–benchmark combinations under a one-sided Mann–Whitney U test.

+ We evaluate five Qwen and Llama models as zero-shot error judges. Qwen3.5-27B performs best among these models, achieving 43.4–72.1% exact first-error-or-NONE accuracy across the three benchmarks. We compare these results with published evaluations while accounting for differences in prompting and scoring.

+ We compare our context-relevance-based error classifier with @llm judges: while our classifier outperforms the @llm judges on one benchmark category involving tracking shuffled objects, @llm judges generally perform better across the evaluated benchmarks.

Although its effectiveness varies across tasks, context relevance may serve as a training-free, low-compute signal for improving reasoning accuracy in @llm:pl.
