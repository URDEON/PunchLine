# PunchLine 0.9.20 — The Proyected / acero vivo

## Locomoción y cámara

- Zancada del Sentinel con mayor adelanto y elevación del pie. La duración se adapta al alcance del pie que sostiene el peso; ante escalones acorta el destino y al detenerse deja de generar pasos.
- The Proyected conserva los clips y pesos existentes; una capa SkeletonModifier3D posterior corrige apoyos, pelvis, torso y extensión de paso. Cede ante ataques, saltos, poderes, ragdoll y emotes. Aplicada a su forma base; los otros cuerpos conservan sus animaciones.
- C y clic central activan/desactivan lock. La cabeza del Sentinel deja de seguir el ratón al desactivarlo y regresa suavemente al frente. La tecla se reasigna en Ajustes > Teclas.
- Dos cierres mecánicos interiores en el cuello, sin rehacer la malla original. Lente radial ligera en primera persona de Sentinel, intensidad configurable de 0 a 0,35, aplicada al mundo antes del HUD.

## Daño modular y estabilidad

- Cuatro módulos de integridad local: brazo del cañón 65, brazo de apoyo 75 y cada tren inferior 85. El módulo más cercano al punto de impacto recibe el daño; no se destruyen piezas al azar.
- Los originales se ocultan y se copia su geometría compartida a un resto físico con colisión solo con mundo. No se duplican las mallas en disco. Cables y seis chispas por unión expuesta.
- Brazo derecho perdido deshabilita cañón; izquierdo deshabilita escudo; martillo exige ambos. Un tren inferior perdido reduce velocidad al 45% y bloquea propulsión; dos impiden caminar y pisar. M1 elige un miembro intacto.
- Los restos se conservan durante la vida de la transformación; morir inicia su retirada junto con el despiece general. Reaparición después de 3,85 s y de finalizar ambas limpiezas.
- Medidor segmentado de estabilidad proporcional a HP/maxHP; alertas por debajo de 20%, señal perdida al morir. Se conservan vida real, validación de golpes y reglas de combate.
- Reparada una referencia a mallas eliminadas al montar el cañón, que podía provocar errores al calcular módulos dañados.

## Interfaz y archivo

- Inicio con Demo (juego), Multijugador, Ajustes y Extras. Botón de apagado con confirmación; prototipos técnicos dentro de Extras.
- Ajustes compartidos entre inicio y pausa: Imagen, Audio, Cámara, Interfaz y Teclas; previsualizaciones 3D, perspectiva y transiciones, manteniendo controles legibles y accesibles con scroll.
- Catálogo rotativo de 25 estudios visuales/modelos en el inicio; Extras permite explorar arte, girar modelos y ver dos videos históricos identificados por su versión.
- Se reutiliza el arte y las mallas existentes. Los estudios de habilidades son renders del juego, no se presentan como nuevos dibujos de concepto. Los videos no prueban esta actualización.

## Multijugador y rendimiento

- El anfitrión decide daños y pérdidas. Los clientes reciben integridad, miembros perdidos, transformaciones de restos y lock. No se simula otra física del mismo brazo en el cliente.
- Se transmiten poses humanas después de aplicar apoyos. Los restos iniciales se colocan en su posición actual al conectarse, no en el antiguo punto de impacto.
- Máximo dos rayos por actualización de cada planificador local, cero en réplicas. Visores de menú limitados a 20 actualizaciones/s y desactivados cuando no son visibles. Se mantiene la geometría optimizada de 0.9.19.
- La lente utiliza una pasada de pantalla y puede desactivarse. No se afirma mejora de FPS sin medición gráfica.
