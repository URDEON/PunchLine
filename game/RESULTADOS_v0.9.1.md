# Resultados ejecutados — Naoya 0.9.1

Motor del usuario: Godot `4.4.1.stable.official.49a5bc7b6`, Linux x86_64. Proyecto: copia separada de `Naoya_0.9_IMPORTAR_GODOT.zip`. Todos los casos siguientes se ejecutaron sin renderizado gráfico. Los guiones llaman a los sistemas reales del proyecto; sus estados/posiciones iniciales son preparación explícita de laboratorio.

| Suite | Aprobadas | Qué comprueba |
|---|---:|---|
| combat_test.gd | 37/37 | M1, Counter, habilidades, guardia, dominio y limpieza de formas |
| polish_test.gd | 25/25 | Aceleración/frenado, mezcla y buffers, ráfaga, variantes, pausa/ajustes y límites del HUD actual |
| presentation_test.gd | 22/22 | Animaciones cargadas, emote, Kogane, transiciones y estelas limitadas |
| assets_test.gd | 23/23 | Recursos existentes, rig, huesos, clips y audio que cargan |
| revision_test.gd | 60/60 | Reglas nuevas de 0.9.1 descritas debajo |
| Total de suites | **167/167** | Sin fallos ni errores de GDScript durante esas ejecuciones |
| review_demo.gd --revision | **8/8** | Demostración automatizada; no es video |
| Misma demo con --realtime | **8/8** | Ritmo en segundos y liberación por reloj de física; no es video |

Las cuatro suites anteriores se conservaron, ajustando expectativas cuando cambió intencionalmente el daño, la duración de Counter y el salto directo de laboratorio a FORM2. No se conservaron expectativas viejas que contradigan las reglas nuevas.

## Casos nuevos

- Selección sin rueda, prioridad del centro, ángulo/alcance, exclusión de muertos/derribados y blancos detrás de paredes; elegir alternativa visible.
- Velocidad progresiva, seguimiento de posición/velocidad, límite de giro, influencia de cámara y rumbo estable al perder objetivo. Sin blanco no hay autocombo.
- Compromiso con rumbo fijo, cámara sin corrección durante esos 140 ms y dash lateral real que evita contacto. Sin nueva invulnerabilidad ni refijación. Se prueba humana y evolucionada.
- Entrada normal de 18, carga 14; cercana de 18 con desplazamiento circular y final limitado. Sin entrada válida no hay retención gratis; guardia frontal, pared, cancelación y reinicio liberan estados.
- Counter activa 5 s exactamente, sigue activo antes del plazo y restaura animación después; reinicio limpia freeze y retención.
- M1 real ignora tumbados y recuperación; daño vuelve después de la protección. Cuarto golpe normal, uppercut y downslam siguen funcionando con los daños nuevos.
- Muerte con ultimate comienza FORM1 con 60 HP/cargas correctas; G exige su evolución; no hay salto normal BASE→FORM2; laboratorio sí puede prepararla explícitamente.
- Estacionario ataca sin perseguir, perseguidor avanza, evasor activa dash en compromiso y evita daño. Los tres selectores del menú operan sobre NPC independientes.

## Qué no se pudo comprobar

Importación: terminó, con errores de listeners del editor y cuatro `Parameter "t" is null` del renderer Dummy al guardar importaciones 3D. No hubo errores de parseo. La carga de assets aprobó, pero su apariencia no está validada. No se incluyen cachés `.godot`; el editor de destino reimportará los originales.

Captura: Xorg devolvió `Cannot establish any listening sockets`; `AF_UNIX bind` en carpeta escribible devuelve `Operation not permitted`. No arrancó una pantalla virtual utilizable, no se generó MP4 ni se pudieron revisar fotogramas/audio. Ver `GRABACION_REAL.md` y los registros de `qa/resultados_v091/captura/`.

La primera demo en tiempo real reveló una advertencia por Camera3D interpolada modificada desde `_process`. Se corrigió siguiendo [la documentación de Godot 4.4 para cámara manual](https://docs.godotengine.org/en/4.4/tutorials/physics/interpolation/advanced_physics_interpolation.html): la cámara sigue el blanco interpolado sin heredar interpolación física adicional. La repetición final pasa sin esa advertencia. La suavidad percibida todavía requiere video real.

Los límites de tarjetas del HUD se comprueban por coordenadas en cinco tamaños; no prueba fidelidad al dibujo, legibilidad o estética. El dibujo poligonal pertenece a 0.9.2. No se midieron FPS de renderer, calidad de sonido ni articulación física del ragdoll. Las estelas se limitan a ocho y el pool de voces a doce, pero eso no equivale a una medición de rendimiento.

## Repetir las pruebas

Reemplazar `/ruta/Godot_v4.4.1-stable_linux.x86_64` por el motor proporcionado; ejecutar desde la carpeta del proyecto. En Windows se puede usar la ruta del ejecutable compatible instalado con los mismos argumentos; aquí solo se verificó Linux 4.4.1.

```sh
/ruta/Godot_v4.4.1-stable_linux.x86_64 --headless --editor --path . --import
/ruta/Godot_v4.4.1-stable_linux.x86_64 --headless --path . --script res://qa/combat_test.gd --fixed-fps 60
/ruta/Godot_v4.4.1-stable_linux.x86_64 --headless --path . --script res://qa/polish_test.gd --fixed-fps 60
/ruta/Godot_v4.4.1-stable_linux.x86_64 --headless --path . --script res://qa/presentation_test.gd --fixed-fps 60
/ruta/Godot_v4.4.1-stable_linux.x86_64 --headless --path . --script res://qa/assets_test.gd --fixed-fps 60
/ruta/Godot_v4.4.1-stable_linux.x86_64 --headless --path . --script res://qa/revision_test.gd --fixed-fps 60
/ruta/Godot_v4.4.1-stable_linux.x86_64 --headless --path . --script res://qa/review_demo.gd --fixed-fps 60 -- --revision
/ruta/Godot_v4.4.1-stable_linux.x86_64 --headless --path . --script res://qa/review_demo.gd -- --revision --realtime
```

En esta sesión cada suite usó directorios XDG propios dentro de `/workspace/qa_v091/` para aislar preferencias. Los registros finales están en `qa/resultados_v091/`; las suites imprimen PASS/FAIL y terminan con código distinto de cero al fallar.

## Paquete

Se reconstruye con `qa/empaquetar_zip.py`: `project.godot` en raíz, carpetas explícitas anteriores a sus archivos y atributos de directorio compatibles. Excluye `.godot`, `.git` y `__pycache__`. La verificación comprueba CRC y reproduce extracción en orden, creando carpetas solo cuando encuentra sus entradas, y compara todos los bytes extraídos con el proyecto. El informe y SHA-256 final del ZIP se entregan junto al archivo; no se incluye el motor en este ZIP del juego.
