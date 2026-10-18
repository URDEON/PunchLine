# Naoya 0.9.1 — combate y progresión

Primera entrega incremental desde `Naoya_0.9_IMPORTAR_GODOT.zip`. La base permanece intacta. Se usa el Godot 4.4.1 Linux x86_64 entregado por el usuario. Esta versión corrige reglas de combate; el rediseño grande del HUD corresponde a 0.9.2, después del feedback.

## Cambios implementados

- Habilidad 1 humana y embestida evolucionada seleccionan automáticamente un enemigo por dirección horizontal de cámara, ángulo, alcance y línea de visión. No necesitan clic de rueda ni fijación manual. Priorizan el centro de cámara.
- Aproximación con velocidad progresiva, predicción breve de velocidad del blanco, giro limitado e influencia de cámara. Al perderlo conservan el rumbo sin cambiar instantáneamente de objetivo. Sin blanco avanzan según cámara.
- Compromiso final de 140 ms con dirección fija y contacto comprobado contra posición real. El dash del evasor esquiva por desplazamiento; no se añade invulnerabilidad. No se adquiere de nuevo al blanco durante esa activación.
- Variante humana cercana desde 2,2 m: exige conectar primero; retiene brevemente al blanco, sigue una trayectoria circular mediante velocidad y colisiones, reproduce golpes separados y termina en derribo. Daño total inicial 18, igual que la variante normal. El remate corta la órbita: no se promete una vuelta exacta de 360°.
- Ráfaga con clips existentes separados, anticipación de 45 ms e intervalos de 120 ms. Se fuerza el reinicio de cada golpe y se corrige la conexión de las estelas con los nuevos estados. Contactos llaman al feedback existente; no se incorporó un nuevo pack de audio.
- Cámara de seguimiento con una sola interpolación: ya seguía la posición interpolada del jugador en `_process`, pero heredaba además la interpolación física. La ejecución de la demo en tiempo real detectó esa advertencia; se corrige la configuración de cámara sin quitar interpolación a los actores. Su suavidad percibida sigue pendiente de revisión gráfica.
- Paredes físicas de prueba y consultas de visibilidad evitan selección o daño a través de geometría. Cancelar, morir, reiniciar o perder contacto libera la retención.
- Counter pasa de 14 a 8 de daño, cooldown de 8 a 11 s y detención de 0,85 a 5 s. Se limpian efectos al finalizar/reiniciar/morir y se restablece la animación.
- M1 no daña NPC derribados ni durante los 0,35 s iniciales de recuperación. Se conservan cuarto golpe normal, uppercut y downslam. El combo normal baja de 33 a 23.
- Menos daño en las habilidades y ataques del NPC. Valores y parámetros de guiado accesibles como Resource exportado en `balance_v091.tres`.
- Morir en BASE con ultimate completa renace en FORM1 con 60 HP, energía consumida y evolución en cero. FORM2 requiere FORM1 y su propia carga completa. Morir transformado termina la forma. Solo el laboratorio puede preparar FORM2 directamente.
- Cada uno de los tres NPC tiene su selector independiente: quieto, bloqueador, perseguidor, atacante estacionario y evasor final. El atacante estacionario golpea a alcance sin perseguir; el evasor usa un dash real durante el compromiso.
- Se mantiene Q para dash. **P será selector de personaje**, según la última instrucción del usuario, que reemplaza Q en la referencia antigua. No hay otros personajes jugables nuevos en esta entrega.
- ZIP con `project.godot` en raíz y entradas explícitas de carpetas, conservando la corrección del fallo de extracción anterior.

## Pruebas y límites

167 comprobaciones automatizadas aprobadas, más 8/8 casos de demostración sobre el juego real, sin imagen. Se conservaron suites anteriores y se añadió `qa/revision_test.gd`. Los resultados y comandos están en `RESULTADOS_v0.9.1.md` y `qa/resultados_v091/`.

La captura con Xorg y FFmpeg se intentó. El entorno bloquea la apertura de sockets locales; no hay MP4, revisión de fotogramas ni escucha de audio. Estas pruebas no certifican calidad visual, suavidad percibida ni rendimiento gráfico.

Todavía pendientes: HUD poligonal del dibujo; captura plana 2D de las poses (el Counter conserva el modelo 3D detrás del frame); modelos nuevos con cara; guardia mezclada con piernas; ragdoll articulado; nuevos sonidos; remodelación circular del dominio y mapa completo. No se presentan como terminados. Ver `REVISION_Y_PLAN.md`.

## Comprobar y dar feedback

1. Extraer en una carpeta nueva, importar `project.godot` y ejecutar F5. No combinar archivos con otra versión.
2. En Esc → Pruebas elegir un NPC quieto. Sin fijación de rueda, apuntar aproximadamente hacia él y pulsar 1 desde 6–10 m. Debe conectar 18 y recuperar el control. Probar también sin ningún blanco.
3. Elegir ESQUIVA FINAL y repetir. El NPC debe desplazarse lateralmente justo antes del contacto y recibir cero daño. Frente a una pared, la habilidad debe detenerse y no conectar detrás de ella.
4. Desde aproximadamente 1,8 m sobre un quieto, pulsar 1: observar el recorrido alrededor y los golpes separados. Comprobar que no atraviesa paredes ni deja al NPC retenido al finalizar o pulsar R.
5. Elegir ATACANTE ESTACIONARIO, acercarse a menos de 1,9 m y activar 2 antes de su golpe. Al acertar Counter, el texto del frame cuenta 5 s y el NPC reanuda su animación. Su representación aún no es plana.
6. Hacer cuatro M1 sobre quieto: daño 23 con derribo. Pulsar M1 cuando esté tumbado: debe ignorarlo; después de levantarse y terminar su protección vuelve a poder ser golpeado. Probar también uppercut y downslam.
7. Preparar energía completa en Pruebas, regresar a BASE y recibir daño letal: debe comenzar FORM1, nunca FORM2. FORM2 solo se obtiene al completar evolución en FORM1 y pulsar G.

Enviar capturas o video del 1 a distancia y cercano, esquiva final, Counter y recuperación. Antes de 0.9.2 necesitamos comprobar cómo se leen y sienten esas situaciones en una ejecución gráfica real; el balance queda abierto a ese feedback.
