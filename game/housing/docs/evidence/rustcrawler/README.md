# Evidencia de mundo configurable y Rustcrawler

`features.txt` y `frontend.txt` se ejecutaron desde una extracción del ZIP sin caché
`.godot` inicial. El primer importador headless de Godot emitió diagnósticos
`texture_2d_get: Parameter t is null` al guardar materiales con el renderer dummy;
se conserva el log completo. Después de completar la importación, la comprobación
final no emitió esos errores, el juego completó sus recorridos y el modelo se dibujó
con OpenGL. `clean_model.png` corresponde a esa copia extraída.

`graphics.txt` documenta capturas del menú, mecha de rodillas, araña, cámara corporal
con efectos y sin efectos, y camuflaje. La comparación de píxeles congela cámara y
física. Se usa Mesa por software; no se han medido FPS con GPU de escritorio.

`network/host.txt` y `network/client.txt` pertenecen a dos procesos ENet reales;
se prueban también los comandos E del dueño remoto y su rango de cámara. Los avisos
de interpolación proceden de los visuales originales. La vida, posición y acciones
las decide el host; esto no representa una auditoría exhaustiva antitrampas.

Los logs normalizan finales de línea y espacios finales; conservan sus mensajes.
