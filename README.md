# ofLinuxTestScripts

Docker-based Linux test harness for openFrameworks.
Runs the OF Linux CI checks inside containers so a macOS (or any Docker) host can
simulate Raspberry Pi and other Linux distributions without a physical board.

Default target: the `linux2026` branch of your local openFrameworks checkout.

## Quick start

```bash
# 1. Make sure Docker is running (on macOS: colima start --arch aarch64)
# 2. Point at your OF checkout (defaults to ../openFrameworks)
export OF_ROOT=/Users/mini/Documents/SRC/openFrameworks
export OF_BRANCH=linux2026

# Raspberry Pi 64-bit simulation (Debian bookworm, linux/arm64 - native on Apple Silicon)
./scripts/run.sh rpi-arm64

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
2. `./scripts/linux/download_libs.sh -t latest -a <arch> -g 10`
3. `bash scripts/ci/check_deployed_libs.sh --platform linux --arch <arch>`
4. Builds the OF core, then `scripts/ci/linux/64/run_tests.sh` (unit tests under `tests/`)

Set `SKIP_BUILD=1` for the fast lib-path-only smoke, e.g.
`SKIP_BUILD=1 ./scripts/run.sh rpi-arm64`.

## Layout

- `docker/Dockerfile.*` - one image per target
- `scripts/run.sh` - host orchestrator (checkout branch, build image, run, collect results)
- `scripts/inside/run-inside.sh` - in-container test steps
- `results/` - run logs (gitignored)

## Requirements

- Docker with buildx + QEMU/binfmt for cross-platform runs
  (Colima on macOS provides this: `colima start --arch aarch64`)
- A local openFrameworks checkout
