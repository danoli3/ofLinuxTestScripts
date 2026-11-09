#!/bin/bash
# Rebuild the OF core once per extra GL API (compile-only, Debug) so Raspberry Pi
# 4/5 style targets are checked with desktop GL (the default build already run
# by run-inside.sh) and with OpenGL ES 2 and ES 3.
# Env: GL_VARIANTS  space separated subset of: gles2 gles3   (e.g. "gles2 gles3")
# CI containers have no GPU, so this proves the code compiles and links against
# the ES headers; it does not exercise a Pi V3D driver.
# Runs from /src (an openFrameworks checkout).
set -u
cd /src/libs/openFrameworksCompiled/project || exit 1
FAIL=0

# Current PLATFORM_DEFINES as the OF makefiles compute them, so the variant only
# adds the ES defines instead of replacing OF_USING_GTK, OF_USING_MPG123, etc.
BASE_DEFINES="$(make -pn Debug 2>/dev/null | sed -n 's/^PLATFORM_DEFINES *:\{0,1\}= *//p' | head -n 1)"
echo "Base PLATFORM_DEFINES: ${BASE_DEFINES:-<none>}"

for v in $GL_VARIANTS; do
  case "$v" in
    gles2) EXTRA="TARGET_OPENGLES TARGET_FORCE_GLES_2" ;;
    gles3) EXTRA="TARGET_OPENGLES TARGET_OPENGLES_3" ;;
    *) echo "ERROR: unknown GL variant '$v' (use gles2 or gles3)"; FAIL=1; continue ;;
  esac
  echo; echo "=== GL VARIANT $v: core Debug build with -D$(echo $EXTRA | sed 's/ / -D/g') ==="
  # Old objects were built for another API; the core makefile keys on flags,
  # but a clean object tree makes the result unambiguous.
  find /src/libs/openFrameworksCompiled/lib -type d -name obj -prune -exec rm -rf {} + 2>/dev/null
  if make -j4 Debug "PLATFORM_DEFINES=$BASE_DEFINES $EXTRA"; then
    echo "GL_VARIANT_RESULT:$v:PASS"
  else
    echo "GL_VARIANT_RESULT:$v:FAIL"
    FAIL=1
  fi
done

# Leave the default (desktop GL) objects for anything that runs afterwards.
find /src/libs/openFrameworksCompiled/lib -type d -name obj -prune -exec rm -rf {} + 2>/dev/null
exit $FAIL
