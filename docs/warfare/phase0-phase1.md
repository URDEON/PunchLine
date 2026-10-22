# Warfare:District500 0.9.28 — Fase 0 y primera parte de Fase 1

## Descarga y ejecución

[ZIP completo de la rama Warfare](https://github.com/URDEON/PunchLine/archive/refs/heads/feat/warfare-district500.zip).
Extraerlo en una carpeta nueva, importar **`game/project.godot` en Godot 4.4.1**,
esperar la importación y ejecutar con **F5 → JUGAR**. No es un ejecutable Windows.

Evidencia incluida en el repositorio: [32 comprobaciones](evidence/phase1-results.json),
[registro de integración](evidence/phase1.log), [render Forward+](evidence/render.log)
y [arranque final](evidence/final-smoke.log). Los avisos están conservados en sus registros.

## Base protegida

- Repositorio: `/workspace/PunchLine`, árbol limpio antes de trabajar.
- Base: rama `work`, commit `7109b254d584004b6eabf0042fca6a5afc6e35cf`, versión 0.9.27.
- Rama de implementación: `feat/warfare-district500`.
- Referencia recuperable: `backup/punchline-0.9.27-before-warfare`.
- Bundle: `/workspace/work/warfare/backups/PunchLine-0.9.27.bundle`.
- SHA-256: `12f70db89cd728eded44ad748883318fef45233fcde0c6792ff8eb6721f81c46`.
- `git bundle verify` correcto; bundle sin prerrequisitos y con historial completo.
- Restauración mediante `git clone --bare` a `backups/restore-check.git`, seguida de
  `git fsck --full` correcto. La ruta es relativa al directorio de trabajo anterior.
- El `fsck` fuente mostró blobs sin referencia preexistentes, sin errores de integridad.
  No se ejecutó limpieza de objetos. Los ZIP y copia 0.9.24 siguen intactos.

Recuperación en OTRO directorio, sin sobrescribir cambios:

```sh
git clone /workspace/work/warfare/backups/PunchLine-0.9.27.bundle /ruta/a/PunchLine-restaurado
git -C /ruta/a/PunchLine-restaurado switch --detach backup/punchline-0.9.27-before-warfare
```

El bundle contiene los archivos versionados y sus recursos, no la caché regenerable `.godot`.

## Integración

El arranque abre `ui/warfare_menu.tscn` y después `game_modes/warfare_practice.tscn`.
No se instancian `scripts/main.gd`, robots antiguos, habilidades, HUD de lucha ni fusión.
Los archivos históricos se mantienen inactivos en disco hasta separar las dependencias
de Sentinel. La eliminación física completa del legado queda pendiente.

El adaptador `world/district500/warfare_district.gd` instancia las escenas originales
de terreno y viviendas. Conserva los 77 edificios, interiores, escaleras y colisiones;
no regenera datos geográficos. Reutiliza vegetación y niebla existentes. El punto de
inicio está frente a un edificio de tres plantas para facilitar las pruebas de interiores.

El soldado utiliza una cápsula y un esqueleto de 17 huesos. El modelo provisional original
incluye casco, visor, chaleco, mochila, protección y enlace de muñeca. La imagen aportada
sirve como referencia general de equipamiento, sin copiar marcas, parches ni logotipos.
Puede reemplazarse el componente visual sin reescribir movimiento, entrada o salud.

La marcha procedural sigue distancia horizontal, se detiene al bloquearse y mezcla salto
y postura agachada. No incluye todavía IK, retargeting, AnimationTree ni animaciones de combate.

FPS y TPS comparten cuerpo y esqueleto. Se oculta únicamente la cabeza local en FPS.
Al mirar abajo, un pequeño avance estabilizado de la lente permite ver las piernas;
una consulta al escenario limita ese avance ante paredes. La cámara sigue una
transformación interpolada y estabilizada, sin heredar todo el
movimiento óseo. TPS usa SpringArm volumétrico y cambio de hombro. Bodycam ofrece
balanceo, sway amortiguado, reacción al aterrizar y FOV suave. Se pueden reducir/desactivar
los movimientos y la lente reutilizada; esta última está apagada por defecto.
No se añade desenfoque de movimiento ni se cambia el renderizador.

Salud independiente, observación al incapacitarse y reaparición a los 2,5 s; pausa con
opciones, reaparición manual y regreso al menú. No hay todavía daño por zonas, ragdoll
ni apoyo médico. Las opciones nuevas usan un archivo independiente de las de PunchLine.

## Archivos y motivos

Modificados: `game/project.godot` (versión, arranque y opciones),
`game/scripts/build_info.gd` (título), `README.md` y `CHANGELOG.md` (uso y alcance).

Creados, bajo `game/`:

- `core/warfare_settings.gd`, `unit_health.gd`, `performance_recorder.gd`: opciones,
  salud y telemetría sin controlador antiguo.
- `units/soldiers/soldier.tscn`, `soldier.gd`: composición del personaje.
- `units/soldiers/soldier_command.gd`, `soldier_input.gd`: órdenes y entrada.
- `units/soldiers/soldier_tuning.gd`, `default_soldier.tres`: parámetros editables.
- `units/soldiers/soldier_movement.gd`: cápsula, postura, gravedad y escaleras.
- `units/soldiers/soldier_visual.gd`, `uniform.gdshader`: cuerpo y animación provisionales.
- `units/soldiers/soldier_camera.gd`: FPS/TPS y bodycam.
- `world/district500/warfare_district.gd`: carga directa del distrito existente.
- `game_modes/warfare_practice.tscn`, `warfare_practice.gd`: ciclo jugable y reaparición.
- `ui/warfare_menu.tscn`, `warfare_menu.gd`: menú y previsualización del modelo.
- `ui/warfare_hud.gd`, `warfare_options.gd`: HUD, pausa y ajustes.
- `tests/warfare_phase1_test.gd`, `render_warfare.gd`, `run_warfare.py`: validación integrada.
- Los `.uid` asociados y este informe en `docs/warfare/`.

Se reutilizan `terrain_steps.gd`, `body_lens.gd`, módulos de ambiente y sus recursos.
No se modifican escenas/datos del mapa, modelos Sentinel, articulación, audio,
controladores antiguos ni el renderizador.

## Verificación

Ejecutado con **Godot 4.4.1 estable y Jolt**: **32/32 comprobaciones**.

Se prueban menú real, aislamiento del legado, recursos conservados, anatomía del rig,
entrada humana, diagonales, velocidades, salto/aterrizaje, agachado y techo bajo,
80 cambios de vista sin nodos adicionales, visibilidad FPS/TPS, mouse, accesibilidad,
ausencia de geometría corporal en la vista cercana al mirar hacia abajo,
cámara TPS y límite de avance FPS contra una pared interior, subida/bajada completa de edificios de tres y cuatro
plantas, pausa, salud, observación, reaparición y tres ciclos menú/práctica.

Velocidades medidas por la prueba: caminar 2,1 m/s, correr 4,6 m/s, sprint 6,5 m/s.
Son parámetros ajustables de videojuego.

Prueba de estabilidad: **120 segundos simulados**, `--headless --fixed-fps 60`, con
cambios periódicos de cámara. Nodos constantes: **17.058**; recursos: **9.906**.
Memoria estática observada en ese pase: **154.838.886–154.975.802 bytes**.
Tiempos de física: **2,450–21,229 ms**; proceso: **1,297–3,414 ms**.
Son monitores de este entorno compartido, sin renderer gráfico; no son FPS de juego
ni un benchmark de GPU. El registro detallado está en `phase1-results.json` externo.

Los primeros pases detectaron errores de inferencia de tipos, un Callable vacío,
limitaciones de captura de cursor en headless y la pose inicial incorrecta del modelo.
Se corrigieron antes del pase final. Un pase concurrente con render por software emitió
un aviso de máximo de trabajos de Jolt, que volvió a aparecer en pases sin render
concurrente. El pase final de 32/32 también lo registró. No se confirma la causa:
queda pendiente investigar el planificador físico y repetir bajo carga en hardware objetivo.

El arranque headless adicional tras ajustar la cápsula no registró errores de script,
pero emitió un aviso de interpolación sobre una jardinera estática del mapa existente
(`Non-interpolated instance triggered from physics process`, indicado por Godot como
posiblemente benigno). Se conserva como pendiente de revisión, sin modificar el mapa.

También se ejecutaron las seis pruebas Python del planificador existente: **6/6**.

La prueba gráfica usa Xvfb y **Forward+ / Vulkan con llvmpipe por software**, y comprueba
captura de mouse al entrar y al reanudar. Las capturas corresponden a menú, TPS, cuerpo
visible en FPS, bodycam y opciones. La revisión visual no sustituye una prueba de
comodidad y rendimiento en el equipo del jugador.

## Límites y próxima tarea

- Modelo/marcha provisionales; falta revisar todas las posturas y añadir animación/IK.
- Sin disparo, bots, captura de objetivos, vehículos o red nuevos.
- Sentinel conservado, todavía no controlable. El menú lo muestra deshabilitado y
  pendiente de Fase 4. La fusión antigua no se ejecuta.
- Distrito completo cargado: sin streaming físico ni LOD nuevo. Permanecen los 5.515
  cuerpos estáticos de viviendas y 62 del terreno. El culling existente no los descarga.
- No se diagnosticó la caída histórica de FPS ni se midió GPU/VRAM en la RTX 3050.
  No se declara alcanzado el objetivo de 60 FPS a 1080p.
- No se anuncian como ejecutadas pruebas antiguas de combate, animación o red.

Siguiente cambio: revisar movimiento/cámaras en el equipo de juego y registrar una
sesión real; después implementar una sola arma configurable y reacciones acotadas
de Fase 2. Mantener bots, Sentinel y vehículos en sus fases respectivas.
