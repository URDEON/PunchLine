# Evidencia de PunchLine 0.9.25

`features.txt` y `frontend.txt` proceden de una extracción del ZIP que comenzó sin
`.godot`. Tras completar la importación, pasan los 18 recorridos/comprobaciones y
las 15 comprobaciones del menú y la versión. Se comparan los archivos críticos con
la copia de trabajo. El personaje sube/baja tres plantas; el mecha sube/baja cuatro,
sin teletransportarse entre niveles. Se usa el controlador real con paso de tiempo fijo.

`cold_import_complete.txt` conserva los diagnósticos texture_2d_get del renderer
Dummy durante la primera importación masiva de los GLB originales. La pasada final
con --import no emite esos errores y los recorridos completan con 0. --import espera
los recursos pendientes antes de salir; se ha actualizado el comando del entorno.

`network/` contiene dos procesos ENet reales, 13/13 y salida 0/0: subida, bajada,
postura, mano bajo techo, HUD/protocolo de versión y corrección de posición alterada.
Esto no representa una auditoría exhaustiva antitrampas.

`architecture.txt`: 77 edificios, 799 ventanas, 11/11; geometría, texturas, accesos,
vidrios, huellas y visibilidad. `geometry.json`: seis añadidos reproducibles, sin
invasiones ni bloqueos de rutas existentes. Las regresiones de casas, taller,
postura y araña se conservan en sus logs.

`graphics.txt` y cinco PNG usan OpenGL real con Mesa por software, el juego y su HUD.
Las capturas colocan al mecha en puntos de inspección con física y articulación activas;
los recorridos completos se validan aparte. No se midieron FPS de GPU de escritorio.
Los logs conservan los avisos originales y normalizan espacios finales.
