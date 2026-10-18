# Resultados — Naoya 0.9.2.1

Motor ejecutado: `4.4.1.stable.official.49a5bc7b6`, Linux x86_64, adjuntado por el usuario. No se descargó otro motor. Pruebas automatizadas sin imagen. El usuario usa Godot 4.7.2; esa versión no se ejecutó aquí.

| Suite | Aprobadas |
|---|---:|
| combat_test | 37/37 |
| polish_test | 25/25 |
| presentation_test | 22/22 |
| assets_test | 23/23 |
| revision_test | 60/60 |
| video_feedback_test | 60/60 |
| hud_test | 97/97 |
| hud_feedback_test | 74/74 |
| **Total de suites** | **398/398** |
| Demo de combate | 9/9 |
| Demo del HUD | 10/10 |

La demo del HUD también aprobó los mismos 10 casos con esperas reales en segundos (`--realtime`), sin renderizado. No se cuentan otra vez como casos nuevos.

La suite nueva envía eventos GUI al Viewport: clic en el triángulo, apertura bajo el retrato, filas exactas y futuras deshabilitadas, clic fuera, Enter, selección sin reiniciar recursos, pausa del reloj, Alt y aislamiento del clic respecto a M1. Verifica el deslizador de Ajustes, persistencia y recarga, regreso a la pestaña previa, reserva de Alt y dibujos diferentes al evolucionar y volver a humano.

Se probaron 50%, 80% y 100% en 1280×720, 1920×1080, 1024×768, 360×640, 640×360 y 360×360. La suite anterior añade 640×720 y comprueba textos, geometría de fichas, estado real del juego y menús con scroll.

La primera ronda encontró una constante no admitida por Godot 4.4.1. Se corrigió. Después se detectó que la nueva prueba arrancaba en el viewport predeterminado de 64×64 del modo sin imagen; se fijó explícitamente 1280×720 antes de probar clics. El modo headless no puede confirmar la captura física del cursor, por lo que se comprueba la solicitud de modo y la lógica de cámara/M1. Su efecto real en una ventana queda pendiente de revisión gráfica.

Se ejecutó el conjunto completo y después se repitieron las dos suites HUD al añadir reserva de Alt/Enter. Se adaptó la demo para hacer clic real mediante eventos GUI en el triángulo y Naoya, y modificar el HSlider de Ajustes. Ambas ejecuciones de la demo actualizada aprobaron 10/10. `qa/resultados_v0921/resumen.json` reúne los últimos resultados; conserva el resumen anterior como historial sin duplicar totales.

Importación completada con código 0 y sin errores de parseo en el resultado final. El editor registró fallos de listeners locales por las restricciones del entorno. Los 61 archivos originales de assets se conservan byte por byte; tampoco cambian combat_moves, guided_projection ni combat_tuning. Los cambios en main se limitan a pausa y entrada del HUD.

## Gráficos y grabación

El nuevo intento con Xorg dummy falló antes de iniciar Godot gráfico: `Cannot establish any listening sockets`, fallos al enlazar listeners locales. No se creó un MP4 y no se certifican FPS gráficos, contraste sobre el mapa, animaciones ni audio. No se presenta una prueba sin imagen como gameplay grabado.

Las diez vistas de `qa/vistas_hud` son diseños estáticos exportados del modelo de dibujo actual: seis resoluciones de Base, selector, Fase 1, Fase 2 y escala 50%. Se inspeccionaron selector y dibujos de formas. No son capturas del juego ni reproducen exactamente las fuentes del renderer. Las vistas de 0.9.2 están separadas como historial.

## Repetir

```sh
python3 qa/repetir_pruebas_v0921.py --godot /ruta/Godot_v4.4.1-stable_linux.x86_64 --output /ruta/resultados_nuevos
```

Para grabar en un entorno con pantalla permitida, seguir `GRABACION_REAL.md`. El script y los comandos FFmpeg se conservan; todas las acciones de la demo son automatizadas. Para importar el ZIP en Windows, extraer en una carpeta nueva y abrir project.godot; se incluyen entradas explícitas de carpetas.
