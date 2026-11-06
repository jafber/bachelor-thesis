Models can be prompted to structure their thinking into logical steps. The final sequence of these _reasoning steps_, commonly called a _reasoning trace_, offers an opportunity to locate the exactly where an error occurs rather than judging only the final response.


*Existing @cot monitoring methods broadly fall into two categories.*

- #emph[@prm:pl] are classifier models trained specifically to score individual reasoning steps, often after training on mathematical problems with verifiable answers. They are frequently used in @llm training. @wang_math-shepherd_2024

- #emph[@llm judges] are off-the-shelf models that simply get prompted with finding errors in reasoning traces or steps. #cite(<zheng_processbench_2025>, form: "prose") report strong but imperfect error detection with this approach. They are often used for monitoring outputs during deployment. @williams_how_2026


# structure v1

LLMs are still prone to reasoning errors.
    - Reliability limited in extended reasoning
    - Motwani 2026: GPT-5.2, Gemini 3 Pro <10% accuracy on LongCoT

Robust reasoning is essential for making agents safe and reliable.
    - agents gain broader decision-making privileges on long running tasks
    - intuitive: we want dependable execution without agents "going off the rails"
    - greenblatt 2026

Chain-of-thought (CoT) reasoning makes _reasoning traces_ available for monitoring.
  - Wei 2023: intermediate steps before final answer
  - Wang 2024: monitoring for reasoning accuracy

Internal biases cause incoherent reasoning
    - mccoy 2019: faulty heuristics in nli
    - even persists today! cheng 2025: attestation bias

Internal bias can be corrected by contextual calibration .
    - zhao 2021
    - holtzman 2021

Contextual calibration has been shown to improve accuracy in tasks without reasoning traces. 
    - zhao 2021
    - holtzman 2021

Contextual calibration could improve reasoning accuracy as well.

This thesis makes three main contributions.
  - Qwen 3.5 error detection: >80% performance on three benchmarks
    - Zheng 2025: strong error detection; Zeng 2023 and Tyen 2024: earlier limitations
  - Low context relevance correlates significantly with errors in mathematical reasoning
  - Context relevance comparable to LLM judges on tracking shuffled objects; judges generally better elsewhere

Context relevance captures information about step correctness, but its effectiveness varies across tasks.
  - Potential component of efficient CoT monitoring without additional training

# structure v2

LLMs are still prone to reasoning errors.
  - Reliability limited in extended reasoning
  - Motwani 2026: GPT-5.2, Gemini 3 Pro <10% accuracy on LongCoT

Robust reasoning is essential for making agents safe and reliable.
  - Broader decision-making privileges on long-running tasks
  - Greenblatt 2026: Hugging Face incident

Chain-of-thought (CoT) exposes intermediate reasoning steps, making it possible to examine where reasoning goes wrong.
  - Wei 2023: intermediate steps before final answer
  - Wang 2024: steps as a source of information about errors

One source of reasoning errors is reliance on prior biases rather than the information in the question.
  - McCoy 2019: faulty heuristics in NLI
  - Cheng 2025: attestation bias persists

Reducing model's biases trough contextual calibration has been shown to improve accuracy in tasks without CoT.
  - Zhao 2021: calibrate predictions against content-free input
  - Holtzman 2021: DC-PMI adjusts answer scores using a content-independent prompt
  - Both demonstrate accuracy gains outside step-by-step reasoning

Contextual calibration could also improve accuracy in reasoning tasks.
  - Operationalized with DC-PMI: compare a step's likelihood with the question against its context-independent likelihood
  - Low context relevance: step may reflect prior bias instead of question-specific evidence
  - Identifying these steps is a possible route toward improving reasoning; this thesis tests error detection, not an intervention that improves final-answer accuracy

Existing CoT monitoring methods provide the closest comparison for detecting errors in reasoning steps.
  - Wang 2024: process reward models (PRMs) score steps; often trained on verifiable math
  - Zheng 2025: LLM critics judge reasoning steps; strong but imperfect error detection
  - Unlike trained PRMs or additional LLM judgments, context relevance offers a training-free signal from the model's own probabilities
  - Compare as alternative error-detection signals, not as a new general-purpose monitoring framework

This thesis makes three main contributions.
  - Qwen 3.5 error detection: >80% performance on three benchmarks
    - Zheng 2025: strong error detection; Zeng 2023 and Tyen 2024: earlier limitations
  - Low context relevance correlates significantly with errors in mathematical reasoning
  - Context relevance comparable to LLM judges on tracking shuffled objects; judges generally better elsewhere

Context relevance captures information about step correctness, but its effectiveness varies across tasks.
  - Possible training-free signal for identifying steps that lack question-specific support
