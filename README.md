# Warfare:District500 — 0.9.28

## Descargar y probar en Windows

1. [Descargar ZIP de la rama Warfare](https://github.com/URDEON/PunchLine/archive/refs/heads/feat/warfare-district500.zip).
2. Extraer **todo el ZIP** en una carpeta nueva; no reemplazar la copia original de PunchLine.
3. En **Godot 4.4.1**, elegir **Importar** y seleccionar `game/project.godot` dentro de lo extraído.
   No seleccionar el proyecto inspector `district_housing/project.godot`.
4. Esperar la importación inicial y pulsar **F5**. En el menú Warfare, elegir **JUGAR**.

Es un proyecto editable, no un `.exe`. Esta entrega permite probar movimiento y cámaras;
el modelo es provisional y todavía no incluye disparo, bots ni Sentinel controlable.

## Alcance de esta entrega

Fase 0 (protección y aislamiento del arranque) y primera parte de Fase 1 (soldado y
cámaras). Abrir **`game/project.godot` con Godot 4.4.1** y ejecutar. Se conservan
**Forward+ / Vulkan y Jolt**, District500 y sus 77 edificios, interiores y escaleras.

El soldado provisional es original; un esqueleto y cuerpo completos sirven para FPS y
TPS. El nuevo arranque no instancia luchadores, habilidades ni la fusión antiguos.

| Control | Acción |
| --- | --- |
| WASD / mouse | Movimiento / vista |
| Shift / Alt | Carrera / caminata |
| Espacio / Ctrl mantenido | Salto / agacharse |
| V / B | FPS–TPS / cambiar hombro TPS |
| Esc | Pausa, opciones, reaparición y menú |
| F3 / F9 | Métricas / captura de 60 segundos |

Opciones: FOV, sensibilidad, inversión vertical, distancia TPS, balanceo, intensidad de
movimiento, bodycam, lente opcional, pantalla completa, vegetación y niebla. No hay
desenfoque de movimiento. En FPS solo se oculta la cabeza local. Modelo y animación son
provisionales; todavía no hay disparo, bots, vehículos ni Sentinel controlable.

- [Informe, archivos, resultados, respaldo y límites](docs/warfare/phase0-phase1.md)
- [Resultados de las 32 comprobaciones](docs/warfare/evidence/phase1-results.json)
- [Historial](CHANGELOG.md)

Pruebas con Python estándar y el ejecutable de Godot 4.4.1; guardar evidencia fuera de `game/`:

```sh
python3 -B game/tests/run_warfare.py --godot /ruta/a/Godot --evidence /ruta/a/work/warfare-qa
python3 -B game/tests/run_warfare.py --godot /ruta/a/Godot --evidence /ruta/a/work/warfare-render --render
```

La segunda orden requiere pantalla y Vulkan. El runner rechaza errores de scripts,
comprobaciones fallidas y ejecución incompleta. La prueba gráfica exige Forward+.

`config/name="PunchLine"` conserva `user://` como exige `AGENTS.md`. Ventana y menú
muestran Warfare:District500; las opciones nuevas usan `warfare_settings.cfg`.
La etiqueta `backup/punchline-0.9.27-before-warfare` conserva el estado original.
Los recursos heredados siguen en disco, inactivos desde el nuevo arranque; su limpieza
física se pospone hasta separar Sentinel y confirmar dependencias compartidas.

<details>
<summary>Referencia histórica de PunchLine 0.9.27</summary>

## PunchLine

Proyecto editable de PunchLine **0.9.27** con District500 y **77 edificios procedurales**.
Suelo visible y texturizado, casas con tejados y detalles, interiores y ventanas con vistas.
Se conservan las 71 construcciones anteriores y se añaden tres edificios de tres plantas
y tres de cuatro, con escaleras, interiores y balcones transitables.

La araña tiene primera persona sin superposición, tercera persona ajustable y salto desde superficies.

Niebla volumétrica nativa con **Forward+** y pasto procedural con viento en las zonas verdes.
Calidad del pasto e intensidad de niebla ajustables en **AJUSTES → IMAGEN**.

Abrir **game/project.godot** con Godot 4.4.1 y una GPU compatible con Vulkan.
La ciudad anterior fue retirada.

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

</details>
