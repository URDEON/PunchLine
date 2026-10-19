# Evidencia de PunchLine 0.9.31

Godot 4.4.1, proyecto completo `game/project.godot`. Datos de usuario aislados para
las suites locales. Los archivos históricos de otras versiones no se modificaron.

## Pruebas funcionales: 210/210

| Suite | Resultado | Comprueba |
| --- | --- | --- |
| [world_features_test](world_features_test.log) | 22/22 | Equipamiento, contenedores huecos, grúa real, reinicio, techos sólidos y orden de paquetes |
| [window_climb_test](window_climb_test.log) | 6/6 | Ventana generada con cristal, marcos y alféizar; subida sin penetración ni inversión |
| [surface_motion_test](surface_motion_test.log) | 18/18 | Continuidad y velocidad de transiciones entre superficies |
| [camera_jump_test](camera_jump_test.log) | 26/26 | Cámara corporal, tercera persona, esquinas y salto |
| [feature_test](feature_test.log) | 30/30 | Mundo, semilla y cabeza araña con controles reales |
| [multistorey_test](multistorey_test.log) | 28/28 | Entradas y escaleras de edificios de tres/cuatro plantas con personaje y mecha |
| [destruction_test](destruction_test.log) | 21/21 | Fractura local, colisiones, derrumbe por soporte, geometría original, daño y reinicio |
| [frontend_test](frontend_test.log) | 19/19 | Menús, galería, configuración DEMO, personajes, movimiento y combate |
| [camera_audio_test](camera_audio_test.log) | 10/10 | Cámara libre, patas rígidas y pisadas por contacto |
| [critical_test](critical_test.log) | 13/13 | G durante 3 s, apagado, explosión, daño y reaparición |
| [human_access_test](human_access_test.log) | 16/16 | Puertas humanas y recorridos interiores amueblados |
| [thermal_surface_test](thermal_surface_test.log) | 1/1 | Visión térmica al caminar invertido |

Ejecutar `python game/qa/v0931/run_checks.py` desde la raíz del repositorio.
Las suites nuevas se combinan con las pruebas anteriores que siguen siendo válidas.

## Multijugador: 52/52

Host y cliente ENet reales en UDP 17969; ambos procesos terminaron con código 0.
[Host](network/host.txt) · [Cliente](network/client.txt).
Incluye controles y propiedad de la grúa, carga trasladada con la misma pose,
techos asentados idénticos y reconstrucción para conexiones nuevas, además de
araña, cámara, visión, saltos, fractura, daño y autodestrucción.

Ejecutar `python game/qa/v0931/run_network.py`, sin otro servidor en ese puerto.

## Distribución y arranque

[Auditoría independiente](layout_audit.log) con Shapely de diez configuraciones:
cinco semillas, densidad baja/alta, repetibilidad y posiciones distintas. Comprueba
parcelas, retiros de 1.8 m, ausencia de solapamientos y conexión de cada ramal a las
veredas originales. [Resultados](layout_audit.json) · [Plano de semilla 923](seed_923_overlay.svg).
La semilla 923 genera 65 construcciones en baja y 139 en alta; esta última incluye
29 edificios de varias plantas. [Resumen del plan](plan_summary.log).

[Arranque completo](smoke.log) espera la generación asíncrona y disponibilidad del
jugador. La prueba de interfaz también importa y recorre una copia limpia del ZIP;
su registro se conserva en [archive_frontend.log](archive_frontend.log).
La primera importación headless emite diagnósticos `texture_2d_get` del renderer
Dummy al importar GLB existentes; la segunda importación y la ejecución se
comprueban por separado en [archive_validation.json](archive_validation.json).

## Render nativo: 10/10 capturas

Forward+ sobre Vulkan/Lavapipe, 960 × 600. [Registro](render.log).
Estas capturas verifican recursos y aspecto; no miden rendimiento de GPU.

| Mundo | Interiores y menú |
| --- | --- |
| [Patio y grúa](cargo_yard_and_gantry.png) | [Recepción](building_reception.png) |
| [Contenedor abierto y carga](open_container_interior.png) | [Espera y seguridad](building_waiting_security.png) |
| [Distrito más denso](denser_neighbourhood.png) | [Baño](public_bathroom.png) |
| [Cielo diurno y nubes](day_sky_and_clouds.png) | [Galería 3D](menu_model.png) |
| [Cielo nocturno](procedural_night_sky.png) | [Ilustración sin modelo anterior](menu_art_without_stale_model.png) |

Jolt puede advertir al incorporar el distrito que esperó trabajos disponibles;
también aparecen avisos de interpolación durante la construcción inicial. Las
pruebas finalizan sin errores de scripts, shaders o recursos.
