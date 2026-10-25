# Test results

Last updated: 2026-10-25. openFrameworks branch under test: `linux2026`
(head `029798f03` at time of the GitHub runs; Pi runs at `1d0f764c0`+).
Harness: this repo. GitHub runs execute on native runners
(`ubuntu-24.04` / `ubuntu-24.04-arm`); Pi runs executed locally on an
arm64 Mac under Colima (arm64 native, arm/v7 via QEMU).

Definitions: Smoke = `scripts/ci/linux/test_lib_paths.sh` only.
Full = lib-path tests, `download_libs.sh`, `check_deployed_libs.sh`,
OF core build, `scripts/ci/linux/64/run_tests.sh` (unit tests in `tests/`).

## Summary

| Target | OS | Smoke | Full | Evidence |
|---|---|---|---|---|
| rpios-trixie-arm64 | Raspberry Pi OS Trixie, Debian 13, arm64 | 35/35 | PASS | local logs `rpios-trixie-arm64-*.log` |
| rpios-trixie-armv7 | Raspberry Pi OS Trixie, Debian 13, armv7l (QEMU) | 35/35 | Partial (libs 10/10) | local log `rpios-trixie-armv7.log` |
| mint-amd64 | Linux Mint 22.2 (`linuxmintd/mint22.2-amd64`) | 35/35 | PASS | https://github.com/danoli3/ofLinuxTestScripts/actions/runs/40153868943 |
| pop-amd64 | Pop!_OS 22.04 (Ubuntu 22.04 + apt.pop-os.org) | 35/35 | PASS | https://github.com/danoli3/ofLinuxTestScripts/actions/runs/40152846935 |
| zorin-amd64 | Zorin OS 18 base-equivalent (`ubuntu:24.04`) | 35/35 | PASS | https://github.com/danoli3/ofLinuxTestScripts/actions/runs/40152848878 |
| cachyos-amd64 | CachyOS (`cachyos/cachyos-v3`) | 35/35 | PASS | https://github.com/danoli3/ofLinuxTestScripts/actions/runs/40153865539 |
| omarchy-amd64 | Omarchy userland (`archlinux`) | 35/35 | PASS | https://github.com/danoli3/ofLinuxTestScripts/actions/runs/40153867267 |
| kali-amd64 | Kali Linux rolling (`kalilinux/kali-rolling`) | (in full) | PASS | https://github.com/danoli3/ofLinuxTestScripts/actions/runs/40154435687 |
| kali-arm64 | Kali Linux rolling, arm64 | (in full) | PASS | https://github.com/danoli3/ofLinuxTestScripts/actions/runs/40157323604 |
| jetson-arm64 | NVIDIA L4T r36.2.0 / JetPack 6 (Ubuntu 22.04, arm64) | (in full) | PASS | https://github.com/danoli3/ofLinuxTestScripts/actions/runs/40156047872 |

Not yet run: `rpi-arm64` (Bookworm, platform verified only),
`ubuntu-2404-amd64`, `ubuntu-2204-amd64`, `debian-amd64`, `fedora-amd64`,
`arch-amd64` (superseded by `omarchy-amd64` for Arch coverage).

## Per-target detail

### Raspberry Pi OS Trixie arm64 (`n4jm4/raspberry-pi-os:trixie`, native)

- Lib-path tests: 35/35 (30/30 before the RPi fixtures were added).
- Download + deployed libs: `aarch64` 10/10; generic `arm64` also 10/10.
- Core: builds with `-march=armv8-a -mcpu=cortex-a72`.
- Unit tests: pass after the fixes below, except two environment artifacts:
  - `utils/fileUtils` fails on a virtiofs-mounted checkout (mode-000
    fixtures); passes 91/91 on a native filesystem.
  - `utils/strings` fails 2/43 under a POSIX locale; passes 43/43 with
    `LC_ALL=C.UTF-8` (now set by the workflows/harness).
- Finding fixed on the OF branch (`1d0f764c0`): RPi OS reports `ID=debian`
  and containers have no device-tree, so nothing detected a Pi and the
  generic `linux/arm64` artifact was fetched while the build expected
  `linux/aarch64` (`tessTesselate`/`kiss_fftr` link errors). Downloader and
  makefile now accept `/etc/rpi-issue` and the Raspberry Pi apt repo as
  markers; explicit `-a arm64` on a Pi normalises to `aarch64`.

### Raspberry Pi OS Trixie armv7 (`linux/arm/v7`, QEMU)

- Lib-path tests: 35/35. Download `armv7l`: deployed-libs 10/10
  (`--allow-incomplete`, matching upstream CI).
- OF core compile was not run to completion: emulated compilation is too
  slow for the local session limits. No ARMv6 target is run (unsupported).

### Linux Mint 22.2 / Pop!_OS 22.04 / Zorin OS 18 (amd64)

- All full PASS. Pop initially failed on the repo key URL
  (`apt.pop-os.org/repo/key` 404s; key now fetched from the Ubuntu
  keyserver, fingerprint `204DD8AEC33A7AFF`) and, with Zorin, on the
  `strings` locale issue above. Zorin has no credible published container
  image, so its exact Ubuntu 24.04 base is used and labelled as such.

### CachyOS / Omarchy (Arch family, amd64)

- First full runs failed at `FreeImage.h: No such file or directory`:
  Linux excluded the bundled FreeImage and linked system `-lfreeimage`,
  which Arch dropped to the AUR. Filed as
  openframeworks/apothecary#674. Fixed OF-side (`9704d872b`): Linux now
  uses the apothecary FreeImage (header + `FreeImage.a`). After removing
  the temporary AUR workaround from these images, both full runs PASS.

### Kali Linux rolling (amd64 + arm64)

- Both full PASS. Arm64 image builds initially failed because Kali's
  mirror redirector (`http.kali.org` → `mirror.us.cdn-perfprod.com`) was
  unreachable from GitHub arm runners; the Dockerfiles pin
  `mirrors.ocf.berkeley.edu` over http (the minimal base has no CA
  certificates for https yet). Infrastructure only; no OF change.

### NVIDIA Jetson L4T r36.2.0 (`nvcr.io/nvidia/l4t-base:r36.2.0`, arm64)

- Full PASS using the Ubuntu `arm64` apothecary libs.
- The dedicated `linux_jetson` apothecary asset is not published (the
  downloader received a 29-byte 404 and no `glm`), so `download_libs`
  now maps Jetson to `linux/arm64` (`029798f03`): explicit `-a jetson` /
  `armv8l`, Tegra device-tree, and `/etc/nv_tegra_release` all resolve to
  the Ubuntu arm64 package, and the makefile Jetson lib path points at
  `linux/arm64`. `JETSON_DETECTED` can also be overridden (`6424d1042`)
  because L4T containers expose no device-tree. Tegra GL/EGL drivers come
  from L4T itself, not from OF third-party libs.

## Fixes landed on OF `linux2026` from this testing

| Commit | Change |
|---|---|
| `1d0f764c0` | Detect Raspberry Pi OS userland (downloader + makefile); correct `aarch64` libs |
| `9704d872b`, `3dc5f1f17` | Use apothecary FreeImage on all Linux; drop system `-lfreeimage` |
| `6424d1042` | Allow `JETSON_DETECTED` override for containers |
| `029798f03` | Jetson uses Ubuntu `arm64` libs in downloader + makefile |

Test coverage: `scripts/ci/linux/test_lib_paths.sh` in openFrameworks
(40/40) asserts the lib-path fallbacks, RPi detection fixtures, FreeImage
source, and the Jetson mappings.

## Reproducing

```bash
export OF_ROOT=/path/to/openFrameworks   # default ../openFrameworks
export OF_BRANCH=linux2026
./scripts/run.sh rpios-trixie-arm64        # local Docker
./scripts/run.sh kali-arm64
# or GitHub: Actions tab -> pick the distro workflow -> Run workflow
# (inputs: of_branch, level=smoke|full)
```

Logs from GitHub runs are uploaded as `<target>-results` artifacts.
