# Resultados 0.9.10

**1205/1205 comprobaciones automatizadas aprobadas** con el Godot 4.4.1 Linux adjuntado, Jolt y Compatibility.

| Prueba | Resultado | Mapa |
| --- | --- | --- |
| combat_test | 38/38 | legacy |
| polish_test | 25/25 | legacy |
| presentation_test | 23/23 | legacy |
| assets_test | 23/23 | legacy |
| revision_test | 60/60 | legacy |
| video_feedback_test | 60/60 | legacy |
| hud_test | 97/97 | legacy |
| hud_feedback_test | 74/74 | legacy |
| modelo_alien_test | 86/86 | legacy |
| visual_revision_test | 59/59 | legacy |
| crystal_v095_test | 22/22 | legacy |
| integration_v095_test | 48/48 | legacy |
| ragdoll_v095_test | 11/11 | legacy |
| update_v096_test | 66/66 | legacy |
| update_v097_test | 75/75 | legacy |
| preferences_migration_v097_test | 6/6 | legacy |
| update_v098_test | 49/49 | legacy |
| preferences_migration_v098_test | 6/6 | legacy |
| robot_test_v099 | 47/47 | legacy |
| robot_skills_v099_test | 79/79 | legacy |
| map_crystal_v099_test | 87/87 | legacy |
| preferences_migration_v099_test | 4/4 | legacy |
| update_v0910_test | 83/83 | punchline |
| demo | 9/9 | legacy |
| hud_demo | 10/10 | legacy |
| modelo_demo | 10/10 | legacy |
| v094_demo | 13/13 | legacy |
| v095_demo | 7/7 | legacy |
| v096_demo | 5/5 | legacy |
| v097_demo | 10/10 | legacy |
| v098_demo | 13/13 | legacy |

Las regresiones anteriores usan explícitamente el laboratorio conservado para comprobar sus mecánicas y estaciones. update_v0910_test usa PunchLine, que es el mapa predeterminado, y verifica suelo y reapariciones, enemigos, orientación, locomoción, grafo físico conectado, unión de pies, recuperación, poses distintas de habilidades, ataque real de la IA con la rueda abierta y animaciones del selector.

Se inspeccionaron 16 PNG reales de Godot: idle, carrera, impacto con simulación física activa y recuperación de cada chasis. La captura usa Xorg dummy y Mesa llvmpipe; las acciones son automatizadas. Los PNG se entregan aparte para mantener el ZIP del juego ligero. No hay video.

La versión 0.9.9 se conserva intacta. No se eliminaron huesos ni pesos ni se descargó otro Godot. El mapa original se conserva en qa_v0910/map_source del entorno y sus modelos/texturas editables están dentro del proyecto.

La importación headless del editor puede registrar sockets de depuración restringidos y avisos de miniaturas del renderizador Dummy. Las pruebas de ejecución y la captura gráfica final no presentan errores.

## Repetir

```text
python qa/repetir_pruebas_v0910.py --godot "/ruta/al/Godot_adjuntado" --output "/ruta/nueva/resultados"
```

El runner conserva comandos, códigos de salida, logs, mapa probado y carpetas XDG aisladas. Para capturas, usar qa/robot_visual_v0910.gd con pantalla X11 y NAOYA_QA_OUTPUT; los comandos exactos están en CAPTURAS_0.9.10.md.

Godot 4.7.2 Windows, rendimiento de hardware y la sensación con teclado/mouse reales requieren la prueba del usuario. Las escaleras incompletas señaladas por el autor del mapa y los ragdolls de las formas de maldición siguen pendientes.
