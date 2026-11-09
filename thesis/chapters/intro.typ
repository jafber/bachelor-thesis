#import "@preview/glossarium:0.5.10": gls

= Introduction

@llm:pl are still prone to reasoning errors. While the capability of @llm:pl to perform long-running tasks has improved rapidly over the past years, their reliability declines when problems require extended reasoning. On LongCoT, a benchmark of problems requiring thousands of reasoning tokens, even state-of-the-art models like GPT-5.2 and Gemini 3 Pro achieve less than 10% accuracy @motwani_longcot_2026.

Reasoning is essential for reliable and safe agents across domains including maths, software engineering and science. But failure to work from a given set of instructions without "going off the rails" can have consequences beyond just producing incorrect results. #cite(<wang_persona_2025>, form: "prose") demonstrate that fine tuning models on examples of incorrect reasoning increases their propensity for broadly misaligned behavior.

@cot:long exposes intermediate steps, making it possible to examine where reasoning goes wrong. #emph(gls("cot", first: true)) is a training method that encourages models to reason about a problem before producing a final answer @wei_chain--thought_2023. Analyzing this output, a method known as _@cot monitoring_, offers an opportunity to locate exactly where an error occurs rather than judging only the final response. @cot monitoring is commonly employed both during training, to guide models toward producing logically coherent reasoning steps @wang_math-shepherd_2024, as well as during some deployment settings, to catch models when they produce faulty or dangerous outputs @williams_how_2026.

Despite improvements, @cot monitors remain inaccurate on certain error detection benchmarks @zheng_processbench_2025. Furthermore, monitoring @llm:pl in deployment is a compute intensive task, limiting real-world adoption @williams_how_2026.

When generating text, @llm:pl naturally gravitate toward statements that are common from their training data. This can make a familiar answer seem plausible even when the question does not support it. _Contextual calibration_ can reduce these biases by estimating a model's preference toward particular answers before seeing the actual test input, then correcting its output probabilities accordingly.

This approach has improved performance on tasks like sentiment classification and multiple choice tests, where the model only needs to produce a few tokens to give its answer @zhao_calibrate_2021 @holtzman_surface_2021. Multi-step reasoning poses a different challenge: each step can contain many tokens and depends on both the question and the preceding reasoning. We generalize the idea of contextual calibration to this setting, asking whether it can help detect errors within a reasoning trace rather than select a short answer.

#figure(
  image("../figures/contextual-relevance.png"),
  placement: auto,
  caption: [Per-step fully ablated context relevance on an example reasoning trace that contains an error. For each step, we evaluate its average log likelihood given the full question and previous steps. To calculate context relevance, we subtract the average log likelihood for the step given only a generic context like "A reasoning problem". In the example, the second reasoning step results from the @llm's internal bias instead of following from the question. This gives the step a low context relevance, signaling the reasoning error.]
) <intro-figure>

We investigate whether contextual calibration can detect errors in reasoning traces by measuring how strongly each step is supported by the question. In mathematical terms, we are given a question $q$ and multi-step reasoning trace $s_1, s_2, dots, s_n$ and tasked with detecting whether any reasoning step contains an error. For each step $s_i$, we evaluate the difference

$ op("CR")_"fully ablated" (i) = L(s_i | q, s_(<i)) - L(s_i | q_g), $

where $L$ is the average token log likelihood assigned by the @llm, $s_(<i)$ denotes the preceding steps, and $q_g$ is a generic prompt such as "A reasoning problem." We call this difference _fully ablated context relevance_: its baseline contains neither the actual question nor the previous steps. Low context relevance may signal incorrect reasoning steps that seem plausible because of internal biases rather than support from the problem and reasoning history.

Our work makes three main research contributions:

+ We introduce _context relevance_ as a new method for detecting errors in reasoning traces. We evaluate its performance on three error-detection benchmarks, establishing a statistically significant correlation between low contextual relevance and reasoning errors.

+ We evaluate the existing error detection capabilities of state-of-the-art @llm:pl, achieving strong benchmark performance. This supports the strong error-detection capabilities reported by #cite(<zheng_processbench_2025>, form: "prose") while updating the picture presented by earlier studies @zeng_mr-gsm8k_2023 @tyen_llms_2024.

+ We compare our context-relevance-based error classifier with @llm judges: while our classifier outperforms the @llm judges on one benchmark category involving tracking shuffled objects, @llm judges generally perform better across the evaluated benchmarks.

Although its effectiveness varies across tasks, context relevance may serve as a training-free, low-compute signal for improving reasoning accuracy in @llm:pl.
