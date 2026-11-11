#!/bin/bash
# Build an addon's examples with Emscripten (wasm32 or wasm64) inside the emscripten/emsdk image.
# cwd = OF checkout. Env: WASM (32|64), GLES (3 = WebGL2 default | 2 = WebGL1 via OF_WEBGL_VERSION=1), ADDON_DIR (addons/<name>), EXAMPLES (default: every example-* with
# addons.make minus ios/ImGuizmo), JOBS.
set -u
WASM="${WASM:-32}"
GLES="${GLES:-3}"
ADDON_DIR="${ADDON_DIR:?ADDON_DIR required}"
JOBS="${JOBS:-4}"
TPL=scripts/templates/emscripten

stage() {
  local name="$1" src="$ADDON_DIR/$1" dst="examples/_addon_test/$1"
  rm -rf "$dst"; mkdir -p "$dst"
  cp -R "$src/src" "$dst/src"
  [ -f "$src/addons.make" ] && cp "$src/addons.make" "$dst/"
  [ -d "$src/bin" ] && cp -R "$src/bin" "$dst/bin"
  cp "$TPL/Makefile" "$TPL/config.make" "$dst/"
  [ "$GLES" = 2 ] && printf '\nPROJECT_DEFINES += OF_WEBGL_VERSION=1\n' >> "$dst/config.make"
}

echo "##[group]OF core, wasm$WASM/ES$GLES"
(cd libs/openFrameworksCompiled/project && emmake make -j"$JOBS" Debug PROJECT_EMSCRIPTEN_WASM="$WASM") \
  || { echo "::error::OF core failed to build for wasm$WASM"; exit 2; }
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
  echo "##[group]$n (wasm$WASM/ES$GLES)"
  stage "$n"
  if (cd "examples/_addon_test/$n" && emmake make -j"$JOBS" Debug PROJECT_EMSCRIPTEN_WASM="$WASM"); then PASS+=("$n"); else FAILED+=("$n"); fi
  echo "##[endgroup]"
done

{
  echo "### $ADDON_DIR on emscripten wasm$WASM/ES$GLES (Debug)"
  echo "| example | result |"; echo "|---|---|"
  for n in "${PASS[@]:-}"; do [ -n "$n" ] && echo "| $n | ✅ built |"; done
  for n in "${FAILED[@]:-}"; do [ -n "$n" ] && echo "| $n | ❌ failed |"; done
} | tee -a "${GITHUB_STEP_SUMMARY:-/dev/null}"
echo "PASS=${#PASS[@]} FAIL=${#FAILED[@]}"
[ "${#FAILED[@]}" -eq 0 ]
