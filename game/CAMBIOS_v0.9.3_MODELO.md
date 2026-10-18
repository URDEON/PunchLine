# Naoya 0.9.3 — Prueba de modelo

Esta entrega sustituye el personaje de la forma BASE por el alien elegido por el usuario. Parte de 0.9.2.1 y usa el último GLB enviado, `Meshy_AI_Celestial_Wanderer_1010065336_texture (1).glb`. Las otras tareas de 0.9.3 siguen enumeradas en `PENDIENTES_ACTUALES.md`.

El archivo recibido tenía malla y texturas, pero no esqueleto, pesos ni animaciones. Se preparó un rig local con Blender 4.3.2 a partir de `assets/rpg_animations/Unarmed.glb`, que ya estaba en el juego. Se ajustaron las posiciones de reposo a los brazos y piernas del nuevo personaje, conservando los nombres de huesos y los clips del pack. No se compró ni descargó otro pack.

| Recurso | Recibido | Integrado |
|---|---:|---:|
| Triángulos | 75.028 | 12.000 |
| Vértices exportados | 43.204 | 8.770 |
| Huesos | 0 | 53 |
| Clips en el GLB | 0 | 64 del pack existente |
| Mapas de color y normales | 1024 × 1024 | Los mismos bytes JPEG |

La reducción de triángulos es del 84%. La malla editable tiene 6.000 vértices; el GLB duplica algunos en costuras UV y cambios de normales. Los pesos están normalizados y limitados a cuatro influencias por vértice. Se soldaron las posiciones antes de calcularlos para que las costuras UV mantengan los mismos pesos y la ropa no se abra durante las animaciones.

El jugador usa `assets/characters/alien/Alien_Naoya_Rig_Combat.glb` con sus materiales, sin aplicar la paleta del muñeco anterior. Los NPC siguen usando el recurso original. La escala encaja con el collider que ya existía. Las transformaciones continúan usando los modelos de Fase 1 y Fase 2 del proyecto; el alien reaparece al volver a BASE. Q sigue siendo dash y P selector.

La demo `qa/modelo_demo.gd` prepara situaciones explícitas de laboratorio y activa locomoción, guardia, M1, patada, dash, baile, transformación y retorno mediante las funciones reales del juego. No se cambiaron daño, cooldowns, colisiones ni mecánicas para conseguir resultados.

Se corrigió también un error anterior del dibujo del HUD al agotarse una barra: el recorte podía devolver un polígono degenerado que Godot no conseguía triangular. Ahora se dibujan solo las partes con triangulación válida. La animación del relleno, las cantidades y los segmentos conservan sus reglas. Las pruebas rechazan también errores del motor durante la ejecución de cada suite y demo.

Las imágenes en `qa/modelo_alien/poses_blender/` son renders del modelo y sus poses en Blender, no capturas del juego. Sirven para revisar el skin y las deformaciones. No hay rig facial ni física independiente de ropa o antenas en esta etapa. La guardia por capas y el ragdoll articulado siguen pendientes.

Abrir el proyecto en una carpeta nueva. La importación y las pruebas se ejecutaron con el Godot 4.4.1 adjuntado; todavía falta revisar la presentación gráfica en el Godot 4.7.2 del usuario. Consultar `RESULTADOS_v0.9.3_MODELO.md` y `GRABACION_REAL.md` para la evidencia y sus límites.
