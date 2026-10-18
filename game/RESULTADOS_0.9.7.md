# Resultados — Naoya 0.9.7

834/834 comprobaciones pasaron. Ejecución automatizada del motor real, sin render gráfico, con `4.4.1.stable.official.49a5bc7b6`, el ejecutable Linux adjuntado por el usuario. Backend físico Jolt; proyecto GL Compatibility. Godot 4.7.2 Windows no se ejecutó en este entorno.

| Suite | Pasaron / total |
| --- | --- |
| Combate | 38/38 |
| Pulido | 25/25 |
| Presentación | 23/23 |
| Recursos | 23/23 |
| Revisión de mecánicas | 60/60 |
| Reportes de video anteriores | 60/60 |
| HUD | 97/97 |
| Ajustes del HUD | 74/74 |
| Modelo alien | 86/86 |
| Revisión visual numérica | 59/59 |
| Cristalización | 22/22 |
| Integración 0.9.5 | 48/48 |
| Ragdoll | 11/11 |
| Regresión 0.9.6 | 63/63 |
| Actualización 0.9.7 | 75/75 |
| Migración de ajustes y récord | 6/6 |
| Siete demos automatizadas | 64/64 |
| Total | 834/834 |

La importación finalizó con código 0, sin errores de script. El intento del editor de iniciar su servidor local de depuración produjo mensajes de sockets bloqueados durante la importación; no impidió importar los recursos. Las suites y demos terminaron con código 0 sin `SCRIPT ERROR`, `ERROR:` ni fallos de aserciones. Registros y comandos exactos: `resultados_v097/resumen.json` y los archivos `.log`.

## Cobertura nueva

La suite 0.9.7 simula ragdoll desde idle, uppercut, salto y finisher del jugador, y desde idle de los tres bandidos sobre una azotea. Comprueba simulación física, doce anclajes, recuperación, longitudes, escalas y la malla deformada. Los casos muestreados tuvieron velocidades máximas entre 4,26 y 8,15 m/s; diámetros de malla entre 2,11 y 2,54 m. La fracción de aristas muestreadas con estiramiento superior a 2× quedó por debajo del 1,18%. Se excluyen del cálculo aristas menores a 4 mm. Algunas aristas individuales aún presentan estiramiento local; esta prueba busca detectar deformación general, no certifica skinning perfecto en todas las articulaciones.

También comprueba los dos fotogramas móviles, silueta plana, limpieza del rastro, preview que anima mientras el mundo permanece pausado, los ocho clips del selector, fin automático del gesto, ventanas instanciadas, siete estaciones, puerta física, iluminación, impulso, rotura frontal/trasera de los vidrios, retirada de colisiones, rearme, M1 y tecla E reales, y rueda en 1280×720, 640×360 y 360×640.

La demo nueva valida diez pasos mediante las mecánicas reales. Sus preparativos reposicionan personajes para aislar pruebas; las entradas y resultados se automatizan. Las seis demos anteriores siguen ejecutándose para regresión de combate, HUD, modelo, cristalización, formas y herramientas de mapa.

## Comprobación de recursos y límites

Se ejecutaron además seis comprobaciones de migración con datos aislados: copia del tamaño del HUD, distancia de cámara, controles Q/P/E y récord/muestras del Eco; conservación de preferencias y récord actuales cuando ya existen. La prueba está en `qa/preferences_migration_v097_test.gd` y también se incluye en el ejecutor de regresión.

Se exportaron poses deformadas de la malla real y se revisaron renders de Blender. Son inspecciones del recurso, no capturas del juego; no demuestran transparencia, iluminación ni apariencia final del renderizador de Godot. El script conserva la exportación y la revisión para repetirlas.

El paquete se extrajo en una carpeta vacía y se importó sin caché. Después de terminar la importación, volvió a pasar la suite 0.9.7 (75/75) y la escena principal arrancó durante 180 fotogramas con código 0, sin errores de script ni de ejecución. La importación con renderizador Dummy produjo mensajes `texture_2d_get` por texturas sin representación gráfica; no se observaron en el arranque ni en la suite posterior. Los registros de esta comprobación están en `resultados_v097/zip_limpio/`.

No se produjo MP4. Xorg falla con `Cannot establish any listening sockets`; no pudo abrirse la pantalla virtual. No se presentó una animación externa como gameplay. Ver `GRABACION_REAL.md` y `resultados_v097/pantalla/`.

Quedan pendientes la validación gráfica y de rendimiento del juego completo, la ejecución en Godot 4.7.2 Windows y la física propia de las formas de maldición. Ver `AUTOCRITICA_0.9.7.md` para los límites de las pruebas.

## Repetir

```text
python qa/repetir_pruebas_v097.py --godot /ruta/al/Godot --project /ruta/al/proyecto --output /ruta/a/resultados_nuevos
```

En Windows puede usarse `py` en lugar de `python`. La carpeta de salida debe ser nueva. El proyecto se importa antes de ejecutar las suites. `qa/review_demo.gd -- --v097` conserva la demostración nueva y `qa/grabar_ffmpeg.py` conserva la grabación con una pantalla gráfica disponible.
