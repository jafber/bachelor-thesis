#import "@preview/glossarium:0.5.10": gls

= Background

We first describe how language models generate and score reasoning traces, then review error detection, contextual calibration, and evaluation metrics.

== Autoregressive Generation

Language models generate text one token at a time. Before processing text, a language model splits it into _tokens_: words, parts of words, or punctuation marks. Given an input _prompt_, the model assigns a probability to each possible next token. The model then selects a token, either by choosing the most probable one (_greedy decoding_) or by randomly sampling from the distribution. It appends the selected token to the input and repeats the process. This is called _autoregressive generation_: each new token depends on the input and the tokens already generated @jurafsky_speech_2026.

Many modern @llm:pl are _causal models_, meaning they predict the probability of each token based on the preceding tokens in a sequence. For a given text, a forward pass produces a probability distribution over possible next tokens at each position. Causal masking prevents each prediction from using later tokens @jurafsky_speech_2026.

These probabilities allow us to score existing text rather than generating new tokens. Multiplying per-token probabilities gives the probability of the complete sequence. For a sequence $x$ containing tokens $x_1, dots, x_m$ and a preceding context $c$,

$ P_"LM" (x | c) = product_(t=1)^m P_"LM" (x_t | c, x_(<t)), $

where $x_(<t)$ denotes the tokens preceding token $x_t$, and $P_"LM"$ denotes the probability the model assigns to a given token @jurafsky_speech_2026.

== Reasoning Traces and How to Monitor Them

@cot:long refers to intermediate reasoning expressed by a language model before its final answer. Eliciting @cot improves performance on several arithmetic, commonsense, and symbolic reasoning tasks @wei_chain--thought_2023. By prompting a model to explicitly reason step-by-step, we can create a _reasoning trace_ made up of individual _reasoning steps_ from the @cot.

Monitoring the @cot can identify problems in a model's reasoning that might otherwise remain hidden. @cot monitors are sometimes employed to look for behavior that violates instructions or safety constraints. For example, OpenAI use alignment monitors during certain training runs and evaluations @williams_how_2026. Reasoning error monitors instead examine whether a @cot employs correct reasoning. In mathematics, these assessments can help select solutions or provide step-level rewards during reinforcement learning @wang_math-shepherd_2024. While studies have shown a correlation between incorrect reasoning and misalignment in @llm:pl @wang_persona_2025, this work evaluates mathematical, symbolic, and verbal reasoning errors, not safety violations.

@cot monitors commonly fall into one of two categories:

- #emph[@prm:pl] are classifiers trained to assess individual reasoning steps. Unlike outcome evaluation, which assesses the final result, @prm:pl assign scores throughout a solution. Their supervision can come from human step annotations or automatically generated labels @lightman_lets_2023 @wang_math-shepherd_2024. Unlike the methods evaluated here, these models require task-specific training.

- #emph[@llm judges] are off-the-shelf models prompted to inspect a trace. A general-purpose @llm receives the problem and solution and is asked to identify errors, without requiring task-specific fine-tuning. Earlier evaluations found substantial difficulties in error localization @tyen_llms_2024, while ProcessBench reports stronger results for more recent critics @zheng_processbench_2025. The categories overlap: generative @prm:pl can also produce verification reasoning @khalifa_process_2025.

== How to Evaluate Discrete Predictions

@cot monitors can be evaluated on two tasks: deciding whether a reasoning trace contains an error (_binary detection_) and identifying the erroneous step (_localization_). In binary detection, a trace with an error is _positive_ and a clean trace is _negative_. A true positive (TP) is an error correctly detected; a true negative (TN) is a clean trace correctly cleared. A false positive (FP) is a false alarm, and a false negative (FN) is a missed error. Binary accuracy is $("TP" + "TN") / N$, the fraction of correct decisions among $N$ traces.

Accuracy alone can be misleading when one class is much more common than the other (_class prevalence_). If 90 of 100 traces are clean, a monitor that labels _every_ trace clean achieves 90% binary accuracy while missing all ten errors. Its accuracy mainly reflects how many clean traces are in the dataset, not an ability to find errors. Reporting accuracy separately for erroneous and clean traces reveals this failure. Exact localization accuracy is stricter still: it requires the annotated first-error index for an erroneous trace, or `NONE` for a clean one. A monitor can detect that a trace contains an error yet point to the wrong step, succeeding at binary detection but failing localization.

The _F1 score_ focuses on detecting the positive class, here erroneous traces. It combines _precision_—the fraction of predicted errors that really are errors—with _recall_—the fraction of actual errors detected:

$ op("Precision") = "TP" / ("TP" + "FP"), quad op("Recall") = "TP" / ("TP" + "FN"). $

F1 is their harmonic mean: $F_1 = (2 "TP") / (2 "TP" + "FP" + "FN")$. It is high only when both precision and recall are high; unlike accuracy, it gives no credit for true negatives. _Weighted F1_ computes an F1 score for each class in turn and averages the two scores, weighting each by the number of traces in that class @jurafsky_speech_2026. Because the larger class receives more weight, weighted F1 can still be influenced by class prevalence.

The _Matthews correlation coefficient_ (MCC) instead compares predictions with the true labels using all four counts, TP, TN, FP, and FN. It ranges from 1 for perfect agreement to −1 for completely reversed predictions; 0 means no correlation when the coefficient is defined. Thus it checks whether a monitor distinguishes errors from clean traces, rather than merely benefiting from a common class, and complements accuracy and F1 on imbalanced datasets @chicco_advantages_2020. Both F1 and MCC evaluate whether an error is present, not whether its step was localized correctly.

== Likelihood and Contextual Calibration

For each token in a supplied reasoning trace, an autoregressive @llm assigns a probability using only the text preceding that token. Causal masking allows a transformer to compute these probabilities in parallel without using later tokens. Given a reasoning step $s$ made up of $m$ tokens $x_1, x_2, dots, x_m$, we can compute that step's _average log likelihood_:

$ L(s | c) = 1 / (m) sum_(t=1)^(m) log P_"LM" (x_t | c, x_(<t)), $

where $c$ is the context preceding the reasoning step. Exponentiating the negative average log likelihood gives the step's _perplexity_ @jurafsky_speech_2026:

$ op("PPL")(s | c) = exp(-L(s | c)). $

High perplexity indicates that a model does not expect $s$ to follow from $c$. Perplexity has previously been used in CoT verification @vacareanu_general_2024. However, unexpected wording is not necessarily incorrect, and familiar mistakes may have high probability.

#cite(<zhao_calibrate_2021>, form: "prose") observe that language models exhibit a _common token bias_, assigning higher probabilities to tokens that appear more frequently in their training data. For example, when presented with the question _"A human wants to submerge himself in water, what should he use? a) Cup b) Whirlpool bath"_, smaller language models might incorrectly answer "Cup" --- simply because it is a more common word than "Whirlpool bath" @holtzman_surface_2021. In logical inference tasks, models can also favor answers matching their prior beliefs even when those answers contradict the supplied premises @cheng_llms_2025.

#cite(<zhao_calibrate_2021>, form: "prose") estimate these answer preferences by replacing the test input with content-free text such as `N/A`, while retaining the prompt's format and examples. Their _contextual calibration_ method adjusts answer scores against this baseline. For classification, it divides each answer's probability by its content-free probability:

$ r_k = hat(p)_k / hat(p)_("cf", k), quad hat(y) = op("arg max")_k r_k. $

Here, $k$ indexes candidate labels, $hat(p)_k$ is the model's probability for label $k$, and $hat(p)_("cf", k)$ is its content-free baseline. The ratios are scores, not a normalized probability distribution; applying softmax yields the calibrated distribution in the paper. Predictions select the highest score rather than sampling from it. For generation tasks, the authors instead use an additive correction and calibrate only the first output token @zhao_calibrate_2021.

Contextual calibration improved text classification, fact retrieval, and information extraction. Related likelihood-ratio methods have also been applied to multiple choice answers @holtzman_surface_2021 and token-by-token abstractive summarization @chae_mitigating_2024. Our extension concerns scoring steps in existing multi-step reasoning traces, rather than the first use of calibration for longer text.

