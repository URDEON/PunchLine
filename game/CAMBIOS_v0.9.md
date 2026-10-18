# Naoya — Laboratorio de combate 0.9

Proyecto recuperado a partir de las tres partes de la versión 0.8.2.

## Control y combate

- Aceleración y frenado progresivos, entrada anticipada de 160 ms para M1 y habilidades.
- Mantener clic permite encadenar M1; se puede desactivar en ajustes.
- Salto con buffer de 120 ms y tolerancia de 100 ms al salir de una superficie.
- Rush de tres impactos separados (7 + 6 + 6), con 19 de daño y 14 de energía total.
- El downslam atraviesa la guardia. Los M1 comprueban la diferencia de altura.
- Cámara con seguimiento suavizado, colisión, FOV ajustable y reacción al impacto graduable.
- Pausas visuales breves en los impactos sin modificar el reloj global ni los cooldowns.

## Animación y presentación

- AnimationTree con mezcla continua de nueve estados de locomoción; la mezcla y cadencia siguen la velocidad real.
- Los M1 usan la duración real de cada clip en vez de una duración supuesta.
- Se conserva el pack humano original y el baile retargeteado. No se añadió un pack nuevo.
- Paleta de piel, ropa y calzado por vértices; conserva la malla, pesos y animaciones del GLB.
- Ondulación de las formas con fase continua y frecuencia suavizada, evitando saltos al cambiar de velocidad.
- Arena con material de cuadrícula, iluminación, hitos y señalización de las tres estaciones.
- Estelas con menor persistencia y máximo de ocho siluetas. Ajuste para desactivar partículas y estelas.
- Los modelos de las dos formas conservan el rig básico de siete huesos de 0.8.2; no se presenta como rig artístico nuevo.

## Audio

- Buses de efectos, música e interfaz, con volúmenes independientes y limitador en la mezcla principal.
- Dash y bloqueo recortados con fundidos para evitar colas desproporcionadas.
- Pasos alternados según distancia recorrida, con leves variaciones de tono.
- Se priorizan voces libres antes de reemplazar un sonido que está reproduciéndose.
- La música del emote baja momentáneamente ante efectos fuertes.
- Sonido original de clic para la interfaz, sintetizado para esta versión.

## Interfaz

- Vida y fase arriba; energía, estados y cuatro tarjetas de habilidades abajo.
- Iconos vectoriales, estado de desbloqueo, requisitos y barras de enfriamiento.
- Menú de pausa con Pruebas, Ajustes y Controles. Teclas reasignables y preferencias persistentes.
- Preparación explícita de energía, formas, NPC y reinicio desde el laboratorio.
- Distribución adaptable a ventanas anchas y estrechas; se comprueba a 1280×720, 640×720, 360×640, 640×360 y 1920×1080.

## Referencias

Se consultó la [wiki de Head of the Hei / Naoya](https://jujutsushenaniganswiki.com/wiki/head-of-the-hei/) y la página de [controles y mecánicas](https://jujutsushenaniganswiki.com/wiki/controls-mechanics/).
Decisive Strike sirvió de referencia para la secuencia de avance y ráfaga; las descripciones de movilidad, cuadros y variantes sirven como referencia de lectura visual. Se conserva el diseño propio de las dos fases, la ruta de cinco cuadros, el counter y el dominio de 14 segundos. No se afirma que el balance sea una reproducción exacta de Jujutsu Shenanigans.

## Abrir y probar

Extraer el proyecto en una carpeta nueva, importar `project.godot`, esperar a la importación y pulsar F5. Configuración de Godot 4.4 con GL Compatibility; validación realizada con Godot 4.6.3 Linux y con el Godot 4.4.1 Linux x86_64 adjuntado por el usuario. La validación gráfica sigue bloqueada por las conexiones locales del entorno.

Pruebas automatizadas:

```sh
godot --headless --path . --script res://qa/combat_test.gd --fixed-fps 60
godot --headless --path . --script res://qa/presentation_test.gd --fixed-fps 60
godot --headless --path . --script res://qa/assets_test.gd --fixed-fps 60
godot --headless --path . --script res://qa/polish_test.gd --fixed-fps 60
```

La demo `qa/review_demo.gd` es una prueba automatizada que ejecuta los sistemas del juego. Prepara posiciones y energía para exhibir las fases; estos preparativos están rotulados durante la demo y no se aplican al juego normal.

```sh
godot --path . --script res://qa/review_demo.gd --fixed-fps 60 --write-movie prueba.avi
```

Las capturas de la demo van a `user://review` de forma predeterminada. Se puede configurar una carpeta distinta con `-- --output=/ruta`.

La captura real con FFmpeg, los comandos y el impedimento actual están documentados en `GRABACION_REAL.md`. `--realtime` adapta las esperas de la demo al tiempo de ejecución; no cambia las mecánicas del juego.
