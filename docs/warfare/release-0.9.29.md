# Warfare:District500 0.9.29

## Descarga y prueba

[Descargar ZIP de la rama](https://github.com/URDEON/PunchLine/archive/refs/heads/feat/warfare-district500.zip).
Extraer todo en una carpeta nueva e importar **`game/project.godot` con Godot 4.4.1**.
Esperar la importación inicial y pulsar **F5 → JUGAR**. El menú permite elegir Soldado o
Junkyard Sentinel antes del despliegue. No se entrega un `.exe` en esta actualización.

La base anterior está en el commit `88e21cf460a5625bfb90dc46304ba5060ca075d6` y en la referencia
`backup/warfare-0.9.28-before-shooter`. Se conserva la referencia 0.9.27 original. La rama de
trabajo continúa siendo `feat/warfare-district500`; no se sustituye `main` ni la rama 0.9.31.

## Menú y presentación recuperados

`ui/warfare_menu.gd` ahora hereda de `launcher.gd`. Se reutilizan el fondo animado,
`ink_button.gd`, sonidos, distribución, transiciones y galería `menu_portrait.gd` del menú original.
La galería acepta un reparto configurable: Soldado y Sentinel. Los cuatro robots, luchadores
y arte de habilidades anteriores no se seleccionan ni se ejecutan en Warfare.

El botón Extras permite previsualizar animaciones reales. **P**, el triángulo del HUD del
Sentinel y el botón de pausa devuelven a la selección de unidades. Las opciones de pausa
se desplazan en un contenedor para conservar el acceso con ventanas pequeñas.

El HUD militar toma de la imagen aportada la distribución de la información, sin copiar una
interfaz como textura estática: equipos y captura arriba, minimapa abajo a la izquierda,
arma/munición abajo a la derecha, salud y confirmación de impacto. El minimapa dibuja los
vectores reales de District500 y la posición/orientación del jugador. El objetivo A muestra
captura y puntuación reales en práctica. No se simula una batalla o población de bots inexistente.

Sentinel conserva un HUD diferente que reutiliza `hud_identity.gd` y los recursos Sci-Holo,
con retrato del modelo original, integridad porcentual y carga del cañón.

## Recursos y animaciones aportados

Se recibieron Basic Shooter Pack.zip, Slim Shooter Pack.zip, Stepping Backward.fbx,
mp5a5.rar, M4A1.rar y una referencia visual del HUD. Los manifiestos
`game/assets/animation_sources/shooter/provenance.json` y
`game/assets/weapons/provenance.json` registran SHA-256 y procedencia. No se atribuye una
licencia o autoría no suministrada. Los archivos adjuntos se tratan como datos de recursos.

Los FBX únicos se conservan, incluyendo las variantes Slim diferentes. Los archivos repetidos
idénticos se comparten. `tools/build_shooter_library.gd` genera una biblioteca comprimida de
**24 clips**: idle de apuntado, marcha/carrera, retroceso, strafe, salto, recarga, disparo,
reacción, giros, lanzamiento de granada y paso atrás, junto con las variantes Slim aportadas.
La raíz horizontal se centra para que la animación no desplace la cápsula física.

Un `AnimationTree` mezcla locomoción y acciones de la parte superior, preservando el movimiento
de piernas al recargar/disparar. El paso atrás adicional se usa al comenzar un desplazamiento
breve hacia atrás. En Ajustes se elige Basic/Slim para los roles con variantes disponibles.
Los clips de giro/granada se conservan para ampliación y previsualización; no hay granadas
jugables implementadas en esta entrega.

El rig skinned **X Bot de los paquetes** sustituye al muñeco de cajas anterior. Es un modelo
de referencia con equipamiento militar provisional, no un soldado militar terminado. Cámara,
salud, entrada y equipo permanecen desacoplados de la representación. Se usa el mismo cuerpo,
esqueleto y arma en FPS/TPS. Un SkeletonModifier oculta la cabeza local después de la animación
y añade postura agachada, orientación del torso y reacciones acotadas. No hay todavía un
sistema completo de IK de manos/pies; quedan ajustes de agarre y de postura para el modelo final.

## Armamento funcional de videojuego

Se instancian las geometrías originales de los FBX de M4A1 y MP5A5. El M4A1 incluye una paleta;
la MP5A5 aporta texturas de color y normales. Se normalizan escala y ejes en tiempo de carga,
sin reemplazar los modelos ni modificar su geometría fuente. El montaje usa la transformación
evaluada del hueso de mano, evitando calibrarlo contra un BoneAttachment todavía en reposo.

| Parámetro inicial de juego | M4A1 | MP5A5 |
| --- | --- | --- |
| Familia de munición | AR | SMG |
| Cadencia configurada | 7 disparos/s | 11 disparos/s |
| Cargador / reserva | 30 / 150 | 30 / 180 |
| Recarga | 2,3 s | 1,85 s |
| Daño base abstracto | 24 | 16 |
| Alcance máximo de juego | 180 unidades | 75 unidades |
| Inicio de pérdida de daño | 60 unidades | 12 unidades |

Son parámetros editables de equilibrio, no datos reales del armamento. La cadencia observada
en pasos físicos está cuantizada por la frecuencia de simulación. Los Resources contienen
los valores; no se ocultan estadísticas dentro del controlador.

La lógica separa reservas AR/SMG, consume munición por disparo, recarga mediante transferencia,
cancela recarga al cambiar de arma y bloquea el disparo durante recarga/carrera. El apuntado
reduce dispersión y FOV. Se comprueba el trayecto de cámara y el del arma para bloquear daño
a través de paredes. Al reanudar, un gatillo mantenido requiere soltarse para volver a disparar.

Tres balizas físicas en el estacionamiento registran impactos, daño y recuperación. No son
bots. Un objetivo A se captura al permanecer en su zona. Hay trazas y audio espacial mediante
pools de ocho trazas y seis voces, sin nodos ni fragmentos físicos creados por cada disparo.
El sonido de las armas pequeñas es un efecto electrónico provisional generado una sola vez.

## Sentinel recuperado

La unidad aparece completa al elegirla. `sentinel_visual.gd` carga el Junkyard Sentinel original
y reutiliza `sentinel_articulation.gd`, el brazo Rustwing, locomoción, apoyos y sonidos de pasos.
No instancia `fusion_g.gd`, `fusion_controller.gd` ni los cuatro robots. El controlador tiene
dimensiones, velocidad, cámara TPS y salud de unidad pesada (300).

Apuntar o disparar despliega el brazo cañón original; el disparo espera a que esté desplegado.
La carga/recarga es abstracta de videojuego. Hay daño contra las balizas y reaparición directa.
No se implementan camión, contenedor, ensamblaje, vehículos ni las demás acciones de combate
antiguas del Sentinel en esta entrega. La aparición está separada del controlador.

## Archivos principales

- Adaptados: `launcher.gd`, `scripts/menu_portrait.gd`, menú/HUD Warfare, controlador/escena del
  soldado, cámara, entrada y movimiento; `project.godot`, README y CHANGELOG pasan a 0.9.29.
- Nuevos: `combat/weapon_data.gd`, Resources de armas, `weapon_visual.gd`, `soldier_equipment.gd`,
  `combat_feedback.gd`, `practice_target.gd`.
- Nuevos: `soldier_animations.gd`, `soldier_pose.gd`, `soldier_preview.tscn`, biblioteca, fuentes
  FBX y script reproducible de construcción.
- Nuevos: `units/mega_mecha/sentinel.gd`, `sentinel_visual.gd`, `sentinel.tscn`.
- Nuevos: `military_overlay.gd`, `military_minimap.gd`, `practice_objective.gd`, pruebas y evidencia.
- Conservados: escenas/datos geográficos de District500, generador, edificios, recursos de
  Sentinel/Rustwing, su articulación original, controles antiguos y respaldo de PunchLine.

## Verificación y límites

Resultado final: **42/42 pruebas de combate** y **32/32 de regresión** aprobadas.
Registros y resultados: [combate](evidence/v0.9.29/shooter.log),
[regresión](evidence/v0.9.29/phase1.log), [render](evidence/v0.9.29/render.log).
Capturas reales de esta versión: [menú recuperado](evidence/v0.9.29/restored_menu.png),
[HUD militar/M4A1](evidence/v0.9.29/m4a1_fps_hud.png),
[MP5A5](evidence/v0.9.29/mp5a5_aim.png),
[galería de unidades](evidence/v0.9.29/sentinel_selection.png) y
[Sentinel con Sci-Holo](evidence/v0.9.29/sentinel_sci_holo.png).
Las capturas muestran el estado real: agarre y postura del soldado siguen siendo provisionales,
incluida la colocación de las manos respecto del arma en primera persona.

Godot ejecutado: **4.4.1 estable**, con **Jolt**. Las suites verifican menú original, galería,
clips, árbol de animación, raíz centrada, intercambio de armas/modelos, cadencias relativas,
daño, obstáculos, recarga, reservas, pausa, efectos temporales, objetivo, pools, Sentinel,
su cámara, cañón, HUD, reaparición y selección. La regresión de movimiento recorre las escaleras
de tres y cuatro plantas con el controlador real, alterna cámaras, prueba techos y repite escenas.

La prueba de estabilidad incluye **120 segundos simulados** en headless, con cambios de vista.
Esto no sustituye una sesión prolongada en tiempo real. Las capturas gráficas usan **Vulkan /
Forward+ y llvmpipe por software**. No hay benchmark nuevo de RTX 3050, GPU/VRAM ni confirmación
de 60 FPS en el equipo de referencia. El distrito sigue cargando todas sus colisiones; no se
introduce streaming físico ni se atribuye la degradación histórica a una causa sin pruebas.

Durante la integración se corrigieron la asignación de un Array tipado del cañón, el montaje
contra una pose de mano desactualizada y comprobaciones antiguas que asumían el rig de cajas.
La cabeza skinned se verifica durante `modification_processed`, antes de que Godot restaure
la pose de entrada del modificador. Se mantienen los registros finales y cualquier aviso.

Pendientes: modelo militar final, ajustes finos de agarre/IK y transiciones, accesos estrechos
del Sentinel en todos los edificios, audio final, bots y partidas por equipos, optimización
medida en hardware de juego, vehículos y destrucción ampliada. No se anuncia nada de ello como terminado.
