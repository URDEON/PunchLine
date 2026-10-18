# Pruebas de la 0.9.15

Acciones automatizadas, Godot 4.4.1 adjuntado. **No se grabó video ni se completó una revisión visual de esta versión.**

| Grupo | Resultado | Alcance |
|---|---:|---|
| Regresión anterior | 1205/1205 | Combate, animaciones, ragdolls base, vidrio, mapa, HUD, controles y preferencias |
| Integración | 183/183 | Fusión, réplica local, menús, formulario online, controladores, energía y HUD robótico |
| Combate del mega | 47/47 | Cuatro habilidades, M1 con derribo, carga/recuperación, paredes, bloqueo de mira, propulsión, humo, receptor de daño y limpieza |
| Controladores online y réplica | 17/17 | Daño normal sin cancelar M1; otro mega lo cancela; golpe elevado, cañón, ragdoll normal, pitch, entradas inválidas, vuelo y snapshots |

Son **1452 comprobaciones locales**. Las pruebas online de esta versión crean controladores y una réplica en otro World3D dentro del entorno de prueba: **no son una partida ENet entre tres procesos o tres PC**.

Se exportó el paquete Windows con las plantillas 4.4.1 existentes. Su PCK pasó **80/80** comprobaciones con el runtime Linux de la misma versión (47 de combate, 17 de réplica y 16 de HUD); el registro del paquete se encuentra en `resultados_v0915/paquete_exportado`. Esto no equivale a ejecutar el EXE en Windows.

## Geometría

El GLB original se conserva byte por byte. Se midieron sus bordes de unión para crear fuelles que conectan ambos lados del hombro, cintura y piernas, sin aumentar la silueta con esferas. También se comprobó que el puño llega al suelo con pies plantados y que el pisotón levanta el pie. El AABB del mecha articulado y los resultados numéricos están guardados. Esto verifica transformaciones y cobertura geométrica, no sustituye una inspección de su aspecto en pantalla.

## Bloqueos y pruebas pendientes

- El intento gráfico informó `X11 Display is not available` y no pudo crear Wayland. La solicitud de acceso adicional quedó pendiente y fue cancelada; se continuó sin volver a bloquear la entrega por ella.
- No se certificaron la apariencia de los shaders, el menú con profundidad, la mezcla auditiva ni los FPS de esta versión. Hay un script gráfico listo para ejecutarse en tu PC.
- No se volvió a probar transporte ENet real en la 0.9.15. Requiere partida manual entre los tres con la misma versión.
- Windows nativo/Godot 4.7.2, apoyo sobre desniveles, choque del dash con techos, balance y legibilidad con tus ajustes necesitan prueba manual.
- Rust Vanguard usa articulación mecánica y aturdimiento; su ragdoll físico sigue pendiente. Los derribos físicos nuevos se verificaron contra personajes con el ragdoll existente.

La importación headless puede registrar errores del servidor TCP del editor porque el sandbox no permite abrir esos sockets. Los procesos de juego que validan las mecánicas completaron las comprobaciones sin errores de GDScript.

## Repetir

Desde la carpeta con `project.godot`, usando directorios nuevos para los registros:

```sh
python qa/repetir_pruebas_v0915.py --godot /ruta/Godot --output /ruta/regresion_nueva
python qa/repetir_mechas_v0915.py --godot /ruta/Godot --output /ruta/mechas_nuevo
```

Para generar capturas reales en un equipo con pantalla:

```sh
Godot --path . --resolution 1280x720 --script res://qa/mega_visual_v0915.gd
```

Indica `NAOYA_QA_OUTPUT` con una carpeta de salida antes de ejecutar ese script. No genera imágenes que simulen gameplay: carga el proyecto y sus mecánicas reales. No hay capturas de esta versión incluidas como si hubieran sido generadas.
