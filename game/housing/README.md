# PunchLine — District500 y viviendas procedurales

La ciudad anterior fue retirada de la copia editable por indicación del usuario.
El juego individual y el multijugador cargan el mismo District500 y los mismos edificios.
El `project.godot` original se conserva byte por byte. No se exportó ni modificó un ejecutable.

## Abrir y jugar

Abrir **`game/project.godot` con Godot 4.4.1** y ejecutar el proyecto. El lanzador conserva
las opciones individual y multijugador. WASD mueve, Espacio salta, Q activa dash, F bloquea,
1–4 usa habilidades y G activa la fusión con energía suficiente. En el selector de personaje
está Robot; los cuatro chasis, su locomoción, combate y articulación son los del proyecto real.
El inicio está en el estacionamiento protegido y sin edificios.

Para inspeccionar solo geometría, abrir `district_housing/project.godot`, proyecto independiente
sin dependencias de los personajes: cámara libre WASD/QE; botón derecho y ratón para orientar.

## Qué contiene la integración

- 19 polígonos originales verificados contra el GeoJSON a 1 mm. Semilla 923 reproducible.
- **77 edificios en 17 macro-lotes**: 20 viviendas, 3 comercios de esquina, 5 talleres para
  mecha agachado, 1 almacén para mecha de pie y 48 edificios sólidos `access=inaccessible`.
  Dos lotes quedan vacíos porque la búsqueda actual no encuentra un acceso/huella válido;
  no es una prueba de imposibilidad geométrica. Véase `docs/lots.md`.
- Retiro mínimo 2,5 m y separación mínima 3 m. Las huellas físicas, incluidas las rampas
  inclinadas, no invaden calles, veredas, estacionamiento ni otros lotes. Parking_00 permanece libre.
- Cada interior accesible tiene piso, techo y paredes con grosor, entrada permanentemente
  abierta y dos habitaciones conectadas. Rampas de 12 cm de desnivel dentro de la propiedad.
  Fachadas inaccesibles completamente sólidas y sin puertas que aparenten funcionar.
- Escena editable `housing/scenes/GeneratedHousing.tscn`, con jerarquía
  `GeneratedBuildings/lot_ID/Building_ID`. Pisos, paredes, puertas, ventanas, techo,
  interiores y rampas son categorías separadas. Prefabs medidos en `housing/scenes/prefabs/`.
- Materiales compartidos, culling visual a 180 m y generación explícita con hash. Ningún
  edificio se instancia por frame. `set_roof_visible` oculta solo mallas, sin quitar colisiones.

## Origen del mapa y correcciones documentadas

El proyecto recibido por Drive trae otras ciudades, **no el District500.tscn original**.
Se reconstruyeron las cuatro capas disponibles directamente del GeoJSON:
26 Roads, 1 Parking, 19 Lots y 15 Sidewalks, con alturas del JSON y colisiones.
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
`docs/integration_changes.json` identifica los seis scripts originales editados y hashes de origen.

## Medidas reales y agachado

`data/robot_measurements.json` contiene mediciones ejecutadas con Godot 4.4.1 de cápsulas,
escalas, vértices con skinning CPU y módulos rígidos del mecha. La pose final del modificador
se aplica desde su cache para medir los robots base. `robot_measurements_initial.json`
conserva la primera toma y la procedencia del perfil dimensional utilizado.

Los robots base tienen cápsula de 2 m y anchos de 0,64 / 0,88 / 0,80 / 0,92 m.
El mecha fusionado tiene cápsula de **4 m × 2,10 m** y mínimo configurado de 2,70 m.
Bajo techo de 3 m se midió una cápsula de 2,90 m y una envolvente visual de unos 2,46 m.
Los portones usan 3,20 m libres y 4,07 m de ancho, considerando la envolvente visual medida,
no solo los 2,10 m físicos. El almacén deja 4,30 m de altura libre. Márgenes: 30 cm sobre
la altura agachada medida y 35 cm por lado sobre la anchura de diseño.

La prueba real encontró un atasco: el sensor existente saltaba un dintel fino al consultar
solo el extremo del avance. `scripts/robot_clearance.gd` ahora consulta puntos intermedios
del trayecto y espera 0,15 s de espacio libre antes de expandir la cápsula. Conserva su anchura,
las consultas de volumen, el rig/IK y el formato de snapshots existente. La compresión física
anticipada evita penetración; la articulación visual y recuperación mantienen sus transiciones.
No escala el personaje ni desactiva colisiones para cruzar. La ocupación antes de la fusión
sigue validándose en el controlador original.

## Pruebas ejecutadas

Evidencia en `docs/evidence/`, generada en esta sesión, no tomada de informes antiguos:

| Comprobación | Resultado |
| --- | --- |
| Pruebas Python del planificador | 6/6 |
| Validación del distrito guardado y repetición con 923 | 77 edificios, 0 invasiones; 5 talleres y 1 almacén requeridos |
| Taller con mecha real y juego completo | 14/14: entrada, interior, techo, IK, habilidad, bloqueo, boost y salida |
| Jugador real y comprobaciones de arquetipos | 8/8; almacén/fachada por consultas físicas, estrechez por ShapeCast |
| Regresión existente de postura de los cuatro chasis y fusión | 37/37 |
| Dos procesos host/cliente ENet reales | 10/10; ambos procesos finalizan con código 0 |
| Importación de editor y arranque individual headless | Correctos |

La prueba de red verifica postura/cápsula, representación, corrección de una alteración local
de posición y recuperación de pie al salir. No equivale a una revisión exhaustiva antitrampas.
El jugador real recorre una casa; el mecha real recorre el taller piloto. Las dimensiones y
huellas del resto se validan geométricamente, sin afirmar recorridos manuales de los 77 edificios.

Rendimiento: `performance_none.json` y `performance_district.json` registran 180 muestras
por caso, con mapa/actores y con/sin edificios. Los datos incluyen CPU de física, nodos y
formas. Se capturaron en un entorno compartido y headless: **no son mediciones de GPU ni
FPS de renderizado y no demuestran una mejora de rendimiento**. No hay revisión gráfica
ni comparativa de FPS al explorar interiores en este equipo.

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
"$GODOT" --headless --path game --script housing/qa/archetype_checks.gd
"$GODOT" --headless --path game --script qa/update_v0924_test.gd
python3 game/housing/qa/run_network.py
```

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
revisión gráfica cercana y FPS con render; mejorar búsqueda en los dos lotes vacíos;
pruebas exhaustivas de giros, acciones extremas, todas las variantes y más clientes.
No se generaron escaleras ni edificios de dos plantas. Hay culling, no streaming físico;
no se añadió decoración repetitiva que justifique MultiMesh. No hay un sistema nuevo de destrucción.
