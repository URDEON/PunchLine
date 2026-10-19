# Evidencia 0.9.29

- `functional_summary.json`: doce suites, 185 comprobaciones aprobadas.
- `network/host.txt` y `client.txt`: dos procesos ENet reales; 39 comprobaciones, ambos códigos 0. Incluyen geometría persistente, entradas remotas y posición de la alarma en el robot.
- `layout_audit.json`: diez semillas/densidades reproducibles y auditadas con Shapely.
- `native_forward_plus.log`: doce capturas con Forward+ / Vulkan y verificación de transformaciones de fractura en el renderer nativo.
- `clean_zip_frontend.log`: 17/17 comprobaciones desde el ZIP extraído e importado sin caché inicial.
- `validation_summary.json`: resumen conjunto.

Los registros conservan una advertencia inicial de Jolt sobre su presupuesto de trabajos al incorporar el distrito. Todas las suites terminan; no hay errores de script ni fallos de las comprobaciones finales. El render usa Mesa/Lavapipe por software y no mide FPS de una GPU de juego.

Las capturas de derrumbe muestran un instante durante la caída; los fragmentos continúan su simulación hasta apoyarse o alcanzar su presupuesto de vida.

La primera importación masiva del ZIP emitió 55 diagnósticos `Parameter t is null` del renderer Dummy al procesar GLB existentes. El runtime limpio de menús y personajes finalizó sin errores.
La segunda importación desde caché terminó sin errores; registro: `clean_zip_reimport.log`.
