# Destrucción estructural · 0.9.29

El impacto rompe una zona de la pared; los huecos afectan la colisión. Si se elimina suficiente mampostería portante, las partes que dependían de ella se desprenden. Las losas y tejados conservan su geometría al caer; los fragmentos menores chocan con el mundo y entre sí. El daño y el estado permanente pertenecen al anfitrión.

## Investigación aplicada

Se consultaron estas fuentes primarias:

- [NVIDIA Blast: estructuras de soporte, fragmentos, enlaces y esfuerzo](https://docs.nvidia.com/gameworks/content/gameworkslibrary/blast/blast.htm). Se aplican la separación entre daño, conectividad, representación física y presentación; la activación de cuerpos al perder soporte; y presupuestos de simulación.
- [NvBlastBond: área, centro y normal de las uniones](https://docs.nvidia.com/gameworks/content/gameworkslibrary/blast/1.1/api_docs/files/struct_nv_blast_bond.html). Motiva medir la capacidad de apoyo de cada planta y conservar una representación geométrica de las piezas.
- [Godot 4.4: cuerpos rígidos](https://github.com/godotengine/godot-docs/blob/4.4/tutorials/physics/rigid_body.rst). Los fragmentos usan masa, fricción, rebote, velocidad inicial y gravedad; sus transformaciones no se reescriben mientras los simula Jolt.
- [Godot 4.4: Jolt, márgenes y colisiones](https://github.com/godotengine/godot-docs/blob/4.4/tutorials/physics/using_jolt_physics.rst). Se emplean formas convexas, CCD y capas separadas para los fragmentos pequeños.

Implementación: GDScript, los materiales del edificio y Jolt de Godot 4.4.1. Las decisiones estructurales se calculan en el juego; los cuerpos dinámicos resuelven su movimiento con el motor físico.

## Cómo funciona

1. El primer impacto subdivide solamente el paño afectado. Paredes: celdas de aproximadamente 0.85 m; losas: 1.65 m. Conservan el material y su textura. El daño disminuye con la distancia al impacto y distingue mampostería, hormigón, madera, acero y vidrio.
2. Un impacto débil deja grietas. Al agotar la resistencia de una celda, se elimina su geometría y su colisión; las piezas vecinas permanecen. Las transformaciones se suben explícitamente al MultiMesh para que la imagen nativa coincida con el estado físico.
3. Un grafo de contactos conecta paredes, pisos, tejados, escaleras, cristales y mobiliario con los apoyos. La consulta usa una cuadrícula espacial por edificio. Las islas sin apoyo caen; también falla una planta cuando conserva menos del 30 % de su capacidad portante inicial.
4. Vidrios y muebles sin soporte se retiran junto con sus colisiones; las luminarias próximas a un techo desprendido se apagan. Los elementos grandes admitidos por el presupuesto caen con su forma y material originales. Los fragmentos menores son sólidos convexos irregulares.
5. El anfitrión calcula el peligro de los elementos que caen mediante volúmenes barridos, gravedad y consultas contra el mundo. Producen daño y ragdoll; los pisos intermedios pueden detenerlos. Este daño funciona aunque se desactiven los fragmentos pequeños en ajustes.
6. Los derrumbes dejan acumulaciones bajas y transitables con malla y colisión deterministas. Se generan igual para todos los participantes, se incluyen en el estado de nuevas conexiones y desaparecen al reiniciar el mundo.

## Presupuestos y multijugador

- Hasta 64 cuerpos de escombros en movimiento: por evento, 20 fragmentos pequeños y 8 piezas grandes.
- Hasta 192 fragmentos visuales en reposo y 64 grupos de acumulaciones estructurales físicas, de tres montículos cada uno. Las acumulaciones miden 0.16–0.25 m de alto.
- Los cuerpos pequeños usan la capa 64 y chocan con el escenario y otros escombros. Las acumulaciones permanentes forman parte de la colisión del mundo. La pausa individual congela los cuerpos y los temporizadores.
- El anfitrión replica las celdas fracturadas, su resistencia, las piezas retiradas, los edificios colapsados y las acumulaciones permanentes. La animación de fragmentos sueltos se simula localmente; el daño ambiental lo decide el anfitrión.
- Mientras un cliente genera el distrito, espera para confirmar el roster y conserva los paquetes de destrucción que lleguen. Recibir de nuevo la misma revisión no reproduce el impacto.

La conectividad y la capacidad por planta son una aproximación para el juego. La fractura de paños es una partición geométrica localizada; el cálculo no es un análisis de ingeniería ni un solver completo de esfuerzos. La caída física y el daño conservan presupuestos para permitir varias demoliciones durante la partida.

Pruebas y capturas: [informe de la actualización](update_v0929.md).
