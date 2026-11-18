# Fase 3 — ligereza, fluidez y poda

Fecha: 2026-11-18.

## Regla principal: la UI está congelada

La UI de warp-lite se queda **como está ahora**. La referencia es `docs/target-ui.png` y `notes/bench/warp-lite-first-run.png`. No se cambia layout, colores, tipografía, spacing, textos, banners, menús ni comportamiento de componentes sin permiso explícito del usuario. Si una persona con la que colabora pide un cambio, se lo pide primero al usuario y el usuario lo aprueba.

Las reglas completas están en [`../AGENTS.md`](../AGENTS.md). Esto no impide quitar superficies que no forman parte de la UI objetivo (AI, Drive, onboarding, tips, notebooks, voz, MCP, etc.), pero se anuncian, se hacen con captura antes/después y no se toca ningún elemento de la referencia.

## Objetivo

Hacer warp-lite **lo más ligero, fluido y rápido posible** sin cambiar la UI:

- menos RAM de proceso y de árbol;
- arranque y shell más rápidos;
- menos latencia de tecleo y scroll;
- binario más pequeño;
- cero red en el arranque;
- cero superficies de AI/cloud que no queremos.

Cada optimización se mide antes y después. Nada se da por bueno sin números.

## Marcador (baseline)

Máquina: Ryzen 5 3600, 16 GB RAM, GTX 1650, Windows 10 19045, SSD.
Build: `warp-lite` release, features `gui,skip_login`, perfil `warp-lite/settings.toml`.
Medición: `measure-startup.ps1 -Runs 5`, 5 s de settle, app cerrada entre runs.
JSON: [`bench/startup-20261118-231429.json`](bench/startup-20261118-231429.json).

| Métrica | Baseline | Objetivo | Notas |
|---|---:|---:|---|
| Ventana caliente | **65,2 ms** (48,2–116,1) | <100 ms | ya cumple |
| Shell listo | **388,1 ms** (302,4–473,4) | <150 ms | PowerShell; probar cmd/pwsh |
| RAM proceso, 1 tab | **331,1 MB** (327–334,8) | ¿<200 MB? | medir suelo del renderer |
| RAM privada, 1 tab | **436,0 MB** (431–441,5) | — | |
| RAM árbol, 1 tab | **487,6 MB** (483,2–491,3) | ¿<400 MB? | el shell pesa ~150 MB |
| RAM privada árbol | **556,9 MB** (551,9–562,6) | — | |
| RAM 10 tabs | pendiente | medir | |
| Binario | **336,9 MB** | <100 MB | `strip` no ayuda; poda/opt-level |
| Red al arrancar | pendiente | 0 | medir con proxy/ETW |
| Throughput 19 MB | 1,4 MB/s | no prioritario | techo de ConPTY |
| Parser headless | 24,4 MB/s | — | fase 0 |

Primer arranque con config nueva: **1025 ms** de ventana / **2339 ms** de shell (creación de config y SQLite). No usar ese número como baseline de arranque.

## Auditoría de primer arranque

Perfil limpio con `WARP_DATA_PROFILE=audit` y el `settings.toml` copiado:

- No aparece onboarding, login ni modal de bienvenida.
- Entra directo al terminal.
- El bloque se renderiza correctamente (`echo audit` → `audit`).
- No aparece el banner de alias en el perfil limpio.
- En el perfil principal el banner de alias apareció una vez tras el primer comando (`bench/warp-lite-v0.1.0.png`). Parece un tip de una sola vez ligado a preferencias, no un estado de primer arranque reproducible.
- Captura limpia: [`bench/warp-lite-first-run.png`](bench/warp-lite-first-run.png).

Pendiente: auditar menús, command palette, settings y barra superior con perfil limpio, y apuntar cada superficie que no esté en `docs/target-ui.png`.

## Hallazgos

- **El binario no es debuginfo.** `llvm-objdump -h` da `.text` ~160 MB, `.rdata` ~184 MB y `.pdata` 7,4 MB. `llvm-strip --strip-all` no cambia el tamaño. El PDB de debug es aparte y pesa 626 MB. Para bajar el EXE hay que podar código y assets, no hacer strip.
- **El árbol de procesos incluye el shell.** 487,6 MB de árbol con 331,1 MB de Warp: el resto es OpenConsole + PowerShell. Cambiar de shell puede mover esa parte sin tocar Warp.
- **El primer arranque limpio no muestra onboarding ni banner.** El banner de alias es un tip de una sola vez del perfil principal; no se reproduce con `WARP_DATA_PROFILE=audit`.
- **El primer arranque con config nueva tarda ~1 s de ventana / ~2,3 s de shell** por creación de config/SQLite. Es un coste de una sola vez; no confundirlo con el arranque en caliente.

## Backlog de optimización

### 1. Superficies

- [ ] Confirmar si el banner de alias puede reaparecer y, si sí, ocultarlo.
- [ ] Menús AI/Drive/Oz.
- [ ] Command palette: entradas AI, Drive, onboarding, notebooks, voz, MCP, editor/diff, computer use, auto-update.
- [ ] Settings: páginas AI/Drive/cloud/telemetry.
- [ ] Iconos de la barra superior que no estén en el target.
- [ ] Onboarding, tips y modales de primer uso.
- [ ] Notebooks, voz, MCP, file tree, LSP, editor de código/diff, computer use.
- [ ] Auto-update.

### 2. Features de compilación

- [ ] Revisar `default` de `app/Cargo.toml` y quitar features no usadas una a una (`agent_mode`, `mcp_server`, `warp_packs`, `global_ai_analytics_collection`, ...).
- [ ] Nunca `--no-default-features` en bloque.

### 3. Crates

- [ ] Código → dependencia → crate.
- [ ] Candidatos: `voice_input`, `input_classifier`/ONNX, `notebooks`, `computer_use`, `code_review`/`lsp`, `onboarding`, `drive`, `ai`, `mcp`, `cloud_*`.
- [ ] `cargo tree -i` y `cargo machete` después de cada corte.
- [ ] No tocar `warp_terminal`, `warpui`, `warpui_core`, `warp_editor`, `settings`, `command` ni `sum_tree`.

### 4. Arranque

- [ ] Medir red con proxy/ETW.
- [ ] Revisar trabajo antes de ventana: DB, migraciones, assets, fuentes, features.
- [ ] Lazy init de superficies no usadas.
- [ ] Comparar PowerShell vs `cmd` vs `pwsh -NoProfile` (RAM y tiempo de shell).

### 5. RAM

- [ ] Medir 1 vs 10 tabs.
- [ ] Medir con `cmd` para separar Warp del shell.
- [ ] Revisar caches, texturas, atlas de fuentes, scrollback y thumbnails.
- [ ] Liberar memoria al cerrar tabs.
- [ ] Evaluar allocator y límites de cache.

### 6. Fluidez

- [ ] Latencia de tecleo (medición interna, no solo SendKeys).
- [ ] Frame pacing y scroll a 4K/120.
- [ ] Virtualización del BlockList sin reescribir la UI.
- [ ] Throttling de tabs en background.

### 7. Binario y packaging

- [ ] `strip` no reduce el EXE: no tiene secciones de debug. Los 336,9 MB son `.text` (~160 MB) + `.rdata` (~184 MB); el debug está en un PDB aparte de 626 MB. El tamaño tiene que salir de podar código/assets y, si compensa, de `opt-level = "s"` + LTO.
- [ ] Probar `release-lite` con `opt-level = "s"`, LTO thin y codegen-units; medir tamaño y rendimiento.
- [ ] Auditar `.rdata`: assets embebidos (fuentes, iconos, shaders, skills, completion specs) que no se usan.
- [ ] Quitar assets no usados.
- [ ] Icono, versión y nombre.
- [ ] Medir tamaño tras cada opción.

### 8. Red y telemetría

- [ ] Cero peticiones al arrancar.
- [ ] Quitar clientes cloud si no se usan.

## Protocolo de medición

1. Build release, misma máquina y misma config.
2. 1 frío aproximado + 5 calientes; descartar el primero de los calientes si hay outlier.
3. Cerrar la app entre runs; esperar 2 s.
4. `measure-startup.ps1`; guardar JSON en `notes/bench/`.
5. Si se toca UI, captura antes/después con `PrintWindow`.
6. Anotar binario y red.
7. No comparar debug con release.

## Plan

- [ ] **P0** — baseline, `phase-3.md`, auditoría de primer arranque, red.
- [ ] **P1** — superficies.
- [ ] **P2** — features de compilación.
- [ ] **P3** — crates.
- [ ] **P4** — packaging.

## Registro de cambios

| Fecha | Commit | Cambio | Ventana | Shell | RAM proc | RAM árbol | Binario | Captura |
|---|---|---|---:|---:|---:|---:|---:|---|
| 2026-11-18 | `c939f41f7` | binario `warp-lite` + perfil propio | 65,2 ms | 388,1 ms | 331,1 MB | 487,6 MB | 336,9 MB | `bench/warp-lite-first-run.png` |
