# Fase 2 — UI real de Warp como base

Fecha: 2026-11-18.

## Decisión

La UI del producto será la **UI real de Warp** (`warp-oss` / crate `app`), no el clon de `warp_lite`. Para que sea literalmente la misma no tiene sentido reimplementar tab bar, bloques, input editor, chips, syntax highlighting y tipografía: ya están en Warp.

`warp_lite` queda como laboratorio de rendimiento (PTY + parser + benchmarks), no como frontend final.

## Perfil “solo terminal”

Settings aplicados en `%LOCALAPPDATA%\warp\WarpOss\config\settings.toml`:

```toml
[general]
restore_session = false
show_warning_before_quitting = false

[agents.warp_agent]
is_any_ai_enabled = false

[agents.warp_agent.other]
show_conversation_history = false
show_agent_notifications = false
should_render_use_agent_toolbar_for_user_commands = false

[agents.warp_agent.input]
show_agent_tips = false
show_model_selectors_in_prompt = false

[agents.third_party]
should_render_cli_agent_toolbar = false

[agents.knowledge]
rules_enabled = false
warp_drive_context_enabled = false

[warp_drive]
enabled = false

[privacy]
telemetry_enabled = false
crash_reporting_enabled = false
```

## Capturas

- `bench/warp-real-final2.png` — **base definitiva**: Warp real, un tab, bloque, input limpio y sin footer de agente. La `w` extra del comando es un artefacto del test, no del terminal.
- `bench/warp-real-minimal.png` — Warp real con AI/Drive/telemetría off; input limpio.
- `bench/warp-real-clean.png` — Warp real sin model selector.
- `bench/warp-real-nofooter2.png` — build `--no-default-features`: UI real pero con button bar de agente; **descartada** como base.

## Estado de la base

- Build completa `warp-oss` (`gui,skip_login`) reconstruida en 20m 31s.
- Perfil de settings aplicado: AI off, Drive off, telemetría off, sin model selector, sin footer de agente.
- La UI es la de Warp sin reimplementar nada: tab bar, bloques, input editor, chips, syntax highlighting y tipografía.
- RAM observada: ~327–335 MB. La poda de crates sigue pendiente.
- Siguiente: canal/binario `warp-lite` propio y inicio de la poda de superficies/crates.

## Repositorio

- Rama `main` = `a4ad25c41` (upstream) + `63abf362e` (footer de agente off) + `f6f202c33` (docs, settings y scripts) + `4d15de8c5` (check de prerequisites). Los hashes locales se reescribieron al publicar el repositorio.
- Tag `lab/prototype-v1` = prototipo propio (`warp_lite`, PTY + parser + benchmarks). No es la UI del producto.
- Documentación y scripts dentro del repo: `warp-lite/`.
  - `README.md` — instrucciones y reglas.
  - `settings.toml` — perfil “solo terminal”.
  - `install-settings.ps1` — instala el perfil en `%LOCALAPPDATA%\warp\WarpOss\config\settings.toml`.
  - `build.ps1` — build completo `warp-oss` con detección de CMake/protoc/LLVM.
  - `run.ps1` — instala settings si faltan y arranca el binario.
- Captura objetivo dentro del repo: `warp-lite/docs/target-ui.png`.

## Lo que hemos aprendido

- `--no-default-features` compila y conserva la UI, pero cambia el input a la variante “universal” y saca el button bar de agente (A, imagen, @, +). No sirve como base visual.
- La build completa con el perfil de settings sí da el input limpio que quieres.
- La app sigue dependiendo de crates de AI/cloud de forma incondicional (`ai`, `cloud_object_*`, `warp_server_client`, `mcp`, `warp_multi_agent_client`, ...). La poda real es de código/deps, no solo de feature flags.

## Plan

1. Restaurar la build completa `warp-oss` con `gui,skip_login` (en curso).
2. Crear un binario/canal `warp-lite` con este perfil de settings por defecto y branding propio.
3. Ocultar/eliminar superficies que no sirven: footer/button bar de agente, menús AI, Drive, onboarding, settings de AI, notebooks, voz, MCP, editor de código/diff, computer use, auto-update.
4. Cortar crates y dependencias incondicionales, midiendo arranque/RAM después de cada corte.
5. Mantener intacta la UI que sí queremos: terminal, bloques, tabs, input editor, completions, temas, keybindings, splits, scrollback.

## Estado

- Build completa de restauración: lanzada en segundo plano.
- El parche del `AgentInputFooter` (ocultar footer si AI off) está aplicado, pero el button bar que se ve en la build sin features es otro componente (`UniversalDeveloperInputButtonBar`). Se quitará en la fase de poda.

