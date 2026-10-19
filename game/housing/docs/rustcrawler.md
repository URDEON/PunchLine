# Mundo configurable y cabeza Rustcrawler

Abrir `game/project.godot` con Godot 4.4.1. Pulsar **DEMO**, introducir una semilla numérica
o de texto, elegir densidad y día/noche, y confirmar **CREAR MUNDO Y JUGAR**. El botón
ALEATORIA propone otra semilla. Se recuerda la última configuración en `user://world.cfg`.

La semilla controla las variantes, dimensiones de casas y selección de edificios. Los
centros y las calles conservan District500. Las dimensiones se reducen dentro de las
envolventes verificadas y se conservan los seis accesos medidos de mecha. La misma semilla
y densidad producen el mismo resultado en esta versión de Godot. La configuración afecta
a DEMO; multijugador conserva el distrito común, independiente de las preferencias locales.
La generación se ejecuta dentro de Godot, sin Python en el equipo del jugador.

## Expulsar la cabeza

Con un robot seleccionado, llenar la energía y completar la fusión con G. Con el Sentinel
apoyado y la salida de la cabeza despejada, pulsar **E**. La cabeza sale, despliega las seis
patas y pasa a control del jugador con **50 HP**. El mecha queda en su ubicación, con colisión,
se arrodilla, baja torso y brazos, apaga el motor y pierde luz gradualmente.

| Control | Acción |
| --- | --- |
| WASD y ratón | Caminar y mirar; adhesión automática al suelo, paredes y techos |
| Espacio | Saltar desde suelo, pared o techo; sin doble salto |
| V | Alternar primera y tercera persona |
| Rueda | Regular la distancia de la cámara |
| 1 | Escáner de personajes a 25 m: señales visibles durante 6 s, recarga de 10 s |
| 2 | Camuflaje de 8 s, recarga de 16 s; pulsar otra vez para desactivarlo |
| E cerca o encima del mecha | Reconectar la cabeza y reactivar el Sentinel |
| Esc | Menú habitual |

La reconexión requiere estar a unos 3 m del centro del chasis, un trayecto despejado y
volumen libre para restaurar la cápsula del mecha. Devuelve su vida previa a la expulsión;
la vida de la araña es independiente. Hay 5 s de estabilización antes de otra expulsión.
Al perder los 50 HP se pierde al jugador: se ejecutan la muerte y reaparición originales,
incluida la espera y destrucción del mecha. No se cambia gratis a un personaje vivo.

El camuflaje hace translúcido el modelo, oculta su nombre en red y evita la persecución
de los enemigos de DEMO. Se rompe al recibir daño o usar el escáner. Mantiene la colisión
y puede recibir impactos; no concede invulnerabilidad. El escáner dibuja señales a través
de obstáculos. El control, daño, enfriamientos y reconexión los decide el anfitrión en red.
El protocolo cambia: anfitrión y clientes deben usar esta entrega.

## Modelo y cámara

El GLB adjunto se conserva en `assets/characters/rustcrawler/Rustcrawler.glb`. Sus UVs,
texturas y geometría se mantienen. El rig original tenía los reposos en cero y no
proporcionaba una animación utilizable. `rustcrawler_rig.gd` construye una piel de 13 huesos:
un cuerpo y dos articulaciones por cada una de las seis patas, con IK y trípodes alternos.
Los apoyos se consultan contra colisiones y se mantienen en coordenadas del mundo.

Desde 0.9.26, la cámara respeta V y la rueda igual que el mecha y gira con la superficie.
En primera persona sigue directamente el cuerpo interpolado y excluye su propia malla
solo de la vista del dueño. Otros jugadores y el retrato conservan el modelo completo.
En tercera persona se ven las seis patas y el barrido de una esfera acorta la distancia
ante paredes o techos; si falta espacio, usa temporalmente la vista interior.
La primera persona conserva la cabina corporal del Sentinel. En **AJUSTES → CÁMARA** se regulan aberración cromática, bloom y suciedad de lente,
además del ojo de pez existente. El bloom se calcula en pantalla para funcionar en
GL Compatibility. Los efectos se dibujan antes del HUD para mantener legibles los textos.

El salto se separa en la dirección de la superficie y después usa gravedad. Las patas
se recogen durante el vuelo y vuelven a buscar apoyos al aterrizar. El anfitrión valida
el salto en red; pulsar varias veces en el aire no concede saltos adicionales.

## Validación

La entrega **0.9.26** tiene evidencia nueva en `evidence/spider_v0926/`: 26 comprobaciones
de cámara y salto, 22 de anfitrión/cliente ENet, 28 de regresión de la araña y 15 del menú.
Las cuatro suites de prueba terminan con código 0; también termina con 0 el render
OpenGL/Mesa de primera persona, dos distancias de tercera persona y salto real.
Los avisos de interpolación de recursos antiguos y V-Sync del render por software
no son errores de script. No se midieron FPS de hardware.

Se usan el juego, el controlador y la fusión originales. Evidencia anterior en `evidence/rustcrawler/`:

- 28 comprobaciones de semilla, densidad, seis accesos, expulsión, HP, habilidades,
  pared, techo, tejado inclinado de una casa real, retorno, muerte y reaparición.
- 13 comprobaciones de menú, configuración aplicada, noche, selección y combate.
- 18 comprobaciones host/cliente ENet, con daño, snapshots, cápsula, camuflaje, escaneo,
  corrección de alteraciones locales, reconexión y reaparición. Ambos procesos terminan con 0.
- Regresiones: 37 de postura y 14 del taller con el mecha real.
- Capturas con OpenGL/Mesa y comparación de píxeles con los efectos activados y desactivados.

```sh
GODOT=/workspace/godot441/Godot_v4.4.1-stable_linux.x86_64
"$GODOT" --headless --path game --script qa/rustcrawler/feature_test.gd
"$GODOT" --headless --path game --script housing/qa/frontend_test.gd
"$GODOT" --headless --path game --script qa/rustcrawler/camera_jump_test.gd
python3 game/qa/rustcrawler/run_network.py
# Con pantalla gráfica, sin --headless:
"$GODOT" --path game --audio-driver Dummy --rendering-method gl_compatibility \
  --resolution 1280x800 --script qa/rustcrawler/camera_render.gd
```

Las capturas usan Mesa por software y no establecen FPS de una GPU de escritorio. La prueba
de red cubre dos procesos; no constituye una prueba exhaustiva de todas las habilidades
de combate ni de todos los bordes posibles de cada edificio.
