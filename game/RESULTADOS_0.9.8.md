# Resultados — Naoya 0.9.8

**905/905 comprobaciones pasaron** en la regresión completa: 18 suites y ocho demos ejecutadas por el Godot 4.4.1 Linux adjuntado, con Jolt Physics y GL Compatibility. Registros y comandos en `resultados_v098/resumen.json` y los `.log`. Se conserva la regresión de las versiones anteriores.

La suite nueva pasó **49/49**: impulsos horizontales/uppercut/downslam, giro real, simulación, recuperación, rig conservado, malla deformada, calle transitable, ocho azoteas con colisión alineada, foso conservado, fachadas agrupadas, skyboxes, habilidad 1, M1, bloqueo, cristalización, mezcla y menú. Otras seis comprobaciones validan la migración desde 0.9.7 con prioridad sobre 0.9.6 y la conservación de datos actuales.

En los tres impactos nuevos muestreados, la velocidad angular máxima fue 12 rad/s, el diámetro de la malla estuvo entre 2,48 y 2,51 m y menos del 0,26% de las aristas muestreadas se estiraron por encima de 2×. Se excluyen aristas menores de 4 mm. No se alteró el rig de 53 huesos ni los pesos. Estas medidas detectan deformación general; no certifican cada articulación en todas las poses posibles.

La demo 0.9.8 pasó **13/13** tanto a 60 como a 30 pasos de captura por segundo: recorrido y dash, audio real de habilidad 1, limpieza de fotogramas, tres cuartos M1 con ragdoll/recuperación, bloqueo del NPC, vidrio con modelo oculto y restauración a los cinco segundos, azotea y menú. Los actores se recolocan para aislar los casos; los ataques, contactos, colisiones y sonidos se ejecutan mediante los sistemas del juego.

Se corrigió una comprobación antigua que intentaba consultar `shell.visible` después de que la envoltura de transformación ya había sido eliminada. Ahora acepta su retirada como resultado correcto y sigue exigiendo que la forma 2 esté visible. No se cambió la transformación para satisfacer la prueba.

La importación terminó con código 0 y sin errores de script. El editor sin pantalla puede registrar advertencias de sockets de depuración o texturas del renderizador Dummy; las suites terminaron sin `SCRIPT ERROR`, `ERROR:` ni fallos de aserciones.

Se produjo un MP4 real de 33,2 segundos, 1280 × 720 a 30 FPS, H.264 y AAC, con código 0 y 13/13 comprobaciones en la demo gráfica. Se revisaron imágenes del distrito, habilidad 1, ragdolls, vidrio, azotea, noche y ajustes. La inspección visual del vidrio reveló una limitación anterior: ambas caras siguen mostrando la misma fotografía. Las pruebas numéricas de duración, ocultación y restauración pasaron, pero no comprobaban los píxeles. La solicitud de una nueva prueba gráfica fue cancelada antes de ejecutarse; se retiró la corrección experimental no verificada. `qa/crystal_graphics_v098.gd` conserva el diagnóstico de diferencias de imagen para la próxima revisión. El texto de la grabación que dice «independientes» no demuestra que las imágenes lo sean.

La grabación gráfica y la comprobación del ZIP final se documentan en `GRABACION_REAL.md` y sus registros correspondientes. El MP4 se entrega por separado para mantener el proyecto descargable en un único ZIP.

No se ejecutó Godot 4.7.2 Windows ni se midieron FPS de juego en tu equipo. Movie Maker avanza con pasos fijos, de modo que el video demuestra ejecución, imagen y audio, pero no rendimiento en tiempo real.

Para repetir:

```text
python qa/repetir_pruebas_v098.py --godot /ruta/Godot --project /ruta/proyecto --output /ruta/resultados_nuevos
```

El ZIP se verificó por CRC, se extrajo en una carpeta vacía y terminó la importación antes de ejecutar 49/49 comprobaciones nuevas y el arranque de 180 fotogramas, ambos con código 0 y sin errores de ejecución. Se compararon 466 archivos de código y recursos de runtime con el paquete probado, sin diferencias. Registros en `resultados_v098/zip_limpio/`.
