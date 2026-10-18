# Casas accesibles al mecha y reacción al espacio

Las puertas residenciales anteriores tenían 1,46 m de ancho y 2,20 m de alto:
servían al personaje pequeño, pero impedían entrar al mecha. Ahora las viviendas
y comercios tienen pasos exteriores y tabiques interiores adaptados al robot.

| Variante | Ancho libre | Altura libre |
| --- | --- | --- |
| Amarillas y demás paletas | 3,92 m | 3,22 m |
| Azules, paletas 3 y 6 | 3,57 m | 3,02 m |
| Talleres medidos existentes | 4,07 m | 3,20 m |
| Almacén existente | 4,07 m | 4,30 m |

Los anchos consideran los 3,37 m de envolvente horizontal conservadora medida,
además de la cápsula física de 2,10 m. Se conservan la altura interior de 3,40 m,
las huellas exteriores, rampas, lotes y senderos originales. Las casas azules
exigen una compresión más profunda al cruzar el dintel. Cambiar de semilla también
aplica estos accesos a la nueva combinación de paletas.

`DistrictHousingGenerator.access_profile` calcula los pasos efectivos a partir
del diseño original. Los guarda en `robot_passage` y en los metadatos de `Doors`;
los JSON originales conservan sus dimensiones de procedencia. La escena editable
guardada y el generador en tiempo de ejecución usan la misma revisión.

`robot_clearance.gd` sigue anticipando techos y dinteles antes de mover la cápsula.
Conserva su radio y consulta espacio libre antes de recuperar la altura. Además,
consulta paredes junto a ambos hombros y un apoyo sobre la mano izquierda.
Usa los ejes reales del mecha ensamblado, que difieren del modelo del jugador.

`mecha_confinement.gd` suma una postura de incomodidad: recoge codos, inclina el
torso y la cabeza y reduce gradualmente el paso hasta un 28 %. Una IK de dos
articulaciones lleva cada mano a la pared o techo detectado, manteniendo las
longitudes de los brazos. Los pies siguen usando su IK de apoyo existente.
Las manos ceden a habilidades, cañón, bloqueo, boost y gestos; la colisión y el
agachado físico continúan. En espacio abierto se recuperan la postura y velocidad.

El anfitrión decide altura, presión y contactos. Los snapshots replican puntos y
normales para que los demás jugadores vean la misma postura sin consultas físicas
adicionales en el cliente. El protocolo es `punchline-district-confinement-2`;
anfitrión y clientes deben descargar esta misma versión.

Validación con Godot 4.4.1, usando el juego, personaje y mecha originales:

- `housing/qa/confinement_test.gd`: entrada y salida reales de amarilla y azul,
  compresión diferenciada, contactos de techo/pared, cañón y recuperación. Consulta
  los 71 pasos exteriores, tabiques e interiores con la anchura visual medida.
- `python3 game/housing/qa/run_confinement_network.py`: dos procesos ENet en puerto
  17965, recorrido, cápsulas, contactos, manos y corrección de alteración local.
- `housing/qa/architecture_test.gd`: texturas, 568 ventanas, huecos reales y límites
  de las geometrías, incluyendo todos los detalles y rampas.
- Regresiones de taller, postura y Rustcrawler conservadas.
- `housing/qa/render_confinement.gd`: capturas OpenGL del mecha real en entradas
  y apoyado en superficies, sin sustituir modelos ni reproducir poses fijas.

Evidencia en `evidence/confinement/`. Mesa por software permite revisar imágenes;
no establece FPS de una GPU de escritorio. Se comprueban recorridos representativos
y los 71 pasos por consultas físicas, sin afirmar un recorrido manual de cada casa.
