# warp-lite base

This directory holds the warp-lite docs, settings and scripts. The product is the real Warp UI in `app/`; nothing in the UI is reimplemented.

- Upstream: `warpdotdev/warp` at `a4ad25c41`.
- Local patch: hide the agent input footer when AI is disabled (`63abf362e`).
- Settings profile: `settings.toml`.
- Target UI: `docs/target-ui.png`.
- Phase reports and benchmarks: `notes/`.

## Project rules

The UI is frozen at `docs/target-ui.png`. Do not change layout, colors, typography, spacing, copy, banners, menus or component behavior without explicit approval from the user (or a collaborator's request relayed and approved by the user). All optimizations must be measured before and after. See [AGENTS.md](AGENTS.md) and [notes/phase-3.md](notes/phase-3.md).

## Build

Requirements: Windows, Rust 1.92 (installed from `rust-toolchain.toml`), MSVC Build Tools, CMake, protoc, LLVM/libclang and Git LFS.

```powershell
# from the repository root
powershell -ExecutionPolicy Bypass -File .\warp-lite\build.ps1 -CheckOnly
powershell -ExecutionPolicy Bypass -File .\warp-lite\build.ps1
```

`build.ps1` locates CMake, protoc and LLVM, sets `LIBCLANG_PATH`, and builds `warp-lite` in release mode with `gui,skip_login,lite_assets`. Use `-Bin warp-oss` to build the upstream OSS binary for comparison; it automatically drops `lite_assets`.

Manual equivalent:

```powershell
cargo build --release --bin warp-lite --features "gui,skip_login,lite_assets"
```

Do not use `--no-default-features`: it changes the input to the universal variant and removes the agent button bar, so the UI stops matching the target.

## Run

```powershell
powershell -ExecutionPolicy Bypass -File .\warp-lite\run.ps1
```

`run.ps1` installs `settings.toml` if the config file is missing and starts `target\release\warp-lite.exe`.

`warp-lite` uses the OSS channel with the `dev.warp.WarpLite` application ID, so it gets its own config and state directories. Settings are installed to:

```text
%LOCALAPPDATA%\warp\WarpLite\config\settings.toml
```

The profile disables AI, the agent footer, model selectors, Warp Drive, telemetry, crash reporting and session restore.

## What we keep

Terminal, blocks, tabs, input editor, completions, syntax highlighting, themes, keybindings, splits and scrollback. External CLI agents (Claude Code, OpenCode, Codex) run as normal commands.

## What we remove

Warp's agent/Oz/agent mode, Warp Drive/cloud/login/collaboration, onboarding, notebooks, voice, MCP, code editor/diff, file tree, LSP, computer use, auto-update and factories.

The goal is incremental and measured: remove one surface or crate, build, check that the UI still matches, and record startup/RAM.

## Reduced assets and languages

`lite_assets` excludes the onboarding/AI/Oz PNGs from `app/assets/async/png`; theme JPGs and bundled assets remain. Syntax highlighting keeps the common languages (rust, go, yaml, python, javascript/jsx, typescript, shell, html, css, c, json, toml, powershell, dockerfile, markdown); the other grammars were removed to cut ~43 MB from the binary.

## Layout

```text
warp-lite/
  build.ps1              build helper for Windows
  run.ps1                install settings if needed and launch
  install-settings.ps1   install settings.toml into the channel config dir
  settings.toml          minimal terminal profile
  docs/                  target UI capture
  notes/                 phase reports, benchmarks and screenshots
  scripts/               build and benchmark harness
```

## Known traps

- `app/build.rs` copies `conpty.dll`, `OpenConsole.exe` and the DXC DLLs into `<repo>/target/<profile>` and ignores `CARGO_TARGET_DIR`. Do not change the target directory.
- A full build takes roughly 20–40 minutes.
- `warp-lite` and `warp-oss` are development binaries: they do not auto-update and use separate config directories (`WarpLite` and `WarpOss`).
- The first launch can take a few seconds while the shell is created.
