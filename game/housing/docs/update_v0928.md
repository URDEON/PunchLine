# PunchLine 0.9.28

Abrir **game/project.godot** con Godot 4.4.1 y Vulkan / Forward+.
La entrega incluye el juego completo, sus menús, personajes y mecánicas.

## Mundo por semilla

DEMO abre semilla numérica o de texto, ALEATORIA, densidad, día/noche y edificios
destructibles. La misma configuración reproduce el mismo plano en esta versión.
Ahora cambian posiciones, tipos, dimensiones, plantas, patios y variantes visuales.
Las calles, veredas, estacionamiento y polígonos originales permanecen intactos.
Se conservan los seis accesos medidos de mecha y las seis torres añadidas previamente.

La semilla 923 con densidad completa genera **87 edificios**, incluidos **24 comercios**
y **24 viviendas con patio**. Hay viviendas, tiendas con ocho rótulos, talleres,
almacén y apartamentos de dos, tres y cuatro plantas. Las casas azules mantienen el
acceso más ajustado para el robot; las demás conservan mayor holgura. Las escaleras,
interiores, ventanas y accesos son físicos.

En MULTIJUGADOR el anfitrión configura el mundo antes de CREAR PARTIDA. Al conectarse,
los clientes reciben su configuración antes de crear personajes. No utilizan su semilla
local para esa partida. Las preferencias de calidad de imagen siguen siendo individuales.

## Rustcrawler

Se conserva el GLB suministrado y su aspecto: sensor, antenas, armadura y seis patas.
El cuerpo y los segmentos se reconstruyen como piezas rígidas con sus UV y texturas;
se elimina la deformación radial del cuerpo. El conjunto central se ajusta al volumen
medido de la cabeza instalada y el collider se calcula desde ese tamaño. Las patas usan
IK de dos segmentos, alcance limitado, apoyos mundiales y trípodes alternos. Las
articulaciones llevan cubiertas mecánicas.

E expulsa la cabeza con el mecha fusionado y apoyado. Mantiene 50 HP, adhesión a paredes
y techos, salto, escaneo y camuflaje. E cerca del chasis permite regresar; perder sus 50 HP
activa la muerte y reaparición normales. V alterna primera/tercera persona y la rueda
ajusta la distancia. La cámara corporal excluye todas las piezas del modelo propio.

**T** (reasignable en TECLAS) recorre normal → nocturna → térmica → rayos X:

- Nocturna: luz infrarroja local, amplificación tonal y grano verde.
- Térmica: geometría de personajes a 40 m, colores de calor y comprobación de visibilidad.
- Rayos X: siluetas de personajes a 40 m a través de paredes. El chasis descargado
  aparece como señal fría. Son modos de visualización de actores, sin simulación térmica física.

La visión, movimiento, vida y habilidades de cada araña los valida el anfitrión.

## Destrucción

Puños, pisotones, martillo, ariete y cañón del mega mecha dañan la arquitectura.
Al romper una pieza se retiran su malla, detalles cercanos y colisión; el daño estructural
acumulado puede derrumbar el edificio completo, incluidas las colisiones del tejado.
Los edificios permanecen destruidos hasta reiniciar el mundo. La reaparición del jugador
no los reconstruye. Al iniciar otra vez DEMO se genera el mundo completo desde su semilla.

El anfitrión decide el daño en red y envía los cambios. Los jugadores que se conectan
reciben el estado previo de destrucción. Los escombros son una presentación local limitada
a 32 cuerpos, desaparecen a los siete segundos y no bloquean a los jugadores.
El ajuste «Edificios destructibles» permite desactivar el daño en ese mundo.

## Imagen y sonidos

AJUSTES → IMAGEN ofrece **Rendimiento / Equilibrado / Alto**. Aplican suavizado,
densidad de pasto, niebla, resolución de sombras, oclusión ambiental, iluminación
indirecta de pantalla y escombros. También se pueden ajustar pasto, viento y niebla
por separado. Los presets conservan la misma colisión de los árboles y los edificios.

Cielo diurno físico, iluminación nocturna diferenciada, ACES, sombras en cascada y
SSAO en equilibrado/alto; alto añade SSIL. No se implementó trazado de rayos.
Pasto de hojas geométricas con variación y viento, y árboles por semilla con troncos,
ramas y follaje animado agrupado por sectores. En la configuración predeterminada:
**186 árboles y 193.397 grupos de pasto**; la calidad limita cuánto se dibuja.

Los tres MKV enviados aportan ocho clips mono con fundidos: tres pasos mecánicos,
dos impactos y tres movimientos de ensamblaje. Se reproducen en contactos de pies,
fusión, reconexión e impactos; se conserva una capa grave bajo las pisadas. El interruptor
«Sonidos de tus referencias» permite volver a los anteriores. La procedencia, recortes
y huellas de los vídeos están en `assets/audio/mecha_v0928/sources.json`.

## Comprobación

Pruebas y capturas de esta entrega: [evidence/update_v0928](evidence/update_v0928).
Los scripts vigentes están en `game/qa/v0928`; las evidencias anteriores son históricas.
Se aprobaron 329 comprobaciones de juego, 30 de red ENet, diez planos reproducibles
con auditoría independiente de accesos y 193.397 posiciones de pasto sin invasiones.
El ZIP extraído pasó 17 comprobaciones de menú y juego tras importar sin caché inicial.
Las capturas nativas verificaron la térmica con objetivo visible/oculto (105/0 píxeles
muestreados) y rayos X a través de la misma pared (665).
Véase [informe de validación](evidence/update_v0928/validation_report.json).

```sh
GODOT=/workspace/godot441/Godot_v4.4.1-stable_linux.x86_64
export XDG_CONFIG_HOME=/workspace/.config XDG_DATA_HOME=/workspace/.local/share XDG_CACHE_HOME=/workspace/.cache
"$GODOT" --headless --path game --import
"$GODOT" --headless --fixed-fps 60 --path game --script qa/v0928/feature_test.gd
"$GODOT" --headless --fixed-fps 60 --path game --script qa/v0928/systems_test.gd
"$GODOT" --headless --fixed-fps 60 --path game --script qa/v0928/combat_test.gd
"$GODOT" --headless --fixed-fps 60 --path game --script qa/v0928/multistorey_test.gd
"$GODOT" --headless --fixed-fps 60 --path game --script qa/v0928/frontend_test.gd
"$GODOT" --headless --fixed-fps 60 --path game --script qa/v0928/world_reset_test.gd
"$GODOT" --headless --path game --script qa/v0928/layout_export.gd
/workspace/punchline-tools/bin/python game/qa/v0928/audit_layout.py
python3 game/qa/v0928/run_network.py
```

Red sin `--fixed-fps`, puerto local 17964. La validación gráfica requiere una pantalla:
`qa/v0928/render.gd` con Forward+ / Vulkan y sin `--headless`. En el entorno cloud se usa
Xvfb y Mesa/Lavapipe por software; las capturas no acreditan FPS de una GPU de juego.
Las capas originales Curbs, RoadMarkings y ParkingMarkings siguen sin haberse suministrado.
No se exportó ejecutable.
