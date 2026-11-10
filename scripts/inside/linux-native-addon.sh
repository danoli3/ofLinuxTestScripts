#!/bin/bash
# Build an addon's examples natively on an x86_64/aarch64 Linux host with the OF checkout as cwd.
# Env: ADDON_DIR (addons/<name>), EXAMPLES (space list, default: every example-* with addons.make,
#      minus ios/ImGuizmo), JOBS.
set -u
ADDON_DIR="${ADDON_DIR:?ADDON_DIR required}"
JOBS="${JOBS:-4}"
ARCH="$(uname -m)"
case "$ARCH" in x86_64) TPL=linux64 ;; aarch64) TPL=linuxaarch64 ;; *) TPL="linux$ARCH" ;; esac

stage() {
  local name="$1" src="$ADDON_DIR/$1" dst="examples/_addon_test/$1"
  rm -rf "$dst"; mkdir -p "$dst"
  cp -R "$src/src" "$dst/src"
  [ -f "$src/addons.make" ] && cp "$src/addons.make" "$dst/"
  [ -d "$src/bin" ] && cp -R "$src/bin" "$dst/bin"
  cp "scripts/templates/$TPL/Makefile" "scripts/templates/$TPL/config.make" "$dst/"
}

echo "##[group]OF core (emptyExample)"
cp "scripts/templates/$TPL/Makefile" "scripts/templates/$TPL/config.make" examples/templates/emptyExample/
(cd examples/templates/emptyExample && make Debug -j"$JOBS") || { echo "::error::OF core / emptyExample failed to build"; exit 2; }
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
  echo "##[group]$n ($TPL)"
  stage "$n"
  if (cd "examples/_addon_test/$n" && make Debug -j"$JOBS"); then PASS+=("$n"); else FAILED+=("$n"); fi
  echo "##[endgroup]"
done

{
  echo "### $ADDON_DIR on $TPL (native build, Debug)"
  echo "| example | result |"; echo "|---|---|"
  for n in "${PASS[@]:-}"; do [ -n "$n" ] && echo "| $n | ✅ built |"; done
  for n in "${FAILED[@]:-}"; do [ -n "$n" ] && echo "| $n | ❌ failed |"; done
} | tee -a "${GITHUB_STEP_SUMMARY:-/dev/null}"
echo "PASS=${#PASS[@]} FAIL=${#FAILED[@]}"
[ "${#FAILED[@]}" -eq 0 ]
