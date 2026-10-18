# Pruebas PunchLine 0.9.20

## Proyecto editable

- Regresión general: **1205/1205** comprobaciones aprobadas.
- Integración de controladores, física, HUD, cámara y réplicas: **451/451**.
- Total del proyecto: **1656/1656** comprobaciones locales automatizadas.

Se adaptaron los casos del HUD al nuevo nombre The Proyected y a las cinco categorías de ajustes. Las pruebas detectaron y llevaron a corregir referencias a mallas eliminadas, apoyos demasiado largos, separación insuficiente en pasos laterales, lecturas al retirar una escena y el orden de la lente respecto al HUD. Los registros finales y resúmenes están en `resultados_v0920`.

Las comprobaciones nuevas incluyen 33 de controles, locomoción humana, cámara y pérdida de funciones, 27 de inicio/ajustes/extras y 15 de daño/lock/reaparición del invitado. Se mantienen 84 de cuerpo/emotes/dirección, 34 de terreno y el resto de la regresión.

## Mediciones y alcance

- Error máximo del pie del Sentinel mientras está plantado: **0,00000763 m** en el recorrido automatizado de suelo, pendientes, escalones y plataforma. Incluyendo pies en vuelo: **0,104 m**; se limita el alcance en lugar de estirar las piernas.
- Longitudes de segmentos mecánicos: error inferior a 0,002 m. Pie lateral mantiene separación en los cuatro sentidos comprobados.
- The Proyected: error de apoyo máximo **0,000032 m**, error de longitud de segmento máximo **0,000009 m**, 275 muestras de apoyo observadas después de ejecutar el modificador real del esqueleto.
- Dos rayos de suelo como máximo por actualización de cada planificador local. Los clientes reutilizan apoyos del anfitrión y no hacen las mismas consultas.
- Tres snapshots completos de mechas con cuatro módulos destruidos: **28580 bytes**, por debajo de 64 KiB antes de compresión. La escena de prueba ejecuta autoridad y réplicas en mundos locales.
- Se inspeccionaron poses técnicas exportadas de Godot y renderizadas en Blender, incluida primera persona con cuerpo visible. No son capturas de gameplay ni validación de la lente gráfica.

## PCK exportado

**207/207 comprobaciones aprobadas sobre el PCK de la entrega.** Se cargaron sus recursos reales y se ejecutaron controles/daño/cámara, galería, réplicas, emotes y combate con el motor Linux. Esto no equivale a ejecutar el EXE nativamente en Windows. Registros `exportado_*` y resumen `exportacion.json` en `resultados_v0920`.

## Ejecución

Motor utilizado: **Godot 4.4.1 Linux** proporcionado por el usuario. Se exporta con sus plantillas de Windows disponibles. El nombre interno Naoya se conserva para migrar preferencias; el personaje visible se llama The Proyected.

No hay pantalla X11/Wayland accesible en el sandbox y la apertura de sockets locales del editor está restringida. La importación/exportación reporta errores de puertos de depuración TCP; las pruebas de controladores y el empaquetado se ejecutan. No se eludieron las restricciones.

No se ejecutó el EXE nativamente en Windows, ni se midieron GPU/FPS o una conexión WAN. Apariencia final, rendimiento y uso en Godot 4.7.2 requieren prueba manual. Los videos incluidos en Extras son grabaciones históricas de 0.9.14 y 0.9.8, etiquetadas como tales.

## Repetir

```sh
python qa/repetir_pruebas_v0920.py --godot /ruta/Godot --output /ruta/nueva/regresion
python qa/repetir_mechas_v0920.py --godot /ruta/Godot --output /ruta/nueva/integracion
python qa/verificar_exportacion_v0920.py --godot /ruta/Godot --pack /ruta/PunchLine_0.9.20.pck --output /ruta/nueva/exportacion
```
