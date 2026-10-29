# ProcessBench — benchmark specification

**Source:** Zheng et al., *ProcessBench: Identifying Process Errors in Mathematical Reasoning*, §§3–4, Appendix E (pp. 2–7, 13 of the PDF in this directory). Data inspected in `../benchmark-overview.ipynb`: [`Qwen/ProcessBench`](https://huggingface.co/datasets/Qwen/ProcessBench).

## Task and data

3,400 complete, model-generated mathematical solutions with human-expert labels for the **earliest erroneous paragraph**, or `-1` if none. Four named splits: `gsm8k` (400, grade-school word problems), `math` (1,000, competition mathematics), `olympiadbench` (1,000, Olympiad-level), `omnimath` (1,000, Olympiad-level). The solutions come from 12 open-source Qwen/LLaMA generators (model mix differs by split; Appendix B, p. 12). Steps were re-paragraphed by Qwen2.5-72B-Instruct to make them logically coherent segments; use the released segmentation rather than re-splitting by sentence/newline (§3.2, p. 4).

Each example has `id`, `generator`, `problem`, `steps` (list of paragraph strings), `final_answer_correct` (boolean), and `label`. Labels index `steps` from **0**, with `-1` for all-correct; e.g. Figure 2 (p. 2) has `label: 2` for the third element of `steps`. Judge input must contain only `problem` and the tagged `steps`; do not show `label` or `final_answer_correct` (or reference solutions). Errors include mathematical, logical, conceptual, and missing essential conditions/justifications (§3.1, pp. 3–4). Later steps need not be judged after the earliest error.

**Pitfalls:** A correct final answer does **not** imply a valid process. Paper Table 2 (p. 5) gives error/no-error counts after annotation: GSM8K 207/193, MATH 594/406, OlympiadBench 661/339, Omni-MATH 759/241. Initial sampling balanced *final-answer* correctness (200/200 for GSM8K, 500/500 for each other split), **not** process correctness: among correct-final-answer traces, process error rates are 3.5%, 18.8%, 32.2%, and 51.8%, respectively. Do not derive `label` from `final_answer_correct`. Difficult cases without agreement among up to five annotators were discarded (~30%); the authors caution that difficult Olympiad labels can still be inaccurate (§3.2 and Limitations, pp. 5, 9).

## Paper's zero-shot judge prompt

Appendix E, Figure 7 (p. 13) specifies this template. Insert the actual `problem` and *each* released step as `<paragraph_0> ... </paragraph_0>` through `<paragraph_{n-1}> ... </paragraph_{n-1}>` (the `n-1` tags shown in the paper are schematic):

```text
The following is a math problem and a solution (split into paragraphs, enclosed with tags and indexed from 0):
[Math Problem]
{problem}
[Solution]
<paragraph_0>
{steps[0]}
</paragraph_0>
...
<paragraph_{n-1}>
{steps[n-1]}
</paragraph_{n-1}>
Your task is to review and critique the solution paragraph by paragraph. Once you identify an error in a paragraph, return the index of the paragraph where the earliest error occurs. Otherwise, return the index of -1 (which typically denotes "not found"). Please put your final answer (i.e., the index) in \boxed{}.
```

Extract the index in the final `\boxed{...}`; `\boxed{-1}` means no error. For paper-comparable scoring (§4.1, pp. 6–7), compute separately exact-match accuracy on `label != -1` and `label == -1`, then their harmonic mean **per split** (called “F1” in the paper, not conventional binary classification F1); average the four split scores for the overall figure. The paper reports open-source critic results using **majority vote over eight samples** (Appendix D, p. 13: usually top-p 0.9; Qwen2.5-Math-7/72B-Instruct uses p=0.8, temperature=0.7, k=20), with a separate greedy-decoding table in Appendix F (p. 16). Do not compare one greedy sample against the majority-vote table without noting the protocol difference.
