# PunchLine 0.9.25: edificios de tres y cuatro plantas

Se conservan las 71 construcciones anteriores y se añaden seis edificios de 14 × 14 m:

| Lote | Plantas | Centro X/Z |
| --- | --- | --- |
| lot_03 | 3 | -113 / -140 |
| lot_04 | 4 | 50 / -90 |
| lot_07 | 3 | -228 / 152 |
| lot_12 | 4 | 85 / -70 |
| lot_14 | 3 | 87 / 14 |
| lot_16 | 4 | 223 / 142 |

El distrito completo tiene **77 edificios y 799 ventanas con huecos reales**.
Cada planta tiene piso físico, ventanas transparentes, mobiliario y acceso. Las plantas
superiores incluyen balcones retranqueados dentro de la huella, con puertas y barandas.
Fajas entre plantas, columnas, jardineras, letreros, contraventanas y tejados de teja
aportan variación a las fachadas. La semilla cambia acabados y tejados; las posiciones,
dimensiones estructurales y cantidades de plantas se conservan, incluso con densidad baja.

Entrar por la puerta central; la escalera en U está al fondo del vestíbulo. Se sube por
el tramo izquierdo, se cruza el descanso posterior y se continúa por el tramo derecho.
En cada planta el vestíbulo comunica los dos tramos, las galerías laterales y el balcón.
El último piso cierra el acceso al tramo que ya no continúa. El recorrido inverso permite
bajar y salir. **El mecha completo también puede subir**, conservando su cápsula de
2,10 m de ancho y agachándose cuando lo requiere el techo.

Las alturas entre pisos son de 3,60 m, con 3,40 m libres. Cada vuelo sube 1,80 m en
3,80 m de recorrido y tiene doce peldaños de 15 cm. El cuerpo usa una colisión en
rampa continua; la IK de los pies consulta los peldaños en una capa independiente.
Los descansos y vuelos miden 3,80 m de ancho. Los huecos del forjado son reales y
tienen protecciones. La detección de espacio consulta también detrás de la cápsula,
evitando recuperar altura antes de despejar el borde de un forjado.

`data/multistorey_plan.json` añade ubicaciones validadas sin reubicar casas. El planificador
comprueba retiro de 2,50 m, separación de 3 m y exclusión de calles, veredas, Parking_00
y otros lotes. Los arquetipos nuevos se incorporan por el pedido del usuario sin editar
el JSON geográfico original. `DistrictHousingGenerator.load_plan` combina ambos planes.
Juego, red, escenas guardadas, prefabs e inspector usan el mismo generador.

La versión vigente está en `application/config/version` de `game/project.godot`.
`BuildInfo` la muestra en ventana, lanzador, HUD, menús, red e informes. `config/name`
queda estable para conservar `user://`. Ajustes, semilla y nombre online de 0.9.24
se recuperan solo si no existe un archivo actual. `AGENTS.md` exige incrementar
la versión y actualizar `CHANGELOG.md` en cada entrega.

Validación con Godot 4.4.1:

- `housing/qa/multistorey_test.gd`: 18 comprobaciones; ascenso y descenso reales del
  personaje hasta la tercera planta y del mecha hasta la cuarta.
- `python3 game/housing/qa/run_confinement_network.py --suite multistorey`: 13
  comprobaciones ENet, recorrido, pisos, postura, manos, versión y posición autoritativa.
- `housing/qa/architecture_test.gd`: 11 comprobaciones, 77 edificios y 799 ventanas.
- `python district_housing/tools/validate_multistorey.py`: reproducibilidad, separación,
  rutas y exclusiones, sin bloqueos nuevos en accesos existentes.
- `housing/qa/render_multistorey.gd`: versión, tres/cuatro plantas, escalera y vistas.

Las capturas colocan al mecha en puntos de inspección y dejan actuar su física y animación;
los recorridos completos se comprueban por separado. Evidencia en `evidence/multistorey/`.
Mesa por software permite revisar imágenes y no establece FPS de GPU de escritorio.
