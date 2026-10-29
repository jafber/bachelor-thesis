- I was trying out the first difference metric for DC-PMI and History contribution
- make some ROC for this
- resume pi session

## For thesis 

- recreate the paper
    - pick one model, make it reason about solution correctness
    - get MCC for solution correctness classification
    - get accuracy for first error step prediction within set of incorrect solutions
- compare signals for classifying first error step
- tie back to paper method
    - find sensible threshold, create classifier model on training set
    - get MCC on test set
    - get accuracy on test set
- (optional) web app to visualize different signals




Qwen3.5-9B, thinking + non-thinking
Qwen3.5-27B, thinking + non-thinking
(maybe also Qwen3.5-4B thinking + non-thinking, since it doesn't cost much compute)
(maybe also GPT-OSS 120B as a large comparison model)

I want to test the performance of different open source models on llm-as-a judge error detection in reasoning traces:

Qwen3.5-9B, thinking + non-thinking
Qwen3.5-27B, thinking + non-thinking
(maybe also Qwen3.5-4B thinking + non-thinking, since it doesn't cost much compute)

The setup is simple: given a problem and a step-by-step solution, determine whether the solution contains an error, and if it does, output the index of the first erroneous step. to test this, I want to use 3 different benchmarks: MR-GSM8k, BIG-Bench Mistake and ProcessBench. Look at papers/*.md to get an overview of how the authors constructed these benchmarks. Then, come up with a good architecture to run these benchmarks on a given model. the structure should always be the same:

- zero shot
- determine whether the solution contains an error, and if it does, output the index of the first erroneous step
- cache LLM answer
- parse LLM answer (be vocal about unparseable answers!)
- compute accuracy, F1, MCC of model answers

In the end, create llm-critic-demo.ipynb where we run Qwen3.5-4B non-thinking on 100 samples of each task type, of each benchmark. output statistics. also print one random sample of a judge's full answer per task type.

Architecture requirements:

- business logic and plot generation should happen in python modules. only use notebooks to visualize results.
- we MUST implement a flexible, robust caching mechanism. notebooks must be idempotent (i.e. no inference on re-runs). you can take inspiration from ../mr-gsm8k/score_dc_pmi.py.

Work on your own until you have a working setup. You can use online search. You can run the notebook (you MUST NOT start new SLURM jobs though).