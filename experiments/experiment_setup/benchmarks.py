"""Benchmark loading, normalization and deterministic task selection."""
import ast
from dataclasses import dataclass
import json
from pathlib import Path
import random
import re

ROOT = Path(__file__).resolve().parent.parent
BBM_TASKS = ("dyck_languages", "logical_deduction", "multistep_arithmetic", "tracking_shuffled_objects", "word_sorting")
PB_TASKS = ("gsm8k", "math", "olympiadbench", "omnimath")


@dataclass(frozen=True)
class Example:
    benchmark: str
    task: str
    uid: str
    question: str
    steps: tuple[str, ...]
    label: int | None  # zero-based; None means no error
    ground_truth_answer: str | None = None


def load_examples():
    from datasets import load_dataset

    tasks = {}
    mr = load_dataset("Randolphzeng/Mr-GSM8K", split="test")
    for row in mr:
        steps = ast.literal_eval(row["model_output_steps"])
        wrong = row["model_output_solution_correctness"] == "wrong"
        label = int(row["model_output_solution_first_error_step"]) - 1 if wrong else None
        e = Example("MR-GSM8K", row["question_type"], str(row["uuid"]), row["question"], tuple(steps), label, row["ground_truth_answer"])
        tasks.setdefault((e.benchmark, e.task), []).append(e)
    for task in BBM_TASKS:
        with (ROOT / "BIG-Bench-Mistake" / f"{task}.jsonl").open() as file:
            for index, line in enumerate(file):
                row = json.loads(line)
                e = Example("BIG-Bench-Mistake", task, str(index), row["input"], tuple(row["steps"]), row["mistake_index"], row["target"])
                tasks.setdefault((e.benchmark, e.task), []).append(e)
    pb = load_dataset("Qwen/ProcessBench")
    for task in PB_TASKS:
        for row in pb[task]:
            e = Example("ProcessBench", task, str(row["id"]), row["problem"], tuple(row["steps"]), None if row["label"] == -1 else int(row["label"]))
            tasks.setdefault((e.benchmark, e.task), []).append(e)
    for group in tasks.values():
        assert len({e.uid for e in group}) == len(group)
        assert all(e.steps and (e.label is None or 0 <= e.label < len(e.steps)) for e in group)
    return tasks


def sample_tasks(tasks, size=100, seed=42):
    assert size > 0
    return [e for key, group in tasks.items() for e in random.Random(f"{seed}:{key}").sample(group, size)]


def sample_control_and_error(examples, seed=42):
    """Return (error, control) examples matched by task and number of steps.

    Draw error traces in random order, pairing each with an unused, randomly
    chosen error-free trace of the same length. Discard unmatched errors.
    """
    tasks = {}
    for example in examples:
        tasks.setdefault((example.benchmark, example.task), []).append(example)
    rng = random.Random(seed)
    errors, controls = [], []
    for group in tasks.values():
        candidates = [example for example in group if example.label is not None]
        available = {}
        for example in group:
            if example.label is None:
                available.setdefault(len(example.steps), []).append(example)
        rng.shuffle(candidates)
        for example in candidates:
            matches = available.get(len(example.steps), [])
            if not matches:
                continue
            errors.append(example)
            controls.append(matches.pop(rng.randrange(len(matches))))
    return errors, controls


def select_examples(tasks, benchmarks=None, task_names=None, sample_size=None, seed=42):
    known_benchmarks = {benchmark for benchmark, _ in tasks}
    known_tasks = {f"{benchmark}/{task}" for benchmark, task in tasks}
    assert not benchmarks or set(benchmarks) <= known_benchmarks, "Unknown benchmark"
    assert not task_names or set(task_names) <= known_tasks, "Unknown task"
    selected = {key: group for key, group in tasks.items()
                if (not benchmarks or key[0] in benchmarks)
                and (not task_names or f"{key[0]}/{key[1]}" in task_names)}
    assert selected, "No tasks selected"
    if sample_size is not None:
        assert all(len(group) >= sample_size for group in selected.values()), "Sample size exceeds task size"
        return selected, sample_tasks(selected, size=sample_size, seed=seed)
    return selected, [e for group in selected.values() for e in group]


def problem_for(e):
    if e.benchmark != "BIG-Bench-Mistake":
        return e.question
    if e.task == "word_sorting":
        return f"Sort the following words alphabetically: List: {e.question}"
    if e.task == "dyck_languages":
        return ("Complete the rest of the sequence, making sure that the parentheses "
                f"are closed properly. Input: {e.question}")
    if e.task == "multistep_arithmetic":
        return f"Evaluate the following arithmetic expression: {e.question} ?"
    assert e.task in {"logical_deduction", "tracking_shuffled_objects"}
    return e.question


def numbered_steps(e):
    if e.benchmark == "MR-GSM8K":
        steps = []
        for i, step in enumerate(e.steps, 1):
            match = re.match(r"^Step\s+(\d+):\s*", step)
            assert match and int(match[1]) == i, f"Unexpected MR-GSM8K step label: {step[:80]!r}"
            steps.append(step[match.end():])
    else:
        steps = e.steps
    return tuple(f"Step {i}: {step}" for i, step in enumerate(steps, 1))


def solution_for(e):
    return "\n".join(numbered_steps(e))
