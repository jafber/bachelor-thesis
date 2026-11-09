#import "@preview/glossarium:0.5.10": gls

= Background

This chapter introduces how @llm:pl generate reasoning traces, common error detection methods, and contextual calibration. It also describes the evaluation metrics used to assess error predictions. Building on this background, the next chapter introduces our _context relevance_ metric.

== Autoregressive Generation and Chain of Thought

Language models generate text one token at a time. Before processing text, a language model splits it into _tokens_: words, parts of words, or punctuation marks. Given an input _prompt_ the model assigns a probability to each possible next token. The model then selects a token, either by choosing the most probable one (_greedy decoding_) or by randomly sampling from the distribution. It appends the selected token to the input and repeats the process. This is called _autoregressive generation_: each new token depends on the input and the tokens already generated @jurafsky_speech_2026.

Many modern @llm:pl use the _transformer architecture_. A transformer is a neural network that processes tokens through in layers of attention mechanisms and feed-forward networks. By design, transformer models produce a next-token probability distribution at every position during their first pass over the input. Each prediction uses only the text up to that position; later tokens are hidden from it @jurafsky_speech_2026.

These probabilities allow us to score existing text rather than generating new tokens. Multiplying per-token probabilities gives the probability of the complete sequence. For a sequence $x$ containing tokens $x_1, dots, x_m$ and a preceding context $c$,

$ P_"LM" (x | c) = product_(t=1)^m P_"LM" (x_t | c, x_(<t)), $

where $x_(<t)$ denotes the tokens preceding token $x_t$, and $P_"LM"$ denotes the probability the model assigns to a given token @jurafsky_speech_2026.

@cot:long refers to intermediate reasoning expressed by a language model before its final answer. Eliciting @cot improves performance on several arithmetic, commonsense, and symbolic reasoning tasks @wei_chain--thought_2023. By prompting a model to explicitly reason step-by-step, we can create a _reasoning trace_ made up of individual _reasoning steps_ from the @cot.

== Monitoring Reasoning Traces

Monitoring the @cot can identify problems in a model's reasoning that might otherwise remain hidden. @cot monitors are sometimes employed to look for behavior that violates instructions or safety constraints. For example, OpenAI use alignment monitors during certain training runs and evaluations @williams_how_2026. Reasoning error monitors instead examine whether a @cot employs correct reasoning. In mathematics, these assessments can help select solutions or provide step-level rewards during reinforcement learning @wang_math-shepherd_2024. While studies have shown a correlation between incorrect reasoning and misalignment in @llm:pl @wang_persona_2025, this work focuses on mathematical reasoning monitoring only.

@prm:pl are classifiers trained to assess individual reasoning steps. Unlike outcome evaluation, which assesses the final result, @prm:pl assign scores throughout a solution. Their supervision can come from human step annotations or automatically generated labels @lightman_lets_2023 @wang_math-shepherd_2024. This requires additional training data, and successful verification in one domain does not guarantee transfer to harder problems.

@llm judges are off-the-shelf models prompted to inspect a trace. A general-purpose @llm receives the problem and solution and is asked to identify errors, without requiring task-specific fine-tuning. Earlier evaluations found substantial difficulties in error localization @tyen_llms_2024, while ProcessBench reports stronger results for more recent critics @zheng_processbench_2025. The categories overlap: generative @prm:pl can also produce verification reasoning @khalifa_process_2025.

== Likelihood and Contextual Calibration

For each token in a supplied reasoning trace, an autoregressive @llm assigns a probability using only the text preceding that token. Causal masking allows a transformer to compute these probabilities in parallel without using later tokens. Given a reasoning step $s$ made up of $m$ tokens $x_1, x_2, dots, x_m$, we can compute that step's _average log likelihood_:

$ L(s | c) = 1 / (m) sum_(t=1)^(m) log P_"LM" (x_t | c, x_(<t)). $

where $c$ is the context preceding the reasoning step. Exponentiating the negative average log likelihood gives the step's _perplexity_ @jurafsky_speech_2026:

$ op("PPL")(s | c) = exp(-L(s | c)). $

High perplexity indicates that a model does not expect $s$ to follow from $c$. Perplexity has previously been used in CoT verification @vacareanu_general_2024. However, unexpected wording is not necessarily incorrect, and familiar mistakes may have high probability.

Language models are prone to bias in their probability distributions. In their study "Calibrate Before Use: Improving Few-Shot Performance of Language Models", #cite(<zhao_calibrate_2021>, form: "prose") observe that language models exhibit a _common token bias_, assigning higher probabilities to tokens that appear more frequently in their training data. For example, when presented with the question _"A human wants to submerge himself in water, what should he use? a) Cup b) Whirlpool bath"_, smaller language models might incorrectly answer "Cup" --- simply because it is a more common word than "Whirlpool bath" @holtzman_surface_2021. Similar, although less obvious, biases persist in models today. As recently as #cite(<cheng_llms_2025>, form: "year"), researchers found that in logical inference tasks, models favored answers matching their own believes, even when those answers contradicted the task @cheng_llms_2025.

Calibrating model probabilities against a baseline can improve the answers @llm:pl give. The method proposed by #cite(<zhao_calibrate_2021>, form: "author") is to estimate a model's answer biases by prompting it with a content-free input such as `N/A`. The resulting probability distribution can then be used to adjust the predictions made by the model. In this method, called _contextual calibration_, a _calibrated_ prediction $bold(hat(q))$ is obtained by dividing the model's probability distribution $bold(hat(p))$ on a given input by the content-free baseline $bold(hat(p))_"cf"$:

$ bold(hat(q)) = bold(hat(p)) slash.o bold(hat(p))_"cf" $

By sampling outputs from the calibrated distribution $bold(hat(q))$, #cite(<zhao_calibrate_2021>, form: "author") were able to improve model performance on a variety of text classification, fact retrieval and information extraction benchmarks. The same idea was successfully adapted to tasks like answering multiple choice questions @holtzman_surface_2021 and, more recently, writing abstractive summarizations @chae_mitigating_2024.

== How to Evaluate Discrete Predictions

Binary error detection and exact error localization answer different questions. For binary detection, a positive trace contains an error and a negative trace is clean. True positives (TP) and true negatives (TN) are correct decisions; false positives (FP) are false alarms and false negatives (FN) are missed errors. Binary accuracy is $("TP" + "TN") / N$, where $N$ is the number of traces. Exact localization accuracy instead requires the annotated first-error index, or `NONE` for a clean trace. Predicting the wrong error location can therefore succeed in binary detection while failing localization. Reporting accuracy separately on erroneous and clean traces helps expose this distinction and the influence of class prevalence.

F1 balances precision and recall for the positive class. Precision measures how often an error prediction is correct, while recall measures the fraction of erroneous traces detected:

$ op("Precision") = "TP" / ("TP" + "FP"), quad op("Recall") = "TP" / ("TP" + "FN"). $

Their harmonic mean is $F_1 = (2 "TP") / (2 "TP" + "FP" + "FN")$. F1 does not account for true negatives. Weighted F1 instead averages the class-specific F1 scores using each class's sample count as its weight @jurafsky_speech_2026.

The Matthews correlation coefficient (MCC) measures the correlation between binary predictions and labels, incorporating all four confusion-matrix counts. Its range is −1 for perfectly inverted predictions to 1 for perfect agreement; zero indicates no correlation when the coefficient is defined. It provides a useful complement to accuracy and F1 when class proportions are uneven @chicco_advantages_2020. Like binary F1, it measures error presence rather than exact location. The methodology therefore specifies the prediction target alongside each reported metric.
