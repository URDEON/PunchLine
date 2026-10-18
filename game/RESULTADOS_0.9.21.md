# Pruebas PunchLine 0.9.21

## Resultado final

- Regresión general: **1205/1205** comprobaciones.
- Integración de controladores, animación, cámara, daño y réplicas: **523/523**.
- Proyecto editable: **1728/1728** comprobaciones aprobadas.
- PCK exportado de esta entrega: **279/279** comprobaciones aprobadas con Godot Linux.

Los resultados y comandos están en `resultados_v0921_revision`. No equivalen a ejecutar el EXE nativamente en Windows ni a medir una GPU.

## Regresiones reproducidas

El caso nuevo de estabilidad obtuvo **4/9 en 0.9.20** y **9/9 en 0.9.21**. Reprodujo M1 de un brazo perdido, pisotón de una pierna perdida, elección incorrecta de pierna para el sísmico, pasos de pierna destruida y restos que no se eliminaban al reiniciar la transformación. El archivo REPRODUCCION_0.9.20_espera_5_fallos.txt conserva esos cinco fallos esperados; no forma parte del resultado final aprobado.

Las 18 comprobaciones nuevas de réplicas verifican los cuatro chasis, poses finales, una cápsula con identidad estable durante 90 actualizaciones, apagado del láser al morir, duración restante en recepción tardía, colisiones de cadáver y limpieza al cambiar de generación.

## Apoyos de robots base

**45/45** comprobaciones específicas de los cuatro rigs: caminar/correr, consultas de suelo, unión visual del control de pie con la cadena, longitudes, límite de giro, pendiente física, emotes, ragdoll, opción de desactivar y regreso a The Proyected.

El error de longitud máximo medido fue inferior a **0,000006 m** en los cuatro chasis del recorrido integrado. Las correcciones se limitan a **0,24 rad** por articulación. Los controles visuales de pies se mantienen a menos de **0,001 m** del extremo corregido. Máximo de dos rayos por actualización a 20 Hz; el cliente no los duplica.

Se inspeccionaron además cuatro poses técnicas de la geometría deformada a partir de los huesos de Godot, renderizadas en Blender. No son capturas de gameplay ni una ejecución gráfica de Godot.

## Observación de emotes

En el primer ensayo del PCK dos muestras de emotes no observaron avance entre siete pasos físicos bajo carga. AnimationPlayer procesa sus clips en el ciclo de process. La prueba se corrigió para observar ese ciclo, manteniendo los umbrales de avance del clip y deformación ósea, con un plazo máximo de un segundo. La versión final pasó 84/84 sobre el PCK y también 84/84 con el proyecto limitado a 30 FPS de ejecución. No se forzó el avance de animaciones ni se cambiaron los clips para aprobarla.

## Límites

Motor ejecutado: **Godot 4.4.1 Linux** proporcionado por el usuario; se utilizan sus plantillas de Windows ya disponibles. No se descargó otro motor.

El sandbox no permite abrir una pantalla gráfica X11/Wayland ni los puertos TCP locales del editor. La importación/exportación reporta esos errores de sockets de depuración. Las pruebas emplean controladores reales y réplicas en dos mundos locales, sin una conexión WAN. No se eludieron restricciones ni se generó video simulado.

Quedan para prueba manual: calidad visual y sonido finales, FPS/GPU, EXE nativo de Windows, Godot 4.7.2 y una partida entre PC por Internet. Las optimizaciones de recursos físicos se comprueban por su reutilización; no se afirma una cifra de FPS.

## Repetir

```sh
python qa/repetir_pruebas_v0921_revision.py --godot /ruta/Godot --output /ruta/nueva/regresion
python qa/repetir_mechas_v0921_revision.py --godot /ruta/Godot --output /ruta/nueva/integracion
python qa/verificar_exportacion_v0921_revision.py --godot /ruta/Godot --pack /ruta/PunchLine_0.9.21.pck --output /ruta/nueva/exportacion
```
