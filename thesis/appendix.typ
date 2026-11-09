== Running LLM Judges in Thinking Mode <thinking>

Qwen3.5 supports "thinking mode", generating a @cot before its final answer @qwen_team_qwen35_2026. Our main evaluation disables this mode and requests a direct judgment. In exploratory thinking-mode runs, we observed repetitive reconsideration of the same premises, sometimes without a verdict before the generation limit. We refer to this behavior as _thinking loops_; finite outputs cannot establish that a model would continue indefinitely.

For example, take this reasoning trace from MR-GSM8K:

```
There are 6 girls in the park. If there are twice the number of boys in the park, how many kids are in the park?

Solution:
Step 1: There are twice the number of boys in the park, so there are 2 boys/girl * 6 girls = <<2*6=12>>12 boys in the park.
Step 2: In total there are 12 boys + 6 girls = <<12+6=18>>18 kids in the park.
Step 3: #### 18
```

When prompted to judge this trace in thinking mode, Qwen3.5-4B repeatedly revisits the phrase "twice the number of boys". The wording is genuinely incomplete: it does not state what the number of boys is twice. The following excerpts show the repetition, not that the model's concern is unfounded:

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

Repetitive thinking has also been reported in smaller reasoning models @pipis_wait_2025. Proposed mitigations include changing the sampling temperature @pipis_wait_2025 and limiting deliberation through budget forcing @muennighoff_s1_2025. We did not complete a benchmark-wide thinking-mode comparison, so these observations do not establish its accuracy relative to direct judgments.

== Why Score Trajectories Can Be Misleading <trajectories>

We compare average score trajectories around annotated first errors with trajectories around matched positions in clean traces. Using random seed 42, we pair each selected erroneous trace with an unused clean trace from the same benchmark task and with the same number of steps. Errors without an available match are discarded, leaving 2,678 pairs. The clean trace is anchored at its paired error's step index, not at an independently sampled position. We pool scores from all five models and average them at offsets from −5 to +5 around each anchor.

#figure(
  image("figures/trajectory.png"),
  caption: [Average scores for the matched erroneous traces. Panels, left to right: perplexity, fully ablated CR, question-ablated CR, and history-ablated CR. Offset zero is the annotated first error. Bands show pointwise 95% percentile-bootstrap intervals obtained by resampling individual trace–model scores at each offset; they do not account for dependence between models scoring the same trace.],
) <error-trajectories>

In @error-trajectories, fully ablated and history-ablated context relevance reach local minima at the first error. Read in isolation, this could suggest an error-specific drop.

#figure(
  image("figures/trajectory-control.png"),
  caption: [Average scores for the matched clean traces, with the same panel order and bootstrap procedure as @error-trajectories. Here, the horizontal axis measures distance from the matched anchor, not from an actual error.],
) <control-trajectories>

The clean traces in @control-trajectories also show a broad trough near their anchors. Fully ablated context relevance is lowest at offset zero; history-ablated context relevance is lowest at offset −1. A trough alone is therefore not specific to reasoning errors, although the error-aligned curves show a sharper drop at zero.

The source of the control pattern remains unresolved. Step position and trace length may affect scores independently of correctness. In addition, traces too short to reach a given offset contribute nothing there, so the average at each offset can contain a different mixture of tasks and trace lengths. These plots do not isolate an error effect; a paired comparison at the matched anchor, with uncertainty estimated over trace pairs, would be more informative.
