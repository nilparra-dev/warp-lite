# Arquitectura: las tres opciones reales

## Hallazgo importante

El “look Warp” no está repartido de forma limpia entre las crates del workspace. La parte visual del terminal sí está en `warpui`/`warpui_core`, y el motor VT/PTY en `warp_terminal`. Pero el **modelo de bloques** vive en la app:

- `app/src/terminal/model/blocks.rs` — lista de bloques, alturas y `SumTree<BlockHeightItem>`.
- `app/src/terminal/block_list_element.rs` — render del BlockList.
- `app/src/terminal/block_list_viewport.rs` — viewport, scroll y selección.
- `app/src/terminal/model/mod.rs` — `TerminalModel`, que mezcla terminal, bloques y estado de UI.

Eso cambia el cálculo: no basta con enlazar `warp_terminal` + `warpui` para tener Warp. Hay que llevar también una capa de app, o reimplementarla.

## Opción A — Fork de la app y poda

Partir de `app/` y quitar agentes, nube, telemetría, editor de código, etc.

- **A favor:** el resultado es exactamente Warp desde el día 1. Bloques, editor, palette, tema, atajos, todo.
- **En contra:** `app` son ~79 crates alcanzables y una cantidad enorme de código. Muchas dependencias de AI/cloud son incondicionales; quitarlas es tocar código en muchos sitios. El upstream se mueve a diario y los rebases duelen.
- **Licencia:** AGPL. Para uso personal da igual; si se publica, el derivado va AGPL.
- **Cuándo tiene sentido:** si la fidelidad exacta con Warp vale más que el control y el tamaño.

## Opción B — Warp Lite: crates buenas + BlockList propio

Nuevo binario/crate que enlace solo:

- `warpui` + `warpui_core` (render GPU, texto, layout, input).
- `warp_terminal` (VT, PTY, shell integration).
- `warp_editor` (input tipo editor).
- `command`, `sum_tree`, `settings`.

Y reimplemente una versión simple del BlockList (tipo, altura, `SumTree`, virtualización) y el cableado de workspace/tabs.

- **A favor:** mucho más pequeño que la app, control total, se puede mantener el look y la tipografía exactos porque el renderer es el de Warp. Se puede empezar con un MVP y crecer.
- **En contra:** hay que rehacer la capa de app (bloques, tabs, settings, shell integration). No es un fin de semana.
- **Licencia:** AGPL igualmente, porque `warp_terminal` y `warp_editor` son AGPL. Para uso personal, perfecto.

## Opción C — libghostty-vt + UI propia

Motor VT de Ghostty (MIT, 1.0, ABI estable) y UI/render propios.

- **A favor:** licencia limpia para un futuro comercial, binario pequeño, el mejor throughput de parsing conocido. Control absoluto.
- **En contra:** es el camino más largo: hay que escribir el renderer de texto, el editor de input, los bloques, el PTY de Windows y la integración de shell. Se puede reutilizar la estética de Warp (Hack 13/1.2, colores, radios, shader de contraste), pero no el código AGPL.
- **Cuándo tiene sentido:** si el objetivo comercial pasa a ser prioritario o si queremos un binario mínimo de verdad.

## Recomendación provisional

Para uso personal y velocidad de resultado: **B**. Para producto cerrado: **C**. **A** solo si después de medir Warp nos damos cuenta de que el 90% de lo que queremos es Warp tal cual con cuatro cosas apagadas.

La Fase 0 decide con números:

- Si Warp OSS tarda <1 s en arrancar y <200 MB con 10 tabs, la poda de A puede ser suficiente.
- Si tarda 2-3 s y 500 MB, B o C están justificados.
- Si el core `warp_terminal` + `warpui` ya compila y se siente rápido en un prototipo, B gana.

## Invariantes técnicos que no se negocian

1. **SumTree + virtualización.** Nada de `Vec<Block>` con relayout completo en cada scroll.
2. **Atlas de glifos + subpíxel.** Reutilizar el pipeline de Warp o copiar su enfoque; el texto es el 80% de la percepción de calidad.
3. **Shell integration por OSC/DCS.** Sin marcadores de prompt/command/exit code no hay bloques fiables.
4. **Cero red en el arranque.** Ningún login, telemetry, update check ni GraphQL.
5. **Medir antes de optimizar.** Arranque, RAM, throughput y latencia de tecleo.
