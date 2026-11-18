#!/bin/bash
# Build every openFrameworks example (examples/<category>/<example>) natively, Debug, continuing past failures.
# cwd = OF checkout (after `of setup linux`). Env: CONFIG (Debug|Release), JOBS, CATEGORIES (default: all but android/ios/tvOS).
set -u
CONFIG="${CONFIG:-Debug}"
JOBS="${JOBS:-4}"
LOGDIR="${LOGDIR:-$PWD/example-logs}"
mkdir -p "$LOGDIR"

echo "##[group]OF core ($CONFIG)"
(cd libs/openFrameworksCompiled/project && make -j"$JOBS" "$CONFIG") || { echo "::error::OF core failed to build"; exit 2; }
echo "##[endgroup]"

PASS=(); FAILED=(); SKIPPED=()
for cat in ${CATEGORIES:-$(cd examples && ls -d */ | tr -d / )}; do
  case "$cat" in android|ios|tvOS|templates) continue ;; esac
  for d in examples/"$cat"/*/; do
    d="${d%/}"; n="$cat/$(basename "$d")"
    case "$(basename "$d")" in *osx*) continue ;; esac
    if [ ! -f "$d/Makefile" ]; then SKIPPED+=("$n"); continue; fi
    echo "##[group]$n"
    if make -C "$d" -j"$JOBS" "$CONFIG" > "$LOGDIR/$(echo "$n" | tr / _).log" 2>&1; then
      PASS+=("$n"); echo "ok"
    else
      FAILED+=("$n"); echo "FAILED"; grep -E "error:|Error [0-9]|undefined reference" "$LOGDIR/$(echo "$n" | tr / _).log" | head -8
    fi
    echo "##[endgroup]"
  done
done

{
  echo "### OF examples ($(uname -m), $CONFIG): ${#PASS[@]} built, ${#FAILED[@]} failed, ${#SKIPPED[@]} skipped (no Makefile)"
  if [ "${#FAILED[@]}" -gt 0 ]; then echo "| failed example |"; echo "|---|"; for n in "${FAILED[@]}"; do echo "| $n |"; done; fi
  if [ "${#SKIPPED[@]}" -gt 0 ]; then echo "<details><summary>skipped</summary>"; echo; for n in "${SKIPPED[@]}"; do echo "- $n"; done; echo "</details>"; fi
} | tee -a "${GITHUB_STEP_SUMMARY:-/dev/null}"
echo "PASS=${#PASS[@]} FAIL=${#FAILED[@]} SKIP=${#SKIPPED[@]}"
[ "${#FAILED[@]}" -eq 0 ]
