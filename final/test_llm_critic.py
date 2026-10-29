import io
import json
import sqlite3
import logging
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import llm_critic
from llm_critic import Example, evaluate, logger, parse_response, prompt_for, random_answers, statistics


class CriticTests(unittest.TestCase):
    def setUp(self):
        self.mr = Example("MR-GSM8K", "original", "a", "1+1?", ("Step 1: 1+1=3", "Step 2: answer 3"), 0)
        self.pb = Example("ProcessBench", "math", "b", "1+1?", ("1+1=3", "answer 3"), 0)

    def test_native_numbering_and_parse_errors(self):
        self.assertEqual(parse_response("FINAL: 1", self.mr), (0, None))
        self.assertEqual(parse_response("Let me check each step.\nFINAL: 1", self.pb), (0, None))
        self.assertEqual(parse_response("FINAL: 2\nMore reasoning.\nFINAL: 1", self.pb), (0, None))
        self.assertIsNotNone(parse_response("Still reasoning, no final answer", self.pb)[1])
        self.assertIsNotNone(parse_response("FINAL: 1\nMore reasoning", self.pb)[1])
        self.assertEqual(parse_response("FINAL: NONE", self.pb), (None, None))
        self.assertIsNotNone(parse_response("FINAL: 0", self.mr)[1])
        self.assertIsNotNone(parse_response("FINAL: 0", self.pb)[1])
        self.assertEqual(parse_response("FINAL: 1\nFINAL: 2", self.mr), (1, None))
        self.assertIsNotNone(parse_response("Step 1", self.mr)[1])
        self.assertEqual(parse_response("<|im_start|>user\nFINAL: <integer or NONE><|im_end|>\n"
                                        "<|im_start|>assistant\nFINAL: 1<|im_end|><|endoftext|>", self.mr), (0, None))
        self.assertIsNotNone(parse_response("<|im_start|>assistant\nFINAL: 1\nMore reasoning<|im_end|>", self.mr)[1])

    def test_mode_specific_prompt_and_token_budget(self):
        self.assertIn("Reply with ONLY one line", prompt_for(self.mr))
        configs = []
        def backend(config):
            configs.append(config)
            return lambda prompt: "Reasoning.\nFINAL: 1" if config["thinking"] else "FINAL: 1"
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "results.sqlite"
            evaluate([self.mr], cache_path=path, backend_factory=backend, progress=False)
            thinking = evaluate([self.mr], cache_path=path, thinking=True,
                                backend_factory=backend, progress=False)
            changed = evaluate([self.mr], cache_path=path, thinking=True,
                               generation_kwargs={"temperature": 0.6},
                               backend_factory=backend, progress=False)
        self.assertEqual([config["max_new_tokens"] for config in configs], [128, 4096, 4096])
        self.assertEqual(configs[0]["generation_kwargs"], {"do_sample": False})
        self.assertEqual(configs[1]["generation_kwargs"]["temperature"], 1.0)
        self.assertEqual(configs[2]["generation_kwargs"]["temperature"], 0.6)
        self.assertNotEqual(thinking.iloc[0].cache_key, changed.iloc[0].cache_key)
        self.assertEqual(thinking.iloc[0].prediction, 0)

    def test_uniform_steps_and_missing_task_instructions(self):
        self.assertEqual(prompt_for(self.mr).count("Step 1:"), 1)
        self.assertIn("Step 1: 1+1=3", prompt_for(self.mr))
        self.assertIn("Step 1: 1+1=3", prompt_for(self.pb))
        for task, question, expected in (
            ("word_sorting", "apple pear", "Sort the following words alphabetically"),
            ("dyck_languages", "[ {", "Complete the rest of the sequence"),
            ("multistep_arithmetic", "(1 + 2) =", "Evaluate the following arithmetic expression"),
        ):
            example = Example("BIG-Bench-Mistake", task, task, question, ("test",), None)
            prompt = prompt_for(example)
            self.assertIn(expected, prompt)
            self.assertIn("Step 1: test", prompt)
            self.assertNotIn("Thought 1:", prompt)

    def test_reference_answers_and_debug_output(self):
        mr_row = dict(question_type="original", uuid="mr", question="1+1?",
                      model_output_steps="['Step 1: 1+1=3']",
                      model_output_solution_correctness="wrong",
                      model_output_solution_first_error_step=1, ground_truth_answer="2")
        bb_row = dict(input="1+1 =", steps=["1+1=3"], mistake_index=0, target="2")
        pb_row = dict(id="pb", problem="1+1?", steps=["1+1=3"], label=0)
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "BIG-Bench-Mistake").mkdir()
            for task in llm_critic.BBM_TASKS:
                (root / "BIG-Bench-Mistake" / f"{task}.jsonl").write_text(json.dumps(bb_row) + "\n")
            with patch.object(llm_critic, "ROOT", root), patch("datasets.load_dataset", side_effect=[
                [mr_row], {task: [pb_row] for task in llm_critic.PB_TASKS},
            ]):
                tasks = llm_critic.load_examples()
        examples = [group[0] for group in tasks.values()]
        self.assertEqual(examples[0].ground_truth_answer, "2")
        self.assertEqual(examples[1].ground_truth_answer, "2")
        self.assertIsNone(examples[-1].ground_truth_answer)
        self.assertNotIn("Correct answer", prompt_for(examples[0]))
        self.assertNotIn("Correct answer", prompt_for(examples[1]))
        with tempfile.TemporaryDirectory() as tmp:
            results = evaluate([examples[0], examples[-1]], cache_path=Path(tmp) / "cache.sqlite",
                               backend_factory=lambda config: lambda prompt: "FINAL: 1", progress=False)
        with patch("sys.stdout", new_callable=io.StringIO) as out:
            random_answers(results, [examples[0], examples[-1]])
        output = out.getvalue()
        self.assertIn("Question:\n1+1?", output)
        self.assertIn("Solution steps:\nStep 1: 1+1=3", output)
        self.assertIn("Correct answer: 2", output)
        self.assertIn("Correct answer: Not provided", output)
        self.assertIn("Ground truth first error step: Step 1", output)
        self.assertIn("LLM judge's transcript:\nFINAL: 1", output)

    def test_timestamped_logs_and_notebook_progress(self):
        import tqdm.auto

        output = io.StringIO()
        handler = logging.StreamHandler(output)
        handler.setFormatter(logger.handlers[0].formatter)
        logger.addHandler(handler)
        try:
            with tempfile.TemporaryDirectory() as tmp, patch.dict("sys.modules", {"ipykernel": object()}), \
                    patch.object(tqdm.auto, "tqdm", side_effect=lambda examples, **kwargs: examples) as bar:
                evaluate([self.mr, self.pb], cache_path=Path(tmp) / "results.sqlite",
                         backend_factory=lambda config: lambda prompt: "FINAL: 1")
                bar.assert_called_once()
                self.assertEqual(bar.call_args.kwargs["total"], 2)
            logs = output.getvalue()
            self.assertRegex(logs, r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} INFO")
            self.assertIn("Loading backend", logs)
            self.assertIn("Evaluation complete: 2 examples (cache hits=0, generated=2)", logs)
        finally:
            logger.removeHandler(handler)

    def test_batch_mixed_hits_order_and_short_final_batch(self):
        examples = [Example("ProcessBench", "math", str(i), f"Question {i}",
                            ("first", "second"), None) for i in range(6)]
        calls = []

        class Backend:
            def generate_batch(self, prompts):
                calls.append(list(prompts))
                return ["FINAL: 1" if "Question 0\n" in prompt or "Question 3\n" in prompt
                        else "FINAL: 2" for prompt in prompts]

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "results.sqlite"
            evaluate([examples[0], examples[3]], cache_path=path,
                     backend_factory=lambda config: Backend(), progress=False)
            calls.clear()
            result = evaluate(examples, cache_path=path, batch_size=3,
                              backend_factory=lambda config: Backend(), progress=False)
            self.assertEqual([len(batch) for batch in calls], [3, 1])
            self.assertEqual([int(prompt.split("Question ")[1].splitlines()[0])
                              for batch in calls for prompt in batch], [1, 2, 4, 5])
            self.assertEqual(result.uid.tolist(), [str(i) for i in range(6)])
            self.assertEqual(result.prediction.tolist(), [0, 1, 1, 0, 1, 1])
            calls.clear()
            cached = evaluate(examples, cache_path=path, cache_only=True,
                              backend_factory=lambda config: self.fail("Loaded cached backend"), progress=False)
            self.assertEqual(calls, [])
            self.assertEqual(result.transcript.tolist(), cached.transcript.tolist())

    def test_transformers_batch_decodes_full_sequence_with_special_tokens(self):
        import torch

        class Inputs(dict):
            def to(self, device):
                return self

        class Tokenizer:
            pad_token_id = 0

            def apply_chat_template(self, messages, **kwargs):
                return Inputs(input_ids=torch.tensor([[0, 11, 12], [11, 12, 13]]))

            def batch_decode(self, ids, **kwargs):
                self.decoded_ids = ids.tolist()
                self.decode_options = kwargs
                return ["<|im_start|>user<|im_end|><|im_start|>assistant FINAL: 1<|im_end|>"] * len(ids)

        class Model:
            device = "cpu"

            def generate(self, **kwargs):
                self.kwargs = kwargs
                return torch.tensor([[0, 11, 12, 21, 22], [11, 12, 13, 21, 22]])

        judge = object.__new__(llm_critic.TransformersJudge)
        judge.tokenizer = Tokenizer()
        judge.model = Model()
        judge.max_new_tokens = 128
        judge.thinking = False
        judge.generation_kwargs = llm_critic.generation_kwargs_for(False)
        self.assertEqual(len(judge.generate_batch(["a", "b"])), 2)
        self.assertEqual(judge.model.kwargs["do_sample"], False)
        self.assertNotIn("logits_processor", judge.model.kwargs)
        self.assertEqual(judge.tokenizer.decoded_ids, [[0, 11, 12, 21, 22], [11, 12, 13, 21, 22]])
        self.assertEqual(judge.tokenizer.decode_options, {"skip_special_tokens": False})

    def test_thinking_sampling_overrides_and_presence_penalty(self):
        import torch

        judge = object.__new__(llm_critic.TransformersJudge)
        judge.max_new_tokens = 4096
        judge.generation_kwargs = llm_critic.generation_kwargs_for(True, {"temperature": 0.6})
        kwargs = judge._generate_kwargs(3)
        self.assertTrue(kwargs["do_sample"])
        self.assertEqual((kwargs["temperature"], kwargs["top_p"], kwargs["top_k"], kwargs["min_p"]),
                         (0.6, 0.95, 20, 0.0))
        self.assertEqual(kwargs["repetition_penalty"], 1.0)
        self.assertNotIn("presence_penalty", kwargs)

        class Inputs(dict):
            def to(self, device):
                return self

        class Tokenizer:
            pad_token_id = 0

            def apply_chat_template(self, messages, **kwargs):
                return Inputs(input_ids=torch.tensor([[1, 2, 3]]))

            def batch_decode(self, ids, **kwargs):
                return ["transcript"]

        class Model:
            device = "cpu"

            def generate(self, **kwargs):
                self.kwargs = kwargs
                return kwargs["input_ids"]

        judge.thinking = True
        judge.tokenizer = Tokenizer()
        judge.model = Model()
        self.assertEqual(judge.generate_batch(["problem"]), ["transcript"])
        self.assertTrue(judge.model.kwargs["do_sample"])
        self.assertEqual(judge.model.kwargs["top_p"], 0.95)
        self.assertEqual(judge.model.kwargs["top_k"], 20)
        self.assertEqual(len(judge.model.kwargs["logits_processor"]), 1)
        scores = torch.zeros(1, 6)
        scores_after = kwargs["logits_processor"][0](torch.tensor([[1, 2, 3, 4, 4]]), scores)
        self.assertEqual(scores_after.tolist(), [[0, 0, 0, 0, -1.5, 0]])
        self.assertEqual(llm_critic.generation_kwargs_for(False), {"do_sample": False})
        self.assertEqual(llm_critic.generation_kwargs_for(False, {"do_sample": True, "top_p": 0.8}),
                         {"do_sample": True, "top_p": 0.8})

    def test_cache_stores_full_transcript_and_example_identity(self):
        transcript = "<|im_start|>user\nQuestion<|im_end|>\n<|im_start|>assistant\nFINAL: 1<|im_end|>"
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "cache.sqlite"
            result = evaluate([self.mr], cache_path=path, progress=False,
                              backend_factory=lambda config: lambda prompt: transcript)
            with sqlite3.connect(path) as db:
                columns = [row[1] for row in db.execute("PRAGMA table_info(responses)")]
                self.assertNotIn("raw", columns)
                row = db.execute("SELECT key, benchmark, task, uid, transcript FROM responses WHERE uid=?",
                                 (self.mr.uid,)).fetchone()
                self.assertEqual(row, (result.iloc[0].cache_key, "MR-GSM8K", "original", "a", transcript))
            cached = evaluate([self.mr], cache_path=path, cache_only=True, progress=False)
            self.assertEqual(cached.iloc[0].transcript, transcript)
            self.assertEqual(cached.iloc[0].prediction, 0)

    def test_batch_interruption_resume_and_single_vs_batch(self):
        examples = [Example("ProcessBench", "math", str(i), f"Question {i}",
                            ("first", "second"), None) for i in range(5)]
        calls = []

        class Backend:
            def __init__(self, fail=False):
                self.fail = fail

            def generate_batch(self, prompts):
                calls.append([int(prompt.split("Question ")[1].splitlines()[0]) for prompt in prompts])
                if self.fail and len(calls) == 2:
                    raise RuntimeError("batch generation failed")
                return ["FINAL: 1" if i % 2 else "FINAL: NONE" for i in calls[-1]]

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "batched.sqlite"
            with self.assertRaisesRegex(RuntimeError, "batch generation failed"):
                evaluate(examples, cache_path=path, batch_size=2,
                         backend_factory=lambda config: Backend(fail=True), progress=False)
            self.assertEqual(calls, [[0, 1], [2, 3]])
            calls.clear()
            resumed = evaluate(examples, cache_path=path, batch_size=2,
                               backend_factory=lambda config: Backend(), progress=False)
            self.assertEqual(calls, [[2, 3], [4]])
            calls.clear()
            single = evaluate(examples, cache_path=Path(tmp) / "single.sqlite", batch_size=1,
                              backend_factory=lambda config: Backend(), progress=False)
            self.assertEqual(calls, [[i] for i in range(5)])
            self.assertEqual(resumed[["uid", "transcript", "parse_error"]].to_dict("records"),
                             single[["uid", "transcript", "parse_error"]].to_dict("records"))
            self.assertEqual(resumed.prediction.fillna(-1).tolist(), single.prediction.fillna(-1).tolist())

    def test_peak_memory_reported_after_generation_and_failure(self):
        reported = []

        class FakeJudge:
            def __init__(self, *args, **kwargs):
                pass

            def generate_batch(self, prompts):
                if len(prompts) == 2:
                    raise RuntimeError("generation failed")
                return ["FINAL: 1" for _ in prompts]

            def log_peak_memory(self):
                reported.append(True)

        with tempfile.TemporaryDirectory() as tmp, patch.object(llm_critic, "TransformersJudge", FakeJudge):
            path = Path(tmp) / "results.sqlite"
            evaluate([self.mr], cache_path=path, progress=False)
            evaluate([self.mr], cache_path=path, progress=False, cache_only=True)
            self.assertEqual(len(reported), 1)  # cached runs do not load a judge
            with self.assertRaisesRegex(RuntimeError, "generation failed"):
                evaluate([self.mr, self.pb, self.pb], cache_path=Path(tmp) / "failed.sqlite",
                         batch_size=2, progress=False)
            self.assertEqual(len(reported), 2)

    def test_peak_memory_format_without_gpu(self):
        import torch

        judge = object.__new__(llm_critic.TransformersJudge)
        judge.device = "cuda:0"
        output = io.StringIO()
        handler = logging.StreamHandler(output)
        logger.addHandler(handler)
        try:
            with patch.object(torch.cuda, "synchronize") as sync, \
                 patch.object(torch.cuda, "max_memory_allocated", return_value=5 * 1024 ** 3) as peak:
                judge.log_peak_memory()
            sync.assert_called_once_with("cuda:0")
            peak.assert_called_once_with("cuda:0")
            self.assertIn("Peak GPU memory allocated on cuda:0: 5.00 GiB", output.getvalue())
        finally:
            logger.removeHandler(handler)

    def test_batch_with_legacy_callable_backend(self):
        calls = []
        with tempfile.TemporaryDirectory() as tmp:
            result = evaluate([self.mr, self.pb], cache_path=Path(tmp) / "results.sqlite", batch_size=2,
                              backend_factory=lambda config: lambda prompt: calls.append(prompt) or "FINAL: 1",
                              progress=False)
        self.assertEqual(len(calls), 2)
        self.assertEqual(result.prediction.tolist(), [0, 0])

    def test_resume_and_cache_only(self):
        calls = []
        def backend(_config):
            def answer(prompt):
                calls.append(prompt)
                return "FINAL: 1"
            return answer
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "results.sqlite"
            with self.assertRaisesRegex(RuntimeError, "Cache miss"):
                evaluate([self.mr], cache_path=path, cache_only=True)
            first = evaluate([self.mr], cache_path=path, backend_factory=backend)
            self.assertEqual(len(calls), 1)
            both = evaluate([self.mr, self.pb], cache_path=path, backend_factory=backend)
            self.assertEqual(len(calls), 2)
            evaluate([self.mr, self.pb], cache_path=path, cache_only=True)
            self.assertEqual(len(calls), 2)
            self.assertEqual(statistics(both).accuracy.tolist(), [1.0, 1.0])
            with self.assertRaisesRegex(RuntimeError, "Cache miss"):
                evaluate([self.mr], cache_path=path, cache_only=True, thinking=True)
            self.assertEqual(first.iloc[0].prediction, 0)


if __name__ == "__main__":
    unittest.main()
