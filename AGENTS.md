# Commit / PR attribution

- Do not add Codex attribution to commits, PR descriptions, issues, or comments.

# openFrameworks Linux setup

- Full container tests must run the checked-out openFrameworks version's standard
  dependency setup before compiling. Prefer the OF menu's command-line entrypoint,
  `bash ./of setup linux`, which runs `install_dependencies.sh` for the distro.
- Only fall back to the checked-out distro's `install_dependencies.sh` when the OF
  menu entrypoint is absent. A failing menu/setup command must fail the test;
  do not hide it by falling back or adding replacement package lists.
- Dockerfiles provide container/test tooling. Hand-maintained package lists are
  not a substitute for running OF setup. Use distro packages for dependencies
  such as Cairo rather than building them separately.
- FreeImage must be built and packaged by Apothecary and downloaded with the OF
  libraries. Do not install FreeImage through apt, dnf, pacman, or AUR, or add
  system FreeImage as a workaround for a missing/broken Apothecary package.
  Remove stale FreeImage package requests in OF's dependency installers upstream;
  keep this harness running the actual OF setup so those regressions stay visible.
- Setup must run without interactive prompts, preserve the requested library
  architecture, and report failures before attempting core/unit-test builds.
- Keep smoke-only path checks separate from full dependency/build/test coverage.
