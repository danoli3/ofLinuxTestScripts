#!/usr/bin/env python3
"""Check ref selection with a real disposable checkout and no Docker daemon."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


HARNESS = Path(__file__).resolve().parents[2]


class RunnerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.of = self.root / "of"
        self.of.mkdir()
        self.git("init", "-b", "fixture")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.com",
                 "-c", "core.hooksPath=/dev/null", "commit", "--allow-empty",
                 "-m", "release fixture")
        self.git("tag", "0.12.2-RC1")
        self.release = self.git("rev-parse", "HEAD")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.com",
                 "-c", "core.hooksPath=/dev/null", "commit", "--allow-empty",
                 "-m", "newer fixture")
        self.newer = self.git("rev-parse", "HEAD")
        # Copy the runner so its logs stay in the disposable harness directory.
        runner = self.root / "harness/scripts/run.sh"
        runner.parent.mkdir(parents=True)
        runner.write_text((HARNESS / "scripts/run.sh").read_text())
        self.runner = runner
        binary = self.root / "bin/docker"
        binary.parent.mkdir()
        binary.write_text('#!/bin/bash\nprintf "%s\\n" "$*" >> "$DOCKER_CALLS"\n')
        binary.chmod(0o755)
        self.calls = self.root / "docker-calls"
        self.env = dict(os.environ, OF_ROOT=str(self.of),
                        DOCKER_CALLS=str(self.calls),
                        PATH=str(binary.parent) + os.pathsep + os.environ["PATH"])
        self.env.pop("OF_BRANCH", None)

    def git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.of), *args],
                                       text=True, stderr=subprocess.STDOUT).strip()

    def run_harness(self):
        return subprocess.run(["bash", str(self.runner), "rpi-arm64"],
                              env=self.env, text=True, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT)

    def test_default_selects_release_tag(self):
        result = self.run_harness()
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.git("rev-parse", "HEAD"), self.release)
        self.assertIn("buildx build", self.calls.read_text())

    def test_ref_override_is_preserved(self):
        self.env["OF_BRANCH"] = "fixture"
        result = self.run_harness()
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.git("rev-parse", "HEAD"), self.newer)

    def test_missing_ref_stops_before_container_build(self):
        self.env["OF_BRANCH"] = "missing-release"
        result = self.run_harness()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("stopping before tests", result.stdout)
        self.assertEqual(self.calls.read_text().splitlines(), ["info"])
        self.assertEqual(self.git("rev-parse", "HEAD"), self.newer)


if __name__ == "__main__":
    unittest.main()
