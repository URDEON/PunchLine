# Pruebas de locomoción 0.9.18

- Regresión general: **1205/1205**.
- Integración y regresión de mechas, HUD, cámaras y controladores locales: **262/262**.
- Total: **1468/1468** comprobaciones locales automatizadas, incluida la validación del tamaño y posición de las juntas interiores.

Dentro de la integración hay **34 pruebas específicas de locomoción** y **9 de réplicas**. Se comprueban reposo sin pasos falsos, caminar/correr, laterales, retroceso, frenada, giros, pendientes, escalones, plataforma móvil, pared, despegue/aterrizaje, cañón, opción A/B, longitud constante de segmentos y primera persona.

Error máximo medido del pie apoyado respecto de su objetivo: **0,0423 m** en la prueba de un cuerpo de 4 m. El máximo también contando pies en vuelo fue **0,0898 m**; los objetivos se limitan al alcance de las piernas. No se ocultan esos casos como una precisión perfecta.

Presupuesto observado: **máximo 2 rayos por actualización**. El cliente de la prueba replica los apoyos sin realizar rayos. Tres estados completos caben dentro del límite de 64 KiB anterior a compresión.

Las seis juntas interiores añaden **1.008 triángulos y una superficie** compartida. Los archivos de los modelos optimizados son idénticos a 0.9.17.

La sonda de animación aislada obtuvo medianas de **0,076–0,091 ms** con la función activada en este entorno. La carga concurrente puede alterar el resultado; es CPU sin imagen, no FPS gráficos. El registro y el programa para repetirla se incluyen en el proyecto.

## Alcance y límites

Se ejecutó Godot 4.4.1 Linux del usuario. Las pruebas utilizan física y controladores reales mediante acciones automatizadas. No hay pantalla X11/Wayland accesible, por lo que no se ha visto una partida gráfica ni se ha grabado video. Se revisaron poses técnicas exportadas del juego en Blender; esos renders no se presentan como gameplay.

No se afirma validación visual definitiva, medición de GPU, ejecución nativa de Windows/Godot 4.7.2 ni prueba WAN entre PC. La lista manual permite comparar la marcha con la opción desactivada.

El experimento se aplica a Sentinel. Adaptar el sistema a Naoya y a los robots base requiere trabajar con sus esqueletos y clips, sin sustituirlos de forma indiscriminada.

## Repetir

```sh
python qa/repetir_pruebas_v0918.py --godot /ruta/Godot --output /ruta/nueva/regresion
python qa/repetir_mechas_v0918.py --godot /ruta/Godot --output /ruta/nueva/integracion
Godot --headless --path . --script res://qa/locomotion_profile_v0918.gd
Godot --headless --path . --script res://qa/joint_caps_v0918_test.gd
```
