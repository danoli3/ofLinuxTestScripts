#!/bin/bash
# ARMv6 (Pi 1 / Pi Zero) leg. No RPi OS trixie/bookworm linux/arm/v6 container
# image is published, so this mirrors the PR CI rpi-build approach inside the
# arm64 container: verify the armv6l library path + deployed archives.
set -u
cd /src
FAIL=0
echo "=== ARMv6l cross check (host: $(uname -m)) ==="
bash scripts/ci/linux/test_lib_paths.sh || FAIL=1
./scripts/linux/download_libs.sh -t latest -a armv6l -g 10 || FAIL=1
bash scripts/ci/check_deployed_libs.sh --platform linux --arch armv6l --allow-incomplete || FAIL=1
echo "--- archive architectures under lib/linux/armv6l (expect ARM) ---"
find libs -path "*lib/linux/armv6l*" -name "*.a" | head -n 5 | while read -r a; do echo "$a:"; ar p "$a" 2>/dev/null | head -c 20 | od -c | head -n1; file "$a" 2>/dev/null || true; done
echo "ARMV6L_EXIT:$FAIL"
exit $FAIL
