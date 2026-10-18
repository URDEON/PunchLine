# Naoya 0.9.2 — HUD del boceto

Nueva copia sobre 0.9.1.1, cuyo combate el usuario confirmó que funciona correctamente. La versión anterior se conserva. Se prioriza la geometría del dibujo recibido y se respeta la última asignación: **Q dash, P selector de personaje**.

## HUD

- Retrato circular de Kogane con antenas, ojos, alas y base ornamental. P abre Personaje; el retrato también permite abrirlo mediante clic cuando el cursor está disponible.
- Cuatro iconos circulares superiores: caída/recuperación, velocidad, forma y guardia. Sus indicadores responden a estados reales; la pestaña Controles explica sus significados.
- Salud en tres segmentos inclinados de 50/30/20 HP, consumidos desde la derecha. Cada segmento vacío pierde el color de relleno y muestra una fractura; el número de vida sigue visible. La transición del relleno se suaviza, mientras la marca de segmento vacío responde al valor real.
- Energía/tiempo de forma, evolución y tecla de transformación integrados al grupo superior.
- Cuatro polígonos distintos conectados con separadores: Proyección arriba, Counter a la izquierda, Golpe veloz en la pieza central inferior y Patada a la derecha. Se preserva la silueta al escalar uniformemente el conjunto; no se convierte en una cuadrícula.
- Figuras sencillas trazadas a mano mediante vectores: desplazamiento entre paneles, rival dentro de un frame, golpe con líneas de velocidad y pose de patada. No se usan ilustraciones generativas.
- Azul en la cabecera durante cooldown; nombre, dibujo, tecla y segundos permanecen visibles. El borde dorado identifica ejecución. Fase1 y Fase2 cambian nombres, dibujos, bloqueos y señales del dominio conforme a sus reglas reales.
- La ayuda y las esquinas muestran las teclas actuales después de reasignarlas. Las teclas largas se abrevian en la esquina; su nombre completo permanece en la ayuda emergente y en Controles.

## Menú y personaje

P abre/cierra la pestaña Personaje. Solo Naoya aparece como jugable. Elegirlo vuelve al combate conservando vida, cargas, forma y cooldowns; no simula cambiar a personajes que todavía no existen.

Esc abre Pruebas; el menú contiene Personaje, Pruebas, Ajustes y Controles. Pausa simulación y animaciones. En ventanas estrechas las pestañas forman dos filas; el contenido se desplaza verticalmente y los botones de regreso permanecen visibles. Se conservan los tres selectores independientes de NPC, preparación de fases, ajustes de audio/cámara/imagen y reasignación de teclas.

Si una configuración antigua usaba P para otra acción y aún no incluía Personaje, se evita que P active ambas: la otra acción recupera su tecla original si está disponible, o una alternativa libre. Controles avisa de la migración. Se conservan los valores de audio y demás ajustes. Las configuraciones que ya incluyen Personaje conservan esa asignación personalizada.

## Verificación y límites

323 comprobaciones aprobadas, incluidas 96 específicas del HUD, más 9/9 casos de combate y 7/7 de la demo del HUD. Motor utilizado: el Godot 4.4.1 Linux previamente enviado por el usuario. El usuario utiliza 4.7.2; esta entrega no se ejecutó con ese motor.

Se exportaron e inspeccionaron vistas vectoriales estáticas de los mismos comandos de dibujo, posiciones y etiquetas del Control. Ayudan a revisar composición y separadores; **no son screenshots de Godot ni gameplay**. Su tipografía puede diferir del renderer real. Están en `qa/vistas_hud/`.

La pantalla virtual sigue bloqueada al abrir listeners locales; no se generó un MP4. `qa/grabar_ffmpeg.py` y `qa/hud_demo.gd` están preparados para grabar la prueba real cuando haya pantalla permitida. Hace falta comprobar el HUD sobre el escenario y su legibilidad con gráficos en el equipo del usuario. Ver `RESULTADOS_v0.9.2.md` y `GRABACION_REAL.md`.

No se alteran las reglas del combate validado. Modelos, nuevos clips, mezcla de guardia/caminata, ragdoll articulado, audio nuevo, captura plana de pose dentro del mundo, dominio y mapa siguen en las etapas posteriores.
