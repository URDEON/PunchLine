# Estado en 0.9.4

El alien de BASE y sus texturas fueron validados por ti en 0.9.3. No hace falta volver a adjuntarlos. Esta versión integra los archivos de panel, Skull Wisp y Universal Animation Library 2 recibidos.

| Trabajo | Estado |
|---|---|
| Movimiento y transiciones | Mezcla de pose, velocidad, dirección y cadencia implementada |
| Guardia al caminar | Implementada por capas, con piernas en movimiento |
| M1 y patada | Contacto visual ajustado; tercer M1 con hook del pack nuevo |
| Pack UAL2 | Cuatro clips adaptados; hook integrado; originales conservados |
| Fase 2 | Reposo vertical, desplazamiento horizontal y cara hacia delante |
| Fotograma | Panel enviado, shader y captura de pose a textura 2D implementados; duración, restauración y limpieza comprobables sin imagen |
| Dominio | Barrera exterior, suelo circular, límite circular, colisiones y limpieza implementados |
| Kogane | Skull Wisp integrado; mensajes según estados reales |
| Presentación gráfica en Godot 4.7.2 | Pendiente en tu equipo: poses, encuadre 2D, transparencia por ambos lados y dominio |
| Video real | Bloqueado aquí por conexiones locales de Xorg; demo y script de FFmpeg incluidos |

No se incluyen en esta etapa los trabajos que quedaron sin marcar: ragdoll articulado, reemplazo de audio, rediseño completo de arena, más animaciones de habilidades y otra revisión del HUD. Q sigue siendo dash y P selector; la escala del HUD sigue en Esc > Ajustes.

Para revisar esta entrega no necesitas otro modelo ni una suscripción. Extrae en una carpeta nueva e importa `project.godot`. Los botones de fotograma en Esc > Pruebas permiten comprobar el vidrio y la captura en BASE y fase 2. Si aparece un defecto visual, un video corto del movimiento o efecto y el mensaje de error permiten localizarlo.

La solicitud completa se conserva en `REFERENCIA_SOLICITUD_COMPLETA.txt`; documentos anteriores son historial. Ver `CAMBIOS_v0.9.4.md`, `RESULTADOS_v0.9.4.md` y `GRABACION_REAL.md`.
