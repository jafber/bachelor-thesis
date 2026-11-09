# BIG-Bench Mistake — benchmark specification

**Source:** Tyen et al., *LLMs cannot find reasoning errors, but can correct them given the error location*, §§2–3 and Appendices A, B, E (pp. 2–5, 11–12, 15 of the [local PDF](Tyen%20et%20al.%20-%202024%20-%20LLMs%20cannot%20find%20reasoning%20errors%2C%20but%20can%20correct%20them%20given%20the%20error%20location.pdf)). Data and actual prompts: `../BIG-Bench-Mistake/README.md`, `../BIG-Bench-Mistake/*.jsonl`, `../BIG-Bench-Mistake/mistake_finding_prompts/`; also inspected in `../benchmark-overview.ipynb`.

## Task and data

2,186 PaLM 2 Unicorn chain-of-thought traces from five BIG-bench tasks: `word_sorting` (alphabetical ordering, 300), `tracking_shuffled_objects` (track swaps, multiple choice, 300), `logical_deduction` (ordering/constraint puzzles, multiple choice, 300), `multistep_arithmetic` (evaluate nested expressions, 300), `dyck_languages` (complete bracket sequences, 986). Traces are annotated with the first **logical** mistake or no mistake. Four tasks have human annotations (at least three raters, majority decision); Dyck languages is mostly automatically annotated (§2.1). All traces were generated at temperature 0. For human annotation, each task sampled 255 final-answer-wrong and 45 final-answer-correct traces; this is **not** a balanced process-correct/process-wrong split. The full Dyck set has 482 correct-final-answer and 504 incorrect-final-answer traces; the paper's sampled Dyck subset has **592** traces (88/504 respectively; Table 2, p. 3). Table 4 (p. 4) uses sampled Dyck traces, sometimes just 300 for cost, so do not compare full-986 evaluation to the published figures.

Each JSONL record has `input` (question; includes options for the multiple-choice tasks), `steps` (list of thought strings **without** `Thought N:` prefixes), `answer` (extracted model answer), `target` (reference answer), and `mistake_index`. The first error index is **0-based** in the files; JSON `null` means no error. Format for a judge as `Thought 1: {steps[0]}`, `Thought 2: {steps[1]}`, etc. A model's `Thought N` answer converts to `mistake_index = N - 1`; `No` converts to `null`. Never expose `target`, `answer`, or `mistake_index` to the judge separately: the answer may already appear in the thought text.

**Pitfalls:** Answer accuracy and mistake-free reasoning are different: traces can reach a correct final answer despite an earlier error. Exact location, not just error existence, is required. Annotators skip later steps after the first error, since subsequent deductions may depend on a false premise (§2.1). Dyck auto-annotation is based on matching a constrained trace format; its label provenance differs from the other tasks. Appendix B (p. 12) notes that an erroneous common first step in the original multistep-arithmetic generation examples was removed from all traces before annotation; do not put it back when judging. The dataset's skew makes overall exact-match accuracy sensitive to sampling and to false alarms on no-error traces: report by task and by error/no-error status as well.

## Zero-shot prompting versus published evaluation

**There is no published zero-shot judge recipe here.** The paper's §3 and Appendix A.2 (pp. 3–4, 12) specify **three-shot** prompting, comparing direct trace-level, direct per-step Yes/No, and CoT per-step prompting. Appendix A.2 specifies OpenAI-style chat messages, temperature 0, and no stop tokens for these judge runs. The repository's task-specific `mistake_finding_prompts/*_prompts.py` contains the full example-filled `DIRECT_MESSAGES`, `DIRECT_PERSTEP_MESSAGES` and `COT_PERSTEP_MESSAGES`. To reproduce its numbers, use those messages and their matching templates, not the proposed zero-shot variant below. The paper's best overall result (52.87% for GPT-4, §3.1) uses direct **per-step**, not trace-level prompting.

For a new, **non-paper zero-shot** direct trace-level baseline, omit the demonstration messages but retain the repository's numbering and output contract (see `multistep_arithmetic_prompts.py`, `DIRECT_TEMPLATE`; other tasks have analogous templates):

```text
For this sequence of steps, identify the first mistake made, if any.
{input}
Thought 1: {steps[0]}
Thought 2: {steps[1]}
...
Q: Is there a mistake in this sequence? Write "No" if there are no mistakes, or the number N if there is a mistake in Thought N.
```

For exact reproduction, consult the **task-specific** template for question punctuation/format; some append `?` to `input`. The paper scores a response as correct only when the first mistake matches exactly or `No` is returned for a no-mistake trace (§3). This zero-shot variant changes the experimental setting and cannot be directly compared to the paper's three-shot results.
