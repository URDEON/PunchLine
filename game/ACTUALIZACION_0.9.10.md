# Naoya 0.9.10 — PunchLine y robots conectados

La revisión corrige los robots que miraban en sentido contrario al movimiento, la separación de piernas y pies en ragdoll y la recuperación del torso. El mapa PunchLine v5.4 adjuntado sustituye al distrito como escenario predeterminado. Se conserva Naoya 0.9.9 como respaldo intacto.

## Robots

La orientación visual gira 180° para alinear el frente real del modelo con la dirección del controlador. También se corrigieron el retrato y el preview de emotes. El retrato ahora respeta el tamaño del círculo y no se desborda.

Se usan las animaciones originales del Animated Mech Pack, sin retargeting ni cambios de pesos. Idle, caminar y correr se mezclan gradualmente en un AnimationTree por modelo; se ajusta la cadencia al desplazamiento. Leela y George utilizan Walk_Tall/Run_Tall; Stan y Mike Walk/Run. El Robot corre a 6 m/s antes del modificador de chasis y camina con Ctrl a 2,4 m/s antes de ese modificador. La velocidad de Naoya se conserva.

| Chasis | Habilidad 1 | Habilidad 2 |
| --- | --- | --- |
| Leela | Kick con arco de barrido del cuerpo | Jump seguido de Kick ascendente |
| Stan | Preparación con Pickup y liberación de Punch | SwordSlash sin arma, como martillazo descendente |
| George | Dos ciclos de Punch con dos contactos | Run_Holding de aproximación seguido de Punch |
| Mike | Guardia derivada de Idle y brazos de Walk_Holding | Preparación con HitRecieve_2 y Punch al acertar el counter |

Estas son secuencias y adaptaciones de los clips del pack; no se atribuyen nombres inventados al archivo original. Los puntos de contacto se ajustan a las fases de cada acción. La tercera habilidad y los huecos deshabilitados conservan su función.

## Ragdoll

El hueso común de torso y piernas es **Body**. Usar Torso como raíz dejaba las caderas sin una restricción al cuerpo. Ahora el grafo físico incluye Body y todas las piernas.

Foot.L/R son controles separados del Body. En Leela y George deforman 238 influencias de vértices cada uno; en Stan y Mike no tienen pesos. Solo se simulan los pies que deforman la malla, unidos explícitamente a LowerLeg. Sus controles visuales siguen el final de la cadena de la pierna sin alterar el rig original. La recuperación mezcla también Body y los pies, evitando dejar el torso girado.

Hay 14 cuerpos físicos en Leela, 12 en Stan, 18 en George y 12 en Mike, con una restricción menos que cuerpos y sin miembros físicos desconectados. Se conservan los 17/43/47/43 huesos y los pesos originales.

## Mapa y apariciones

- PunchLine de 240 × 240 m conserva grupos editables, modelos, BIN y texturas del ZIP.
- Colisiones de triángulos en terreno, edificios y mobiliario: respetan huecos e interiores y no convierten un edificio entero en una caja sólida.
- Dos Marker3D del jugador alrededor de la plaza: aproximadamente (-47, -12) y (47, 12) en el plano X/Z. En cada reaparición se escoge uno aleatoriamente, se comprueba el suelo excluyendo a los actores y se orienta la cámara hacia la plaza.
- Los tres enemigos reaparecen dentro de la zona de combate, con posiciones adaptadas y sin perder sus apariencias ni modos de entrenamiento.
- Materiales con mipmaps y filtrado para reducir el parpadeo a distancia. El suelo no proyecta sombras sobre sí mismo; recibe las de personajes y edificios.
- Se conservan ejercicios E, iluminación, vidrios de práctica y Eco. El Eco del mapa nuevo tiene recorrido y archivo de récord propios.
- Esc > Explorar permite abrir el laboratorio anterior y volver a PunchLine. Ascensor, foso y plataformas históricas siguen disponibles en ese laboratorio.

El README del mapa original indica que faltan escaleras para acceder a todos los pisos. Esta actualización integra el mapa y sus colisiones; no presenta esos accesos pendientes como terminados.

## Interfaz y controles

B abre una rueda de emotes **sin pausar el juego**. El cursor se libera, el movimiento con teclado sigue disponible y los enemigos continúan actuando. El selector no concede invulnerabilidad: recibir un golpe lo cierra. Los clics de selección no disparan M1 al cerrarse.

P y el triángulo dorado mantienen el selector de personaje con una apertura de 0,22 s y cierre de 0,14 s mediante desplazamiento, escala y opacidad. La pausa se conserva hasta terminar de cerrar. Q sigue siendo dash.

## Verificación y límites

Consulta RESULTADOS_0.9.10.md y PRUEBA_MANUAL_0.9.10.md para los resultados finales. Se utiliza exclusivamente el Godot 4.4.1 Linux que adjuntaste. Se tomaron capturas del juego real en una pantalla virtual para revisar orientación, física y recuperación. Las acciones fueron automatizadas; no se generó un video ni una animación que imitara gameplay.

Godot 4.7.2 Windows, sensación con control manual y rendimiento en hardware del usuario siguen pendientes. No hacen falta más modelos, un nuevo rig ni una suscripción para probar estas correcciones.
