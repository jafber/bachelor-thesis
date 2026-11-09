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

Step 2 incorrectly decreases the price instead of increasing it. Still, an @llm might favor this step because applying a discount to a clothing item is a familiar concept from the training data. If the question's explicit price increase makes the step less likely than under a generic context, its context relevance will be negative.

We can calculate different context relevance scores to find out which pieces of context influence an @llm's decision to take a given reasoning step. To compare different sources of information, we use a generic question $q_g$, here `A reasoning problem.`, as a minimal domain cue. 

=== Fully Ablated Context Relevance

_Fully ablated context relevance_ measures the combined contribution of question and history. Its baseline contains neither the actual question nor previous steps:

$ op("CR")_"fully ablated" (i) = L(s_i | q, s_(<i)) - L(s_i | q_g). $

Intuitively, this asks: does the step fit this particular question better than a generic reasoning problem? A positive score means that the full context increases the step's average log likelihood. A score near zero means that removing the context changes it little; a negative score means that removing the context makes the step more likely.

=== Question-Ablated Context Relevance

_Question-ablated context relevance_ measures what the question adds beyond the history. We replace the question while retaining all previous steps:

$ op("CR")_"question ablated" (i) = L(s_i | q, s_(<i)) - L(s_i | q_g, s_(<i)). $

This asks whether the original problem still provides useful information once the preceding reasoning is available. However, earlier steps may repeat the problem's premises. A low score can therefore reflect redundancy rather than an unsupported step: removing the question need not remove the information it supplied.

=== History-Ablated Context Relevance

_History-ablated context relevance_ measures what earlier steps add beyond the question. Here, the baseline retains the problem but removes the preceding reasoning:

$ op("CR")_"history ablated" (i) = L(s_i | q, s_(<i)) - L(s_i | q). $

This asks whether a step becomes more plausible after the intermediate work leading to it. A derived result may benefit strongly from that history, whereas a restatement of the problem may not. Conversely, a step following an earlier mistake can be highly predictable from the erroneous history. History dependence is thus not equivalent to correctness.

== How We Measure the Relationship Between Context Relevance and Reasoning Correctness

Context relevance gives each reasoning step a continuous score, not a verdict of "correct" or "incorrect." To see whether the score is associated with reasoning errors, we compare it with labeled steps: does a step annotated as the first error tend to have lower context relevance than other steps? We can express this as _error evidence_ by reversing the score, so that higher evidence means lower context relevance. 

The _area under the receiver operating characteristic curve_ (AUROC) summarizes how well that evidence ranks steps. Intuitively, it is the chance that a randomly chosen annotated first error receives stronger error evidence than a randomly chosen other step, counting a tie as half a success. An AUROC of 0.5 means the scores rank these pairs no better than chance; 1 means every pair is ranked correctly @fawcett_introduction_2006. While AUROC signals correlation, it does not establish that low context relevance _causes_ errors.

To turn a continuous signal like context relevance a discrete prediction, we can set a _threshold_: flag a step when its error evidence exceeds a chosen cutoff. A lower cutoff finds more potential errors but also risks more false alarms. For a whole trace, the monitor can propose the step with the strongest evidence, and return that step if it clears the cutoff or `NONE` otherwise. We can choose a cutoff to favor a particular goal, such as maximizing exact localization accuracy, which requires both detecting an error and identifying the right step. However, strong AUROC across all steps does not guarantee accurate trace-level predictions.
