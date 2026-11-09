"""Tests for paper-style judge metrics (including invalid output denominators)."""
import unittest

import pandas as pd
from sklearn.metrics import matthews_corrcoef

from experiment_setup.judge_metrics import score, summarize, processbench_average


class JudgeMetricsTests(unittest.TestCase):
    def test_invalid_is_not_none_and_exact_error_location_matters(self):
        rows = pd.DataFrame(dict(label=[None, None, 0, 1, 2, 0],
                                 prediction=[None, None, 0, 0, None, None],
                                 parse_error=[None, "invalid", None, None, None, "invalid"]))
        metrics = score(rows)
        self.assertEqual(metrics['unparseable'], 2)
        self.assertAlmostEqual(metrics['accuracy'], 2 / 6)
        self.assertAlmostEqual(metrics['correct_accuracy'], 1 / 2)
        self.assertAlmostEqual(metrics['error_accuracy'], 1 / 4)
        self.assertAlmostEqual(metrics['processbench_hm'], 1 / 3)
        self.assertAlmostEqual(metrics['mr_mcc'], matthews_corrcoef(
            [0, 0, 1, 1, 1, 1], [0, 1, 1, 1, 0, 0]))

    def test_macro_hm_not_pooled_hm(self):
        rows = pd.DataFrame(dict(benchmark=['ProcessBench'] * 12,
                                 task=['a'] * 4 + ['b'] * 8,
                                 label=[None, None, 0, 1] + [None] * 4 + [0] * 4,
                                 prediction=[None, 0, 0, 1] + [None] * 4 + [None] * 4,
                                 parse_error=[None] * 12))
        tasks = summarize(rows, ('task',))
        self.assertAlmostEqual(tasks.iloc[0].processbench_hm, 2 / 3)
        self.assertEqual(tasks.iloc[1].processbench_hm, 0)
        self.assertNotEqual(score(rows)['processbench_hm'], tasks.processbench_hm.mean())
        self.assertTrue(pd.isna(processbench_average(rows)))  # require all four splits


if __name__ == '__main__':
    unittest.main()
