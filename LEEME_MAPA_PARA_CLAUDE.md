# Mapa completo de PunchLine para Claude — 0.9.31

Origen: URDEON/PunchLine, rama feat/district-housing.
Commit exacto: 6c6a33e4439a4a03bfabffde9f80b3c7d55da4fc

## Qué es este paquete

Módulo editable del mapa actual con sus escenas, datos, generadores, texturas,
materiales, shaders, vegetación, interiores, destrucción y patio de carga con grúa.
Incluye el código de integración con el juego y las pruebas para que puedas
comprender cómo funciona y proponer o implementar mejoras compatibles.

Para Claude: comienza leyendo este archivo y game/housing/docs/update_v0931.md;
para los cambios de superficie de la araña, lee también update_v0930.md y
contexto_juego/game/scripts/head_spider.gd.

Este paquete es un módulo para integrar en el juego completo. No contiene los
modelos y sonidos de personajes, menú y combate. El ZIP del juego completo adjunto
por separado contiene todos esos recursos y el proyecto ejecutable de Godot.
No hay un project.godot ejecutable en la raíz de este módulo para evitar abrir
accidentalmente un proyecto incompleto.

## Cómo ejecutar y probar las mejoras

1. Extrae PunchLine_0.9.31.zip (juego completo).
2. Abre game/project.godot con Godot 4.4.1, renderizador Forward+ / Vulkan.
3. Las carpetas game/ y district_housing/ de este módulo conservan las rutas del
   repositorio: aplica allí los archivos que modifiques. contexto_juego/ contiene
   copias de consulta; su subcarpeta game/ corresponde a game/ del juego completo.
4. Ejecuta DEMO, semilla 923, densidad alta. El mundo genera 139 construcciones,
   incluidas 29 de varias plantas, 34 comercios y 41 viviendas con patio. La
   densidad baja genera 65 construcciones. Espera a que termine la pantalla de carga.
5. Repite las pruebas pertinentes desde la raíz del juego completo:
   python game/qa/v0931/run_checks.py
   python game/qa/v0931/run_network.py
   El segundo comando abre host/cliente ENet reales en UDP 17969.

El proyecto district_housing es el inspector histórico; el mapa actual jugable se
construye dentro de game/. GeneratedHousing.tscn y generated_plan.json contienen
escenas/planes de procedencia: el runtime usa el planificador por semilla. Las
cantidades y limitaciones de documentos anteriores son históricas. Para el estado
actual prevalecen README.md, CHANGELOG.md y update_v0931.md.

## Dónde está cada sistema

| Sistema | Archivos |
| --- | --- |
| Montaje y carga del mapa | game/scripts/punchline_map.gd |
| Semilla, densidad, día/noche y destructibilidad | game/scripts/world_config.gd, seeded_district.gd |
| Terreno vectorial, veredas y colisiones | game/housing/scenes/District500.tscn, scripts/VectorDistrict.gd, data/vector_meshes.json |
| Parcelas y plan base | game/housing/data/district_lots.json, generated_plan.json |
| Casas, ventanas y techos | game/housing/scripts/DistrictHousingGenerator.gd |
| Edificios, plantas y escaleras | game/housing/scripts/MultiStoreyBuilding.gd |
| Recepción, mobiliario, seguridad y baños | game/housing/scripts/BuildingFacilities.gd |
| Instancias editables y destrucción | game/housing/scripts/BakedMultiMesh.gd |
| Iluminación, cielo, niebla, nubes y hierba | game/scripts/district_ambience.gd, district_greenery.gd; game/shaders/ |
| Árboles y decoraciones | game/scripts/district_trees.gd, district_decor.gd |
| Fractura, soporte y restos estructurales | game/scripts/district_destruction.gd |
| Contenedores huecos y grúa | game/scripts/cargo_yard.gd |
| Texturas y recursos del entorno | game/housing/textures/, game/assets/environment/ |
| Formato y herramientas de las fuentes geográficas | district_housing/tools/, district_housing/data/ |
| Jugador, mecha, araña, cámaras, preferencias y red | contexto_juego/game/ |
| Validaciones y capturas actuales | game/housing/docs/evidence/update_v0931/ |

El mapa recibe el nodo del juego como host. Consulta sus preferencias, jugador,
cámara y feedback; la destrucción aplica daño a actores y la grúa valida al operador.
En multijugador, contexto_juego/game/network/session.gd transmite semilla, daño,
estado de escombros y movimientos de la grúa. Mantén esas interfaces al modificarlo.

## Reglas para conservar compatibilidad

- Conserva las calles, veredas, parcelas y la superficie original del patio, con
  sus coordenadas y accesos medidos. Las adiciones se sitúan sobre esos datos.
- Conserva el determinismo por semilla y la autoridad del host en multijugador.
- Los accesos deben admitir las dimensiones reales del personaje/mecha; se
  incluyen mediciones y pruebas de escaleras y puertas.
- No hornees escenas automáticamente: el horneado sobrescribe ediciones.
- Conserva recursos y licencias. No cambies config/name (datos user://).
- Incrementa la versión del juego si entregas una actualización, junto con el
  README y CHANGELOG, siguiendo AGENTS.md.
- Comprueba colisiones de ambas caras, piezas sin soporte, reinicio de mundo y
  conexiones tardías al cambiar la destrucción.
- La grúa se opera con H junto a la consola (-57.5, .025, -96): I/K rieles,
  J/L carro, U/O altura y Enter enganchar/soltar al llegar al suelo.

## Solicitud que puedes pasar a Claude

Revisa el mapa actual de PunchLine y sus recursos adjuntos. Identifica mejoras
concretas de aspecto, interiores, variedad procedural, iluminación, vegetación,
colisiones, destrucción y rendimiento. Trabaja sobre el código actual, conserva
las interfaces con el juego y multijugador, y entrega los archivos editados con
sus rutas originales. Explica los cambios y verifica los recorridos y sistemas
afectados con las pruebas incluidas cuando dispongas del proyecto completo.

## Integridad

MANIFIESTO_MAPA.json enumera cada archivo con su ruta original y SHA-256, e indica
el commit de procedencia. Se conservan los bytes originales del repositorio.
No se incluyen cachés .godot/, archivos .git/ ni credenciales. Las comprobaciones
actuales de la versión son 210 locales, 52 ENet, diez mapas auditados y diez
capturas Forward+; son evidencia de esta versión, no pruebas de futuras ediciones.
