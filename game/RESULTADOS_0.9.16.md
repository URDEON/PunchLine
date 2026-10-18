# Pruebas de PunchLine 0.9.16

Motor utilizado: **Godot 4.4.1 Linux suministrado previamente por el usuario**. No se descargó otro editor. Renderizador del proyecto: Compatibility. Ejecución de las comprobaciones: headless, con física real y controladores del juego.

## Resultado funcional

| Grupo | Aprobadas |
|---|---:|
| Regresiones anteriores: combate, cristales, audio, HUD, controles, ragdoll, modelos, mapa y demostraciones de laboratorio | 1205/1205 |
| Menú principal y sus tamaños | 30/30 |
| Interfaz online | 16/16 |
| Controladores online, habilidades y cristalización | 28/28 |
| HUD holográfico, valores y cambio de identidad | 16/16 |
| Junkyard, Rustwing, ragdolls base, cañón mantenido, disparos, cuerpos caídos, vidrio, escudo, dash y muerte | 48/48 |
| Invitado, emotes, carga/soltado, réplica de cañón y muerte en otro World3D | 14/14 |
| Escalones: 14/30/40 cm, personaje normal y mega, techo y pared alta | 9/9 |
| Salida individual/online, reinicio de G y retorno desde las dos demos | 7/7 |
| **Total final local** | **1373/1373** |

Se corrigieron los errores detectados durante la iteración y se repitieron los casos afectados. `resultados_v0916/regresion_final.json` identifica los rechecks; los registros finales se conservan al lado. Las suites históricas específicas de las antiguas 22 piezas de Rust Vanguard se sustituyen para esta versión por las comprobaciones de las 112 piezas de Junkyard y las 31 útiles del Rustwing.

La demo V8 original adjunta también se ejecutó antes de adaptarla: 112 mallas Junkyard, 31 componentes útiles del cañón, error de anclaje de muñeca cero y eje del cañón alineado con el antebrazo. Los hashes de `modelos_originales.json` confirman que los dos GLB entregados no fueron alterados.

## Qué significa la prueba online

Los actores, sus entradas, el estado del anfitrión y una réplica en un World3D separado ejecutan código real. Se verifica que el jugador 2 inicia su propio emote, que el anfitrión controla daño/carga y que las poses/recargas se aplican al cliente. **No se comprobó una conexión por Internet ni tres equipos físicos**. Todos necesitan el protocolo de 0.9.16.

## Ejecución gráfica

La apertura real con `DISPLAY=:115` falló con `X11 Display is not available`; el intento de Wayland tampoco dispone de pantalla accesible. No hubo revisión visual en partida ni video. Las miniaturas del HUD son arte de interfaz renderizado en Blender con los modelos/poses originales, no evidencia de gameplay. La importación/exportación headless puede registrar el fallo de sus servidores TCP del editor (`_sock == -1`) por las restricciones del entorno; los registros finales de pruebas funcionales no contienen errores de GDScript.

No se ejecutó Windows nativo ni Godot 4.7.2. Deben comprobarse manualmente en tu equipo: alineación visual final, transparencias, humo/propulsores, calidad de las nuevas imágenes y FPS con tres fusiones.

## Repetir

Desde la carpeta del proyecto, indicando la ruta de tu Godot:

```sh
python qa/repetir_pruebas_v0916.py --godot /ruta/a/Godot --output /ruta/nueva/regresion
python qa/repetir_mechas_v0916.py --godot /ruta/a/Godot --output /ruta/nueva/mechas
Godot --headless --path . --max-fps 60 --script res://qa/navigation_v0916_test.gd
```

Los scripts preparan posiciones/energía de laboratorio y automatizan entradas para verificar las mecánicas. No sustituyen el daño o la física por resultados fingidos. La lista manual está en `qa/mechas/PRUEBA_MANUAL_0.9.16.md`.

## Paquete exportado

Exportación Windows x86_64 generada con las plantillas 4.4.1 ya disponibles. Su PCK se cargó mediante el ejecutable Linux 4.4.1 y pasó **85/85** comprobaciones: combate 48, réplica online 14, navegación 7 y HUD holográfico 16. Esto verifica los recursos y scripts exportados; no equivale a ejecutar el EXE en Windows. Registros y comandos en `resultados_v0916/paquete_exportado.json`.

