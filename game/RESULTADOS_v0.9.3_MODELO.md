# Validación de 0.9.3 — Prueba de modelo

Se ejecutó Godot 4.4.1, el motor adjuntado por el usuario, sin imagen. Las acciones de prueba fueron automatizadas. Esta validación comprueba funcionamiento e integridad; la revisión de cámara, iluminación, fluidez visual y sonido dentro del juego sigue pendiente en un entorno gráfico.

| Grupo | Comprobaciones aprobadas |
|---|---:|
| Combate, ajustes y presentación | 84/84 |
| Recursos, revisión y correcciones de videos anteriores | 143/143 |
| HUD y feedback del HUD | 171/171 |
| Skin, materiales y animaciones del nuevo modelo | 86/86 |
| Demos reales de combate, HUD y modelo | 29/29 |
| Total | 513/513 |

No hubo errores de script ni errores del motor durante las suites y demos de la ronda final. El editor sin imagen registra errores al crear sus conexiones locales, consecuencia del bloqueo del entorno. La primera importación del nuevo GLB también emitió un mensaje de textura nula al generar una miniatura con el renderer Dummy; la importación terminó y las pruebas comprobaron la carga de los mapas de color y normales. Ambos registros se conservan.

La revisión de logs detectó un error de triangulación anterior al modelo, en un relleno del HUD casi vacío. Se corrigió y se repitió la ronda completa: el error ya no aparece en las suites ni demos finales. No cambió la cantidad mostrada en las barras ni el balance del combate.

El GLB integrado contiene una malla de 12.000 triángulos y 8.770 vértices exportados, un skin con 53 huesos y 64 clips. Las pruebas comprueban pesos válidos y normalizados, cuatro influencias por vértice, huesos existentes, pesos coincidentes en costuras UV, material sin sustitución por paleta, mapas 1024 × 1024 y conservación de todos los clips del rig anterior. También evalúan cambios reales en las poses de reposo, carrera, guardia, golpe, patada, derribo, levantarse y Running Man.

La demo del modelo comprueba movimiento del CharacterBody, entrada y salida de guardia, daño real de M1 y patada, desplazamiento de dash con Q, baile, cambio a Fase 1 y restauración del modelo al reiniciar. La cápsula del jugador conserva altura 1,9 y radio 0,38. Los 33 archivos fuente de los assets anteriores conservan sus bytes, sin contar metadatos generados de importación. La tabla de balance, habilidades y movimiento no se modificaron. Ver `qa/resultados_modelo/integridad_0921.json`.

Se inspeccionaron renders de Blender de reposo, guardia, carrera, golpe y patada. No se observaron costuras abiertas ni la deformación que aparecía al calcular pesos antes de soldar las posiciones. Las dos texturas JPEG del último envío se conservan byte por byte en el GLB final; sus hashes están en `qa/modelo_alien/procedencia_modelo.json`. Estas imágenes no certifican la calidad del renderer de Godot ni el rendimiento a 30/60 FPS.

No se obtuvo un video real: Xorg falló antes de iniciar Godot gráfico al abrir sus sockets locales. El proyecto incluye la demo y los comandos FFmpeg para repetir la grabación cuando haya pantalla disponible, en `GRABACION_REAL.md`. No se descargó otro Godot ni se presentó una animación de Blender como gameplay.

Registros actuales: `qa/resultados_modelo/`. Los resultados y vistas de versiones anteriores conservan sus nombres y son históricos. Para repetir las comprobaciones, desde el proyecto extraído:

```sh
python3 qa/repetir_pruebas_modelo.py --godot /ruta/Godot_v4.4.1-stable_linux.x86_64 --output /ruta/resultados_093_nuevos
```

Para reconstruir el modelo se entregan el GLB original recibido, el rig fuente, el archivo Blender editable y los tres scripts en el paquete separado `Naoya_0.9.3_MODELO_Y_RIG.zip`.
