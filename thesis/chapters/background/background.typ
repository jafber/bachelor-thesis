= Background

// Target: at most 5 pages of final prose; five sections, no numbered subsections.
// New references below: Jurafsky & Martin; Fawcett; Chicco & Jurman.

== Autoregressive generation and chain of thought

- *Transformer generation* — approximately 0.6 pages including CoT
  - Tokens → embeddings and positions → causal transformer layers → logits → softmax probabilities
  - Greedy selection or sampling; repeated next-token prediction using preceding tokens
  - Sequence probability: $P_theta(x | c) = product_t P_theta(x_t | c, x_(<t))$
  - Source: *[New: Jurafsky & Martin]*, tokens and transformers chapters
- *Chain of thought (CoT)*: explicit intermediate reasoning before a final answer
  - CoT prompting through reasoning demonstrations; not inherently a training method
  - Improved reasoning performance, no correctness guarantee — @wei_chain--thought_2023
- *Task and notation*: question $q$; trace $s_1, dots, s_n$; history $s_(<i)$
  - Step: benchmark-defined text segment; target: first erroneous step or `NONE`
  - Correct final answer ≠ correct process — @zeng_mr-gsm8k_2023 @zheng_processbench_2025

== Monitoring reasoning traces

- *Process versus outcome evaluation* — approximately 0.6 pages
  - Intermediate steps versus final answer; applications in solution selection, training feedback, error detection — @lightman_lets_2023 @wang_math-shepherd_2024
- *Process reward models (PRMs)*: trained step-level scorers
  - Human or automatic supervision; training-data costs and imperfect domain transfer — @lightman_lets_2023 @wang_math-shepherd_2024 @zheng_processbench_2025
- *LLM judges / critics*: general-purpose models prompted to locate errors
  - No task-specific fine-tuning; capability and prompt dependence
  - Earlier localization difficulties versus stronger recent critics — @tyen_llms_2024 @zheng_processbench_2025
  - Overlapping categories: generative PRMs with verification reasoning — @khalifa_process_2025
- *Scope*: offline assessment of supplied mathematical and logical traces
  - Observable text, not internal computation; possible monitor-induced obfuscation — @baker_monitoring_2025
  - Exclusions: correction, formal verification, alignment guarantees; no unmeasured compute-advantage claims

== Likelihood, information theory, and contextual calibration

- *Step likelihood* — approximately 1 page
  - Teacher forcing: scoring observed tokens, not regenerating solutions; causal access to preceding text only
  - Mean token log likelihood; $m_i$ scored tokens, natural logarithms:
    $ L(s_i | c) = 1 / m_i sum_(t=1)^(m_i) log P_theta(x_(i,t) | c, x_(i,<t)) $
  - Length normalization; remaining wording/tokenization sensitivity — *[New: Jurafsky & Martin]*
- *Surprisal and perplexity*
  - Surprisal: negative log probability; step perplexity: $op("PPL")(s_i | c) = exp[-L(s_i | c)]$
  - Higher perplexity → less expected text, not necessarily an error
  - Likelihood-only baseline; prior CoT verification use — *[New: Jurafsky & Martin]*; @vacareanu_general_2024
- *Motivation*: familiar statements versus premise-supported statements
  - Natural language inference: premise–hypothesis entailment; attestation bias as analogy, not established CoT mechanism — @cheng_neutralizing_2025
- *PMI and domain-conditional PMI (DC-PMI)*
  - Pointwise association: $op("PMI")(x; y) = log P(y | x) - log P(y)$
  - Answer $a$, question $q$, domain cue $d$:
    $ op("DC-PMI")(a, q; d) = log P(a | q, d) - log P(a | d) $
  - Adjustment for prior string preference and surface-form competition — @holtzman_surface_2021
- *Contextual calibration*: content-free input (`N/A`) → label-bias estimate → probability adjustment toward uniform baseline predictions
  - Related to DC-PMI, not identical; no guarantee of calibrated correctness probabilities — @zhao_calibrate_2021
- *Closest related extensions*: summarization faithfulness via DC-PMI; information-theoretic CoT assessment — @chae_mitigating_2024 @ton_understanding_2025
  - Novelty restricted to proposed context-ablation scores for first-error detection

== From contextual calibration to context relevance <cr>

- *Own adaptation* — approximately 1 page
  - DC-PMI/calibration inspiration: full-context versus reduced-context likelihood of the same observed step — @holtzman_surface_2021 @zhao_calibrate_2021
  - Context relevance (CR): mean-log-likelihood increase; low CR as hypothesized error evidence
  - Generic question $q_g$: `A reasoning problem.`; fixed instructions across configurations
  - Ablation: question replacement and/or history omission, not model-weight changes
- *Fully ablated*: joint contribution of question and history
  - $ op("CR")_"fully ablated"(i) = L(s_i | q, s_(<i)) - L(s_i | q_g) $
- *Question ablated*: question contribution with history retained
  - $ op("CR")_"question ablated"(i) = L(s_i | q, s_(<i)) - L(s_i | q_g, s_(<i)) $
  - Limitation: question information retained indirectly through history
- *History ablated*: history contribution with question retained
  - $ op("CR")_"history ablated"(i) = L(s_i | q, s_(<i)) - L(s_i | q) $
  - History dependence, not necessarily support from the question
- *Interpretation and limits*
  - Positive / zero / negative: increased / unchanged / decreased mean log likelihood
  - Identical target tokenization and length: CR = length-normalized log probability ratio; otherwise separately normalized differences
  - DC-PMI-inspired, not automatically formal PMI; no additive decomposition into question/history variants
  - Context dependence ≠ validity; valid generic steps potentially low-scoring
  - Training-free scoring versus labeled threshold fitting; implementation details → Methods

== From continuous scores to error decisions

- *Evaluation targets* — approximately 1.2 pages
  - Step ranking; binary trace-error detection; exact first-error-or-`NONE` localization
  - First-error annotations only; later-step negatives ≠ verified correct steps — @zeng_mr-gsm8k_2023 @tyen_llms_2024 @zheng_processbench_2025
- *Thresholding*: error evidence $e_i = -op("CR")(i)$; higher perplexity as baseline evidence
  - Step decision: $hat(z)_i = 1[e_i >= tau]$
  - Own trace rule: highest-evidence step, earliest tie; candidate if evidence ≥ threshold, otherwise `NONE`
  - Missed errors / false alarms trade-off; validation-based tuning versus optimistic in-sample optimization — *[New: Fawcett]*
- *AUROC*: area under true-positive-rate versus false-positive-rate curve across thresholds
  - Probability of positive outranking negative, half credit for ties; 0.5 chance, 1 perfect
  - Threshold-free ranking ≠ localization accuracy — *[New: Fawcett]*
- *Accuracy*: binary $("TP" + "TN") / N$ versus exact index-or-`NONE` agreement
  - Conditional accuracy on erroneous and clean traces; overall sensitivity to class prevalence — *[New: Chicco & Jurman]*; benchmark papers
- *F1*: positive class = erroneous trace; TP/FP/TN/FN = true/false positives/negatives
  - Precision $= "TP" / ("TP" + "FP")$; recall $= "TP" / ("TP" + "FN")$
  - $F_1 = (2 "TP") / (2 "TP" + "FP" + "FN")$; harmonic mean of precision and recall, no TN contribution
  - Weighted F1: support-weighted class-specific scores — *[New: Jurafsky & Martin]*; @tyen_llms_2024
- *Matthews correlation coefficient (MCC)*: binary prediction–label correlation; all four confusion-matrix cells
  - −1 inverse, 0 uncorrelated, 1 perfect; useful under imbalance, not localization — *[New: Chicco & Jurman]*; @zeng_mr-gsm8k_2023
- *ProcessBench “F1”*: $op("HM") = (2 A_"error" A_"clean") / (A_"error" + A_"clean")$
  - Harmonic mean of conditional localization accuracies, *not binary F1* — @zheng_processbench_2025
- *Mann–Whitney U*: directional rank-distribution comparison; significance ≠ predictive utility; dependence/multiple comparisons → Methods

// Bibliography additions (planning notes, not final chapter content):
// Jurafsky & Martin, Speech and Language Processing, 3rd-edition online draft:
// https://web.stanford.edu/~jurafsky/slp3/
// Fawcett (2006), An introduction to ROC analysis, Pattern Recognition Letters 27(8), 861–874:
// https://doi.org/10.1016/j.patrec.2005.10.010
// Chicco & Jurman (2020), The advantages of the Matthews correlation coefficient (MCC)
// over F1 score and accuracy in binary classification evaluation, BMC Genomics 21, 6:
// https://doi.org/10.1186/s12864-019-6413-7
// Editorial alignment: introduction's CoT definition and raw probability ratio;
// explicit question-ablation versus fully ablated distinction; consistent "context relevance".
// Methods: retain implementation/experimental choices, reference background definitions.
