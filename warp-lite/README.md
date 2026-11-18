# warp-lite base

Esta rama es la **base exacta de Warp** sobre la que vamos a construir warp-lite.

- Upstream: `warpdotdev/warp` en `a4ad25c41`.
- Parche local: ocultar el footer de agente cuando AI está desactivado (`7b93a896b`).
- UI objetivo: [docs/target-ui.png](docs/target-ui.png).
- La UI **no se reimplementa**: se usa la app real de Warp (`app/`) y se le quitan funcionalidades por settings, flags y poda de código/crates.

## Build

Requisitos: Windows, Rust 1.92 (lo instala rustup desde `rust-toolchain.toml`), MSVC Build Tools, CMake, protoc, LLVM/libclang, Git LFS.

```powershell
cd D:\dev\warp-lite\warp
powershell -ExecutionPolicy Bypass -File .\warp-lite\build.ps1 -CheckOnly   # valida CMake/protoc/LLVM
powershell -ExecutionPolicy Bypass -File .\warp-lite\build.ps1
```

Build completo, **sin** `--no-default-features`:

```powershell
cargo build --release --bin warp-oss --features "gui,skip_login"
```

No uses `--no-default-features` para la UI: cambia el input a la variante universal y saca el button bar de agente (A, imagen, @, +). La build completa con el perfil de settings es la que da la UI objetivo.

## Ejecutar

```powershell
powershell -ExecutionPolicy Bypass -File .\warp-lite\install-settings.ps1
powershell -ExecutionPolicy Bypass -File .\warp-lite\run.ps1
```

O directamente:

```powershell
.\target\release\warp-oss.exe
```

`skip_login` crea un usuario de test; no hay login real. El perfil de settings apaga AI, Warp Drive, cloud y telemetría.

## Settings

`settings.toml` se instala en:

```text
%LOCALAPPDATA%\warp\WarpOss\config\settings.toml
```

Incluye:

- AI off (`agents.warp_agent.is_any_ai_enabled = false`).
- Model selector off.
- Agent footer off.
- Warp Drive off.
- Telemetría/crash reporting off.
- Sin restaurar sesión.

## Qué queremos conservar

- Terminal, bloques, tabs, input editor.
- Completions, syntax highlighting, temas, keybindings, splits.
- La posibilidad de ejecutar agentes CLI externos (Claude Code, OpenCode, Codex) como comandos normales dentro del terminal.

## Qué vamos a quitar

- Agente propio de Warp, Oz, agent mode, MCP propio.
- Warp Drive, cloud, login, colaboración.
- Onboarding, notebooks, voz.
- Editor de código/diff, file tree, LSP, computer use.
- Auto-update, telemetry, factories.

La poda debe ser **incremental y medida**: quitar una superficie/crate, compilar, arrancar, comprobar que la UI sigue igual y medir RAM/arranque.

## Laboratorio

El prototipo de terminal propio (`warp_lite`, PTY + parser + benchmarks) **no está en esta rama**. Está guardado en:

```text
tag lab/prototype-v1
```

Es solo un laboratorio de rendimiento. No es la UI del producto.

## Trampas conocidas

- `app/build.rs` copia `conpty.dll`/`OpenConsole.exe`/DXC a `<workspace>/target/<profile>` e ignora `CARGO_TARGET_DIR`. No cambies el target dir.
- La build completa tarda ~20-40 min.
- `warp-oss` es un binario de desarrollo: no auto-actualiza y usa un directorio de config separado (`WarpOss`).
- El primer arranque puede tardar en crear la shell; espera unos segundos antes de teclear.
- Si ves dos tabs restaurados, revisa `general.restore_session` y el estado persistido.
