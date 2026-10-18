# PunchLine 0.9.19 — Cuerpo, mirada, marcha lateral y emotes

Se trabaja sobre la copia íntegra de 0.9.18. Las carpetas 0.9.17 y 0.9.18 se conservan como respaldo. Los modelos y texturas no se han reemplazado.

## Correcciones

- En primera persona, Sentinel conserva pecho, pelvis, ambos brazos, piernas, pies y juntas. Solo se excluyen las piezas de la cabeza de la cámara local. El resto de jugadores conserva su vista completa del robot.
- Los ojos acompañan la bisagra de la cabeza y se adelantan unos 62 cm desde esa bisagra, manteniendo un mínimo de separación frontal al girar para evitar colocar la cámara en la placa del pecho. La cabina y su telemetría siguen disponibles. La altura acompaña el cuerpo y su compresión; no se agranda la hitbox para mover la cámara.
- La cabeza sigue la dirección de la vista en horizontal y vertical, con límites anatómicos. En primera persona/lock, el cuerpo acompaña giros amplios sin tener que girar con cada movimiento pequeño de la vista. El bloqueo y los ataques conservan su orientación de combate.
- La marcha usa la velocidad local real para distinguir avance, retroceso y strafe. Los pasos siguen la dirección recorrida; los brazos balancean lateralmente al desplazarse de lado. La pelvis transfiere apoyo hacia la pierna plantada, con compensación de pecho y aceleración.
- Se aumenta la elevación del pie en vuelo y se impide que su destino cruce al otro lado del cuerpo. El giro de los pies se adapta de forma limitada a la dirección de desplazamiento. Los segmentos rígidos conservan su longitud.
- Los cuatro robots base resuelven los nombres reales de Dance/Hello/Yes/No, activan el AnimationPlayer y detienen su AnimationTree de locomoción. El emote ya no queda sin reproducción al salir de esa mezcla.
- Sentinel tiene baile de acero, saludo de titán y gestos afirmativo/negativo mediante sus piezas rígidas. No se afirma que disponga de un nuevo rig con pesos o clips importados. Los pies conservan apoyo durante esos gestos.
- Movimiento, ataque, dash, bloqueo, aturdimiento, vidrio, caída y muerte cancelan los emotes según corresponda. Los gestos breves terminan automáticamente; el baile se mantiene hasta cancelarse.
- Las réplicas reciben orientación de mirada, apoyos y reloj de emote desde la autoridad. No se añaden consultas físicas de pies a los clientes. La entrada de primera persona online permite el mismo rango vertical de cámara que el modo individual.
- El menú y la telemetría identifican 0.9.19 para distinguir esta compilación del ejecutable 0.9.17.

## Alcance

La nueva marcha y la mirada por piezas pertenecen al Sentinel. Naoya y los robots base conservan sus clips de locomoción y cámaras anteriores; los cuatro robots sí reciben la corrección de emotes.

No se modifican daño, vida, alcance, resistencia de M1, ragdoll, tamaño, armas ni duración de la fusión. Las pruebas de regresión comprueban esos sistemas.

## Probar

1. Verifica que el menú y el HUD indiquen **0.9.19**. Un EXE 0.9.17 no utiliza los scripts que se extraigan junto a él.
2. Individual > P > Robot. Esc > Combate permite preparar la fusión; G activa Sentinel.
3. V entra en primera persona. Mira hacia abajo: comprueba cuerpo y dos brazos. Gira la vista suavemente en reposo y después más de 50 grados.
4. Con cámara al frente y lock/primera persona, mantén A y D. Prueba también S y diagonales. Ctrl cambia a caminar.
5. B abre la rueda sin pausar. Prueba los cuatro gestos en cada robot y en Sentinel. Camina o ataca para cancelar el baile.
6. En online los tres jugadores deben usar **0.9.19**. Comprueba los emotes del invitado y su cabeza desde el otro PC.

Consulta RESULTADOS_0.9.19.md para distinguir las pruebas automáticas de la revisión gráfica que sigue siendo manual.
