import sqlite3
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from experiment_setup.benchmarks import Example
from experiment_setup import dc_pmi
import run_experiment


class DCPMITests(unittest.TestCase):
    def setUp(self):
        self.wrong = Example("ProcessBench", "math", "wrong", "1+1?", ("one", "two"), 1)
        self.right = Example("ProcessBench", "math", "right", "2+2?", ("one", "two"), None)

    def test_scoring_contexts_and_token_spans(self):
        backend = object.__new__(dc_pmi.LikelihoodBackend)
        backend.prompt = lambda question: f"PROMPT {question}"
        backend.score_texts = lambda texts: [
            ([1] * (len(text) - 1), [-1.0] * (len(text) - 1),
             [(i, i + 1) for i in range(len(text))]) for text in texts
        ]
        batch = [(self.wrong, dc_pmi.scoring_inputs(self.wrong))]
        payload = backend.score_batch(batch)[0]
        self.assertEqual(len(payload["full"]["step_spans"]), 2)
        self.assertEqual(len(payload["generic_domain"]["step_spans"]), 2)
        self.assertEqual(payload["full"]["step_spans"][0][1] - payload["full"]["step_spans"][0][0],
                         len("Step 1: one"))
        self.assertEqual(len(payload["generic_domain"]["token_logprobs"]),
                         2 * len("Step 1: one"))
        self.assertEqual(len(dc_pmi.derive_scores([(self.wrong, "key", payload)])), 2)

    def test_dc_pmi_uses_full_sequence_log_likelihoods(self):
        payload = {
            "full": dict(token_ids=[1, 2, 3, 4], token_logprobs=[-1., -2., -3., -4.],
                         step_spans=[[0, 2], [2, 4]]),
            "generic_domain": dict(token_ids=[1, 2, 3], token_logprobs=[-2., -2., -2.],
                                   step_spans=[[0, 1], [1, 3]]),
            "question_ablated": dict(token_ids=[1, 2, 3, 4], token_logprobs=[-1., -1., -1., -1.],
                                     step_spans=[[0, 2], [2, 4]]),
            "history_ablated": dict(token_ids=[1, 2], token_logprobs=[-1., -1.],
                                    step_spans=[[0, 1], [1, 2]]),
        }
        scores = dc_pmi.derive_scores([(self.wrong, "key", payload)])
        first, second = scores.iloc[0], scores.iloc[1]
        self.assertEqual(first.dc_pmi_generic_domain, -1.)  # -3 - (-2)
        self.assertEqual(second.dc_pmi_generic_domain, -3.)  # -7 - (-4)
        self.assertEqual(second.dc_pmi_question_ablation, -5.)  # -7 - (-2)
        self.assertEqual(second.dc_pmi_history_ablation, -6.)  # -7 - (-1)
        self.assertEqual(second.average_log_likelihood, -3.5)

    def test_metrics_auc_and_cache_resume(self):
        calls = []

        class Backend:
            def __init__(self, model_id, inference_batch_size):
                calls.append("load")

            def score_batch(self, batch):
                calls.extend(e.uid for e, _ in batch)
                results = []
                for e, _ in batch:
                    full = [-2., -4.] if e.label is not None else [-1., -1.]
                    contexts = {}
                    for name, logprobs in (("full", full), ("generic_domain", [-2., -2.]),
                                           ("question_ablated", [-2., -2.]),
                                           ("history_ablated", [-2., -2.])):
                        contexts[name] = dict(token_ids=[1, 2], token_logprobs=logprobs,
                                              step_spans=[[0, 1], [1, 2]])
                    results.append(contexts)
                return results

            def log_peak_memory(self):
                pass

        with tempfile.TemporaryDirectory() as tmp, patch.object(dc_pmi, "LikelihoodBackend", Backend):
            path = Path(tmp) / "cache.sqlite"
            first = dc_pmi.evaluate([self.wrong], cache_path=path, batch_size=2)
            self.assertEqual(calls, ["load", "wrong"])
            with sqlite3.connect(path) as db:
                self.assertEqual(db.execute("SELECT count(*) FROM likelihoods").fetchone()[0], 1)
            with self.assertLogs(dc_pmi.logger, level="INFO") as logs:
                both = dc_pmi.evaluate([self.wrong, self.right], cache_path=path)
            self.assertIn("Cache lookup complete: 1/2 examples loaded from cache; 1 need inference",
                          "\n".join(logs.output))
            self.assertIn("Starting DC-PMI inference: 1 samples", "\n".join(logs.output))
            self.assertEqual(calls, ["load", "wrong", "load", "right"])
            cached = dc_pmi.evaluate([self.wrong, self.right], cache_path=path,
                                     cache_only=True)
            self.assertEqual(calls, ["load", "wrong", "load", "right"])
            from pandas.testing import assert_frame_equal
            assert_frame_equal(both, cached)
            self.assertAlmostEqual(first.iloc[1].dc_pmi_generic_domain, -2.)
            self.assertEqual(dc_pmi.auc_statistics(both).set_index("metric").loc["perplexity", "auc"], 1.)
            with self.assertRaisesRegex(RuntimeError, "Cache miss"):
                dc_pmi.evaluate([self.wrong], model_id="another-model", cache_path=path,
                                cache_only=True)

    def test_cli_dc_pmi(self):
        with tempfile.TemporaryDirectory() as tmp, \
                patch.object(run_experiment, "load_examples", return_value={("ProcessBench", "math"): [self.wrong]}), \
                patch.object(run_experiment.dc_pmi, "evaluate", return_value=dc_pmi.derive_scores([
                    (self.wrong, "key", {name: dict(token_ids=[1, 2], token_logprobs=[-1., -2.],
                                             step_spans=[[0, 1], [1, 2]]) for name in dc_pmi.CONTEXTS})
                ])) as run:
            output = Path(tmp) / "results.csv"
            run_experiment.main(["dc_pmi", "--task", "ProcessBench/math", "--cache-only",
                                 "--results", str(output)])
            self.assertTrue(output.exists())
            self.assertTrue(output.with_name("results_statistics.csv").exists())
            self.assertTrue(run.call_args.kwargs["cache_only"])


if __name__ == "__main__":
    unittest.main()
