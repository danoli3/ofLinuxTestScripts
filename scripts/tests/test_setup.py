#!/usr/bin/env python3
"""Exercise container orchestration with fake OF commands; never install packages."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


HARNESS = Path(__file__).resolve().parents[2]


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.env = dict(os.environ, OF_ARCH="armv7l", SKIP_BUILD="0",
                        CALLS=str(self.root / "calls"))
        self.write("scripts/of.sh", "# menu implementation marker\n")

    def write(self, name, body):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body)
        return path

    def run_script(self, script):
        return subprocess.run(["bash", str(script)], cwd=self.root, env=self.env,
                              text=True, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT)

    def test_menu_architecture_and_noninteractive_package_managers(self):
        self.write("of", '''
set -eu
test "$*" = "setup linux"
test "$LIB_ARCH" = armv7l
test "$DOWNLOAD_LIBS_ARGS" = "-g 10"
test "$DEBIAN_FRONTEND" = noninteractive
test "$OF_SETUP_CODECS" = 0
test "$OF_ANIM" = 0
test ! -t 0
grep -q 'Assume-Yes "true"' "$APT_CONFIG"
printf '%s\\n' "$APT_CONFIG" > apt-config-path
pacman -S --needed cairo
''')
        pacman = self.write("bin/pacman", '''#!/bin/bash
printf '%s\\n' "$*" > "$CALLS"
''')
        pacman.chmod(0o755)
        self.env["PATH"] = str(pacman.parent) + os.pathsep + self.env["PATH"]
        result = self.run_script(HARNESS / "scripts/inside/setup-of.sh")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual((self.root / "calls").read_text().strip(),
                         "--noconfirm -S --needed cairo")
        self.assertFalse(Path((self.root / "apt-config-path").read_text().strip()).exists())

    def test_failed_menu_is_not_hidden_by_direct_installer_fallback(self):
        self.write("of", "exit 23\n")
        self.write("scripts/linux/debian/install_dependencies.sh",
                   'echo unexpected-fallback > "$CALLS"\n')
        result = self.run_script(HARNESS / "scripts/inside/setup-of.sh")
        self.assertEqual(result.returncode, 23, result.stdout)
        self.assertFalse((self.root / "calls").exists())

    def container_runner(self):
        self.write("scripts/ci/linux/test_lib_paths.sh", "exit 0\n")
        # Substitute container mount points only, leaving runner logic intact.
        runner = (HARNESS / "scripts/inside/run-inside.sh").read_text()
        runner = runner.replace("cd /src", 'cd "' + str(self.root) + '"')
        runner = runner.replace("/harness/", str(HARNESS) + "/")
        return self.write("run-inside.sh", runner)

    def test_setup_failure_stops_before_builds_and_checks(self):
        self.write("of", "exit 23\n")
        self.write("scripts/ci/check_deployed_libs.sh", 'touch "$CALLS"\n')
        self.write("scripts/ci/linux/64/run_tests.sh", 'touch "$CALLS"\n')
        result = self.run_script(self.container_runner())
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("INSIDE_EXIT:1", result.stdout)
        self.assertNotIn("STEP 3", result.stdout)
        self.assertFalse((self.root / "calls").exists())

    def test_smoke_does_not_install_dependencies(self):
        self.write("of", 'touch "$CALLS"; exit 23\n')
        self.env["SKIP_BUILD"] = "1"
        result = self.run_script(self.container_runner())
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertFalse((self.root / "calls").exists())

    def test_jetson_checks_arm64_deployment(self):
        self.write("of", "exit 0\n")
        self.write("scripts/ci/check_deployed_libs.sh", '''
test "$*" = "--platform linux --arch arm64" || exit 7
echo checked > "$CALLS"
''')
        self.env["OF_ARCH"] = "jetson"
        result = self.run_script(self.container_runner())
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual((self.root / "calls").read_text().strip(), "checked")

    def test_armv7_builds_use_userland_architecture(self):
        self.write("of", "exit 0\n")
        self.write("scripts/ci/check_deployed_libs.sh", "exit 0\n")
        self.write("libs/glm/include/glm/vec2.hpp", "// fixture\n")
        (self.root / "libs/openFrameworksCompiled/project").mkdir(parents=True)
        make = self.write("bin/make", '''#!/bin/bash
test "$PLATFORM_ARCH" = armv7l || exit 7
test "$CROSS_COMPILING" = 0 || exit 8
echo core >> "$CALLS"
''')
        make.chmod(0o755)
        self.env["PATH"] = str(make.parent) + os.pathsep + self.env["PATH"]
        self.write("scripts/ci/linux/64/run_tests.sh", '''
test "$PLATFORM_ARCH" = armv7l || exit 7
test "$CROSS_COMPILING" = 0 || exit 8
echo unit-tests >> "$CALLS"
''')
        result = self.run_script(self.container_runner())
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual((self.root / "calls").read_text().splitlines(),
                         ["core", "unit-tests"])


if __name__ == "__main__":
    unittest.main()
