# Naoya 0.9.1.1 — correcciones tras tus videos

Parche sobre la 0.9.1, conservada en otra carpeta. Los videos enviados muestran la 0.9.1 y fueron grabados por el usuario con Godot 4.7.2. Este parche se ejecutó sin imagen con el Godot 4.4.1 Linux que el usuario había enviado; no se descargó otro motor.

## Habilidad 1

El blanco cercano podía seleccionarse correctamente y, aun así, no recibir daño: la preparación no giraba hacia él, y la aproximación pasaba inmediatamente al rumbo fijo. Además, la influencia de cámara podía apartar la trayectoria al acercarse a blancos laterales.

- La preparación ahora orienta gradualmente al personaje con el mismo límite angular de la aproximación; durante esos 0,12 s no lo adelanta.
- La influencia de cámara disminuye al llegar a la zona de compromiso para encarar el objetivo seleccionado.
- El compromiso sigue durando 0,14 s y mantiene el rumbo fijo. Un dash final todavía puede evitar el contacto.
- Daño, cooldown, hitbox, selección por cono, visibilidad, retención y colisiones conservan sus reglas. No se garantiza daño por seleccionar un blanco.

## Legibilidad

- Estelas solo después de desplazarse al menos 0,40 m y como máximo cada 0,10 s. Evita duplicar siluetas casi inmóviles durante una ráfaga normal.
- Vida de estela 0,28 s, opacidad inicial 0,22 y máximo cuatro; antes: 0,45 s, 0,32 y ocho.
- Reiniciar, reaparecer o interrumpir la presentación limpia las estelas anteriores. La opción de desactivar efectos sigue funcionando.
- Texto de los NPC con tamaño independiente de distancia, fuente 28 y pixel_size 0,001, para evitar el crecimiento extremo junto a la cámara. La apariencia final requiere revisión gráfica en tu equipo.

## Pruebas y demostración

Se añade `qa/video_feedback_test.gd`, con contactos reales en 45 combinaciones de distancia y ángulo, un blanco congelado lateral, evasión final, embestida evolucionada y comportamiento de las estelas. `qa/repetir_pruebas_v0911.py` conserva comandos y registros de importación y suites.

La demo existente agrega el 1 después de un Counter real, con la cámara girada y esperando la recuperación del Counter. `qa/grabar_ffmpeg.py` mantiene la captura gráfica real a 1280×720/30 FPS y ahora usa el nombre `Naoya_v0911_prueba.mp4`.

También se corrige un dato del documento de balance: Counter ya concedía 10 de carga, aunque el texto decía 12.

## Pendiente

El HUD poligonal de tu dibujo sigue reservado para 0.9.2, después de tu revisión del combate. Q continúa como dash y P será el selector de personaje. Nuevos modelos, animaciones, sonidos y ragdoll por huesos siguen pendientes. No se incorporó otro pack en este parche.

La pantalla virtual sigue bloqueada al abrir sus conexiones locales. No se generó un video nuevo del parche, ni se certifica su suavidad gráfica o su sonido mediante pruebas sin imagen. Ver `REVISION_DE_TUS_VIDEOS.md`, `RESULTADOS_v0.9.1.1.md` y `GRABACION_REAL.md`.
