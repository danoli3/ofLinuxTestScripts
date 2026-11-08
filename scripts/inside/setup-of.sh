#!/bin/bash
# Run from the OF checkout, inside the disposable Linux test container.
set -eu

export DEBIAN_FRONTEND=noninteractive OF_ANIM=0 NO_COLOR=1 OF_SETUP_CODECS=0

# Some OF installers do not pass -y to every apt call, or --noconfirm to
# pacman. Scope noninteractive package-manager settings to this setup process.
SETUP_TMP=$(mktemp -d)
trap 'rm -rf "$SETUP_TMP"' EXIT
printf 'APT::Get::Assume-Yes "true";\n' > "$SETUP_TMP/apt.conf"
export APT_CONFIG="$SETUP_TMP/apt.conf"
if command -v pacman >/dev/null 2>&1; then
  export OF_TEST_PACMAN
  OF_TEST_PACMAN=$(command -v pacman)
  mkdir -p "$SETUP_TMP/bin"
  cat > "$SETUP_TMP/bin/pacman" <<'PACMAN'
#!/bin/bash
exec "$OF_TEST_PACMAN" --noconfirm "$@"
PACMAN
  chmod +x "$SETUP_TMP/bin/pacman"
  export PATH="$SETUP_TMP/bin:$PATH"
fi

if [ -f of ] && [ -f scripts/of.sh ]; then
  echo "OF menu setup: bash ./of setup linux (LIB_ARCH=${OF_ARCH:-64})"
  LIB_ARCH="${OF_ARCH:-64}" DOWNLOAD_LIBS_ARGS="-g 10" \
    bash ./of setup linux </dev/null
else
  echo "OF menu unavailable; using the checked-out distro dependency installer"
  # Match OF's distro families, including derivatives used by this harness.
  . /etc/os-release
  DISTRO=""
  for candidate in "${ID:-}" ${ID_LIKE:-}; do
    case "$candidate" in
      ubuntu|pop|pop-os|linuxmint|elementary|zorin|neon) DISTRO=ubuntu ;;
      debian|raspbian|kali|parrot) DISTRO=debian ;;
      fedora|rhel|centos|rocky|almalinux|ol|scientific) DISTRO=fedora ;;
      arch|manjaro|endeavouros|garuda|artix|cachyos) DISTRO=archlinux ;;
    esac
    [ -z "$DISTRO" ] || break
  done
  if [ -z "$DISTRO" ] || [ ! -f "scripts/linux/$DISTRO/install_dependencies.sh" ]; then
    echo "ERROR: no OF dependency installer for ${ID:-unknown}" >&2
    exit 1
  fi
  bash "scripts/linux/$DISTRO/install_dependencies.sh" -y </dev/null
  bash scripts/linux/download_libs.sh -t latest -a "${OF_ARCH:-64}" -g 10
fi
