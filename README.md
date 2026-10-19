# PunchLine

Proyecto editable de PunchLine **0.9.30**, con el juego completo y District500.
Semillas que cambian la distribución, viviendas con patios, tiendas y edificios de hasta cuatro plantas.
La configuración predeterminada genera **87 edificios**, 186 árboles, hierba alta con viento y 106 decoraciones de parque.

Rustcrawler conserva el modelo de referencia con cuerpo rígido a escala de la cabeza,
seis patas procedurales a menor cadencia, salto, colisión de cuerpo completo y cámaras ajustables.
Los cambios entre suelo, paredes y techos recorren una curva gradual con giro suave del cuerpo y la cámara, también online.
**C / clic central** libera la cámara de la araña. **T** cambia visión nocturna, térmica y rayos X.
Destrucción localizada con grietas, pérdida de soporte, tejados que caen, daño por derrumbe
y escombros físicos persistentes, sincronizada en multijugador. Pisadas por contacto real y escudo más suave.

Con un 20 % de vida o menos, el robot desbloquea la autodestrucción: mantener **G durante 3 s**,
alarma y apagado durante otros **3 s**, explosión con onda expansiva, daño y ragdoll.
La creación del mundo muestra una pantalla de carga animada por etapas.

**AJUSTES → IMAGEN** incluye presets Rendimiento, Equilibrado y Alto, con iluminación,
vegetación, sombras, niebla volumétrica y efectos. **Sin niebla** se conserva al cambiar de preset.
Nubes animadas y viviendas amuebladas; diez viviendas predeterminadas tienen puertas de tamaño humano.

Abrir **game/project.godot** con Godot 4.4.1 y una GPU compatible con Vulkan.
La ciudad anterior fue retirada.

- [Caminata suave en paredes y techos: 0.9.30](game/housing/docs/update_v0930.md)
- [Destrucción, carga y otras novedades de 0.9.29](game/housing/docs/update_v0929.md)
- [Investigación y sistema de destrucción](game/housing/docs/destruction_v0929.md)
- [Niebla volumétrica y pasto](game/housing/docs/greenery.md)
- [Semillas, cabeza araña y controles](game/housing/docs/rustcrawler.md)
- [Casas para el mecha y contactos procedurales](game/housing/docs/confinement.md)
- [Edificios de tres y cuatro plantas](game/housing/docs/multistorey.md)
- [Historial de versiones](CHANGELOG.md)
- [Uso, integración, pruebas y pendientes](game/housing/README.md)
- [Overlay del distrito](game/housing/docs/district_overlay.svg)
- [Módulo reutilizable independiente](district_housing/README.md)

District500 se reconstruyó desde las cuatro capas del GeoJSON adjunto. Las tres capas
originales de bordillos/marcas no estaban en los archivos suministrados. No se exportó un ejecutable.
