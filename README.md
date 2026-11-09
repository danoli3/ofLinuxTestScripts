# ofLinuxTestScripts

[![All Linux targets](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/all-linux.yml/badge.svg?branch=main)](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/all-linux.yml)
[![CachyOS](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/cachyos.yml/badge.svg?branch=main)](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/cachyos.yml)
[![Jetson](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/jetson.yml/badge.svg?branch=main)](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/jetson.yml)
[![Kali arm64](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/kali-arm64.yml/badge.svg?branch=main)](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/kali-arm64.yml)
[![Kali](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/kali.yml/badge.svg?branch=main)](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/kali.yml)
[![Linux Mint](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/mint.yml/badge.svg?branch=main)](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/mint.yml)
[![Omarchy](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/omarchy.yml/badge.svg?branch=main)](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/omarchy.yml)
[![Pop!_OS](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/pop.yml/badge.svg?branch=main)](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/pop.yml)
[![Zorin OS](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/zorin.yml/badge.svg?branch=main)](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/zorin.yml)
[![Raspberry Pi addon](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/rpi-addon.yml/badge.svg?branch=main)](https://github.com/danoli3/ofLinuxTestScripts/actions/workflows/rpi-addon.yml)

Docker-based Linux test harness for openFrameworks.
Runs the OF Linux CI checks inside containers so a macOS (or any Docker) host can
simulate Raspberry Pi and other Linux distributions without a physical board.

Default branch: `master` in your local openFrameworks checkout.

## Quick start

```bash
# 1. Make sure Docker is running (on macOS: colima start --arch aarch64)
# 2. Point at your OF checkout (defaults to ../openFrameworks)
export OF_ROOT=/Users/mini/Documents/SRC/openFrameworks
export OF_BRANCH=master

# Raspberry Pi 64-bit simulation (Debian bookworm, linux/arm64 - native on Apple Silicon)
./scripts/run.sh rpi-arm64

# Full 32-bit Pi setup, core build and unit tests under QEMU
./scripts/run.sh rpi-armv7l

# Other distributions
./scripts/run.sh debian-amd64
./scripts/run.sh ubuntu-2404-amd64
./scripts/run.sh fedora-amd64
./scripts/run.sh arch-amd64

# Everything
./scripts/run.sh all
```

Each run writes a timestamped log + summary under `results/`.

## Matrix

| Target | Image | Platform | Simulates |
|---|---|---|---|
| `rpios-trixie-arm64` | `n4jm4/raspberry-pi-os:trixie` | `linux/arm64` | **Latest Raspberry Pi OS (Debian 13)** — Pi 3/4/5, Zero 2 (64-bit) |
| `rpios-trixie-armv7` | `n4jm4/raspberry-pi-os:trixie` | `linux/arm/v7` (QEMU) | **Latest Raspberry Pi OS (Debian 13)** — Pi 2/3, Zero 2 (32-bit) |
| `rpi-arm64` | `debian:bookworm` | `linux/arm64` | Raspberry Pi 64-bit (CI `aarch64` leg) |
| `rpi-armv7l` | `debian:bookworm` | `linux/arm/v7` (QEMU) | Raspberry Pi ARMv7, full setup + core build + unit tests |
| `rpi-armv6l` | `debian:bookworm` | `linux/arm/v6` (QEMU) | Raspberry Pi 32-bit (CI `armv6l` leg, slow) |
| `ubuntu-2404-amd64` | `ubuntu:24.04` | `linux/amd64` (QEMU on arm Mac) | CI `build-linux` ubuntu-24.04 |
| `ubuntu-2204-amd64` | `ubuntu:22.04` | `linux/amd64` (QEMU on arm Mac) | CI `build-linux-64-22-04` |
| `debian-amd64` | `debian:bookworm` | `linux/amd64` (QEMU on arm Mac) | Debian (non-Ubuntu) |
| `fedora-amd64` | `fedora:latest` | `linux/amd64` (QEMU on arm Mac) | Fedora (non-Ubuntu) |
| `arch-amd64` | `archlinux:latest` | `linux/amd64` (QEMU on arm Mac) | Arch Linux (non-Ubuntu) |
| `mint-amd64` | `linuxmintd/mint22.2-amd64` | `linux/amd64` (QEMU) | Linux Mint 22.2 (Ubuntu 24.04 base) |
| `cachyos-amd64` | `cachyos/cachyos-v3` | `linux/amd64` (QEMU) | CachyOS (Arch base, x86-64-v3) |
| `pop-amd64` | `ubuntu:22.04` + Pop apt repo | `linux/amd64` (QEMU) | Pop!_OS 22.04 (no official container image published) |
| `zorin-amd64` | `ubuntu:24.04` | `linux/amd64` (QEMU) | Zorin OS 18 base-equivalent (no credible Zorin image published) |
| `omarchy-amd64` | `archlinux:latest` | `linux/amd64` (QEMU) | Omarchy userland = Arch (bare-metal installer, no container image) |
| `kali-amd64` | `kalilinux/kali-rolling` | `linux/amd64` (QEMU locally / native on GH) | Kali Linux rolling (Debian testing base) |
| `kali-arm64` | `kalilinux/kali-rolling` | `linux/arm64` (native) | Kali Linux rolling, arm64 |
| `jetson-arm64` | `nvcr.io/nvidia/l4t-base:r36.2.0` | `linux/arm64` (native, `ubuntu-24.04-arm`) | NVIDIA Jetson L4T (JetPack 6), `JETSON_DETECTED=yes` |

On an Apple Silicon Mac, `linux/arm64` runs natively (fast). `linux/amd64`
targets run under QEMU emulation and are slower - that is expected.

## What each run does

Inside the container, `scripts/inside/run-inside.sh`:

1. `bash scripts/ci/linux/test_lib_paths.sh` - new `lib/linux/<arch>` vs legacy path fallbacks
2. OF menu setup: `bash ./of setup linux`, with `LIB_ARCH=<arch>` and
   `DOWNLOAD_LIBS_ARGS="-g 10"`. This runs OF's distro dependency installer and
   downloads libraries / Project Generator. For older checkouts without the menu,
   runs that checkout's distro `install_dependencies.sh -y`, then downloads libs.
3. `bash scripts/ci/check_deployed_libs.sh --platform linux --arch <arch>`
4. Builds the OF core, then `scripts/ci/linux/64/run_tests.sh` (unit tests under `tests/`)

Set `SKIP_BUILD=1` for the fast lib-path-only smoke, e.g.
`SKIP_BUILD=1 ./scripts/run.sh rpi-arm64`.

Full runs install dependencies noninteractively and stop immediately if OF setup
fails. Dockerfile package lists do not replace OF setup. Installer failures are
reported as setup failures, before compilation. The all-targets workflow includes
full `rpi-armv7l` coverage; `rpios-trixie-armv7` remains a smoke-only QEMU job.

FreeImage comes from the Apothecary library package, not a distro package or AUR.
OF dependency installers that still request system FreeImage need an upstream fix;
the harness reports their failure rather than bypassing the installer.

## Layout

- `docker/Dockerfile.*` - one image per target
- `scripts/run.sh` - host orchestrator (checkout branch, build image, run, collect results)
- `scripts/inside/run-inside.sh` - in-container test steps
- `results/` - run logs (gitignored)

## Requirements

- Docker with buildx + QEMU/binfmt for cross-platform runs
  (Colima on macOS provides this: `colima start --arch aarch64`)
- A local openFrameworks checkout

## Current results (2026-10-25)

Full = download libs + deployed-libs check + OF core build + unit tests
against openFrameworks `linux2026`. Smoke = lib-path tests only.

| Target | OS (2026) | Platform | Result |
|---|---|---|---|
| `rpios-trixie-arm64` | Raspberry Pi OS Trixie (Debian 13) | `linux/arm64` native | ✅ Full PASS (local) |
| `rpios-trixie-armv7` | Raspberry Pi OS Trixie (Debian 13) | `linux/arm/v7` QEMU | ◐ Libs 10/10, paths 35/35; core compile not run to completion under QEMU |
| `mint-amd64` | Linux Mint 22.2 | `linux/amd64` | ✅ Full PASS |
| `pop-amd64` | Pop!_OS 22.04 (Ubuntu base + Pop repo) | `linux/amd64` | ✅ Full PASS |
| `zorin-amd64` | Zorin OS 18 (Ubuntu 24.04 base-equiv.) | `linux/amd64` | ✅ Full PASS |
| `cachyos-amd64` | CachyOS (x86-64-v3) | `linux/amd64` | ✅ Full PASS |
| `omarchy-amd64` | Omarchy (Arch userland) | `linux/amd64` | ✅ Full PASS |
| `kali-amd64` | Kali Linux rolling | `linux/amd64` | ✅ Full PASS |
| `kali-arm64` | Kali Linux rolling | `linux/arm64` native | ✅ Full PASS |
| `jetson-arm64` | NVIDIA Jetson L4T r36.2.0 (Ubuntu 22.04) | `linux/arm64` native | ✅ Full PASS (Ubuntu arm64 libs) |
| `rpi-arm64` | Debian Bookworm (CI RPi leg equiv.) | `linux/arm64` | △ Platform verified only |
| `ubuntu-2404-amd64` | Ubuntu 24.04 | `linux/amd64` | — Not run yet |
| `ubuntu-2204-amd64` | Ubuntu 22.04 | `linux/amd64` | — Not run yet |
| `debian-amd64` | Debian Bookworm | `linux/amd64` | — Not run yet |
| `fedora-amd64` | Fedora latest | `linux/amd64` | — Not run yet |
| `arch-amd64` | Arch Linux | `linux/amd64` | — Not run yet (see `omarchy-amd64`) |

Details, run links and per-step breakdowns: [results/results.md](results/results.md).
