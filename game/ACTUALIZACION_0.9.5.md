# Naoya 0.9.5 — actualización de combate y recursos

Base: copia independiente de la última versión disponible, 0.9.4. El original se conservó en el entorno de trabajo. No se sustituyó el jugador ni se recalcularon sus pesos.

## Cambios jugables

- Cristalización con estados de captura, congelación y liberación. La malla 3D permanece oculta hasta liberar el efecto; se desactivan los animadores durante la captura.
- Dos fotografías reales del modelo, obtenidas mediante cámaras opuestas en un mundo de captura aislado. La espalda tiene su propia textura y superficie; no se refleja la fotografía frontal.
- Un golpe válido rompe el vidrio, aplica su daño normal y restaura el actor antes del knockback. Sin golpe dura cinco segundos. La liberación es idempotente y no crea colisiones adicionales.
- Fragmentos triangulares ligeros, dispersión, giro, fundido y audio `glass.wav`. Impacto y finalización por tiempo tienen distinta intensidad. Límite global de efectos conservado.
- Counter fallido: penalización de cristalización aplicada a Naoya durante cinco segundos. Counter acertado conserva daño y congela al atacante.
- Las inmovilizaciones cortas anteriores, como el segundo golpe de tentáculos, conservan su duración y presentación 3D; no se transformaron en vidrios de cinco segundos.
- Fase 2 horizontal hacia delante y boca abajo durante reposo, movimiento y ataques. El eje largo local +Z sigue el avance; el eje frontal del torso +X apunta al suelo. Collider y cámara conservan su estructura. Esta petición sustituye el reposo vertical de 0.9.4.

## Animaciones

Se inspeccionaron los 18 FBX suministrados: rig Mixamo de 65 huesos frente a 53 del jugador. `X Bot` se conservó como referencia; su pose de referencia difiere de la de los clips. Se adaptaron 17 clips, con 52 huesos mapeados, escala corregida y sin desplazamiento horizontal del root.

| Uso | Clip activo |
|---|---|
| Reposo del jugador humano | `mixamo/idle`, procedente de `idle.fbx` del usuario |
| Caminar/correr | `walking` / `running`, mezclados por velocidad |
| Lateral | `left/right strafe walking` y `left/right strafe` |
| Salto | `jump`, sin duplicar el desplazamiento vertical del controlador |
| Caída corta | `UnarmedFall`, conservado |
| Caída continua de cuatro segundos | `mixamo/Falling`, con contador reiniciado al aterrizar, subir, cristalizarse o entrar en ragdoll |
| Segundo M1 | Cross Punch adaptado al contacto existente |
| Tercer M1 a corta distancia | Elbow Punching; a mayor distancia conserva Hook |
| Habilidad 4 a corta distancia | Kick To The Groin; a mayor distancia conserva la patada anterior |
| Agachado a de pie y giros | Vistas de animación en Esc → Pruebas |

Daños, ventanas de contacto, velocidades del controlador y cooldowns se conservaron. La animación prolongada no se reinicia en cada frame ni interrumpe habilidades. La guardia mantiene su mezcla de brazos y piernas. La selección de variantes queda fijada al iniciar el ataque.

La versión remuestreada de GroinKick provocó un cierre del Godot 4.4.1 adjuntado al incorporarla a la biblioteca de combate. Se dejó fuera de la biblioteca activa y se utiliza el clip completo ya adaptado con reproducción acelerada para durar aproximadamente 0,59 s. Su contacto visual queda aproximadamente 0,02 s antes del contacto jugable; requiere revisión gráfica adicional. Cross y Elbow utilizan los clips ajustados al contacto. Las fuentes y el recurso remuestreado se conservan para diagnóstico.

No existía un sistema jugable de agacharse. Por ello Crouch To Stand se puede revisar en el laboratorio, y no reemplaza el levantarse desde el suelo. Los giros se pueden revisar allí sin duplicar el giro que realiza el controlador.

## Kogane

El Skull Wisp original carecía de rig. Se generó una copia local con Body, WingL, WingR y Tail y pesos suaves sobre la geometría de alas existente. Aleteo de velocidad variable, balanceo, flotación, inclinación por desplazamiento y movimiento sutil de cola. El original permanece intacto.

## Ragdoll

`PhysicalBoneSimulator3D` controla trece cuerpos: pelvis, torso, cabeza, brazos, antebrazos, muslos, pantorrillas y pies. Codos y rodillas usan Hinge; hombros, caderas y torso usan Cone. Los límites de codo se reflejan entre izquierda y derecha; las rodillas se restringen para doblar hacia atrás. Masas y amortiguación varían por parte.

Se exportó una copia del jugador a glTF Embedded desde Blender, preservando su rig y pesos. Blender 4.3 ya no ofrece la opción Embedded: el script exporta glTF estándar y embebe buffers e imágenes en el JSON. La escena independiente `qa/ragdoll_lab.tscn` utiliza esa copia.

La creación del esqueleto físico se hace por código en una estructura local, equivalente a crear y depurar un Physical Skeleton. No se afirma que se utilizó el menú del editor. El GLB usa centímetros y los cuerpos físicos necesitan metros: un esqueleto físico local con los mismos huesos transfiere sus poses al esqueleto original, sin alterar las mallas, pesos ni recursos importados.

La animación se suspende durante la simulación; los cuerpos colisionan con el escenario, no entre sí ni con la cápsula de su controlador. Inactivos tienen capa y máscara cero para no bloquear rayos de habilidades. Al recuperarse se reposiciona el controlador sobre el suelo y se mezclan las rotaciones físicas hacia la animación. Respawn y cristalización cancelan la simulación de forma coherente.

Abrir el menú detiene también los cuerpos físicos y conserva sus velocidades para reanudarlos; no reactiva el animador durante un derribo. La cámara conserva la exclusión de los cuerpos del personaje, incluidos los nuevos cuerpos físicos. Una prueba adicional comprueba que los huesos del rig visual coinciden con las posiciones simuladas, evitando una reducción accidental de escala al transferir las poses.

**Alcance:** ragdoll físico del Naoya humano y de los bandidos Y2K. Las formas de maldición conservan su derribo anterior; su rig de criatura todavía no tiene una configuración física equivalente. Los límites humanos no se aplicaron a sus huesos.

## Bandidos Y2K

- Única base: `UrbanShadow_original.glb`, copia del GLB texturizado suministrado. No se generaron modelos con servicios de IA.
- Original: 165.316 triángulos, 94.463 vértices exportados, una superficie, tres texturas de 2048², UV y sin rig.
- Derivado: 18.000 triángulos y 8.926 vértices de Blender antes de separar normales/UV para exportación. Silueta, rostro y articulaciones protegidos durante la reducción. Original intacto.
- Rig de 53 huesos reutilizado; pesos automáticos sólo para este enemigo que carecía de rig. Sin vértices sin peso y sumas normalizadas.
- Dos máscaras UV de 1024² separan chaqueta, pantalones, gorro, hoodie, zapatillas, pelo y piel. Shader regional sobre las texturas originales; conserva detalle y sombreado. Las zonas dudosas quedan con su textura original y los bordes de regiones son conservadores. La recoloración de pelo afecta zonas identificables de sienes/nuca; ojos y cejas se conservan.
- Seis paletas, tonos naturales de piel, colores de cabello y variación de altura ±3%. La semilla reproduce apariencias. La reaparición elige otra combinación y evita las paletas de compañeros presentes cuando hay alternativas.
- Malla y texturas compartidas; ShaderMaterial independiente por instancia. Se conservaron los tres NPC y sus comportamientos de prueba. Esc → Pruebas añade una galería de seis variantes animadas simultáneamente.
- El enemigo utiliza las animaciones y la IA de persecución/ataque existentes, y activa física en derribos.

## Dominio y laboratorio

F8, o el botón de Pruebas, activa la cámara exterior cuando hay un dominio. Ratón o WASD orbitan; rueda cambia distancia. Vista lateral y superior permiten revisar su esfera de radio 12 y altura 24. F8 devuelve la cámara normal; el dominio conserva su duración. La cámara también vuelve al jugador cuando desaparece la barrera.

Los ajustes de HUD, selector con triángulo dorado, Q para dash y P para personaje permanecen disponibles. Se añadieron vistas de clips y controles de apariencias al menú existente.

## Verificación y límites

Motor ejecutado: **el Godot 4.4.1 Linux adjuntado por el usuario**, compatible con las características 4.4 de `project.godot`. No se descargó otro motor. **Godot 4.7.2 no está instalado en este entorno y no se afirma haberlo probado.**

Pruebas reales automatizadas sin imagen: importación, combate, cooldowns, proyección, counter, cristalización desde ambos lados, cinco segundos, postura, caída, materiales, semillas, ragdoll, suelo, recuperación, HUD y dominio. Los registros y el resumen están en `resultados_v095/pruebas_godot/`.

La importación terminó con código cero y los recursos se cargaron en las escenas. El editor registró errores al intentar abrir sockets de depuración bloqueados por el contenedor; están conservados en el log de importación. Las pruebas ejecutadas de juego no registraron errores de script ni de recursos.

Blender verificó la deformación de la malla del enemigo en reposo, carrera, golpe, caída y recuperación. Los PNG de `resultados_v095/recursos_blender/` son renders de recursos reales, **no capturas de gameplay**. El montaje de paletas aproxima el shader para inspección de máscaras.

**No se generó un video real ni se verificaron píxeles de las fotografías frontal/trasera en Godot.** Xorg falla con `Cannot establish any listening sockets`; el contenedor no permite abrir las conexiones locales de la pantalla virtual. Se conserva el intento y su procedencia. No se eludió esa restricción ni se presentó una prueba sin imagen como grabación.

Quedan pendientes la comprobación gráfica final en Godot, revisión detallada de ropa en todos los extremos de animación, ajustes visuales de recuperación/impactos, física de las formas de maldición y medición de FPS/GPU en un equipo real. Las pruebas numéricas y renders parciales no demuestran ausencia absoluta de clipping en todos los movimientos.

## Repetir las pruebas y grabar

Importar el ZIP después de extraerlo en una carpeta nueva. Seleccionar `project.godot`; no sobrescribir una instalación anterior. El ZIP contiene rutas relativas y entradas de carpetas para evitar el error de extracción de la 0.9 original.

Para respetar el límite de 100 MiB del conector de Drive se excluyeron del ZIP los renders de poses de 0.9.3 y las imágenes históricas de HUD de 0.9.2. Se conservan en la versión anterior y en el entorno. Todos los recursos jugables, originales utilizados, scripts, reportes y evidencias de 0.9.5 están incluidos.

Con Python y el ejecutable propio de Godot:

```text
python qa/repetir_pruebas_v095.py --godot RUTA_AL_GODOT --project RUTA_AL_PROYECTO --output RUTA_NUEVA_DE_RESULTADOS
```

Demo real en una pantalla gráfica existente:

```text
GODOT --path PROYECTO --script res://qa/review_demo.gd --resolution 1280x720 --fixed-fps 60 -- --v095
```

Captura con Movie Maker de Godot en un sistema con pantalla gráfica:

```text
GODOT --path PROYECTO --script res://qa/review_demo.gd --resolution 1280x720 --fixed-fps 60 --write-movie prueba.avi -- --v095
ffmpeg -i prueba.avi -r 30 -c:v libx264 -pix_fmt yuv420p -c:a aac -movflags +faststart Naoya_v095_prueba.mp4
```

Captura FFmpeg en Linux/X11, con pantalla virtual si el sistema permite sus conexiones:

```text
python qa/grabar_ffmpeg.py --godot RUTA_AL_GODOT --project RUTA_AL_PROYECTO --output CARPETA_NUEVA
```

`--existing-display --display :0` reutiliza una pantalla existente. `--pulse-source FUENTE.monitor` añade una fuente real de audio de PulseAudio. No se genera una pista de audio falsa si falta esa fuente. La salida es H.264/AAC, 1280×720 y 30 FPS, con revisión de fotogramas mediante el script.

Las acciones de la demo son automatizadas. Los preparativos de laboratorio aparecen en pantalla; golpes, counter, temporizadores, animaciones, daño y física utilizan los sistemas reales del juego.

Para reconstruir recursos derivados, Blender y NumPy/Pillow para las máscaras:

```text
blender --background --python tools/prepare_enemy_v095.py -- PROYECTO CARPETA_INTERMEDIA
python tools/build_enemy_masks.py --project PROYECTO --geometry CARPETA_INTERMEDIA/enemy_geometry.json
blender --background --python tools/verify_enemy_deformation.py -- PROYECTO CARPETA_INTERMEDIA
blender --background --python tools/preview_enemy_palettes.py -- PROYECTO CARPETA_INTERMEDIA
blender --background --python tools/prepare_kogane_v095.py -- PROYECTO
blender --background --python tools/export_player_ragdoll_source.py -- PROYECTO
```

Después importar Godot antes de ejecutar los adaptadores `tools/retarget_mixamo_v095.gd`. Los originales FBX y los reportes están en `assets/animation_sources/mixamo/`; no es necesario volver a descargar animaciones para jugar.
