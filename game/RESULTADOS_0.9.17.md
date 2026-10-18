# Pruebas de PunchLine 0.9.17

Se utilizó el Godot 4.4.1 Linux que ya estaba en el entorno. No se descargó otro motor.

- Regresión general: **1205/1205** comprobaciones.
- Integración: **219/219**, incluidas 39 de esta revisión y 12 de skybox, escudos y cámara online.
- Total local: **1424/1424**.
- Adicionalmente, **74/74** comprobaciones cargando el PCK exportado con el motor Linux: cámara/cabina, red local, navegación y HUD. Esto no equivale a ejecutar el EXE en Windows.

Las pruebas ejecutan escenas, física y controladores reales mediante scripts automatizados, sin render gráfico. Incluyen montaje de 112 piezas, cañón mantenido/disparo, vidrio sobre el mecha, muerte con desarme, dash/aterrizaje, recuperación ragdoll, escalones, menús, HUD y réplicas locales de jugadores. La prueba específica añade las cuatro alturas de cámara, restauración de capas, bastidor de cabina de una superficie, galería y reducción de superficies/materiales.

## Carga geométrica comprobada

Cuerpo visible: 311.792 → 68.524 triángulos; 115 → 35 superficies; 114 → 3 materiales, contando los acoples. Se verificaron colores y silueta del recurso con renders de comparación en Blender CPU. Las láminas del menú también se renderizaron desde los modelos. Ninguna de esas imágenes representa una partida.

Los registros `carga_v0916.log` y `carga_v0917.log` contienen una sonda CPU del reposo y recuentos de geometría. Se ejecutaron sin imagen y con otras tareas activas; sus tiempos son orientativos y **no son medidas de FPS de GPU**.

## Límites de la verificación

No hay una pantalla gráfica accesible en este entorno (X11/Wayland). No se revisó una partida gráfica ni se grabó video. No se ejecutó el EXE en Windows/Godot 4.7.2 ni una conexión WAN entre tres PC. Estas comprobaciones quedan en `qa/PRUEBA_MANUAL_0.9.17.md`.

Los avisos de sockets del editor durante la importación corresponden a su servidor de depuración bloqueado por el sandbox. Los registros finales de las pruebas funcionales no tienen errores GDScript.

## Repetir

```sh
python qa/repetir_pruebas_v0917.py --godot /ruta/a/Godot --output /ruta/nueva/regresion
python qa/repetir_mechas_v0917.py --godot /ruta/a/Godot --output /ruta/nueva/integracion
```

No modificar las mecánicas para simular un resultado. Para comparar FPS, seguir la lista manual con la misma resolución y calidad usadas en 0.9.16.
