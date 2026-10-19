# Evidencia 0.9.30

Godot 4.4.1, controlador real del juego y preferencias aisladas.

- `surface_motion_test.log`: 18/18. Suelo → pared → techo en 78 pasos de
  transición; avance máximo de 4.0 cm y giro máximo de 3.44° por paso a 60 Hz.
  Cámara corporal: máximo 4.1 cm; órbita de 3 m: máximo 30.8 cm durante la
  retracción, anticipando la esquina. Se comprueban volúmenes de armadura y cámara,
  bordillo, salto pendiente, obstáculo sobrevenido y reconexión.
- `camera_jump_test.log`: 26/26. Cámara libre, primera/tercera persona, rueda,
  colisiones de cámara, salto desde suelo/pared/techo, aterrizaje invertido y retorno.
- `camera_audio_test.log`: 10/10. Pasos por contacto, trípodes, segmentos rígidos,
  ajuste de armadura a colisión y seguimiento de la pose interpolada.
- `feature_test.log`: 30/30. Semillas, fusión, habilidades, colisión durante la
  subida completa al tejado de una vivienda generada y muerte/reaparición.
- `network/host.txt` y `network/client.txt`: 43/43, dos procesos ENet reales,
  códigos de salida 0. Incluye giro continuo observado por la réplica, controles
  remotos, visiones, salto, reconexión, destrucción, escombros y autodestrucción.

Los límites de movimiento son comprobaciones de continuidad, no mediciones de FPS.
La advertencia inicial de presupuesto de trabajos de Jolt al incorporar el distrito
y avisos existentes de interpolación del mecha en retratos online se registran en
los logs. No hubo errores persistentes de script o recursos en las suites aprobadas.
