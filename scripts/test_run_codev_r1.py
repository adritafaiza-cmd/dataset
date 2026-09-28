#!/usr/bin/env python3

import argparse
import json
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from unittest.mock import patch

import run_codev_r1 as codev
from eval_all_generated import iter_generated
from evaluate_generated import evaluation_sim_script


class CodeVR1Tests(unittest.TestCase):
    def test_extract_final_answer_and_keep_helpers(self):
        response = (
            "<think>```verilog\nmodule wrong; endmodule\n```</think>"
            "<answer>```verilog\nmodule helper; endmodule\n"
            "module cdc_2phase; endmodule\n```</answer>"
        )
        rtl = codev.extract_rtl(response, "cdc_2phase")
        self.assertIn("module helper; endmodule", rtl)
        self.assertIn("module cdc_2phase; endmodule", rtl)
        self.assertNotIn("module wrong", rtl)
        self.assertIsNone(codev.extract_rtl("<think>still reasoning", "cdc_2phase"))

    def test_three_prompt_pilot_and_no_false_scores(self):
        self.assertEqual(len(list(codev.jobs(codev.circuits(None, False), 3))), 27)
        with tempfile.TemporaryDirectory() as temp, patch.object(codev, "OUTPUT", Path(temp)):
            report = codev.render_results(["cdc_2phase"], 3)
            self.assertIn("0/3", report)
            self.assertIn("N/A", report)
            self.assertIn("not run", report)

    def test_shared_evaluator_keeps_each_pilot_testbench(self):
        with tempfile.TemporaryDirectory(dir=codev.ROOT / "experiments") as temp:
            for name in codev.PILOT:
                work = Path(temp) / name
                work.mkdir()
                runner, _ = evaluation_sim_script(work / f"{name}.v", name, work, compile_only=False)
                script = runner.read_text()
                self.assertIn(f'BENCH="$ROOT/benchmarks/{name}"', script)
                self.assertIn(f'$BENCH/{codev.manifest_scalar(name, "testbench")}', script)
                self.assertIn(str((work / f"{name}.v").resolve()), script)

    def test_completed_cells_keep_functional_and_rdc_metrics_separate(self):
        with tempfile.TemporaryDirectory() as temp, patch.object(codev, "OUTPUT", Path(temp)):
            records = (
                {"compile_ok": True, "simulate_ok": True, "jg_returncode": 0, "cdc_errors": 0, "rdc_errors": 1, "cdc_clean": False},
                {"compile_ok": True, "simulate_ok": False},
                {"compile_ok": False, "simulate_ok": None},
            )
            for attempt, result in enumerate(records, 1):
                directory = Path(temp) / "cdc_2phase" / "functional" / f"attempt-{attempt:03d}"
                directory.mkdir(parents=True)
                (directory / "results.json").write_text(json.dumps(result))
            outcome = codev.cell("cdc_2phase", "functional", 3)
            self.assertEqual((outcome["compile_pass"], outcome["functional_pass"], outcome["clean"]), (2, 1, 0))
            self.assertEqual((outcome["cdc_errors"], outcome["rdc_errors"]), (0, 1))
            self.assertTrue(outcome["jasper_known"])
            report = codev.render_results(["cdc_2phase"], 3)
            self.assertIn("0.333", report)
            self.assertIn("1.000", report)

    def test_tool_failure_is_not_a_model_compile_failure(self):
        with tempfile.TemporaryDirectory() as temp, patch.object(codev, "OUTPUT", Path(temp)):
            directory = Path(temp) / "cdc_2phase" / "functional" / "attempt-001"
            directory.mkdir(parents=True)
            (directory / "results.json").write_text(json.dumps({"compile_ok": False, "returncode": 127, "log": None}))
            outcome = codev.cell("cdc_2phase", "functional", 1)
            self.assertEqual(outcome["tool_errors"], 1)
            self.assertEqual(outcome["compile_pass"], 0)
            self.assertFalse(outcome["compile_known"])

    def test_local_chat_response_preserves_prompt_and_metadata(self):
        class Handler(BaseHTTPRequestHandler):
            def respond(self, body):
                encoded = json.dumps(body).encode()
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(encoded)))
                self.end_headers()
                self.wfile.write(encoded)

            def do_GET(self):
                self.respond({"data": [{"id": codev.MODEL}]})

            def do_POST(self):
                payload = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
                if payload["model"] != codev.MODEL or payload["messages"][-1]["role"] != "user":
                    self.send_error(400)
                    return
                self.respond({"model": codev.MODEL, "usage": {"prompt_tokens": 10, "completion_tokens": 12}, "choices": [{"finish_reason": "stop", "message": {"content": "<answer>```verilog\nmodule cdc_2phase; endmodule\n```</answer>"}}]})

            def log_message(self, *_args):
                pass

        server = HTTPServer(("127.0.0.1", 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            base = codev.endpoint(f"http://127.0.0.1:{server.server_port}/v1")
            args = argparse.Namespace(system_prompt="official", temperature=0.2, top_p=0.95, max_tokens=8192, seed=1000, timeout=5, model_revision="test", continue_on_error=False)
            with tempfile.TemporaryDirectory() as temp, patch.object(codev, "OUTPUT", Path(temp)):
                codev.generate_one(base, "cdc_2phase", "observable", 1, args)
                attempt = Path(temp) / "cdc_2phase" / "observable" / "attempt-001"
                self.assertIn("module cdc_2phase; endmodule", (attempt / "generated" / "cdc_2phase.v").read_text())
                metadata = json.loads((attempt / "metadata.json").read_text())
                self.assertEqual(metadata["generation_status"], "generated")
                self.assertEqual(metadata["prompt_type"], "observable")
                self.assertEqual(metadata["prompt_sha256"], codev.hashlib.sha256((attempt / "prompt.md").read_bytes()).hexdigest())
                self.assertEqual(next(iter_generated(Path(temp)))[:3], ("cdc_2phase", "observable", "attempt-001"))
                self.assertFalse(codev.cell("cdc_2phase", "observable", 1)["functional_known"])
                codev.generate_one(base, "cdc_2phase", "observable", 1, args)
        finally:
            server.shutdown()
            server.server_close()
            thread.join()


if __name__ == "__main__":
    unittest.main()
