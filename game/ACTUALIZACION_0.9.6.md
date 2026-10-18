# Naoya 0.9.6 — cuerpo unido, terreno y eco de ruta

Parte de la 0.9.5 entregada. La carpeta de esa versión se conserva intacta como respaldo. Se reutilizan los rigs y recursos actuales; no se borran huesos ni pesos del personaje.

## Correcciones principales

- **Ragdoll:** el controlador físico conserva las traslaciones de reposo y las longitudes de todos los huesos visuales. La pelvis desplaza el cuerpo y las extremidades reciben rotaciones físicas. Las anclas se reconstruyen desde la postura del impacto. Se elimina el escalado del rig del enemigo durante el destello de daño. La recuperación busca el suelo real, también sobre plataformas elevadas.
- **Fase 2:** revisión del recurso en Blender identificó la cabeza en **-Z**, y la cola en +Z. Reposo vertical, cabeza arriba y cara hacia delante. Al desplazarse, cabeza hacia el avance y torso hacia el suelo, con transición suave. Se corrige exclusivamente el nodo visual, conservando controlador, colisión y cámara.
- **Habilidad 1:** un solo vidrio por delante del jugador; sigue posición, altura y dirección durante la acción y se libera al terminar. Daño, fijación de objetivo y compromiso del golpe conservados.
- La cristalización de víctimas conserva frente/espalda independientes, rotura de un golpe válido, recuperación 3D y cinco segundos sin impacto.

## Mapa y movimiento

- Rampa transitable, azotea, plataformas de salto, foso real de seis metros con salida y ascensor físico hasta otra azotea.
- El suelo y su colisión comparten el hueco del foso; los obstáculos nuevos tienen colisión.
- Ctrl mantenido permite caminar; al soltarlo se recupera la carrera. Se mantiene Q para dash y P para personajes.
- Cámara ajustable de 2 a 10 metros con la rueda o el menú. Se conserva la detección de obstáculos.
- Salto con tres clips UAL2 retargeteados: despegue, vuelo y aterrizaje. Caída prolongada real mantiene `Falling` después de cuatro segundos descendiendo.
- Menú Explorar permite preparar pruebas de rampas, ascensor, foso y caída desde 220 metros. Estos preparativos son explícitos y no forman parte del combate normal.

## Emotes, Kogane y presentación

- B abre un selector radial; se elige con clic o teclas 1–6. Esc/B cierra el selector. Se pausa el juego mientras se elige.
- Running Man, variante de ritmo, gesto Sí, gesto No, brazos cruzados y llamada. Se reutiliza el baile recibido y cuatro clips reales de UAL2; no se inventan bailes adicionales. Movimiento, daño o habilidades cancelan el emote.
- Kogane entra mediante una vuelta juguetona alrededor del jugador y se coloca a su lado. Se retira encogiéndose hacia el jugador con un pequeño humo blanco y sonido.
- Comentarios burlones reaccionan a ataques del rival, dash, golpes recibidos, ataques bloqueados, proyección fallida, counters, vida baja y récord de recorrido. Se limitan repeticiones y pueden desactivarse.
- Interior del dominio con 24 paneles de proyección, numeración, reloj radial, coronas suspendidas, iluminación y ambiente sonoro. Las reglas de daño del dominio se conservan; F8 sigue permitiendo verlo por fuera.
- Menú de pausa con identidad de proyección, fondo de paneles inclinados, acento dorado, contexto del personaje y pestañas Personaje, Combate, Explorar, Ajustes y Controles. Distribución compacta para pantallas pequeñas.

## Función nueva: Eco de ruta

Desafío de seis puntos que cruza rampa, azotea, saltos y foso. Cronometra el movimiento real y guarda el mejor recorrido junto con las poses del rig, a 12 muestras por segundo. En el intento siguiente aparece un eco transparente de esa ruta para competir contra ella.

El eco usa el mismo modelo, reproduce los huesos registrados y no tiene daño ni colisión. El récord se guarda localmente y puede borrarse desde Explorar. La ruta dura como máximo 120 segundos, limitando memoria y datos. Las pruebas del final de recorrido preparan posiciones explícitamente para comprobar los sensores; esa prueba no se presenta como vídeo de gameplay.

## Audio y recursos

Se conservan los impactos, pasos y efectos Kenney CC0 ya incluidos, con variación de tono y cadencia de pasos según caminar/correr. Se añaden sonidos originales para interfaz, salto, Kogane, puntos del recorrido y ambiente del dominio. El baile utiliza un ritmo original generado reproduciblemente; el MP3 comercial anterior se conserva como recurso histórico y no se reproduce.

`tools/build_audio_v096.py` reproduce los nueve recursos originales. `tools/retarget_extras_v096.gd` reproduce las siete adaptaciones nuevas sin root motion de salto. Licencias y procedencias están en `licenses/`.

Los ZIP/RAR de audio adjuntos exceden el límite de transferencia de 32 MiB del entorno y no se importaron. Se solicitaron enlaces de Drive para continuar su selección. El torrent contiene metadatos de 663 archivos y aproximadamente 10,27 GB; no contiene los sonidos en sí y no se descargó el paquete completo.

## Verificación y límites

Resultados exactos y comandos: `RESULTADOS_0.9.6.md`, `resultados_v096/` y `qa/repetir_pruebas_v096.py`. Motor utilizado: el Godot **4.4.1** adjuntado por el usuario, sin descargar otro. Godot **4.7.2** de Windows no está disponible en este entorno.

Las pruebas de combate y física ejecutan Godot real en modo headless. Los renders del recurso de fase 2 se hicieron con Blender y **no son capturas del juego**. La ejecución con imagen está bloqueada porque Xorg no puede abrir sockets locales. No hay MP4 real de esta versión. La demostración y los comandos de FFmpeg quedan preparados en `qa/v096_demo.gd`, `qa/grabar_ffmpeg.py` y `GRABACION_REAL.md`.

El ragdoll físico se aplica al humano y enemigos Y2K. Las formas malditas conservan sus derribos existentes; no se declara un ragdoll físico nuevo para ellas. Sigue pendiente comprobar visualmente la sesión completa con renderizador, capturas 2D del vidrio, nuevos clips y HUD en el equipo del usuario.
