# Resultados — Naoya 0.9.2

Motor ejecutado: `4.4.1.stable.official.49a5bc7b6`, Linux x86_64, enviado por el usuario. No se descargó otro motor. Todas las pruebas de juego se realizaron sin renderizado. El usuario confirmó que su ejecución anterior de 0.9.1.1 funciona, y utiliza Godot 4.7.2; aún falta su revisión visual de esta versión.

| Suite | Aprobadas |
|---|---:|
| combat_test.gd | 37/37 |
| polish_test.gd | 25/25 |
| presentation_test.gd | 22/22 |
| assets_test.gd | 23/23 |
| revision_test.gd | 60/60 |
| video_feedback_test.gd | 60/60 |
| hud_test.gd | 96/96 |
| **Total de suites** | **323/323** |
| Demo de combate `--revision` | **9/9** |
| Demo del HUD `--hud` | **7/7** |

La demo del HUD también aprobó 7/7 con `--realtime`, usando esperas en segundos. Son los mismos siete casos; no se suman de nuevo al total.

La suite HUD comprueba separación de polígonos, ubicación de las cuatro habilidades, fractura de segmentos, daño real reflejado en salud, indicadores de guardia/dash/forma/caída, Counter real y su cooldown azul, fin del cooldown, selector P con reloj detenido, regreso sin reiniciar recursos, Esc, cambio y persistencia de tecla, disponibilidad de fases y dominio, y migración de preferencias antiguas.

En **1280×720, 1920×1080, 1024×768, 640×720, 360×640, 640×360 y 360×360** verifica límites de grupos, texto/teclas/cooldowns dentro de pantalla, separación entre estado y botón de menú, las cuatro pestañas sin desbordamiento horizontal y scroll hasta el último control.

La primera prueba HUD detectó que el menú conservaba un mínimo de altura de la ventana anterior. Se corrigió usando el tamaño solicitado al recalcular el scroll. Las siete suites aprobaron con 75 casos HUD; después se amplió esa suite con 21 casos de texto y scroll y se repitió solo HUD, aprobando 96/96. Los logs finales están en `qa/resultados_v092/`; se conserva el resultado del conjunto inicial como historial, sin sumarlo de nuevo.

## Importación y gráficos

Importación incremental completada con código 0 y sin errores de parseo. El editor registró errores de sockets/listeners locales de este entorno. La carga de recursos aprueba 23/23. La caché `.godot` no se incluye en el ZIP; el editor de destino reimportará los originales.

Se comprobó que `AF_UNIX bind` devuelve `errno=1, Operation not permitted` y se volvió a intentar Xorg mediante el script real de captura. **Xorg no pudo abrir sus listeners y no se creó un MP4.** No es un problema de duración del video. Los registros y la procedencia se conservan en `qa/resultados_v092/captura/`.

Las vistas PNG/SVG son diseños estáticos exportados de los comandos y etiquetas del HUD, con valores de laboratorio 73 HP, energía62 y Counter6,2 s. Se inspeccionó su composición. No renderizan el escenario ni certifican el aspecto exacto de fuentes, contraste sobre el mapa, animación, FPS gráficos, ejecución en Godot4.7.2 o audio.

## Repetir

Desde la carpeta del proyecto, con Python3 y el motor indicado:

```sh
python3 qa/repetir_pruebas_v092.py --godot /ruta/Godot_v4.4.1-stable_linux.x86_64 --output /ruta/resultados_nuevos
```

Solo HUD:

```sh
/ruta/Godot_v4.4.1-stable_linux.x86_64 --headless --path . --script res://qa/hud_test.gd --fixed-fps 60
```

Vistas de diseño, sin gameplay:

```sh
/ruta/Godot_v4.4.1-stable_linux.x86_64 --headless --path . --script res://qa/exportar_hud.gd --fixed-fps 60 -- --output=/ruta/vistas
python3 qa/vista_hud.py /ruta/vistas
python3 qa/rasterizar_vista.py /ruta/vistas
```

La última conversión requiere librsvg y Cairo de Linux; los SVG pueden abrirse directamente en un navegador. Los scripts no descargan motores ni recursos.

## Prueba manual de la entrega

1. Extraer en una carpeta nueva e importar `project.godot`. Confirmar retrato, tres segmentos y distribución del dibujo.
2. Recibir daño y usar1–4: comprobar HP, segmento vacío y cabeceras azules con segundos. Repetir en las dos fases.
3. Pulsar Q: dash. Pulsar P: selector de Naoya. Regresar conservando recursos; cambiar la tecla desde Controles y comprobar que el HUD la refleja.
4. Abrir Esc y recorrer las cuatro pestañas. Reducir la ventana y llegar por scroll al último control. Cambiar cada NPC y un ajuste de audio/cámara.
5. Grabar unos segundos en Godot4.7.2 para revisar legibilidad sobre el mapa, contraste, tamaño y posibles solapamientos antes de pasar a las animaciones/modelos de0.9.3.
