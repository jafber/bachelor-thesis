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
  image("../placeholder.webp", width: 70%),
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
