# warp-lite — reglas para agentes

Este repositorio es un fork de Warp OSS. El producto es **warp-lite**: un terminal ligero, rápido y sin las superficies de AI/cloud de Warp.

Estas reglas mandan sobre las de upstream cuando entran en conflicto. Si algo no está claro, pregunta antes de tocar la UI.

## Regla número uno: la UI está congelada

La UI debe quedarse **como está ahora**. La referencia visual es:

- `warp-lite/docs/target-ui.png` — UI objetivo.
- `warp-lite/notes/bench/warp-real-final2.png` — Warp real con el perfil aplicado.
- `warp-lite/notes/bench/warp-lite-first-run.png` — warp-lite con perfil limpio.
- `warp-lite/notes/bench/warp-lite-v0.1.0.png` — primer comando en el perfil principal.

**No cambies, sin permiso explícito del usuario:**

- layout, spacing, tamaños, colores, tipografía, iconos, animaciones;
- tab bar, bloques, input editor, chips, footer, menús, command palette;
- textos visibles, placeholders, tooltips, banners o modales;
- comportamiento de componentes visibles.

**La única excepción:** el usuario lo pide explícitamente, o una persona con la que colabora se lo pide al usuario y el usuario lo aprueba. En ese caso, el cambio se hace pequeño, deliberado, con captura antes/después y una entrada en `warp-lite/notes/phase-3.md`. Si no hay una petición explícita, **no se toca la UI**.

Esto no impide:

- quitar superficies que **no forman parte de la UI objetivo** (AI, Drive, onboarding, tips, banners, notebooks, voz, MCP, editor/diff, computer use, auto-update). Es el propósito del proyecto, pero se anuncia, se hace con captura antes/después y no se altera ningún elemento de la referencia. Ante la duda, pregunta.
- cambiar código interno, dependencias, features, build, settings o rendimiento;
- ocultar una superficie que ya está desactivada por settings, si el usuario lo aprueba.

**No hagas mejoras visuales "de paso".** Ni márgenes, ni colores, ni iconos, ni textos. Si algo parece feo, se apunta; no se cambia.

## Objetivo

Hacer warp-lite **lo más ligero, fluido y rápido posible** sin cambiar la UI:

- menos RAM (proceso y árbol);
- arranque y shell más rápidos;
- menos latencia de tecleo y scroll;
- binario más pequeño;
- cero red en el arranque;
- cero superficies de AI/cloud que no queremos.

Cada optimización se mide antes y después. No se acepta "debería ser más rápido" sin números.

## Qué se conserva

Terminal, bloques, tabs, input editor, completions, syntax highlighting, temas, keybindings, splits, scrollback y ejecución de agentes CLI externos (Claude Code, OpenCode, Codex) como comandos normales.

## Qué se quita

Agente propio de Warp, Oz, agent mode, Warp Drive, cloud, login, colaboración, onboarding, notebooks, voz, MCP propio, editor de código/diff, file tree, LSP, computer use, auto-update, factories y telemetría.

## Cómo trabajar

1. **Medir primero.** `warp-lite/notes/phase-3.md` tiene el marcador y el backlog. Cualquier cambio de rendimiento lleva medición antes/después (5 runs en caliente + 1 en frío, misma máquina, misma config).
2. **Un cambio por commit.** Un módulo/crate/superficie por commit, con build, captura y números.
3. **Código → dependencias → crates.** Primero se quita el código, luego la dependencia en `Cargo.toml`, luego el crate del workspace. No al revés.
4. **No usar `--no-default-features` para la UI.** Cambia el input a la variante universal y saca el button bar. La base correcta es la build completa con `gui,skip_login`.
5. **No tocar el target dir.** `app/build.rs` copia ConPTY/DXC a `<repo>/target/<profile>` e ignora `CARGO_TARGET_DIR`.
6. **No reimplementar la UI.** Se usa la app real de Warp y se poda por dentro.
7. **Upstream congelado por fases.** No perseguir `master` a diario. Actualizar por lotes, con merge, y medir después.
8. **Documentar.** Cada fase y cada corte en `warp-lite/notes/`.

## Estado y referencias

- Repo: <https://github.com/nilparra-dev/warp-lite>
- Base: `a4ad25c41` (upstream) + commits locales.
- Binario: `warp-lite` (`app/src/bin/lite.rs`), AppId `dev.warp.WarpLite`.
- Config: `%LOCALAPPDATA%\warp\WarpLite\config\settings.toml`.
- Build: `powershell -ExecutionPolicy Bypass -File .\warp-lite\build.ps1`.
- Run: `powershell -ExecutionPolicy Bypass -File .\warp-lite\run.ps1`.
- Medir: `powershell -ExecutionPolicy Bypass -File .\warp-lite\scripts\measure-startup.ps1 -Exe .\target\release\warp-lite.exe -Runs 5`.
- Notas: `warp-lite/notes/phase-0.md` … `phase-3.md`.

## Convenciones de código

Además de las reglas de upstream en `AGENTS.md` (estilo, tests, formato), en este fork:

- comentarios mínimos y solo para explicar el "por qué";
- no dejar código muerto "por si acaso"; se borra y queda en git;
- no añadir dependencias nuevas sin necesidad;
- no cambiar la UI para "limpiar" código.
