"""Run a cache-resumable first-error experiment from a shell or SLURM job.

Example:
    python run_critic_experiment.py --model Qwen/Qwen3.5-9B --thinking --batch-size 8 --results runs/thinking.csv

Omit --sample-size to evaluate every example in the selected tasks. Repeating the
same command reuses cached transcripts; interrupted runs can be resumed likewise.
"""
import argparse
import json
from pathlib import Path

from llm_critic import ROOT, evaluate, generation_kwargs_for, load_examples, sample_tasks, statistics


def positive_int(value):
    number = int(value)
    if number <= 0:
        raise argparse.ArgumentTypeError("must be a positive integer")
    return number


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--model", default="Qwen/Qwen3.5-4B", help="Hugging Face model ID")
    parser.add_argument("--thinking", action="store_true", help="Enable thinking mode and its generation defaults")
    parser.add_argument("--max-new-tokens", type=positive_int, help="Override the mode's token budget")
    parser.add_argument("--batch-size", type=positive_int, default=1, help="Number of cache misses per GPU batch")
    parser.add_argument("--generation-kwargs", default="{}", metavar="JSON",
                        help='Generation overrides as a JSON object, e.g. \'{"temperature": 0.6}\'')
    parser.add_argument("--benchmark", action="append", metavar="NAME",
                        help="Restrict to a benchmark (repeatable; default: all)")
    parser.add_argument("--task", action="append", metavar="BENCHMARK/TASK",
                        help="Restrict to a benchmark/task pair (repeatable; default: all)")
    parser.add_argument("--sample-size", type=positive_int, metavar="N",
                        help="Sample N examples per selected task (default: all examples)")
    parser.add_argument("--seed", type=int, default=42, help="Sampling seed (default: 42)")
    parser.add_argument("--cache", type=Path, default=ROOT / "cache" / "llm_critic_slurm.sqlite",
                        help="SQLite transcript cache (default: final/cache/llm_critic_slurm.sqlite)")
    parser.add_argument("--cache-only", action="store_true", help="Fail on a cache miss; never load a GPU model")
    parser.add_argument("--results", type=Path, required=True, help="Output CSV with predictions and transcripts")
    args = parser.parse_args(argv)

    try:
        overrides = json.loads(args.generation_kwargs)
        if not isinstance(overrides, dict):
            parser.error("--generation-kwargs must be a JSON object")
        generation_kwargs_for(args.thinking, overrides)
    except (ValueError, AssertionError, TypeError) as exc:
        parser.error(f"invalid --generation-kwargs: {exc}")

    tasks = load_examples()
    known_benchmarks = {benchmark for benchmark, _ in tasks}
    known_tasks = {f"{benchmark}/{task}" for benchmark, task in tasks}
    if args.benchmark and set(args.benchmark) - known_benchmarks:
        parser.error(f"unknown benchmark(s): {sorted(set(args.benchmark) - known_benchmarks)}")
    if args.task and set(args.task) - known_tasks:
        parser.error(f"unknown task(s): {sorted(set(args.task) - known_tasks)}")
    selected = {key: group for key, group in tasks.items()
                if (not args.benchmark or key[0] in args.benchmark)
                and (not args.task or f"{key[0]}/{key[1]}" in args.task)}
    if not selected:
        parser.error("no tasks selected")
    if args.sample_size is not None:
        too_small = [f"{benchmark}/{task}" for (benchmark, task), group in selected.items()
                     if len(group) < args.sample_size]
        if too_small:
            parser.error(f"--sample-size exceeds task size for: {', '.join(too_small)}")
        examples = sample_tasks(selected, size=args.sample_size, seed=args.seed)
    else:
        examples = [example for group in selected.values() for example in group]

    print(f"Evaluating {len(examples)} examples across {len(selected)} tasks; cache: {args.cache}", flush=True)
    results = evaluate(examples, model_id=args.model, thinking=args.thinking,
                       max_new_tokens=args.max_new_tokens, batch_size=args.batch_size,
                       generation_kwargs=overrides, cache_path=args.cache,
                       cache_only=args.cache_only, progress=False)
    summary = statistics(results)
    args.results.parent.mkdir(parents=True, exist_ok=True)
    summary_path = args.results.with_name(f"{args.results.stem}_statistics.csv")
    results.to_csv(args.results, index=False)
    summary.to_csv(summary_path, index=False)
    print(summary.to_string(index=False))
    print(f"Saved {args.results} and {summary_path}", flush=True)


if __name__ == "__main__":
    main()
