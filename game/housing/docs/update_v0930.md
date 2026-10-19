# PunchLine 0.9.30: transiciones de la araña

La araña avanzaba normalmente sobre una pared plana, pero `try_surface` comprobaba
todos los puntos de un arco y aplicaba directamente su pose final en el mismo paso
de física. Eso producía el salto visible al entrar en una pared, doblar una esquina,
subir un saliente o pasar al techo. La cámara también usaba la normal nueva antes
de que el cuerpo terminara de interpolarse.

Ahora se conserva la trayectoria comprobada y se recorre durante varios pasos de
física. El centro de la colisión sigue el arco de separación de la mampostería;
el cuerpo gira mediante cuaterniones y acelera/frena con `smoothstep`. El cálculo
de duración limita el centro a 3 m/s y el giro a 3.6 rad/s incluso en el punto de
mayor velocidad de la curva. La caminata sobre una superficie sigue a 2.4 m/s.
Los bordillos y salientes también se recorren gradualmente.

Cada avance vuelve a comprobar el volumen y su barrido. Si aparece un obstáculo,
se cancela el recorrido conservando la última pose válida. Un salto solicitado
durante el giro queda pendiente hasta terminarlo. Reconexión, muerte y reinicio
descartan el recorrido pendiente. El aterrizaje proyecta el centro sobre el plano
de contacto para evitar el desplazamiento lateral causado por un punto del borde
del cilindro, y deja 2.5 cm de margen físico antes de comenzar el giro.

Primera y tercera persona usan la misma pose interpolada que el cuerpo; el vector
de mirada se transporta a esa orientación sin bloquear la cámara libre. Se
conservan V, rueda, C/clic central, salto y las visiones. Las réplicas online
interpolan los giros entre las actualizaciones de estado del host; posición,
colisiones y decisiones de locomoción siguen siendo autoridad del host.

## Repetir las pruebas

Abrir `game/project.godot` con Godot 4.4.1. Desde la raíz del repositorio:

```sh
python game/qa/v0930/run_checks.py
python game/qa/v0930/run_network.py
```

El primer comando prueba el controlador real en suelo, pared, techo, bordillo,
obstrucción nueva, salto, cámara y tejados de viviendas generadas. Aísla las
preferencias y no modifica pruebas ni evidencia de versiones anteriores. El
segundo usa dos procesos y ENet real, incluyendo el giro visto por la réplica.
Los resultados están en [la evidencia de esta versión](evidence/update_v0930/README.md).
