# District500 — módulo independiente para Godot 4.4.1

El piloto inicial ya se integró con PunchLine 0.9.24 y se extendió a **77 edificios**.
Abre `project.godot` para inspeccionar el distrito con cámara libre (WASD/QE; botón derecho
para orientar). Para jugar con los robots reales, abre **`../game/project.godot`**.

[Instrucciones, pruebas y límites de la integración](../game/housing/README.md).

Incluye planificador Python/Shapely, JSON original de 19 macro-lotes, GeoJSON original,
perfil medido del mecha, plan reproducible con semilla 923, escenas editables, scripts,
interiores, rampas y colisiones. `data/generated_plan.svg` identifica cada edificio;
los datos de sus accesos están en `data/generated_plan.json`. `data/pilot_plan.json`
conserva el taller piloto. `scenes/SyntheticPrototypeGallery.tscn` y `tests/synthetic_profile.json`
son fixtures de laboratorio, **no dimensiones reales de PunchLine**.

La escena District500 reconstruye las cuatro capas vectoriales suministradas. No se recibió
su escena original ni las capas de bordillos/marcas; están señaladas como ausentes.
El JSON y GeoJSON originales no se editaron. En lot_05 se documenta la prioridad de su
exigencia explícita de taller sobre la lista contradictoria de arquetipos.

`tools/setup.sh` prepara dependencias en este entorno. El Godot oficial 4.4.1 se verificó
con SHA512. `tools/validate_district.py` comprueba el plan real, incluidas las huellas físicas
de las rampas y los seis accesos de mecha. `tools/bake.gd` convierte un plan en escena:
solo ejecutarlo para regenerar, porque reemplaza la salida. El generador no actúa por frame.

Cada tarea cloud está aislada: usa el checkout existente y no crees un worktree.
No reemplaces el project.godot del juego con el de este módulo.
