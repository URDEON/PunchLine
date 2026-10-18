# PunchLine 0.9.24 — Informe de pruebas

## Resultado comprobado

Se ejecutó Godot 4.4.1 para Linux con Jolt y renderizador Compatibility en modo
headless. Las acciones de prueba fueron automatizadas sobre los controladores,
animaciones, colisiones, cuerpos físicos y RPC reales del juego.

| Grupo | Resultado final |
|---|---:|
| Regresión de combate, cristales, HUD, recursos y sistemas anteriores | 1138 / 1138 |
| Integración de personajes, mechas, locomoción, cámara y réplicas | 591 / 591 |
| ENet real: anfitrión y dos clientes en procesos separados, combate | 52 / 52 |
| ENet real: fusión, energía, piezas, pasos y sacudida por distancia | 22 / 22 |
| Seis suites ejecutadas contra el PCK exportado | 118 / 118 |
| Fusión mantenida durante 600 segundos con pausa/reanudación | Correcto |
| Integridad de la distribución modular | 670 archivos idénticos |

La prueba del PCK exportado comprende agache (37), articulación/primera persona
y fase 2 (17), locomoción humana (13), frontend (27), daño replicado (15) y
estabilidad (9). Se probaron también los arranques de menú, individual y online
del cargador distribuido. No se ejecutó el EXE de manera nativa en Windows.

## Mediciones relevantes

- Los cuatro chasis pasan bajo una cubierta de prueba de 1,55 m y se incorporan
  al retirarla. El Sentinel pasa bajo una cubierta de 2,95 m y recupera 4 m.
- La reducción física ocurre antes del movimiento: no empuja al controlador dentro
  del suelo mientras el suavizado visual termina de bajar la cabeza.
- El error máximo medido entre los anclajes del codo desprendido fue de 0,006 m
  durante su caída. Ambos cuerpos colisionaron con el suelo y se congelaron al pausar.
- El brazo del cañón tiene geometría dentro del frustum real de la cámara y el ojo
  permanece fuera del pecho y abdomen. Esto comprueba el encuadre, no su calidad estética.
- El apoyo humano medido en la suite de recuperación tuvo un error vertical máximo
  de 0,00184 m y no alargó los segmentos. Se conservan los ciclos originales.
- En la prueba prolongada, después del calentamiento: 1924–1928 nodos, 984 recursos,
  778,37–779,91 MB de memoria estática decimal y sin acumulación de efectos o tweens.
  La prueba se realizó durante el desarrollo de esta misma revisión, antes del último
  ajuste del protocolo de carga. Las suites de exportación y red verifican el estado final.

Los tiempos de CPU del entorno compartido varían con las pruebas concurrentes.
Estas mediciones no certifican FPS gráficos ni reproducen el hardware del usuario.
No se afirma que la caída original a 7–14 FPS haya quedado resuelta en su GPU.
Se incorpora un registro acotado de 60 segundos para medir ese caso en Windows.

## Transparencia sobre los fallos encontrados en las pruebas

Los registros iniciales se conservan. El resumen final identifica las repeticiones
que sustituyen los resultados anteriores; no se borran comprobaciones fallidas.
Se corrigieron estas expectativas antiguas del banco de pruebas:

- Mike tiene actualmente una tercera habilidad de movilidad; no solamente dos.
- El Sentinel actual tiene 112 módulos visuales; el banco ENet aún esperaba los
  22 del modelo anterior. Ahora compara con la escena real del anfitrión.
- Las pruebas de contactos usan un suelo controlado sin escombros. La ciudad,
  sus colisiones y spawns se comprueban por separado contra el recurso real.
- Los roles de red se identifican por nombre, porque el orden de conexión UDP varía.
- El sonido del último apoyo puede finalizar durante la frenada. Se mide reposo
  después de terminar los apoyos, comprobando también velocidad cero.
- Las chispas usan CPUParticles3D para el renderizador Compatibility del proyecto.

## Distribución y límites del entorno

El PCK completo se generó mediante la exportación oficial de Godot. El conector de
Drive rechazó su tamaño (190010976 bytes) porque admite hasta 104857600 bytes por
archivo. La distribución de Drive usa tres paquetes nativos creados con PCKPacker
y un cargador exportado con la misma plantilla Windows 4.4.1 x86_64. No se parchean
bytes ni se concatenan archivos. El cargador comprueba SHA-256 y monta los paquetes
automáticamente. Si falta un archivo muestra una explicación, sin cerrar de inmediato.

La comprobación de los 670 archivos exportados compara su MD5 con el original.
El ZIP completo y la carpeta Drive incluyen el mismo juego; no requieren CMD ni Godot.

No hay Wine ni pantalla gráfica en el entorno. No se entrega una grabación de gameplay
ni se presenta un render de Blender como una prueba del juego. Quedan para la prueba
manual Windows, calidad visual, FPS con GPU, audio escuchado y conexión WAN entre PC.

## Repetir las pruebas

En el proyecto se conservan:

- `qa/repetir_pruebas_v0924.py`: regresión general.
- `qa/repetir_mechas_v0924.py`: integración y posturas.
- `qa/network/repeat_v0924.py`: tres procesos ENet, escenarios `combat` y `mechas`.
- `qa/verificar_exportacion_v0924.py`: suites contra el PCK exportado.
- `qa/soak_v0924.gd`: prueba prolongada; `PUNCHLINE_SOAK_OUTPUT` permite elegir el JSON.
- `tools/bake_contact_hulls_v0924.gd`: regenerar perfiles de contacto de los rigs.
- `tools/export_windows_v0924.py`: exportar con una plantilla Windows de Godot 4.4.1.
- `tools/build_drive_distribution_v0924.py`: paquetes nativos y cargador de Drive.

Los ejecutores Python admiten `--help`; se conserva cada comando ejecutado en los
resúmenes JSON. Para probar la lógica se utilizó `--headless --max-fps 120` y
`NAOYA_QA_ARENA=legacy`; los escenarios ENet utilizan 60 FPS y una arena de contactos
controlada. La suite de ciudad carga el mapa real. Los archivos están en `resultados_v0924`.
