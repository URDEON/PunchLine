# Naoya 0.9.7 — Estación 24 y revisión del ragdoll

Actualización sobre la 0.9.6 disponible en el entorno. La carpeta original se conservó por separado. Se mantiene el alien que aprobaste, su rig de 53 huesos, sus pesos, el combate y los recursos originales. El proyecto continúa siendo un laboratorio de combate, con herramientas para comprobar las mecánicas.

## Ragdoll

- Corregidos los límites angulares: las propiedades de PhysicalBone3D recibían radianes donde Godot esperaba grados.
- Anclajes calculados en la pose real del impacto, incluyendo los huesos auxiliares que no tienen cuerpo físico. Se usan 13 cuerpos, cuatro articulaciones Hinge para codos/rodillas y ocho ConeTwist para el resto.
- Seleccionado explícitamente Jolt Physics, incluido en el Godot 4.4.1 adjuntado. El montaje anterior se volvía inestable con GodotPhysics3D en algunas poses; la misma prueba con Jolt mantuvo velocidades físicas acotadas.
- CCD en los cuerpos, escala física en metros, longitudes visuales originales, rotaciones anatómicas limitadas y corrección de contacto visual con el suelo. No se borran huesos ni se recalculan los pesos del modelo.
- Se coordina la pausa de animaciones con la física y la recuperación. La interpolación del nodo visual se desactiva durante el ragdoll para evitar combinar transformaciones incompatibles.
- Aplica al humano y a los bandidos ya riggeados. Las formas de maldición conservan su derribo anterior.

La validación ahora analiza también los vértices deformados y los triángulos del personaje. Esto detecta estiramientos que una prueba de longitudes de huesos podía pasar por alto. No sustituye una revisión gráfica completa en tu Godot 4.7.2.

## Proyección: habilidad 1

- Exactamente dos fotogramas delanteros a 1,9 y 3,15 metros, actualizados con la posición y dirección del jugador.
- Cada fotograma contiene una silueta plana obtenida de la pose actual del rig, sin duplicar personajes 3D ni crear colisiones nuevas.
- Rastro breve: máximo cuatro fotogramas, separados por distancia y tiempo, con duración de 0,42 segundos y desvanecimiento del vidrio y la silueta.
- Opacidad reducida, especialmente en el fotograma más lejano. No se acumula el rastro al quedarse quieto.
- Se conservan el daño, las ventanas, la selección de objetivo y la recuperación. Los vidrios que inmovilizan enemigos mantienen sus dos caras, rotura de un golpe y duración de cinco segundos.

## Emotes

- Rueda de vidrio con fondo tenue, refracción ligera, contornos y apertura suave.
- Vista previa animada del modelo real dentro de un SubViewport independiente. Cambiar de gesto no mueve ni despausa el personaje del mundo.
- Ocho entradas con teclas 1–8 o clic: Running Man, desafío, sí, no, brazos cruzados, llamada, zombi y presentación.
- Se adaptaron tres clips adicionales del paquete UAL2 recibido; dos se asignan al selector y el tercero queda como respaldo. Se conserva Running Man y su ritmo original. Son ocho gestos, no ocho bailes nuevos.
- Los gestos de duración finita terminan automáticamente. Se conservan las cancelaciones al moverse, atacar, bloquear o recibir daño.
- La rueda adapta su radio a ventanas horizontales y verticales; el HUD conserva el ajuste 50–100%.

## Estación 24

El mapa gana una estación elevada a cuatro metros, dos rampas transitables, cubierta, columnas, edificios de fondo, calles, pasos peatonales, bancos, jardineras, luminarias y señalética. Las ventanas utilizan instancias compartidas. Se conserva el espacio central para las pruebas anteriores, además de azoteas, foso, ascensor y Eco de ruta.

Con E, cerca de una estación interactiva:

| Estación | Acción real |
| --- | --- |
| Guardia | Reinicia y prepara un enemigo que bloquea |
| Duelo | Reinicia y prepara un enemigo que persigue y ataca |
| Eco de ruta | Inicia el desafío de recorrido existente |
| Compuerta | Abre/cierra una barrera con colisión |
| Iluminación | Alterna noche y atardecer |
| Rearmar vidrios | Restaura los tres paneles de práctica |
| Impulso | Lanza al jugador para comprobar salto y caída |

Los tres vidrios del mapa se rompen por un M1 válido desde ambos lados, retiran su colisión y usan los fragmentos y sonido existentes. El contacto se comprueba en la ventana real del golpe. E se puede reasignar desde Controles. El menú Explorar añade acceso a iluminación y rearme de vidrios.

## Organización y compatibilidad

Los cambios están separados en `physical_ragdoll.gd`, `urban_arena.gd`, `projection_echo.gd`, `mesh_pose_snapshot.gd`, la rueda y sus shaders. El GLB original no se sobrescribe. Se migran las preferencias y el récord del Eco desde la carpeta de usuario de la 0.9.6 únicamente cuando faltan en la nueva versión.

Se ejecutó exclusivamente el Godot 4.4.1 Linux enviado por ti. No se descargó otro motor. El proyecto declara Godot 4.4 y GL Compatibility; tu Godot 4.7.2 Windows queda pendiente de comprobación gráfica. Ver `RESULTADOS_0.9.7.md`, `AUTOCRITICA_0.9.7.md` y `GRABACION_REAL.md`.

No se importaron los dos paquetes grandes de audio: siguen pendientes de un enlace accesible. Esta entrega reutiliza el audio ya integrado y sus licencias.
