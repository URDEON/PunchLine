# Resultados de Naoya 0.9.4

Motor: Godot 4.4.1 adjuntado, `4.4.1.stable.official.49a5bc7b6`. Pruebas automatizadas a paso fijo de 60 Hz con renderizador Dummy, sin imagen. Tu versión 4.7.2 no se ejecutó aquí.

**585/585 comprobaciones correctas:** 543 en diez suites y 42 en cuatro demos. Todos esos procesos terminaron con código 0, sin errores de script ni errores de ejecución. Los registros íntegros y comandos están en `qa/resultados_v094/`; `resumen.json` identifica versión, argumentos, cantidades y estado de cada ejecución.

| Suite / demo | Resultado |
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
| demo | 9/9 |
| hud_demo | 10/10 |
| modelo_demo | 10/10 |
| v094_demo | 13/13 |

La importación de recursos terminó con código 0. El editor emitió cuatro errores de apertura de sockets (`_sock == -1`, `ERR_CANT_CREATE`), asociados a las conexiones locales bloqueadas del contenedor. Se conservan en `importacion.log`; no aparecieron en las ejecuciones del juego. No se considera una importación totalmente libre de advertencias del entorno. También se extrajo el ZIP en una carpeta limpia sin caché y se reimportaron todos los recursos: el proceso terminó con código 0 y emitió ocho mensajes `Parameter "t" is null` desde `servers/rendering/dummy/storage/texture_storage.h:107` al guardar las escenas importadas. Se conserva `importacion_zip_limpio.log`; estos mensajes pertenecen al renderizador Dummy y no sustituyen la revisión gráfica de los materiales.

## Comprobado en las nuevas pruebas

- Las piernas cambian de pose mientras el jugador camina con guardia; dirección, cadencia y salida de guardia conservan desplazamiento real.
- Cuatro clips UAL2 con rotaciones finitas normalizadas, siete ventanas visuales conservadas y tercer M1 usando el hook nuevo.
- Fase 2: eje vertical en reposo, horizontal al moverse, vuelta a vertical y dirección frontal de la cara en ambas posturas.
- Fotograma: cinco segundos, bloqueo de acciones, pausa, restauración de modelo/animadores y liberación de recursos; también repetición, reset, muerte del NPC y captura de fase 2 alta.
- Material Override sobre el panel original, transparencia base solicitada y ausencia de geometría decorativa añadida al panel.
- Kogane con el recurso Skull Wisp y avisos basados en energía, vida, inmovilización y dominio.
- Dominio con barrera exterior, suelo/colisión cilíndricos, límite circular, apoyo cerca del borde y limpieza al abandonar fase 2.
- Demo: counter ante ataque normal del NPC, M1/patada con daño real, evolución y fin del dominio por duración normal.

Los hashes en `qa/procedencia_recursos_v094.json` comprueban que el alien validado, Skull Wisp y el panel conservan los bytes de sus originales. La adaptación mapea 52 de los 53 huesos del destino; RootMotion permanece sin desplazamiento horizontal. Reposo, skin y pesos del alien no se modificaron.

## Pendiente con gráficos

Xorg no puede abrir los listeners locales: `Cannot establish any listening sockets`. No se generó un video. Registros en `qa/resultados_v094/pantalla/`.

Estas pruebas no verifican píxeles: apariencia/transparencia del shader, textura 2D final, encuadre desde la cámara, calidad visual de las nuevas mezclas, audio audible ni rendimiento gráfico. La captura real está implementada y dispone de una comprobación de imagen al ejecutar `visual_revision_test.gd` con gráficos; en Dummy se omite de forma explícita. Consultar `GRABACION_REAL.md` para repetir la demo y grabarla.

## Repetir sin imagen

Desde la carpeta del proyecto, con Python 3 y una carpeta de resultados nueva:

```sh
python3 qa/repetir_pruebas_v094.py --godot /ruta/Godot --output /ruta/resultados_naoya_094
```

El script usa exclusivamente el ejecutable indicado, importa los recursos y no descarga motores. Las acciones de las demos son automatizadas; preparan estados del laboratorio explícitamente y activan mecánicas reales.

La suite nueva también pasó 59/59 desde el ZIP extraído y reimportado sin caché, sin errores de ejecución (`prueba_zip_limpio.log`). Esta repetición no se suma al total de 585 para evitar contar dos veces las mismas comprobaciones. Las rutas del ZIP son relativas, con entradas de carpetas antes de sus archivos, y se verificó su CRC.
