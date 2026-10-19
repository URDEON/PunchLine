# PunchLine 0.9.29

Abrir `game/project.godot` con Godot 4.4.1 y Forward+. El proyecto independiente `district_housing/project.godot` conserva su función de inspector.

## Cambios jugables

- **Araña:** el volumen físico contiene las esquinas de la armadura. Los cambios de superficie comprueban la forma completa y su recorrido; se superan bordillos y bordes de techo. Al saltar desde un techo puede girar y volver a apoyarse en el suelo. Conserva 50 HP, seis patas rígidas, escaneo, camuflaje y sus cuatro modos de visión.
- **C / clic central:** alterna el bloqueo. En tercera persona, la cámara libre gira alrededor de una araña quieta sin arrastrar su cuerpo. V cambia de vista y la rueda regula la distancia. La misma lógica funciona en DEMO y online.
- **Marcha y audio:** velocidad de araña 2.4 m/s; trípodes alternados de 0.175–0.26 s con predicción del próximo apoyo. Las patas de las réplicas se actualizan cada paso físico. El cuerpo renderizado sigue la pose interpolada compartida con la cámara. Las pisadas mecánicas se disparan al apoyar el pie y usan recortes breves; no se repiten en reposo. Escudo: −12 dB.
- **Autodestrucción:** disponible en un robot con vida del 20 % o inferior y cabeza conectada. El HUD muestra «AUTODESTRUCCIÓN DESBLOQUEADA · mantén G por 3 segundos». Soltar antes cancela la preparación. Al completar los 3 s suena una alarma, el robot pierde energía y se arrodilla durante otros 3 s. Luego explota: radio de 23 m para el Sentinel y 15 m para robots base, onda expansiva, daño con caída por distancia, ragdoll y muerte/reaparición habitual. El anfitrión valida vida y temporizadores.

## Mundo y presentación

La creación muestra una pantalla de carga animada: cálculo de semilla, casas e interiores, árboles, decoración, hierba, colisiones y cámara. La semilla se calcula fuera del hilo principal y la construcción se distribuye en lotes. La recepción de otro mundo online también utiliza este flujo.

La hierba mide 0.52–1.045 m antes de su variación de escala, con límites de culling ampliados para el viento. La configuración predeterminada conserva **87 edificios y 186 árboles**, y añade **106 decoraciones**: bancos, maceteros con flores, grupos de rocas y faroles. La máscara deja libres calles, estacionamientos, veredas y entradas.

Hay nubes animadas. En **AJUSTES → IMAGEN**, desactivar «Niebla volumétrica» selecciona **Sin niebla**; cambiar de preset conserva esa decisión. Las nubes siguen visibles.

Las casas incorporan cocinas, sofás, camas, mesas, estantes, alfombras, cuadros y luminarias cálidas. Diez viviendas predeterminadas tienen puertas de **1.10 × 2.15 m**, con hojas abiertas, además de los interiores preparados para el mecha. Se conservan los seis accesos medidos y las torres de tres/cuatro plantas.

## Demolición

[Investigación e implementación del sistema de destrucción](destruction_v0929.md): daños localizados, grietas, pérdida de soporte, tejados y losas que caen, daño por derrumbe y acumulaciones transitables. El estado permanece hasta reiniciar y se reconstruye para participantes nuevos. La opción de mundo indestructible se mantiene.

## Validación

Las pruebas vigentes están en `game/qa/v0929`. `python3 game/qa/v0929/run_checks.py` ejecuta las suites funcionales con preferencias aisladas; `run_network.py` inicia y cierra dos procesos ENet reales en el puerto 17969. Las pruebas de edificios y puertas usan los controladores del juego para entrar, recorrer habitaciones, subir escaleras y salir.

`layout_export.gd` produce diez configuraciones reproducibles; `audit_layout.py` contrasta sus polígonos contra los datos originales mediante Shapely. Las capas fuente y las restricciones geográficas se conservan. Los lotes 09 y 18 mantienen la limitación previa de acceso validado.

Resultados: **185/185 comprobaciones funcionales**, **39/39 de ENet** y **10 distribuciones auditadas**. El ZIP extraído e importado desde cero pasó además **17/17 pruebas de menús, personajes y juego**. Se capturaron doce vistas nativas, incluidas la carga, la araña, interiores, grietas, derrumbe y explosión.

La evidencia actual se guarda en [`evidence/update_v0929`](evidence/update_v0929). El render se verifica con Forward+ y Vulkan sobre Mesa/Lavapipe; es una comprobación visual por software. Las mediciones de esta máquina no representan FPS de una GPU de juego.

No se modifica la evidencia de versiones anteriores.
