#!/bin/bash
# Cross-build an addon's examples for Raspberry Pi (armv6l / aarch64) the same way OF's CI rpi-build does
# (multistrap sysroot + gnu cross compiler). Runs on an x86_64 Ubuntu host with the OF checkout as cwd.
# Env: ARCH (armv6l|aarch64), ADDON_DIR (addons/<name>), EXAMPLES (space list, default: every example-* that
#      has addons.make, minus ios/ImGuizmo), JOBS.
set -u
OF_ROOT="$(pwd -P)"
ARCH="${ARCH:-armv6l}"
ADDON_DIR="${ADDON_DIR:?ADDON_DIR required}"
JOBS="${JOBS:-3}"
export CROSS_COMPILING=1 PLATFORM_ARCH="$ARCH" PLATFORM_OS=Linux GST_VERSION=1.0
export RPI_ROOT="$OF_ROOT/scripts/ci/linux/rpi/raspbian"
if [ "$ARCH" = "aarch64" ]; then GCC_PREFIX=aarch64-linux-gnu; else GCC_PREFIX=arm-linux-gnueabihf; fi
export PKG_CONFIG_PATH="$RPI_ROOT/usr/include:$RPI_ROOT/usr/lib/pkgconfig:$RPI_ROOT/usr/lib/$GCC_PREFIX/pkgconfig:$RPI_ROOT/usr/share/pkgconfig"
export TOOLCHAIN_ROOT=/usr
export CXX="/usr/bin/${GCC_PREFIX}-g++" CC="/usr/bin/${GCC_PREFIX}-gcc" AR="/usr/bin/${GCC_PREFIX}-ar" LD="/usr/bin/${GCC_PREFIX}-ld"

if [ ! -f libs/glm/include/glm/vec2.hpp ]; then
  echo "::error::apothecary 'latest' libs for $ARCH have no glm/tess2 (zlib smoke-test archive): the OF core cannot be built, so the addon cannot be tested on $ARCH"
  exit 3
fi

stage() {  # stage <name> : examples/_addon_test/<name> with the rpi Makefile/config.make
  local name="$1" src="$ADDON_DIR/$1" dst="examples/_addon_test/$1"
  rm -rf "$dst"; mkdir -p "$dst"
  cp -R "$src/src" "$dst/src"
  [ -f "$src/addons.make" ] && cp "$src/addons.make" "$dst/"
  [ -d "$src/bin" ] && cp -R "$src/bin" "$dst/bin"
  cp "scripts/templates/linux${ARCH}/Makefile" "scripts/templates/linux${ARCH}/config.make" "$dst/"
}

echo "##[group]OF core (emptyExample)"
cp "scripts/templates/linux${ARCH}/Makefile" "scripts/templates/linux${ARCH}/config.make" examples/templates/emptyExample/
(cd examples/templates/emptyExample && make Debug -j"$JOBS") || { echo "::error::OF core / emptyExample failed to build for $ARCH"; exit 2; }
echo "##[endgroup]"

if [ -z "${EXAMPLES:-}" ]; then
  EXAMPLES=""
  for d in "$ADDON_DIR"/example-*; do
    n="$(basename "$d")"
    case "$n" in example-ios|example-ImGuizmo) continue ;; esac
    [ -f "$d/addons.make" ] && [ -d "$d/src" ] && EXAMPLES="$EXAMPLES $n"
  done
fi

PASS=(); FAILED=()
for n in $EXAMPLES; do
  echo "##[group]$n ($ARCH)"
  stage "$n"
  if (cd "examples/_addon_test/$n" && make Debug -j"$JOBS"); then PASS+=("$n"); else FAILED+=("$n"); fi
  echo "##[endgroup]"
done

{
  echo "### $ADDON_DIR on $ARCH (cross build, Debug)"
  echo "| example | result |"; echo "|---|---|"
  for n in "${PASS[@]:-}"; do [ -n "$n" ] && echo "| $n | ✅ built |"; done
  for n in "${FAILED[@]:-}"; do [ -n "$n" ] && echo "| $n | ❌ failed |"; done
} | tee -a "${GITHUB_STEP_SUMMARY:-/dev/null}"
echo "PASS=${#PASS[@]} FAIL=${#FAILED[@]}"
[ "${#FAILED[@]}" -eq 0 ]
