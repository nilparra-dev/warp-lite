# Fase 0 — baseline y decisión

Fecha de inicio: 2026-11-18.

## Objetivo

Tener números reales antes de escribir código. “Extremadamente rápido” tiene que ser medible:

- Arranque en frío y en caliente.
- RAM con 1 tab y con 10 tabs.
- Throughput de salida (`seq`, `cat` de un log grande).
- Latencia de tecleo percibida.
- Scroll a 4K/120 Hz sin drops.
- Peticiones de red al arrancar (deberían ser 0 en nuestro build).

## Entorno

| Elemento | Valor |
|---|---|
| OS | Windows 10 Pro 10.0.19045 |
| CPU | AMD Ryzen 5 3600 (6C/12T) |
| RAM | 15.9 GB |
| GPU | NVIDIA GeForce GTX 1650 |
| Disco | SSD + HDD (target en D:\wlt, SSD) |
| Rust | 1.95.0 instalado; el repo pide 1.92.0 |
| MSVC | D:\buildtools (14.44) |
| Git LFS | 3.6.1 |
| Repo | `a4ad25c41` (2026-11-17), 924 MB |
| CMake | 4.4.4 portable en `tools\cmake` |
| protoc | 36.2 (winget) |
| LLVM/libclang | 23.1.6 |

## Checklist

- [x] Clonar `warpdotdev/warp` con LFS.
- [x] Instalar CMake, protoc y LLVM/libclang.
- [x] Compilar `warp-oss` (`--bin warp-oss --features "gui,skip_login"`). 42m 47s.
- [x] Ejecutar y ver si el canal OSS permite llegar a una shell sin cuenta. Sí, con `skip_login`.
- [x] Medir arranque/RAM con `warp-lite/scripts/measure-startup.ps1`.
- [x] Medir throughput end-to-end con `notes/bench/throughput.cmd`.
- [x] Generar mapa de dependencias y clasificar crates.
- [x] Escribir la recomendación final: Warp Lite vs Ghostty. Ver conclusión.

## Baseline medido

Máquina: Ryzen 5 3600, 16 GB RAM, GTX 1650, Windows 10 19045, SSD.
Build: `warp-oss` release con `gui,skip_login`, `restore_session = false`, shell por defecto Windows PowerShell 5.1.

| Métrica | Warp OSS | Objetivo Warp Lite | Notas |
|---|---:|---:|---|
| Ventana (caliente) | **96 ms** (64–127) | < 100 ms | `startup-20261118-170815.json` |
| Shell lista (caliente) | **388 ms** (320–507) | < 150 ms | primer PowerShell hijo |
| RAM 1 tab (proceso) | **336 MB** | < 100 MB | Working Set |
| RAM 1 tab (árbol) | **491 MB** | < 150 MB | Warp + OpenConsole + PowerShell |
| RAM 9 tabs (proceso) | **400 MB** | < 150 MB | Working Set |
| RAM 9 tabs (árbol) | **1.70 GB** | < 400 MB | cada PowerShell ~76 MB |
| Binario release | **337 MB** | < 30 MB | incluye debuginfo; sin strip |
| Throughput 19,1 MB | **14,0 s → 1,4 MB/s** | > 20 MB/s | `throughput.cmd` dentro de Warp |
| Parser VT + grid (headless) | **0,781 s → 24,4 MB/s** | > 20 MB/s | `parse_bench`, sin PTY/render |
| Baseline `cmd type > NUL` | **0,455 s → 42 MB/s** | — | mismo archivo, sin terminal |
| Latencia tecla→comando (5 runs) | **143–187 ms** | < 50 ms | incluye SendKeys + shell + escritura |
| Peticiones de red al arrancar | pendiente | 0 | medir con ETW/Fiddler |

Notas:

- Los tiempos son en caliente (caché de Windows); el primer arranque tras el build fue más lento y no se midió con precisión.
- La sesión se restauró accidentalmente en la primera tanda de 10 tabs. Los números de 9 tabs son con `restore_session = false` y 9 tabs abiertos con `Ctrl+Shift+T`; aun así Warp restauró parte del estado anterior, así que tómarlos como orden de magnitud.
- El throughput es end-to-end: incluye `cmd.exe`, ConPTY/OpenConsole, parsing y render de Warp. El mismo `cmd type` a `NUL` tarda 0,455 s, así que la mayor parte del tiempo es la ruta del terminal, no el shell.
- El binario release incluye debuginfo (`debug = 1`); un strip lo reduciría bastante.
- La latencia tecla→comando no es puro render: incluye `SendKeys` (~10–30 ms), ejecución de PowerShell y escritura del archivo. Sirve como baseline comparable, no como latencia de frame.
- Intento de aislar ConPTY con `pywinpty`: el script se quedó bloqueado leyendo el pipe; pendiente si hace falta. El `parse_bench` ya demuestra que el parser no es el cuello.

## Conclusión de Fase 0

1. **El arranque no es el problema principal.** La ventana aparece en ~100 ms y la shell en ~400 ms; no es dramático.
2. **La memoria sí es un problema.** Un solo tab cuesta ~491 MB de árbol; 9 tabs, ~1,7 GB. Cada PowerShell pesa ~76 MB y Warp añade ~330-400 MB.
3. **El throughput de salida es el problema más grave.** 1,4 MB/s end-to-end frente a 42 MB/s del shell sin terminal.
4. **El motor VT no es el culpable.** El parser + grid de `warp_terminal` hace 24,4 MB/s headless (19,07 MB en 0,781 s, 200k líneas, grid 50x120, scrollback 200k). La diferencia 24,4 → 1,4 MB/s está en la capa de app: BlockList, render, integración de shell y ConPTY/OpenConsole.
5. **Consecuencia:** un “Warp Lite” que reutilice el BlockList de `app/` heredará el problema. La apuesta correcta es reutilizar `warp_terminal` + `warpui` y **reescribir la capa de bloques** con `SumTree` + virtualización, midiendo desde el día 1. Eso es la opción B.
6. Si el objetivo comercial gana peso, la opción C (`libghostty-vt` + UI propia) evita AGPL; el motor de Warp ya demostró que no hace falta cambiarlo por rendimiento.
7. El `parse_bench` vive en `crates/warp_terminal/examples/parse_bench.rs`; es una adición local para medir el core, no código upstream.

## Estado actual (2026-11-18)

- Proyecto creado en `D:\dev\warp-lite`.
- Checkout de Warp en `warp/` (924 MB, commit `a4ad25c41`).
- Toolchain 1.92.0 y dependencias de Cargo descargadas.
- Herramientas de build instaladas.
- `cargo build --release` de `warp-oss` completado en 42m 47s.
- `skip_login` funciona: llega a una shell y ejecuta comandos.
- Mapa de dependencias generado: 30 crates de núcleo vs 79 de app.
- Hallazgo: el BlockList está en `app/`, no en `warp_terminal`.
- Baseline medido: arranque, RAM, throughput, latencia y parser headless.
- **Fase 0 cerrada.** Decisión recomendada: Warp Lite con BlockList propio; el motor `warp_terminal` ya va a 24,4 MB/s.

## Protocolo de medición

1. Compilar en `release` (o `release-lto` si el tiempo de build lo permite).
2. Para arranque: 1 run en frío (aproximado) y 5 en caliente; descartar el primero de los calientes.
3. Cerrar la app entre runs y esperar 2 s.
4. Medir `MainWindowHandle != 0` y `WorkingSet64` a los 5 s.
5. Guardar JSON en `notes/bench/`.
6. No comparar números de debug con release.

## Mapa de dependencias (generado)

Resultado de `scripts/map_deps.py` sobre los 83 crates del workspace:

- **30 crates** alcanzables desde el núcleo (`warp_terminal`, `warp_editor`, `warpui`, `warpui_core`, `command`, `sum_tree`, `settings`).
- **79 crates** alcanzables desde `warp` (la app).
- **49 crates** solo presentes en la app: agentes, nube, GraphQL, MCP, LSP, telemetría, editor de código, onboarding, persistencia, etc.

El detalle está en [dependency-map.md](dependency-map.md). El hallazgo incómodo: el **BlockList vive en `app/src/terminal/model/blocks.rs`**, no en `warp_terminal`. Las crates del núcleo dan VT/PTY, editor y UI, pero no la capa de bloques. Eso hace que “Warp Lite” sea un proyecto de capa de app, no solo un reensamblado de crates. Ver [architecture.md](architecture.md).

## Riesgos detectados

- `warp_terminal` no es tan independiente como parece: depende de `warp_core`, `warp_completer`, `warp_cli`, `session-sharing-protocol`, `secret_redaction`, `warp_assets`, `warp_isolation_platform`.
- `warp_editor` depende de `warp_core`, `warpui_core`, `markdown_parser`, `vim`.
- El binario OSS puede exigir login. Si pasa, el baseline de terminal se hace vía TUI/integración o pidiendo una build `skip_login`.
- La primera compilación va a ser larga; no confundir tiempo de build con tiempo de arranque.

