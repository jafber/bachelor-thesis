"""Cache-resumable first-error experiments on MR-GSM8K, BIG-Bench Mistake and ProcessBench.

Examples:
    python run_experiment.py llm_judge --results runs/judge.csv
    python run_experiment.py dc_pmi --results runs/dc_pmi.csv
"""
import argparse
import json
from pathlib import Path

from experiment_setup.benchmarks import ROOT, load_examples, select_examples
from experiment_setup import dc_pmi, llm_critic


def positive_int(value):
    number = int(value)
    if number <= 0:
        raise argparse.ArgumentTypeError("must be a positive integer")
    return number


def add_shared_options(parser, default_cache):
    parser.add_argument("--model", default="Qwen/Qwen3.5-4B", help="Hugging Face model ID")
    parser.add_argument("--batch-size", type=positive_int, default=1, help="Number of missing examples per batch")
    parser.add_argument("--benchmark", action="append", metavar="NAME")
    parser.add_argument("--task", action="append", metavar="BENCHMARK/TASK")
    parser.add_argument("--sample-size", type=positive_int, metavar="N")
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--cache", type=Path, default=ROOT / "cache" / default_cache)
    parser.add_argument("--cache-only", action="store_true", help="Fail on a cache miss; never load a GPU model")
    parser.add_argument("--results", type=Path, required=True, help="Output per-example or per-step CSV")


def make_parser():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    methods = parser.add_subparsers(dest="method", required=True)
    judge = methods.add_parser("llm_judge", help="Generate first-error predictions")
    add_shared_options(judge, "llm_critic_slurm_v2.sqlite")
    judge.add_argument("--thinking", action="store_true")
    judge.add_argument("--max-new-tokens", type=positive_int)
    judge.add_argument("--generation-kwargs", default="{}", metavar="JSON")
    pmi = methods.add_parser("dc_pmi", help="Score steps with all three DC-PMI ablations")
    add_shared_options(pmi, "dc_pmi.sqlite")
    pmi.add_argument("--inference-batch-size", type=positive_int, default=1,
                     help="Number of tokenized sequences per GPU forward pass")
    return parser


def main(argv=None):
    parser = make_parser()
    args = parser.parse_args(argv)
    overrides = None
    if args.method == "llm_judge":
        try:
            overrides = json.loads(args.generation_kwargs)
            if not isinstance(overrides, dict):
                parser.error("--generation-kwargs must be a JSON object")
            llm_critic.generation_kwargs_for(args.thinking, overrides)
        except (ValueError, AssertionError, TypeError) as exc:
            parser.error(f"invalid --generation-kwargs: {exc}")

    tasks = load_examples()
    try:
        selected, examples = select_examples(tasks, args.benchmark, args.task,
                                             args.sample_size, args.seed)
    except AssertionError as exc:
        parser.error(str(exc))

    print(f"Evaluating {len(examples)} examples across {len(selected)} tasks; cache: {args.cache}", flush=True)
    if args.method == "llm_judge":
        results = llm_critic.evaluate(examples, model_id=args.model, thinking=args.thinking,
                                      max_new_tokens=args.max_new_tokens, batch_size=args.batch_size,
                                      generation_kwargs=overrides, cache_path=args.cache,
                                      cache_only=args.cache_only)
        summary = llm_critic.statistics(results)
    else:
        results = dc_pmi.evaluate(examples, model_id=args.model, batch_size=args.batch_size,
                                  inference_batch_size=args.inference_batch_size,
                                  cache_path=args.cache, cache_only=args.cache_only)
        summary = dc_pmi.statistics(results)
    args.results.parent.mkdir(parents=True, exist_ok=True)
    summary_path = args.results.with_name(f"{args.results.stem}_statistics.csv")
    results.to_csv(args.results, index=False)
    summary.to_csv(summary_path, index=False)
    print(summary.to_string(index=False))
    print(f"Saved {args.results} and {summary_path}", flush=True)


if __name__ == "__main__":
    main()
