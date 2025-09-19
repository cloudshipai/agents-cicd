import os
import sys
import json
import unittest

# Ensure we can import from the python/ directory
sys.path.append(os.path.dirname(__file__))

from finops_analytics_ec2 import analyze

class TestFinOpsAnalyticsEC2(unittest.TestCase):
    def setUp(self):
        with open("examples/finops_ec2_sample.json", "r", encoding="utf-8") as f:
            self.instances = json.load(f)["instances"]

    def test_analyze_generates_recommendations(self):
        result = analyze(
            instances=self.instances,
            current_cost=2332.74,
            cpu_threshold=10.0,
            network_threshold=1_000_000.0
        )
        self.assertIn("total_estimated_savings", result)
        self.assertIn("recommendations", result)
        self.assertGreaterEqual(result["total_estimated_savings"], 0.0)
        self.assertTrue(any(rec["instance_id"] == "i-aaaa1111" for rec in result["recommendations"]))

    def test_no_running_instances(self):
        stopped = [dict(i, State="stopped") for i in self.instances]
        result = analyze(
            instances=stopped,
            current_cost=100.0,
            cpu_threshold=10.0,
            network_threshold=1_000_000.0
        )
        self.assertEqual(result["total_estimated_savings"], 0.0)
        self.assertEqual(len(result["recommendations"]), 0)

if __name__ == "__main__":
    unittest.main()
