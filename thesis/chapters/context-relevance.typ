#import "@preview/glossarium:0.5.10": gls

= The _Context Relevance_ Metric <cr>

Contextual calibration adjusts a model's answer probabilities against a content-free baseline. We adapt this idea to score individual steps in a multi-step reasoning trace. Our metric, _context relevance_, measures how much the question and preceding reasoning increase the likelihood of an observed step. We compare three ablations: removing the question, the reasoning history, or both.

== From Contextual Calibration to Context Relevance

Given a question $q$ and a reasoning trace $s_1, dots, s_n$, we compare each step's average token log likelihood $L$ under its full context with its likelihood after removing parts of that context. Here, $s_(<i)$ denotes the steps preceding $s_i$.

A statement can sound plausible simply because it resembles common training examples. Context relevance instead asks whether the model prefers it more strongly after seeing the actual problem and reasoning history. Take this hypothetical #gls("llm")-generated reasoning trace as an example:

```
Question:
A shirt costs $100. Its price increases by 20%. What is the new price?

Solution:
Step 1: 20% of $100 = $20.
Step 2: Discount shirt: $100 - $20 = $80
Answer: $80
```

Step 2 decreases the price instead of increasing it. An @llm might favor this continuation because discount calculations are familiar. If the question's explicit price increase makes the step less likely than under a generic context, its context relevance will be negative. This is a hypothetical mechanism, not evidence about the model's training data or the cause of a particular error.

To compare different sources of information, we use a generic question $q_g$, here `A reasoning problem.`, as a minimal domain cue. All variants retain the same task instructions and score the same observed step. Ablation means replacing the question or omitting preceding steps, not changing model weights.

Fully ablated context relevance measures the combined contribution of question and history. Its baseline contains neither the actual question nor previous steps:

$ op("CR")_"fully ablated" (i) = L(s_i | q, s_(<i)) - L(s_i | q_g). $

Intuitively, this asks: does the step fit this particular solution better than a generic reasoning problem? A positive score means that the full context increases the step's average log likelihood. A score near zero means that removing the context changes it little; a negative score means that removing the context makes the step more likely.

Question-ablated context relevance measures what the question adds beyond the history. We replace the question while retaining all previous steps:

$ op("CR")_"question ablated" (i) = L(s_i | q, s_(<i)) - L(s_i | q_g, s_(<i)). $

This asks whether the original problem still provides useful information once the preceding reasoning is available. However, earlier steps may repeat the problem's premises. A low score can therefore reflect redundancy rather than an unsupported step: removing the question need not remove the information it supplied.

History-ablated context relevance measures what earlier steps add beyond the question. Here, the baseline retains the problem but removes the preceding reasoning:

$ op("CR")_"history ablated" (i) = L(s_i | q, s_(<i)) - L(s_i | q). $

This asks whether a step becomes more plausible after the intermediate work leading to it. A derived result may benefit strongly from that history, whereas a restatement of the problem may not. Conversely, a step following an earlier mistake can be highly predictable from the erroneous history. History dependence is thus not equivalent to correctness.

Context relevance is a model-based contrast, not a logical proof. Positive scores indicate increased mean log likelihood under full context; zero and negative scores indicate no increase or a decrease. With identical target tokenization and length, the difference equals a length-normalized log probability ratio. Otherwise, it compares separately normalized likelihoods. The variants are inspired by the likelihood-ratio scoring used for multiple choice answers by #cite(<holtzman_surface_2021>, form: "prose"), but we apply them to observed reasoning steps rather than alternative answers. The fully ablated score is not the sum of the other two. Scoring requires no additional model training, although converting these signals into classifiers introduces a separate threshold-selection problem.

== Continuous Scores and Decision Thresholds

Ranking quality measures whether a signal separates first errors from other steps. We orient scores so that larger values indicate stronger error evidence: $e_i = -op("CR")(i)$, or perplexity for the likelihood-only baseline. The receiver operating characteristic (ROC) curve plots the fraction of positives flagged against the fraction of negatives incorrectly flagged as a decision threshold varies. These are the true-positive and false-positive rates. The area under this curve (AUROC) equals the probability that a randomly selected positive receives greater evidence than a randomly selected negative, with half credit for ties. A value of 0.5 indicates chance ranking and 1 perfect separation @fawcett_introduction_2006. Here, positives are annotated first-error steps. Later steps are not necessarily verified as correct, so counting them as negatives limits this interpretation.

A threshold turns continuous evidence into a discrete prediction. A step is flagged when $e_i >= tau$. Lowering $tau$ can catch more errors at the cost of more false alarms. Our trace-level rule selects the highest-evidence step, breaking ties in favor of the earliest, and returns it only if its evidence reaches the threshold; otherwise it returns `NONE`. Good pooled step ranking does not guarantee that this candidate is the first error within a trace. Thresholds should be selected on validation data and evaluated on separate test data; fitting and evaluating on the same traces gives an optimistic in-sample result. A difference between pooled score distributions likewise need not yield useful localization accuracy.

