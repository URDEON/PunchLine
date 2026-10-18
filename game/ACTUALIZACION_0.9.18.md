# PunchLine 0.9.18 — Prueba de locomoción procedural

Esta revisión aplica el experimento al Sentinel de 4 metros. Se conserva 0.9.17 como respaldo. Los clips de Naoya y de los robots base siguen disponibles para una extensión posterior.

## Qué cambia

- El pie apoyado conserva un punto mundial, en vez de recorrer un ciclo fijo pegado al cuerpo.
- Un planificador decide cuándo recolocar cada pie según desplazamiento, aceleración y giro. Anticipa la posición de aterrizaje y adapta la zancada a caminar o correr.
- IK analítica de dos segmentos: no estira huesos ni cambia las longitudes de las piezas.
- Rodillas, tobillos y pelvis compensan el apoyo; el torso y los brazos contrarrestan las piernas. La cabeza compensa parte del balanceo.
- Los pies se orientan con la normal del suelo y acompañan plataformas móviles. La pelvis amortigua los cambios de altura al subir escalones.
- El giro en reposo recoloca los pies y reproduce sonidos de contacto reales. El giro visual del tobillo queda limitado.
- Al frenar, termina el paso y se asienta; ante una pared deja de avanzar el ciclo.
- Despegues y habilidades de impacto liberan el apoyo; al aterrizar o recuperar el control se reconstruye de forma gradual.
- Caminar mientras se mantiene el cañón conserva el apuntado, el disparo y la recarga anteriores.
- Seis articulaciones interiores sencillas cubren juntas abiertas que quedan visibles al flexionar el modelo. Comparten una malla y un material mediante MultiMesh. El GLB original no se modifica.
- La cámara de primera persona aparta también estas juntas del cuerpo propio.

## Rendimiento y red

No se añaden mallas de personajes, esqueletos físicos ni geometría regenerada por fotograma. Las juntas son primitivas compartidas en una única superficie adicional.

Las consultas de suelo tienen presupuesto de dos rayos por actualización, con oportunidades periódicas de 20 Hz y reinicio al establecer un apoyo nuevo. Las réplicas de clientes reciben puntos y normales del anfitrión y no realizan esas consultas.

El estado añadido contiene solo dos pies y datos de movimiento; no se transmiten las 112 piezas del robot. Se comprueba que tres estados quepan en el límite de red existente. Todos los participantes deben usar 0.9.18.

La sonda aislada sin imagen midió medianas cercanas a 0,1 ms de CPU para la animación en este entorno. Son tiempos orientativos, con variación de carga; no representan FPS gráficos ni garantizan el rendimiento en otro PC.

## Comparar dentro del juego

Esc > Ajustes > **Adaptar pasos del mecha al terreno**.

Activado: nueva locomoción. Desactivado: marcha anterior. Se puede comparar sin volver a importar el proyecto.

## Archivos

- `scripts/mecha_foot_planner.gd`: apoyos, predicción y sincronización.
- `scripts/sentinel_articulation.gd`: IK, compensación corporal y juntas interiores.
- `scripts/fusion_controller.gd`: integración, contactos y estado online.
- `scripts/body_camera.gd`: capas de geometría en primera persona.
- `qa/locomotion_v0918_test.gd`: suelo, pendientes, escalones, plataformas, giros, pared, cañón y aterrizaje.
- `qa/locomotion_network_v0918_test.gd`: réplicas, compresión y ausencia de consultas en el cliente.
- `qa/locomotion_profile_v0918.gd`: medición aislada de CPU.

La escena se ha ejecutado con Godot 4.4.1 del entorno. La revisión visual y los FPS en Godot 4.7.2 deben comprobarse en tu equipo. Los renders técnicos de poses que se revisaron en Blender no son capturas de gameplay.
