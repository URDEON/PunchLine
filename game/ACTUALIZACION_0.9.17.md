# PunchLine 0.9.17 — Rendimiento y cabina

La 0.9.16 introdujo un modelo demasiado costoso para la pelea. Esta revisión reduce el coste del Sentinel, conserva su ensamblaje, cañón y articulaciones, y añade primera persona adaptada a cada cuerpo.

## Rendimiento del Sentinel

| Medida del cuerpo visible, con acoples | 0.9.16 | 0.9.17 |
|---|---:|---:|
| Triángulos | 311.792 | 68.524 |
| Superficies visibles | 115 | 35 |
| Materiales distintos | 114 | 3 |

Las cifras incluyen los tres acoples del cañón y excluyen el cañón retraído. El GLB del cuerpo pasa de 311.756 a 68.488 triángulos; el recurso completo del cañón, de 132.826 a 39.818. Se mantienen las 112 piezas del cuerpo y las 31 piezas útiles del cañón.

- Reducción de geometría preparada fuera del juego, con UV y colores conservados.
- Atlas con las texturas a su resolución nativa y margen entre regiones; un material principal por modelo.
- Agrupación de superficies que comparten exactamente el mismo padre rígido y material. Las bisagras, dedos y etapas del cañón mantienen su movimiento independiente.
- Al repetir G se deshace la agrupación y se restauran las piezas para ensamblarlas nuevamente.
- El cañón evita recalcular las transformaciones de todas sus piezas cuando el despliegue no cambia.
- Los originales de Meshy permanecen intactos en el respaldo de fuentes. El personaje continúa articulado por piezas rígidas: no se declara un rig esquelético nuevo.

Estas cifras prueban una reducción de carga. No equivalen a una medida de FPS en la GPU del usuario.

## Cámara y cabina

- V alterna primera/tercera persona. Si V ya tiene una acción personalizada, se conserva esa asignación y puede usarse la rueda. La rueda permite acercarse hasta entrar en primera persona.
- Esc > Ajustes > Distancia: 0 permite guardar primera persona como preferencia.
- En primera persona el cuerpo y los ataques siguen la mira, también con el lock manual desactivado. Online se transmite esa intención al anfitrión, sin que el cliente decida impactos.
- Altura de ojos calculada por cabeza o geometría del personaje. Las cuatro variantes tienen alturas propias; Sentinel mira desde 3,52 m en su cuerpo de 4 m.
- Primera persona disponible en individual y multijugador; no altera la cámara de los otros jugadores.
- Se aparta el cuerpo propio de la cámara mediante capas locales y se restauran al alejarse. En Sentinel permanecen visibles el brazo del cañón y el arma real.
- Cabina original de PunchLine inspirada en la sensación de pilotar un mecha: bastidor 3D, biseles y tornillos, retícula, horizonte, velocidad, integridad y estado real del cañón.
- El bastidor añade una superficie de 72 triángulos. La cabina usa la misma cámara del juego y no renderiza un segundo mundo.
- La cabina se oculta en tercera persona, al cambiar de personaje y durante la cinemática G.

## Multijugador y escudos

- El mundo online utiliza la panorámica Kenney de la mañana que ya tenía el proyecto.
- Los cuatro robots base muestran un escudo frontal al mantener F, ajustado a su tamaño y color. Sentinel conserva su escudo mayor.
- Los invitados ven el bloqueo y el escudo a partir del estado replicado. No se cambia la resolución autoritativa del daño.
- Todos los participantes deben usar 0.9.17.

## Menú

- La galería alterna entre Naoya, Stan, Leela, Mike, George y Sentinel.
- Intercala dos láminas de estudio de los modelos con iluminación cinematográfica, generadas localmente en alta resolución. Son arte del menú; no son capturas de gameplay.
- Fundidos, acercamiento lento, movimiento de cámara y reacción discreta al cursor. Respeta la opción de movimiento de menús.
- Solo mantiene un personaje 3D activo en la galería y limita su render a 30 actualizaciones por segundo; cuando se oculta deja de renderizar.
- Corrección del espacio de la página de controles en ventanas de 360 píxeles de alto.

## Archivos principales

`body_camera.gd`, `mecha_cockpit.gd`, `cockpit_frame.gd`, `rigid_mesh_batch.gd`, `sentinel_articulation.gd`, `robot_skill_vfx.gd`, `menu_portrait.gd`, `network/online_arena.gd` y los dos GLB optimizados.

`qa/optimize_mecha_v0917.py` conserva el procedimiento de atlas y reducción para Blender. `qa/repetir_mechas_v0917.py` y `qa/repetir_pruebas_v0917.py` repiten las pruebas con el Godot que se indique; no descargan motores.
