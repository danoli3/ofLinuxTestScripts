#!/bin/bash
# In-container OF Linux test steps. Repo mounted at /src, this repo at /harness.
# Env: OF_ARCH (aarch64|64|armv6l), SKIP_BUILD=1 for lib-path smoke only,
#      ALLOW_INCOMPLETE=1 to pass --allow-incomplete to check_deployed_libs.sh
set -u
cd /src
FAIL=0
step() { echo; echo "=== $* ==="; }
step "SIM: uname / os"
uname -a; (cat /etc/os-release 2>/dev/null | head -n 3) || true
step "STEP 1: lib path tests"
bash scripts/ci/linux/test_lib_paths.sh || FAIL=1
if [ "${SKIP_BUILD:-0}" = "1" ]; then
  echo "SKIP_BUILD=1: stopping after lib-path tests"
  exit $FAIL
fi
step "STEP 2: download libs (arch=${OF_ARCH:-64})"
./scripts/linux/download_libs.sh -t latest -a "${OF_ARCH:-64}" -g 10 || FAIL=1
step "STEP 3: deployed libs check"
EXTRA=""; [ "${ALLOW_INCOMPLETE:-0}" = "1" ] && EXTRA="--allow-incomplete"
bash scripts/ci/check_deployed_libs.sh --platform linux --arch "${OF_ARCH:-64}" $EXTRA || FAIL=1
step "STEP 4: build OF core + unit tests"
if [ -f libs/glm/include/glm/vec2.hpp ]; then
  (cd libs/openFrameworksCompiled/project && make -j4 Debug) || FAIL=1
  bash scripts/ci/linux/64/run_tests.sh || FAIL=1
else
  echo "SKIP core build: apothecary latest has no glm (same guard as CI rpi-build)"
fi
echo "INSIDE_EXIT:$FAIL"
exit $FAIL
