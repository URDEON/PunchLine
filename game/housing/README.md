# PunchLine — District500 y viviendas procedurales

La ciudad anterior fue retirada de la copia editable por indicación del usuario.
El juego individual y el multijugador cargan el mismo District500 y los mismos edificios.
La configuración original del juego conserva sus controles y render, con versión y arranque
actualizados en 0.9.25. No se exportó ni modificó un ejecutable.

## Abrir y jugar

Abrir **`game/project.godot` con Godot 4.4.1** y ejecutar el proyecto. El lanzador conserva
las opciones individual y multijugador. DEMO abre primero la configuración de mundo: semilla
numérica o de texto, aleatoria, densidad y día/noche. Confirmar «CREAR MUNDO Y JUGAR». WASD mueve, Espacio salta, Q activa dash, F bloquea,
1–4 usa habilidades y G activa la fusión con energía suficiente. En el selector de personaje
está Robot; los cuatro chasis, su locomoción, combate y articulación son los del proyecto real.
El inicio está en el estacionamiento protegido y sin edificios.

Para inspeccionar solo geometría, abrir `district_housing/project.godot`, proyecto independiente
sin dependencias de los personajes: cámara libre WASD/QE; botón derecho y ratón para orientar.

## Qué contiene la integración

- 19 polígonos originales verificados contra el GeoJSON a 1 mm. Semilla 923 reproducible.
- **71 edificios en 17 macro-lotes**, todos con entrada e interior: 62 viviendas, 3 comercios
  de esquina, 5 talleres para mecha agachado y 1 almacén para mecha de pie.
  Por el pedido de dar entradas a todas las casas, las alternativas `facade_only` del
  generador anterior ahora se resuelven como viviendas accesibles; el JSON fuente se conserva.
  Dos lotes quedan vacíos porque la búsqueda actual no encuentra un acceso/huella válido;
  no es una prueba de imposibilidad geométrica. Véase `docs/lots.md`.
- **Seis edificios adicionales**, tres de tres plantas y tres de cuatro, conservan las
  construcciones anteriores: **77 edificios en total**. Escaleras, forjados con huecos,
  balcones y plantas transitables admiten personajes y mecha. Véase [0.9.25](docs/multistorey.md).
- Retiro mínimo 2,5 m y separación mínima 3 m. Las huellas físicas, incluidas las rampas
  inclinadas, no invaden calles, veredas, estacionamiento ni otros lotes. Parking_00 permanece libre.
- Cada interior accesible tiene piso, techo y paredes con grosor, entrada permanentemente
  abierta y dos habitaciones conectadas. Rampas de 12 cm de desnivel dentro de la propiedad.
  Los 77 senderos de acceso se recortan dentro del lote y fuera de las capas protegidas.
- Arquitectura procedural reproducible: ocho paletas, dos tipos de tejado inclinado,
  tejas, chimeneas, zócalos, marcos, contraventanas, porches, jardineras y mobiliario interior.
  Los comercios tienen toldos y carteles. **799 ventanas transparentes** ocupan huecos reales
  en los muros: permiten ver hacia fuera y hacia dentro, conservando su barrera física.
- Escena editable `housing/scenes/GeneratedHousing.tscn`, con jerarquía
  `GeneratedBuildings/lot_ID/Building_ID`. Pisos, paredes, puertas, ventanas, techo,
  interiores y rampas son categorías separadas. Prefabs medidos en `housing/scenes/prefabs/`.
- Texturas compartidas de asfalto, césped, pavimento, estuco, ladrillo, madera y tejas.
  Culling visual a 320 m para todas las piezas y generación explícita con hash. Ningún edificio se
  instancia por frame. `set_roof_visible` oculta solo mallas, sin quitar colisiones.
- Piezas repetidas agrupadas mediante MultiMesh por categoría y material. `BakedMultiMesh.gd`
  conserva sus transformaciones en CPU al guardar escenas sin renderer y las carga una vez;
  las instancias estáticas no interpolan desde matrices vacías. Las colisiones siguen separadas.

## Origen del mapa y correcciones documentadas

El proyecto recibido por Drive trae otras ciudades, **no el District500.tscn original**.
Se reconstruyeron las cuatro capas disponibles directamente del GeoJSON:
26 Roads, 1 Parking, 19 Lots y 15 Sidewalks, con alturas del JSON y colisiones.
El suelo invisible se corrigió invirtiendo el orden de los vértices superiores para el
frente de cara horario de Godot; se mantienen normales hacia arriba y las colisiones.
También se añadió un sustrato inferior con colisión para cerrar las juntas del vector,
sin modificar sus polígonos. Ahora cada superficie tiene textura y coordenadas UV.

Las capas Curbs, RoadMarkings y ParkingMarkings están señaladas como `source_missing`:
no se inventan como si se hubieran recuperado sus mallas originales. La escena está en
`housing/scenes/District500.tscn`; el GeoJSON original está también en `tools/layout_vector.geojson`.

`Roads_21` contiene una autointersección: `make_valid` se aplica a la geometría derivada
para triangulación/exclusión, conservando los archivos fuente originales. Las conexiones
peatonales virtuales pueden cruzar como máximo una franja de 0,5 m de máscara vial entre
lote y vereda, por las discrepancias entre sus bordes vectoriales. **No se construye rampa,
pasarela, mueble ni colisión de vivienda en esa franja.** Se rechaza atravesar una calle
completa, Parking_00 u otra propiedad. El veto a geometría de edificios no se aplica al
suelo original del mapa ni al movimiento del jugador.

En lot_05, la exigencia explícita de un taller agachado tiene prioridad sobre su lista de
arquetipos contradictoria. La excepción queda en `zoning_overrides` del plan; el JSON
original no se modifica. La generación es una propuesta, no un levantamiento de una ciudad real.

Se eliminaron `assets/environment/ruined_city` y `assets/environment/punchline_v54` de
esta copia, además de los props de ejercicios de la ciudad retirada. Los ZIP y la copia original
están preservados fuera del checkout en `/workspace/punchline-source`. El manifiesto
`docs/integration_changes.json` identifica los scripts originales editados y la procedencia de los archivos.

## Semillas y cabeza araña

[Controles, reglas, pruebas y capturas de Rustcrawler](docs/rustcrawler.md). La configuración
de mundo se aplica a DEMO. El mapa multijugador conserva el distrito común para ambos peers;
la cabeza araña funciona en los dos modos.

## Medidas reales y agachado

`data/robot_measurements.json` contiene mediciones ejecutadas con Godot 4.4.1 de cápsulas,
escalas, vértices con skinning CPU y módulos rígidos del mecha. La pose final del modificador
se aplica desde su cache para medir los robots base. `robot_measurements_initial.json`
conserva la primera toma y la procedencia del perfil dimensional utilizado.

Los robots base tienen cápsula de 2 m y anchos de 0,64 / 0,88 / 0,80 / 0,92 m.
El mecha fusionado tiene cápsula de **4 m × 2,10 m** y mínimo configurado de 2,70 m.
Las viviendas amarillas ahora dejan pasos de 3,92 × 3,22 m; las azules, de
3,57 × 3,02 m. Ambos tabiques y entradas admiten al mecha agachado. El robot recoge
los brazos, inclina el cuerpo y apoya las manos en techo/paredes detectados por física.
[Dimensiones, reacción procedural y pruebas de esta corrección](docs/confinement.md).
Bajo techo de 3 m se midió una cápsula de 2,90 m y una envolvente visual de unos 2,46 m.
Los portones usan 3,20 m libres y 4,07 m de ancho, considerando la envolvente visual medida,
no solo los 2,10 m físicos. El almacén deja 4,30 m de altura libre. Márgenes: 30 cm sobre
la altura agachada medida y 35 cm por lado sobre la anchura de diseño.

La prueba real encontró un atasco: el sensor existente saltaba un dintel fino al consultar
solo el extremo del avance. `scripts/robot_clearance.gd` ahora consulta puntos intermedios
del trayecto y espera 0,15 s de espacio libre antes de expandir la cápsula. Conserva su anchura,
las consultas de volumen y el rig/IK. Los snapshots incluyen altura, presión y contactos. La compresión física
anticipada evita penetración; la articulación visual y recuperación mantienen sus transiciones.
No escala el personaje ni desactiva colisiones para cruzar. La ocupación antes de la fusión
sigue validándose en el controlador original.

## Pruebas ejecutadas

Evidencia en `docs/evidence/`, generada en esta sesión, no tomada de informes antiguos:

| Comprobación | Resultado |
| --- | --- |
| Pruebas Python del planificador | 6/6 |
| Validación del distrito guardado y repetición con 923 | 71 edificios y senderos, 0 invasiones; 5 talleres y 1 almacén requeridos |
| Arquitectura y física de toda la escena guardada | 11/11: texturas, caras, 77 puertas y rutas, 799 huecos, vidrio, envolventes y culling |
| Taller con mecha real y juego completo | 14/14: entrada, interior, techo, IK, habilidad, bloqueo, boost y salida |
| Jugador real y comprobaciones de arquetipos | 8/8; almacén por consultas físicas, estrechez por ShapeCast |
| Regresión existente de postura de los cuatro chasis y fusión | 37/37 |
| Dos procesos host/cliente ENet reales | 10/10; ambos procesos finalizan con código 0 |
| Casas amarillas/azules con mecha real y 71 pasos medidos | 20/20; entrada, techo, pared, cañón y salida |
| Contactos procedurales en host/cliente ENet | 13/13; ambos procesos finalizan con código 0 |
| Edificios de tres y cuatro plantas y controlador real | 18/18, subida y bajada del personaje y mecha |
| Recorrido multijugador de escaleras y versión | 13/13, ambos procesos finalizan con código 0 |
| Menú, versión, configuración de mundo, ajustes, extras, selección y combate | 15/15 |
| Importación de editor y escenas de ambos proyectos | Correctas |
| Render gráfico OpenGL 4.5 / Mesa llvmpipe | Capturas reales del terreno, exterior, ventanas, menú y juego |

La prueba de red verifica postura/cápsula, representación, corrección de una alteración local
de posición y recuperación de pie al salir. No equivale a una revisión exhaustiva antitrampas.
El jugador real recorre una casa; el mecha real recorre el taller piloto. Las dimensiones y
huellas de todos se validan con consultas y barridos físicos, sin afirmar recorridos manuales
por las 71 construcciones.

Las capturas `before_*.png` y `after_*.png` documentan la corrección con render real, usando
Xvfb y Mesa llvmpipe. `after_gameplay.png` usa el juego original, sus luces, personaje y HUD.
[Exterior corregido](docs/evidence/after_house.png) · [Vista por ventanas](docs/evidence/after_window.png).
La evidencia inicial de arquitectura está en `docs/evidence/architecture_v2/`.
La corrección posterior de accesos del mecha y contactos está en `docs/evidence/confinement/`.

Los archivos `performance_none.json` y `performance_district.json` corresponden a la entrega
anterior de geometría simple y se conservan como referencia histórica. No caracterizan
esta arquitectura. El render por software en un entorno compartido no establece FPS de una
GPU de escritorio; queda pendiente medir rendimiento en el equipo de juego.

## Repetir en este entorno

Desde `/workspace/PunchLine`:

```sh
bash district_housing/tools/setup.sh
export XDG_CONFIG_HOME=/workspace/.config
export XDG_DATA_HOME=/workspace/.local/share
export XDG_CACHE_HOME=/workspace/.cache
GODOT=/workspace/godot441/Godot_v4.4.1-stable_linux.x86_64
/workspace/punchline-tools/bin/python -m unittest discover -s district_housing/tests -v
/workspace/punchline-tools/bin/python district_housing/tools/validate_district.py
"$GODOT" --headless --path game --script housing/qa/pilot_test.gd
"$GODOT" --headless --path game --script housing/qa/confinement_test.gd
"$GODOT" --headless --path game --script housing/qa/multistorey_test.gd
python3 game/housing/qa/run_confinement_network.py --suite multistorey
python3 game/housing/qa/run_confinement_network.py
"$GODOT" --headless --path game --script housing/qa/archetype_checks.gd
"$GODOT" --headless --path game --script housing/qa/architecture_test.gd
"$GODOT" --headless --path game --script housing/qa/frontend_test.gd
"$GODOT" --headless --path game --script qa/update_v0924_test.gd
python3 game/housing/qa/run_network.py
```

Para las capturas, ejecutar `housing/qa/render_housing.gd` y `housing/qa/render_gameplay.gd`
sin `--headless`, con una pantalla disponible. En esta sesión se utilizó `DISPLAY=:99`
y `LIBGL_ALWAYS_SOFTWARE=1`. Los scripts de captura rechazan el renderer headless.

Las pruebas pueden tardar por la importación inicial de modelos. No hay servicios persistentes
que iniciar. Se usan los checkouts existentes; no crear un worktree para tareas en la nube.

## Regenerar e integrar

`district_housing/tools/plan.py` es el planificador offline; Godot carga/hornea su plan mediante
`DistrictHousingGenerator.gd`. Python 3.12, Shapely 2.1.2 y NumPy 2.5.4 están fijados.
Para regenerar con las medidas reales: `plan.py --profile district_housing/data/measured_profile.json
--scope district`, copiar el resultado a `game/housing/data/generated_plan.json` y ejecutar
`Godot --headless --path game --script housing/qa/bake_housing.gd`. La semilla por defecto es 923.
El piloto se conserva en `housing/data/pilot_plan.json`. Para rehacer la reconstrucción vectorial,
usar `export_vector.py` y `housing/qa/bake_vector.gd`.

El horneado **reemplaza la escena generada**. Guardar ediciones manuales en otra escena antes
de regenerar. No ejecutar el horneado como paso automático de instalación. La entrega
`district_housing` es independiente y reutilizable; nunca copiar su project.godot sobre el principal.

Pendientes: recuperar las tres capas originales ausentes si se dispone del paquete base;
medir FPS en hardware de juego; mejorar búsqueda en los dos lotes vacíos;
pruebas exhaustivas de giros, acciones extremas, todas las variantes y más clientes.
No se generaron escaleras ni edificios de dos plantas. Hay culling, no streaming físico;
las piezas repetidas usan MultiMesh con transformaciones editables. No hay un sistema nuevo de destrucción.
