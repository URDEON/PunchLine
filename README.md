# PunchLine

Proyecto editable de PunchLine **0.9.28**, con el juego completo y District500.
Semillas que cambian la distribución, viviendas con patios, tiendas y edificios de hasta cuatro plantas.
La configuración predeterminada genera **87 edificios**, 186 árboles y pasto con viento.

Rustcrawler conserva el modelo de referencia con cuerpo rígido a escala de la cabeza,
seis patas procedurales, salto y cámaras ajustables. **T** cambia visión nocturna, térmica y rayos X.
Casas destructibles por ataques del mecha, sincronizadas en multijugador, y nuevos sonidos
de pasos, impactos y ensamblaje extraídos de las grabaciones enviadas.

**AJUSTES → IMAGEN** incluye presets Rendimiento, Equilibrado y Alto, con iluminación,
vegetación, sombras, niebla volumétrica y efectos.

Abrir **game/project.godot** con Godot 4.4.1 y una GPU compatible con Vulkan.
La ciudad anterior fue retirada.

- [Novedades, controles y pruebas de 0.9.28](game/housing/docs/update_v0928.md)
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
