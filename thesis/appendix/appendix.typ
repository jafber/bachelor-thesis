== Running LLM Judges in Thinking Mode <thinking>

Qwen3.5 supports "thinking mode" by default, gerating a @cot before answering a prompt @qwen_team_qwen35_2026. To provide a reproducable baseline of model capabilities,we explicitly disabled thinking mode in our @llm evaluations, prompting the model for a judgement directly. We also attempted a separate evaluation with the @llm judges in thinking mode, but frequently ran into _thinking loops_: presented with a task, the models would endlessly second-guess themselves, never arriving at a conclusion.

For example, take this reasoning trace from MR-GSM8K:

```
There are 6 girls in the park. If there are twice the number of boys in the park, how many kids are in the park?

Solution:
Step 1: There are twice the number of boys in the park, so there are 2 boys/girl * 6 girls = <<2*6=12>>12 boys in the park.
Step 2: In total there are 12 boys + 6 girls = <<12+6=18>>18 kids in the park.
Step 3: #### 18
```

When prompted to judge the trace in thinking mode, Qwen3.5-4B keeps overthinking the meaning of the phrase "twice the number of boys":

```
**Analysis of the Problem Statement:**
- Number of girls = 6.
- "If there are twice the number of boys in the park..."
- This phrasing is slightly ambiguous. Does it mean "The number of boys is twice the number of girls"? Or "The number of boys is twice the number of kids"? Or "There are twice the number of boys [as there are girls]"?
[...]
- Wait, the text says "If there are twice the number of boys in the park".
- The solution interprets this as "Number of boys = 2 * Number of girls".
- Is this interpretation correct based on the text?
[...]
- Wait, "twice the number of boys" is the subject of the clause. "If [there are twice the number of boys] in the park". This is missing a comparison.
- However, usually, this specific problem text is a known example where the intended meaning is "Twice as many boys as girls".
- Let's check if the solution explicitly states the interpretation.
[...]
- But wait, look at the text: "If there are twice the number of boys in the park".
- This phrasing is actually often used to mean "The number of boys is twice the number of girls".
- However, strictly speaking, "twice the number of boys" refers to boys.
[...]
- Wait, let's look closer at the prompt text: "If there are twice the number of boys in the park".
- This is a conditional clause. "If [condition], how many kids...".
- The condition is "there are twice the number of boys in the park".
[...]
- Wait, I might be missing a subtle logical trap.
- "If there are twice the number of boys in the park".
- Does it mean "The number of boys is twice the number of girls"?
- Or does it mean "The number of boys is twice the number of kids"?
```

This is a known problem, especially in smaller thinking models @pipis_wait_2025. There are methods to avoid thinking loops, for example increasing generation temperature @pipis_wait_2025 or budget forcing @muennighoff_s1_2025. However, running the evaluations on thinking mode judges ultimately fell out of the scope of this thesis.

== Why Score Trajectories Can Be Deceiving

To understand how the different relevance scores develop around errors in a reasoning trace, we created plots that average a given score across all reasoning traces that contain errors, per step relative to the first error.

#figure(
  image("trajectory.png"),
  caption: "Average perplexity, fully ablated CR, question ablated CR and history ablated CR per step relative to the first error step. Blue line represents the average across all reasoning traces that have a labeled error, taken from all 3 benchmarks. Bands represent 95% bootstrap confidence for the average score."
)

The fully ablated and history ablated context relevance scores look like especially strong error signals in this visualization. We can see that across all reasoning traces, both average fully ablated and average history ablated context relevance drops exactly on the step where an error first occurs.

However, this visualization is misleading. When we sample a control group of error free-traces and randomly center them on steps so that the overall distribution of selected step indices matches that of the error group, we can observe the following trajectories:

#figure(
  image("trajectory-control.png"),
  caption: "Trajectories for the step index matched control group."
)

We can see the same pattern of context relevance scores dipping on the selected steps --- even though they were sampled randomly, and don't contain any errors!

I am not totally sure what causes this pattern in the control group. A possible explanation would be that e.g. fully ablated context relevance just tends to be slightly higher for the first and last few steps of a a reasoning trace, slightly dipping in the middle of the trace.
