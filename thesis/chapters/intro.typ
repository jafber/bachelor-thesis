#import "@preview/glossarium:0.5.10": gls

= Introduction

@llm:pl are still prone to reasoning errors. While the capability of @llm:pl to perform long-running tasks has improved rapidly over the past years, their reliability declines when problems require extended reasoning. On LongCoT, a benchmark of problems requiring thousands of reasoning tokens, even state-of-the-art models like GPT-5.2 and Gemini 3 Pro achieve less than 10% accuracy @motwani_longcot_2026.

Reasoning is essential for reliable and safe agents across domains including maths, software engineering and science. But failure to work from a given set of instructions without "going off the rails" can have consequences beyond just producing incorrect results. #cite(<wang_persona_2025>, form: "prose") demonstrate that fine tuning models on examples of incorrect reasoning increases their propensity for broadly misaligned behavior.

@cot:long exposes intermediate steps, making it possible to examine where reasoning goes wrong. #emph(gls("cot", first: true)) is a training method that encourages models to reason about a problem before producing a final answer @wei_chain--thought_2023. Analyzing this output, a method known as _@cot monitoring_, offers an opportunity to locate exactly where an error occurs rather than judging only the final response. @cot monitoring is commonly employed both during training, to guide models toward producing logically coherent reasoning steps @wang_math-shepherd_2024, as well as during some deployment settings, to catch models when they produce faulty or dangerous outputs @williams_how_2026.

Despite improvements, @cot monitors remain inaccurate on certain error detection benchmarks @zheng_processbench_2025. Furthermore, monitoring @llm:pl in deployment is a compute intensive task, limiting real-world adoption @williams_how_2026.

#emph(gls("nli", first: true)), also called _textual entailment_, describes whether one piece of text is logically implied by another piece of text. For example, the sentence "A dog is running in the park" entails "An animal is running in the park" since a dog is an animal. The ability to assess textual entailment is a fundamental task in reasoning.

Reliance on prior biases is a common mistake in @nli. When generating text, @llm:pl naturally gravitate toward statements that are common from their training data. This makes them prone to _attestation bias_: when judging textual entailment, models favor claims that seem familiar even when the given premises do not support them @cheng_neutralizing_2025.

_Contextual calibration_ can reduce biases in @llm:pl by estimating a model's preference toward particular answers before seeing the actual test input, then correcting its output probabilities accordingly. Variations of this method have been shown to improve performance in a wide range of tasks that require models to give short, verifiable answers, including sentiment classification, multiple choice tests, and @nli @zhao_calibrate_2021 @holtzman_surface_2021. To the best of our knowledge, whether this method can also be used to improve performance on multi-step reasoning tasks remains an open research question.

#figure(
  image("../figures/contextual-relevance.png"),
  placement: auto,
  caption: [Per-step fully ablated context relevance on an example reasoning trace that contains an error. For each step, we evaluate its average log likelihood given the full question and previous steps. To calculate context relevance, we subtract the average log likelihood for the step given only a generic context like "A reasoning problem". In the example, the second reasoning step results from the @llm's internal bias instead of following from the question. This gives the step a low context relevance, signaling the reasoning error.]
)

We investigate whether contextual calibration can detect errors in reasoning traces by measuring how strongly each step is supported by the question. In mathematical terms, we are given a question $q$ and multi-step reasoning trace $s_1, s_2, dots, s_n$ and tasked with detecting whether any reasoning step contains an error. For each step $s_i$, we evaluate the ratio

$ text("CR")_i = P(s_i | q, s_(<i)) / P(s_i | q_g, s_(<i)) $

where $P$ is the likelihood the @llm assigns to a given input. We call this ratio _contextual relevance_. Low contextual relevance may signal incorrect reasoning steps that only result from internal biases instead of logically following from the question.

Our work makes three main research contributions:

+ We introduce _contextual relevance_ as a new method for detecting errors in reasoning traces. We evaluate its performance on three error-detection benchmarks, establishing a statistically significant correllation between low contextual relevance and reasoning errors.

+ We evaluate the existing error detection capabilities of state-of-the-art @llm:pl, achieving strong benchmark performance. This supports the strong error-detection capabilities reported by #cite(<zheng_processbench_2025>, form: "prose") while updating the picture presented by earlier studies @zeng_mr-gsm8k_2023 @tyen_llms_2024.

+ We compare or context-relevance-based error classifier with @llm judges: while our classifier outperforms the @llm judges on one benchmark category involving tracking shuffled objects, @llm judges generally perform better across the evaluated benchmarks.

Although its effectiveness varies across tasks, context relevance may serve as a training-free, low-compute signal for improving reasoning accuracy in @llm:pl.
