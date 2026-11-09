


Relevance of error detection

- LLM performance still degrades on long reasoning tasks
  - @motwani_longcot_2026 demonstrate \<10% accuracy for GPT 5.2 and Gemini 3 Pro on a benchmark suite of problems requiring thousands of tokens of thinking
- Moreover, LLMs are prone to engage in misaligned behavior and over-step boundaries on long running tasks, as demonstrated by the 2026 huggingface incident @greenblatt_brief_2026
- Catching LLMs going down wrong or even harmful reasoning paths during training or at inference-time remains a crucial, unsolved problems to make AI agents safe & effective.

Chain of thought monitoring

- Modern LLMs use Chain of thought [citation needed] to structure their outputs
- CoT monitoring is an active area of study for both performance research (e.g. using CoT monitoring to improve maths reasoning @wang_math-shepherd_2024) and alignment (e.g. employing model-based reviewers to check for malicious behavior @williams_how_2026)
- Distinction: *inference-time monitoring* vs *training-time supervision*
- Approaches for CoT monitoring broadly fall into 2 categories (@zheng_processbench_2025)
  - PRMs: classifier models specifially for evaluating the correctness of a given reasoning step. Usually created by fine tuning existing smaller LLMs (e.g. Mistral-7B as used in @wang_math-shepherd_2024)
  - LLM judges: simply prompt existing LLMs to find errors in a given CoT, like in @zeng_mr-gsm8k_2023

Shortcomings of existing CoT monitoring methods

- *Lack in capabilities*: @tyen_llms_2024 demonstrate that finding errors in CoT is a difficult task, even when models are capable of fixing the errors when pointed out.  GPT-4 only scores 52.87% accuracy on finding errors in BIGBench-Mistake.
- *CoT is not always faithful*: @baker_monitoring_2025 demonstrate that integrating CoT monitors directly into training can teach models to lie in their CoT instead of actually acting in good faith
- *Limited applicability*: PRMs like Math-Shepherd are trained for a specific domain (mathematical reasoning) with verifiable solutions, but evaluating the correctness of steps in more open ended tasks remains difficult

DC-PMI

- PMI: measure from information theory describing how strongly two events are associated
- DC-PMI: first introduced by @holtzman_surface_2021, applies PMI to LLMs solving mulitple choice questions
- Intuition: before asking the question, check how biased the LLM is toward certain answers by prompting the LLM with a generic prompt like "the answer is:". Divide out this bias from the LLMs actual answer probabilities.
- @holtzman_surface_2021 greatly improved LLM performance in multiple choice tasks by applying DC-PMI
- AFAIK has not been used in settings requiring longer reasoning

Contribution:

- We show DC-PMI statistically correlates to errors in mathematical reasoning. Thus, we demonstrate that DC-PMI can potentially serve as a compute efficient error signal in Chain of Thought monitoring.
- We test the error detection capabilities of several Qwen 3.5 models on 3 different error detection benchmarks, acheiving >80% performance in all of them. Thus we support the findings made by @zheng_processbench_2025 that modern LLMs display strong error detection capabilities, while updating the findings reported by @zeng_mr-gsm8k_2023 and @tyen_llms_2024.
- We find that while DC-PMI acheives similar performance to LLM judges in reasoning traces involving tracking shuffled objects, LLM judges generally outperform DC-PMI as error classifiers

= Background

== Chain of Thought

- Modern LLMs use chain of thought to structure their outputs

== Current inference time error detection methods

=== LLM-as-a-judge

- Simple idea: use "LLM judges", also called "Critic models" to proofread CoT
- Work from 2-3 years ago demonstrated poor performance
  - @tyen_llms_2024 demonstrate GPT-4 only scores 52.87% accuracy on finding errors in BIGBench-Mistake
  - @zeng_mr-gsm8k_2023 underlines this: GPT-4-Turbo only gets 48.8% at finding first error step in similar MR-GSM8K benchmark
- However, more recent work from Qwen @zheng_processbench_2025 showed performance increased to 87.9% for GPT o1-mini on similar ProcessBench benchmark

=== Dedicated Process Reward models

- Process Reward Models (PRM) are models trained specifically to evaluate the correctness of a single step in a reasoning trace
- Models like Math-Shepherd @wang_math-shepherd_2024 or RLHFlow @xiong_implementation_2024 fine tune base LLMs in the \~7B param size range to explicitly classify maths reasoning steps
- There's two main ways of training these
  - a) human labeled dataset, e.g. PRM800K (see @lightman_lets_2023) consisting of labeled reasoning traces for MATH questions
  - b) automatically rate reasoning steps by how often they lead to the correct solution in a monte carlo simulation (e.g. OmegaPRM technique proposed by @luo_improve_2024)
- PRMs can be used in a variety of applications:
  - Inference time guidance: Deciding between multiple generated solutions (best-of-n selection. @lightman_lets_2023 increase performance of fine-tuned GPT-4 on MATH from 69.6% (majority vote) to 78.2% (PRM selection))
  - Training data filtering: Qwen2.5 filtered reasoning data using a "math-specific reward model" @yang_qwen25-math_2024
  - Reinforcement learning: (@wang_math-shepherd_2024) fine tune LLaMA2-7B on Math-Sheperd PRM, improving GSM8K performance from 66.6 to 73.2%
  - Inference time error detection: @zheng_processbench_2025 demonstrate GPT o1-mini acheives 87.9% accuracy on benchmark for detecting reasoning errors in traces
  - CoT monitoring for misaligned behavior: OpenAI use combination of activation probes on model weights and reviewer models on CoT to flag runs exhibiting misaligned behavior @williams_how_2026. Were able to catch e.g. an agent abusing DNS queries to escape internet access restrictions @noauthor_agent_2026

== DC-PMI uses probability ratios to 

= What DC-PMI Can Contribute <contribution>

_I'm concerned about this part. TBH I think applying DC-PMI to CoT error detection is pretty useless. PRMs just seem like the more straightforward solution here._

- Intuitively the shortcoming of PRMs is that it's probably only applicable to these straightforward science questions with a definitive correct answer
  - @lightman_lets_2023 shows that a PRM trained on MATH reasoning traces also does well at classifying chemistry and physics reasoning
  - I'm not sure if PRM models for e.g. testing alignment exist
- I guess the nice thing about DC-PMI is that it might be able to detect relevance regardless of domain
  - e.g. we could use DC-PMI to evaluate solutions to maths questions, but we might also be able to use it to evaluate whether an agents chain of thought is aligned to a rule document, or whether a long research task stays on track with the relevant question
  - *This is where I see the highest potential value*
  - It's just an untested hypothesis though, and I'm not sure how to test it. Probably out of scope for my thesis?
- Also of course training a PRM is extra work - DC-PMI just uses an existing LLM, no extra training needed
- Compute efficiency? I guess evaluating DC-PMI is probably faster than running fine tuned LLMs (see ThinkPRM), but I doubt it's faster than simple classifier models like PathfinderPRM

*The central research question of my thesis: Can DC-PMI provide a training-free signal for detecting errors in mathematical chain-of-thought reasoning?*

= Related Work

- An interesting method is also to look at how much a given step increases the logprob of the correct answer, see @ton_understanding_2025.


= Potential Experiments

=== Recreate results from the MR-GSM8K paper

This is a pretty simple one. Just pick the model we use in the following experiments and run the same benchmark. Personally, I think recreating results is very important and underrated in science.

=== Does low DC-PMI Correlate to incorrect steps?

- Take MR-GSM8K dataset
  - contains questions from GSM8K with AI-generated reasoning traces
  - some of the reasoning traces lead to the correct solution, some lead to an incorrect solution
  - first error step in the reasoning traces is labeled
- Calculate metrics for each reasoning step for LLama 3 8B
  - Average log likelihood of step given the full context
  - Average log likelihood of step when we replace the question with a generic string
  - DC-PMI (difference of the two)
  - Perplexety of given step
- evaluate AUROC for each of these
- preliminary result:

#image("../figures/auroc-demo.png", width: 50%)

The cool thing is, we can see in the distribution of DC-PMI scores that the steps with first errors (in blue) generally have lower DC-PMI than other, correct steps (in red):

#image("../figures/generic-histogram-demo.png")

=== Does this effect hold up for different models?

I just picked LLama 3 8B for now because it's small and easy to run. How many other models should I try?

=== How does the generic prompt influence outcomes?

We can actually come up with multiple different approaches for evaluating a given steps DC-PMI. Given the sample question $q$, a generic question $q_g$ (like the string "This is a maths question."), and the model's steps $s_1, dots, s_n$, where $op("AvgLL")(x | c)$ is the average log likelihood of the string $x$ following context $c$.

The different scores we compute for a given step $s_i$ are:

1. *Perplexity:*
   $ exp(-op("AvgLL")(s_i | q, s_(<i))) $

2. *Generic DC-PMI:*
   $ op("AvgLL")(s_i | q, s_(<i)) - op("AvgLL")(s_i | q_g) $

3. *Question contribution DC-PMI:*
   $ op("AvgLL")(s_i | q, s_(<i)) - op("AvgLL")(s_i | q_g, s_(<i)) $

4. *History contribution DC-PMI:*
   $ op("AvgLL")(s_i | q, s_(<i)) - op("AvgLL")(s_i | q) $



=== Does DC-PMI give us some more "hidden" signal on whether a step is incorrect

We can see a pattern that DC-PMI usually dips on the first error step (See "Generic domain" chart)

#image("../figures/trajectories-demo.png")

This becomes clearer when we take the "derivative" (or more exactly the first difference):

#image("../figures/first-difference-demo.png")

Interesting pattern! We can see that both the generic DC-PMI and history contribution shoot up one step _after_ the reasoning error. This becomes clearer when we shift the graph one step to the left:

#image("../figures/first-difference-shift-demo.png")

_Why does this happen?_ Good question. A first intition, at least for the history contribution, would be that the error step "throws us off the right path". The step after the error only follows from the previous reasoning trace $s_(<i)$ but strays from the original question $q$. Not sure why the generic domain DC-PMI rises as well.

Three downsides:

1. Since we need to look at the step _after_ the error, real-time applicability in deployment is limited
2. This also means we can only catch errors when they happen before the last step
3. The AUROC for detecting wrong steps is actually worse than with just the generic DC-PMI (0.656 vs. the 0.696 from the AUROC chart above)

#image("../figures/shifted-increase-auroc-demo.png", width: 50%)

*TLDR: This experiment was kind of a dead end. Interesting charts, but they don't actually help us answer the original research question.*

=== Can DC-PMI reliably flag incorrect solutions?

- By picking a threshold from the AUROC curve, we could turn DC-PMI into a binary classifier to classify whether a given reasoning step is correct or incorrect
- We can then evaluate this classifier against the MCC score @zeng_mr-gsm8k_2023 got from using LLM-as-a-judge
- We could also test performance against existing PRMs

I haven't tried this, but I doubt DC-PMI will perform well on this. 

=== Does DC-PMI actually outperform PRM on long-running, open ended tasks?

As I mentioned in @contribution, this is the most interesting question to me, but it's tricky to evaluate.

