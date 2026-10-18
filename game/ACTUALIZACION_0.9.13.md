# PunchLine / Naoya 0.9.13 — Fusión G

La habilidad G usa el `fusion_g.gd` editable del ZIP recibido. El proyecto anterior completo permanece en el menú Individual/Multijugador: no se reemplaza por la escena de demostración. La copia 0.9.12 se conserva separada como respaldo.

## Fusión

- G con Robot inicia una secuencia de 11,5 segundos. El chasis actual asciende primero; llegan los otros tres, cada uno una vez, con propulsores visibles y audio espacial. Se conservan los GLTF, sus clips Idle y los materiales originales. El robot inicial copia el color que lleva el jugador.
- Los cuatro convergen en el núcleo; las 22 piezas del GLB suministrado caen y encajan en el orden original, conservando sus transformaciones finales. Hay sonidos de encaje y una onda final.
- Se mide la geometría real para normalizar la altura: robot normal 2 m; Rust Vanguard 4 m exactos. Escala uniforme, sin cambiar proporciones o texturas. `fusion_finished` se emite una vez al completar la secuencia.
- El controlador `scripts/fusion_controller.gd` bloquea ataques, movimiento, salto y activaciones repetidas durante el montaje. Desactiva temporalmente la colisión del jugador; una barrera ligera protege la zona de ensamblaje y se elimina al terminar o reiniciar.
- Si un techo u obstáculo ocupa el volumen de montaje, busca un punto abierto próximo en la plaza. Los robots entrantes elevan su ruta al detectar edificios. La cámara comprueba obstáculos mediante rayos y vuelve suavemente al seguimiento. Estas comprobaciones geométricas no sustituyen la revisión visual manual de todos los interiores.
- Al terminar, se activa un controlador de desplazamiento rígido con cápsula de 4 m, cámara adaptada, gravedad y colisión con el escenario. WASD mueve, Ctrl camina. Los pasos combinan golpe grave y metal; las cámaras de jugadores a menos de 4 m reciben una vibración atenuada según distancia y su ajuste de cámara.
- Cambiar de personaje, reaparecer o usar Esc > Combate > Reiniciar fusión restaura el controlador anterior, su colisión y visibilidad. La prueba de G puede reiniciarse desde ese menú. La secuencia aislada está en `FusionDemo.tscn` y en el menú inicial.
- El montaje y la forma final se incluyen en snapshots online; los efectos y sonidos usan la autoridad del anfitrión. El protocolo requiere que todos utilicen 0.9.13.

**Límite deliberado:** las 22 piezas son mallas rígidas; no se añadió un esqueleto ni pesos funcionales. El desplazamiento final todavía no articula brazos o piernas. M1, dash, salto y habilidades de combate de Rust Vanguard quedan bloqueados y el HUD indica «Próximamente». No se inventaron animaciones ni un ragdoll para este modelo.

## Efectos de las formas base

`scripts/robot_skill_vfx.gd` añade geometría ligera con desaparición automática y un máximo de 48 efectos activos. No cambia daño ni hitboxes:

| Chasis | Identidad de efectos |
|---|---|
| Leela | Arcos de patada, lanzamiento vertical y anillos de caída |
| Stan | Carga concéntrica, arco de martillo y estelas pesadas paralelas |
| George | Dobles arcos, avance y creciente de patada |
| Mike | Círculos defensivos y arco dorado del counter |

Se corrigió además una referencia de ataque que podía quedar vacía cuando un counter interrumpía el contacto del robot. Los rigs, clips y ragdolls anteriores siguen utilizándose en las formas base.

## Interfaz

Se tomó de los videos la composición lateral con personaje 3D, niebla, tipografía clara, selección de pincel y fundidos. La interfaz utiliza el propio Rust Vanguard, gráficos originales y sonidos existentes; no usa los MP4 como fondo ni como animación editable.

- Menú inicial: Jugar, demostración G, controles y salida; Individual y Multijugador permanecen disponibles.
- Pausa: navegación lateral, contenido desplazable, ajustes y casos de prueba existentes; retrato 3D y transiciones de apertura/cambio de página. El selector conserva su despliegue y cierre animados.
- Resoluciones pequeñas: navegación compacta y redistribución de columnas. Los controles de nombre online se mantienen editables.
- Nuevos ajustes: pantalla completa, VSync y movimiento de interfaz; se conservan volumen, cámara, HUD y controles anteriores.
- En online, abrir el menú bloquea solo las entradas locales. No pausa a los demás.

## Recursos y respaldo

`assets/originales/` contiene los cuatro GLTF del ZIP recibido y las texturas extraídas por Godot, necesarias en la exportación. `assets/fusion/` contiene el GLB de 22 piezas sin modificar y su información de despiece. El Meshy original sin rig operativo se conserva en el respaldo de fuentes, sin cargarlo durante el juego.

El script recibido antes de editar está en `qa/fusion/original_recibido/fusion_g.gd.txt`. No se utilizaron créditos de Meshy, nuevos modelos generados ni otro editor de Godot descargado.

Pruebas, comandos y límites: `RESULTADOS_0.9.13.md`. Pasos manuales: `qa/fusion/PRUEBA_MANUAL.md`.
