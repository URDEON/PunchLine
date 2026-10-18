# Evidencia de arquitectura 2.1

Ejecuciones de esta revisión con Godot oficial 4.4.1. Los logs de esta carpeta corresponden
al terreno y a la arquitectura actuales; los resultados anteriores del directorio padre son históricos.
Las capturas `../before_*.png` muestran el defecto y `../after_*.png` la corrección.
`after_gameplay.png` se obtuvo tras entrar desde DEMO en el menú original, con personaje,
HUD, entorno y mapa reales. Solo se fijó la cámara para encuadrar la captura.

El render de `render_housing.gd` desactiva el culling de distancia para la vista de conjunto;
el de `render_gameplay.gd` mantiene los límites de producción de 320 m.

La prueba sintética del módulo se corrigió para probar el bloqueo con la cápsula de pie
sin ejecutar el agachado automático de su adaptador. Se conserva la comprobación física;
las medidas reales se comprueban por separado con el controlador de PunchLine.

Los avisos de V-Sync corresponden a Xvfb/Mesa. Los avisos de interpolación del rig en la
prueba ENet proceden de la articulación original y no impidieron completar sus comprobaciones.
No se ha medido rendimiento con una GPU de escritorio.

Los logs guardados normalizan finales de línea y espacios al final; sus mensajes se conservan.
