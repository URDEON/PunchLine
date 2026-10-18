# Naoya 0.9.8 — Distrito, impactos y audio

Actualización sobre la 0.9.7 disponible en el entorno, conservada aparte. Se mantienen el alien aprobado, el rig, los pesos, las animaciones, los controles y las mecánicas. Sigue siendo un laboratorio de combate para afinar la base; el multijugador queda pendiente según lo acordado.

## Audio elegido para habilidad 1

La **habilidad 1 del juego**, en forma base, reproduce la ráfaga de `01-34-44`, como pediste en tu última aclaración. Se conserva el tono y la velocidad del recorte. No se duplicó esa muestra en la habilidad 3. La segunda toma `01-24-19` queda como respaldo sin reproducirse a la vez.

Los cuatro M1 usan recortes de `01-24-33`. El dash usa `01-25-23`, la entrada al vidrio `01-24-56` y el bloqueo `01-39-31`. También se incorporaron la aceleración evolucionada de `01-26-26` y la apertura/ambiente del dominio de `01-27-02`. Los sonidos de impacto se activan cuando se registra contacto, y el bloqueo ahora tiene su propio sonido al detener un ataque del NPC.

Para golpes fuertes, uppercut, downslam y contacto con el suelo se prepararon cuatro variantes con las grabaciones de puños y toallas que adjuntaste, conservando el contacto seco y añadiendo cuerpo grave. La interfaz utiliza cuatro sonidos Kenney. No se añadió otra pista musical.

En **Esc > Ajustes** aparecen el volumen de Combate y la opción Audio de referencia. Combate se mezcla dentro de SFX. La ráfaga, el dash y la aceleración siguen espacialmente al actor mientras suenan. Los originales anteriores siguen disponibles como respaldo.

`assets/audio/v098/sources.json` conserva nombres, recortes, procesamiento y hashes de los WAV decodificados usados para producir las muestras. `tools/build_audio_v098.py` permite repetir la extracción con los vídeos o WAV correspondientes y los dos paquetes de foley. Las grabaciones de referencia no se etiquetan como CC0; su procedencia está documentada en `RECURSOS_0.9.8.md`.

## Ragdoll

El impulso adicional se aplica realmente al cuerpo físico elegido: pelvis en golpes horizontales/downslam y torso en uppercuts. Su punto de aplicación está desplazado según el golpe, lo que genera un giro coherente. Las extremidades siguen respondiendo a las articulaciones existentes.

El giro inicial se limita a 6 rad/s y la velocidad angular de cada cuerpo a 12 rad/s para contener giros rápidos al chocar. Se conservan Jolt Physics, los 13 cuerpos, 12 articulaciones, límites distintos de codos/rodillas y hombros/caderas, CCD, longitudes y recuperación. No se borran huesos ni se sustituyen los pesos. La física por huesos sigue aplicándose al humano y los bandidos; las formas de maldición conservan su derribo anterior.

## Distrito ampliado

El suelo pasó de 100 × 100 a **160 × 160 m**. Se despejó el centro desplazando obstáculos al perímetro. Se añadió un circuito de 40 módulos de calle, ocho edificios de dos pisos con azoteas, tres rampas y dos pasarelas, usando las mallas y texturas Kenney adjuntadas. Los modelos repetidos comparten recursos y las colisiones usan formas simples en metros. Las 256 fachadas se agrupan mediante MultiMesh para reducir llamadas de render sin cambiar sus materiales ni geometría.

Se conservan el foso, ascensor, desniveles, estaciones interactivas, vidrios de práctica, guardia/duelo y Eco de ruta. **Esc > Explorar** incorpora Plaza abierta, Bulevar y Azotea del distrito. Las fachadas sirven de entorno y plataformas; no se añadieron interiores transitables.

Los skyboxes panorámicos de mañana y noche responden a la estación de iluminación existente. Las estaciones y navegación del menú incorporan iconos Kenney. Se reforzó el contorno del texto del HUD para poder leerlo con el cielo claro y se corrigió el tamaño de los rótulos de enemigos con la distancia.

## Compatibilidad y repetición

Se utilizó exclusivamente el **Godot 4.4.1 Linux que adjuntaste**, con Jolt Physics y GL Compatibility. No se descargó otro motor. La ejecución en tu Godot 4.7.2 Windows queda pendiente.

Extrae en una carpeta nueva, importa `project.godot` y pulsa F5. Se copian preferencias y récord del Eco desde 0.9.7, o 0.9.6 si faltan, sin sobrescribir datos actuales. Q dash, P personajes, Ctrl caminar, B emotes, K Kogane, E interactuar, rueda para cámara y Esc para el menú.

Los comandos, la demo y el grabador se conservan en `qa/`. Consulta `RESULTADOS_0.9.8.md` y `GRABACION_REAL.md` para la evidencia y los límites de la prueba.
