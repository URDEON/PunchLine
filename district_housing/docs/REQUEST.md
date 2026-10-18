# CODEX — PunchLine: generación procedural de viviendas en District500

## Trabajo solicitado

Estoy desarrollando PunchLine en Godot 4.4.1. Ya tengo el paquete `PunchLine_Distrito500_Godot4_COMPLETO.zip`, con la escena `res://scenes/District500.tscn`, las 7 capas separadas y el GeoJSON `res://tools/layout_vector.geojson`. También adjunto `district_lots.json` con LOS 19 macro-lotes exactos del escenario (coordenadas X,Z en metros) y las normas de generación. No trates el PNG como un mapa de colisiones: la fuente geométrica es el GeoJSON/JSON.

**META:** construir un sistema reproducible de casas y comercios procedurales que se instalen SOBRE los lotes del mapa existente, con algunas estructuras realmente explorables por el jugador y otras por robots/mechas que deban agacharse para atravesarlas. El resultado debe verse bien de cerca, conservar las calles, y ser editable en Godot. No quiero otra imagen ni un simple plano, sino escenas, scripts y geometría funcional.

## REGLAS DE INTEGRACIÓN

1. Inspecciona primero el proyecto cargado. Confirma si la estructura coincide con `district_lots.json`. No supongas que `res://` del mapa ya está integrado en PunchLine; localiza los archivos y adapta rutas.
2. Trabaja sobre una copia/branch. No reemplaces ni modifiques las mallas de `Roads`, `Parking`, `Lots`, `Sidewalks`, `Curbs`, `RoadMarkings` o `ParkingMarkings` salvo correcciones imprescindibles documentadas.
3. Conserva el estacionamiento original `Parking_00` libre. Nunca generes casas, muebles, muros, jardines ni colisiones dentro de calles, estacionamiento o veredas.
4. Los 19 polígonos del JSON SON MACRO-LOTES, no casas. Divide cada macrolote en parcelas internas con una semilla reproducible (923) y retiros reales. Genera una mezcla creíble de viviendas, esquinas comerciales, talleres y fachadas, no una cuadrícula de casas idénticas.
5. Mantén la silueta de calles, accesos, intersecciones y trazado general. Las viviendas deben tener puerta orientada hacia una ruta de acceso real desde la vereda, nunca hacia un muro o terreno de otra propiedad.
6. Los techos, pisos, paredes, puertas, escaleras y habitaciones deben ser GEOMETRÍA 3D con grosor, materiales simples y colisiones adecuadas. Las estructuras que declaras accesibles deben tener puertas abiertas o funcionales, y habitaciones conectadas; no maquetas huecas ni fachadas falsas.
7. Los edificios decorativos deben tener `access=inaccessible` y colliders completos; nunca aparentar puertas funcionales que no lo son.

## ACCESIBILIDAD Y MECÁNICAS DEL MECHA

8. Investiga los robots base y el mecha fusionado en el proyecto real. Mide CollisionShape3D, dimensiones físicas efectivas, postura de agachado del esqueleto y restricciones IK. No uses como medidas definitivas valores de ejemplo. Registra altura de pie, altura agachado, ancho y márgenes.
9. Según `district_lots.json`, garantiza al menos una estructura con acceso de mecha en los macrolotes marcados (5 entradas agachado y 1 de pie en la propuesta), SOLO si caben física y geométricamente en su macrolote. Si no es factible, informa el problema y propón el cambio mínimo sin invadir la calzada.
10. Para las estructuras `workshop_crouch`, haz portones y rutas interiores que exijan agachar el mecha: su altura libre ha de permitir la altura agachada más margen, pero no la de pie, siempre que la física real lo permita. También verifica su anchura en puerta, pasillo y habitación, no solo la altura.
11. Sistema de agachado: ShapeCast3D/RayCast3D para detectar techo y espacio libre, flexión procedural de rodillas y torso (IK donde el rig lo permita), ajuste de cápsula/collider coherente con el cuerpo y transiciones suaves. Si no cabe por ancho, NO atraviesa. No permitas que se levante dentro del techo. Evita alternancia rápida con histéresis.
12. Importante: los robots han de conservar caminata y dash procedurales, combate y bloqueo sin conflictos con agachado; las transiciones no deben sobrescribir animaciones de habilidad. Durante la fusión, comprueba que el cuerpo grande no aparezca incrustado en el interior de una vivienda.
13. En multijugador, el servidor valida ocupación, colisiones, postura y movimiento. Clientes representan los cambios visuales sin permitir atravesar objetos.

## GENERADOR Y ESTRUCTURA

14. Implementa `DistrictHousingGenerator.gd` (o equivalente), un lector `district_lots.json`, cálculo de subdivisiones de polígonos y selección de arquetipos con PRNG local determinista por lote. No coloques viviendas con coordenadas arbitrarias codificadas a mano que ignoren el JSON.
15. Evita solapes usando test geométrico de footprint contra el polígono interno disponible con setback y entre edificios; verifica también que no invada máscaras `Roads`/`Parking`/`Sidewalks`. Coloca entradas en límites orientados al acceso y evita bloqueos.
16. Genera prefabs/escenas modulares editables: paredes, esquinas, ventanas, puertas, tejados, interiores, pisos y colliders, cada categoría como nodos separados. Mantén una jerarquía `GeneratedBuildings/Lot_ID/Building_ID`.
17. Accesos prácticos para combate 3D: interiores suficientemente anchos cuando están declarados accesibles, cámara que no atraviesa techos, transiciones de puertas, posibilidad de abandonar la casa; sin cámara encerrada en tejado. Tejados pueden ocultarse VISUALMENTE sin eliminar colisiones físicas.
18. Optimiza: generación solo cuando cambia semilla/datos; reutilización de materiales, MultiMesh para repeticiones simples cuando corresponda, pocas formas físicas por edificio, LOD/culling/streaming de interiores lejanos. No instancies/destruyas cientos de nodos cada frame. Distingue render, física y FPS en pruebas.
19. Mantén los materiales sencillos y reemplazables. Superficies 3D reales: no convertir cada vivienda en una placa texturizada; calidad de cerca y posibilidad de editar después.
20. Si el mapa y el generador están en proyectos separados, entrega una escena reutilizable e instrucciones de integración; NO sobreescribas el `project.godot` principal de PunchLine.

## PRUEBAS OBLIGATORIAS Y CRITERIOS DE ACEPTACIÓN

- Validación JSON, existencia de los 19 lotes y coordenadas correctas dentro de -250..250 m.
- 0 edificios encima de `Parking_00`, calles, veredas o fuera de los polígonos autorizados.
- Regenerar dos veces con seed 923 genera exactamente la misma disposición.
- Probar al menos: un interior para jugador, un taller para mecha agachado, un almacén para mecha de pie y una fachada no accesible.
- Probar un robot intentando entrar DE PIE en un edificio que exige agacharse: debe detenerse o agacharse, nunca atravesar por escala/colisión desactivada.
- Probar que no se pone de pie bajo techo y que puede salir y recuperar postura gradualmente.
- Probar giro/pasillo/puerta con ShapeCast; prueba una entrada demasiado angosta.
- Probar acciones de combate, dash y animación procedural mientras está agachado; no debe vibrar ni quedar atascado.
- Validar en host y cliente si hay soporte de multijugador; si no puedes iniciar dos instancias, declararlo pendiente.
- Comparar FPS y física antes/después con múltiples edificios y al explorar interiores; no afirmar mejoras sin mediciones.

## ENTREGA

Quiero un proyecto o paquete para Godot 4.4.1 con el generador, JSON de lotes, escenas/prefabs modulares, colisiones e interiores; un mapa/overlay de qué se generó en cada lote; scripts y documentación; instrucciones de uso; pruebas verificables y lista de pendientes. No entregues solo una imagen, un prompt o un JSON sin el código de las escenas. No digas que algo está probado si no lo ejecutaste. No modifiques el ejecutable de PunchLine a menos que puedas exportarlo y verificarlo de forma real.

**Trabaja primero en la implementación de un lote piloto con un taller accesible al mecha agachado. Cuando funcione, extiende al resto de lotes manteniendo la semilla y las reglas del JSON.**
