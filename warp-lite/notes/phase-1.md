# Fase 1 — MVP de warp-lite

Fecha: 2026-11-18.

## Qué funciona

- Ventana nativa Windows con WarpUI + wgpu.
- Shell real (Windows PowerShell) vía `portable-pty`/ConPTY.
- Parser VT de `warp_terminal` (`BlockGrid` + `Processor`).
- Render del grid con Hack 13 px, line-height 1.2.
- Colores ANSI (16/256) mapeados a `ColorU`.
- Cursor de barra en la posición real del grid.
- Teclado: caracteres imprimibles, Enter, Backspace, Tab, Escape, flechas, Home/End, Delete, PageUp/PageDown y Ctrl+letra.
- Cierre de ventana termina el proceso y mata la shell.
- Modo `--headless` para validar PTY + parser sin UI.
- Modo `--pty-bench <script> [rows] [cols]` para medir ConPTY crudo.

## UI Warp-like (iteración 2)

La primera versión era un grid crudo. Ahora la vista tiene:

- **Tab bar** superior con tab activa, indicador, botón `+` y marca `warp-lite`.
- **Bloques** por comando: cabecera con `❯`, comando, `exit code` y duración; cuerpo con output y colores ANSI.
- **Prompt chips** abajo: directorio actual y shell.
- **Input editor** propio: buffer, cursor de barra, historial con ↑/↓, Backspace/Delete, Home/End, Tab y Enter para enviar.
- **Shell integration** propia: `prompt.ps1` emite OSC 133 (A/B/D) y OSC 7 (cwd); PSReadLine se desactiva para que los marcadores sean fiables.
- **Un BlockGrid por comando**: el output se captura y parsea aislado, así el prompt no contamina el bloque.

Captura: [`bench/warp-lite-ui2.png`](bench/warp-lite-ui2.png).

Todavía falta para ser Warp exacto:

- Scrollback/virtualización real (ahora se ven los últimos 3 bloques y 12 líneas por bloque).
- Tabs funcionales (el `+` aún no abre sesión).
- Chip de rama git, completions, syntax highlighting y sugerencias.
- Selección/copiar, búsqueda, resize/reflow.
- Re-medir RAM/latencia con la UI nueva (los números de abajo son del MVP de grid crudo).

## Métricas vs Warp

| Métrica | Warp OSS | warp-lite | Mejora |
|---|---:|---:|---:|
| Ventana (caliente) | 96 ms | **81 ms** | ~16% |
| Shell lista | 388 ms | **221 ms** | ~43% |
| RAM 1 tab (proceso) | 336 MB | **189 MB** | ~44% |
| RAM 1 tab (árbol) | 491 MB | **286 MB** | ~42% |
| RAM privada (árbol) | 563 MB | **455 MB** | ~19% |
| CPU tras 5 s | 3,7 s | **0,6 s** | ~6x |
| Latencia tecla→comando | 143–187 ms | **45–55 ms** | ~3x |
| Throughput 19 MB | 1,4 MB/s | **1,4 MB/s** | igual |
| ConPTY crudo | — | **1,1 MB/s** | techo de Windows |

La latencia incluye `SendKeys` + shell + escritura del archivo; aun así la comparación es consistente.

## Hallazgo: el techo es ConPTY

El parser + grid headless hace **24,4 MB/s**. La app completa y el benchmark de PTY crudo se quedan en **1,1–1,4 MB/s**. Es decir, el cuello de throughput masivo no es la UI ni el parser: es ConPTY en Windows 10. Subir el buffer de consola a 1000x200 no mejora (1,14 MB/s).

Consecuencias:

- Optimizar el BlockList no arregla `cat` de 19 MB.
- Para uso con agentes CLI, la latencia y la RAM importan más que el throughput masivo.
- Si algún día queremos >10 MB/s en salidas grandes, hay que explorar una vía rápida (winpty, pipes para comandos no interactivos, o un host de consola propio). Es un proyecto aparte.

## Cómo ejecutar

```powershell
target\release\warp-lite.exe
```

Sin login, sin red, sin agentes. Para benchmarks:

```powershell
warp-lite.exe --headless
warp-lite.exe --pty-bench notes\bench\ptybench.cmd
```

## Archivos

- `crates/warp_lite/src/main.rs` — ventana, vista, input, cursor, colores.
- `crates/warp_lite/src/session.rs` — PTY, parser, grid, color mapping, benchmarks.
- `notes/bench/warp-lite.png` — primera captura sin colores.
- `notes/bench/warp-lite-colors.png` — captura con `git diff --stat`, colores y cursor.
- `notes/bench/warp-lite-ui2.png` — UI Warp-like con tabs, bloques y editor.
- `notes/bench/startup-20261118-175021.json` — arranque/RAM de warp-lite.

## Siguiente

1. **Bloques + shell integration** (OSC 133/Warp) y scrollback virtualizado. Es el corazón de la Opción B.
2. Tabs/splits.
3. Copiar/pegar, selección y búsqueda.
4. Resize/reflow real.
5. Reducir los 189 MB base (assets/wgpu/renderer).
6. Sólo si hace falta: vía rápida para output masivo.

