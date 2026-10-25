#!/bin/bash
# Host orchestrator: run OF Linux tests in Docker for one target (or all).
# Usage: ./scripts/run.sh <target|all>   (see README matrix)
# Env: OF_ROOT (default ../openFrameworks), OF_BRANCH (default linux2026),
#      SKIP_BUILD=1 for lib-path-only smoke.
set -u
HARNESS="$(cd "$(dirname "$0")/.." && pwd)"
OF_ROOT="${OF_ROOT:-$HARNESS/../openFrameworks}"
OF_BRANCH="${OF_BRANCH:-linux2026}"
TARGET="${1:-rpi-arm64}"
STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$HARNESS/results"

# target -> dockerfile | platform | OF_ARCH | ALLOW_INCOMPLETE
target_def() {
  case "$1" in
    rpios-trixie-arm64) echo "Dockerfile.rpios-trixie|linux/arm64|aarch64|1" ;;
    rpios-trixie-armv7) echo "Dockerfile.rpios-trixie|linux/arm/v7|armv7l|1" ;;
    rpi-arm64)        echo "Dockerfile.rpi-arm64|linux/arm64|aarch64|1" ;;
    rpi-armv6l)       echo "Dockerfile.rpi-armv6l|linux/arm/v6|armv6l|1" ;;
    ubuntu-2404-amd64) echo "Dockerfile.ubuntu-2404-amd64|linux/amd64|64|0" ;;
    ubuntu-2204-amd64) echo "Dockerfile.ubuntu-2204-amd64|linux/amd64|64|0" ;;
    debian-amd64)     echo "Dockerfile.debian-amd64|linux/amd64|64|0" ;;
    fedora-amd64)     echo "Dockerfile.fedora-amd64|linux/amd64|64|0" ;;
    arch-amd64)       echo "Dockerfile.arch-amd64|linux/amd64|64|0" ;;
    mint-amd64)       echo "Dockerfile.mint-amd64|linux/amd64|64|0" ;;
    cachyos-amd64)    echo "Dockerfile.cachyos-amd64|linux/amd64|64|0" ;;
    pop-amd64)        echo "Dockerfile.pop-amd64|linux/amd64|64|0" ;;
    zorin-amd64)      echo "Dockerfile.zorin-amd64|linux/amd64|64|0" ;;
    omarchy-amd64)    echo "Dockerfile.omarchy-amd64|linux/amd64|64|0" ;;
    kali-amd64)       echo "Dockerfile.kali-amd64|linux/amd64|64|0" ;;
    kali-arm64)       echo "Dockerfile.kali-arm64|linux/arm64|arm64|0" ;;
    jetson-arm64)     echo "Dockerfile.jetson-arm64|linux/arm64|jetson|0" ;;
    *) return 1 ;;
  esac
}
ALL="rpios-trixie-arm64 rpios-trixie-armv7 rpi-arm64 ubuntu-2404-amd64 ubuntu-2204-amd64 debian-amd64 fedora-amd64 arch-amd64 mint-amd64 cachyos-amd64 pop-amd64 zorin-amd64 omarchy-amd64 kali-amd64 kali-arm64 jetson-arm64"

command -v docker >/dev/null || { echo "ERROR: docker not found. On macOS: brew install colima docker && colima start --arch aarch64"; exit 1; }
docker info >/dev/null 2>&1 || { echo "ERROR: docker daemon not running. On macOS: colima start --arch aarch64"; exit 1; }
[ -d "$OF_ROOT/.git" ] || { echo "ERROR: OF_ROOT is not a git checkout: $OF_ROOT"; exit 1; }

echo "== OF checkout: $OF_ROOT (branch $OF_BRANCH) =="
git -C "$OF_ROOT" checkout "$OF_BRANCH" >/dev/null 2>&1 || git -C "$OF_ROOT" checkout -b "$OF_BRANCH" "origin/$OF_BRANCH"
git -C "$OF_ROOT" log --oneline -1

run_one() {
  local t="$1" def df plat arch allow img log rc
  def="$(target_def "$t")" || { echo "Unknown target: $t"; return 2; }
  IFS='|' read -r df plat arch allow <<< "$def"
  img="of-linux-test:$t"
  log="$HARNESS/results/${STAMP}-${t}.log"
  echo; echo "===== TARGET $t (platform $plat, OF arch $arch) ====="
  docker buildx build --load --platform "$plat" -t "$img" -f "$HARNESS/docker/$df" "$HARNESS/docker" 2>&1 | tee "$log.build"
  docker run --rm --platform "$plat" \
    -e OF_ARCH="$arch" -e ALLOW_INCOMPLETE="$allow" -e SKIP_BUILD="${SKIP_BUILD:-0}" \
    -v "$OF_ROOT:/src" -v "$HARNESS:/harness:ro" "$img" \
    bash /harness/scripts/inside/run-inside.sh 2>&1 | tee "$log"
  rc=${PIPESTATUS[0]}
  echo "TARGET $t EXIT:$rc  log: $log"
  return $rc
}

OVERALL=0
if [ "$TARGET" = "all" ]; then
  for t in $ALL; do run_one "$t" || OVERALL=1; done
else
  run_one "$TARGET" || OVERALL=1
fi
echo; echo "OVERALL_EXIT:$OVERALL  results: $HARNESS/results/"
exit $OVERALL
