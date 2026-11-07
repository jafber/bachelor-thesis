import sqlite3
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import pandas as pd

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

    def test_prompt_uses_model_specific_chat_template(self):
        backend = object.__new__(dc_pmi.LikelihoodBackend)

        class Tokenizer:
            def apply_chat_template(self, messages, **kwargs):
                self.options = kwargs
                return "prompt"

        backend.tokenizer = Tokenizer()
        backend.model_id = "meta-llama/Llama-3.2-3B-Instruct"
        self.assertEqual(backend.prompt("question"), "prompt")
        self.assertNotIn("enable_thinking", backend.tokenizer.options)
        backend.model_id = "Qwen/Qwen3.5-4B"
        backend.prompt("question")
        self.assertIs(backend.tokenizer.options["enable_thinking"], False)

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
        averaged = dc_pmi.derive_scores([(self.wrong, "key", payload)], average_ll=True)
        self.assertEqual(averaged.iloc[0].dc_pmi_generic_domain, 0.5)  # -3/2 - (-2/1)
        self.assertEqual(averaged.iloc[1].dc_pmi_generic_domain, -1.5)  # -7/2 - (-4/2)
        self.assertEqual(averaged.iloc[1].dc_pmi_question_ablation, -2.5)
        self.assertEqual(averaged.iloc[1].dc_pmi_history_ablation, -2.5)
        self.assertEqual(averaged.iloc[1].average_log_likelihood, -3.5)
        self.assertEqual(averaged.iloc[1].perplexity, second.perplexity)

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
            cached = dc_pmi.load_run([self.wrong, self.right], cache_path=path)
            self.assertEqual(calls, ["load", "wrong", "load", "right"])
            from pandas.testing import assert_frame_equal
            assert_frame_equal(both, cached)
            averaged = dc_pmi.load_run([self.wrong, self.right], cache_path=path, average_ll=True)
            assert_frame_equal(averaged, dc_pmi.evaluate([self.wrong, self.right], cache_path=path,
                                                            cache_only=True, average_ll=True))
            self.assertEqual(calls, ["load", "wrong", "load", "right"])
            dc_pmi.run_inference([self.wrong, self.right], cache_path=path)
            self.assertEqual(calls, ["load", "wrong", "load", "right"])
            with self.assertRaisesRegex(RuntimeError, "Cache miss"):
                dc_pmi.load_run([self.wrong], model_id="another-model", cache_path=path)
            self.assertAlmostEqual(first.iloc[1].dc_pmi_generic_domain, -2.)
            summary = dc_pmi.statistics(both).set_index("metric")
            self.assertEqual(summary.loc["perplexity", "auc"], 1.)
            self.assertEqual(summary.loc["perplexity", "f1"], 1.)
            self.assertEqual(summary.loc["perplexity", "mcc"], 1.)
            self.assertEqual(dc_pmi.statistics(both.assign(dc_pmi_generic_domain=1.)).set_index("metric")
                             .loc["dc_pmi_generic_domain", "p_value"], 1.)
            with self.assertRaisesRegex(RuntimeError, "Cache miss"):
                dc_pmi.evaluate([self.wrong], model_id="another-model", cache_path=path,
                                cache_only=True)

    def test_auc_and_roc_include_post_error_steps_with_directional_scores(self):
        from experiment_setup.plots import plot_first_error_roc, plot_task_auc_bars
        scores = pd.DataFrame([
            dict(benchmark="ProcessBench", task="math", uid="wrong", step=step,
                 first_error=step == 2, verified=step <= 2,
                 **{metric: float(step) for metric in dc_pmi.METRICS})
            for step in range(4)
        ])
        stats = dc_pmi.statistics(scores)
        self.assertTrue((stats.n_steps == 4).all())
        self.assertTrue((stats.coverage == 1).all())
        for row in stats.itertuples():
            self.assertAlmostEqual(row.auc, 2 / 3 if row.metric == "perplexity" else 1 / 3)
        self.assertTrue(pd.isna(stats.loc[stats.metric == "perplexity", "p_value"]).all())
        self.assertTrue((stats.loc[stats.metric != "perplexity", "p_value"] > 0.05).all())
        fig, plotted = plot_first_error_roc(scores)
        self.assertTrue((plotted.n_steps == 4).all())
        self.assertTrue((plotted.auc == stats.auc.to_numpy()).all())
        import matplotlib.pyplot as plt
        plt.close(fig)
        for metric in dc_pmi.METRICS:
            bars = plot_task_auc_bars(stats.assign(model="4B"), metric, ("4B",))
            self.assertEqual(len(bars.axes[0].patches), 1)
            self.assertEqual(bars.axes[0].patches[0].get_alpha(),
                             None if metric == "perplexity" else 0.35)
            plt.close(bars)

    def test_question_ablation_low_scores_predict_errors(self):
        scores = pd.DataFrame([
            dict(benchmark="ProcessBench", task="math", uid=str(i), first_error=i < 4,
                 **{metric: float(i) for metric in dc_pmi.METRICS})
            for i in range(8)
        ])
        stats = dc_pmi.statistics(scores).set_index("metric")
        self.assertEqual(stats.loc["dc_pmi_question_ablation", "f1"], 1.)
        self.assertEqual(stats.loc["dc_pmi_question_ablation", "mcc"], 1.)
        for metric in dc_pmi.METRICS[1:]:
            self.assertEqual(stats.loc[metric, "auc"], 1.)
            self.assertAlmostEqual(stats.loc[metric, "p_value"], 1 / 70)
        self.assertLess(stats.loc["perplexity", "f1"], 1.)
        self.assertTrue(pd.isna(stats.loc["perplexity", "p_value"]))

    def test_auc_significance_and_bar_contrast(self):
        from experiment_setup.plots import plot_task_auc_bars
        import matplotlib.pyplot as plt

        scores = pd.DataFrame([
            dict(benchmark="ProcessBench", task="separated", uid=str(i), first_error=i >= 4,
                 **{metric: float(i) if metric == "perplexity" else -float(i)
                    for metric in dc_pmi.METRICS})
            for i in range(8)
        ])
        stats = dc_pmi.statistics(scores)
        self.assertEqual(stats.loc[stats.metric == "perplexity", "auc"].iloc[0], 1.)
        self.assertTrue((stats.loc[stats.metric != "perplexity", "auc"] == 1).all())
        self.assertTrue(pd.isna(stats.p_value.iloc[0]))
        self.assertAlmostEqual(stats.loc[stats.metric != "perplexity", "p_value"].iloc[0], 1 / 70)
        stats = pd.concat([stats, stats.assign(task="not_significant", p_value=0.5)])
        fig = plot_task_auc_bars(stats.assign(model="4B"), "dc_pmi_generic_domain", ("4B",))
        self.assertEqual([bar.get_alpha() for bar in fig.axes[0].patches], [None, 0.35])
        plt.close(fig)

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
