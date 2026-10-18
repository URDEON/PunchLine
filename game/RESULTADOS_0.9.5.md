# Resultados de Naoya 0.9.5

**673/673 comprobaciones aprobadas.** Acciones automatizadas; ejecución real de Godot sin imagen.

Motor: 4.4.1.stable.official.49a5bc7b6, ejecutable Linux adjuntado. Godot 4.7.2 no se ejecutó aquí.

| Prueba | Resultado |
|---|---|
| combat_test | 37/37 |
| polish_test | 25/25 |
| presentation_test | 22/22 |
| assets_test | 23/23 |
| revision_test | 60/60 |
| video_feedback_test | 60/60 |
| hud_test | 97/97 |
| hud_feedback_test | 74/74 |
| modelo_alien_test | 86/86 |
| visual_revision_test | 59/59 |
| crystal_v095_test | 22/22 |
| integration_v095_test | 48/48 |
| ragdoll_v095_test | 11/11 |
| demo | 9/9 |
| hud_demo | 10/10 |
| modelo_demo | 10/10 |
| v094_demo | 13/13 |
| v095_demo | 7/7 |

Los registros y comandos exactos están en resultados_v095/pruebas_godot/. La importación finalizó con código cero; su log conserva errores de sockets de depuración bloqueados por el contenedor. Ninguna prueba de juego tuvo errores de script o recursos.

La auditoría física comprueba restricciones, suelo, estabilidad, transferencia al rig visual y recuperación. La integración comprueba pausa real, animadores suspendidos, semillas, nuevas apariencias al reaparecer, canales de máscaras y dominio.

Blender comprobó deformación en cinco poses del enemigo y produjo renders de recursos para inspección. Esas imágenes no son capturas de Godot.

Grabación gráfica bloqueada por Xorg: Cannot establish any listening sockets. No hay MP4 real ni verificación de píxeles frontal/trasero. La demo real y el script FFmpeg se incluyen para repetirla con pantalla gráfica.

Ragdoll físico: humano y bandidos. Las formas de maldición conservan el derribo anterior. Otros límites están en ACTUALIZACION_0.9.5.md.
