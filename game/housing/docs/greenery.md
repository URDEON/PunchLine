# Niebla volumétrica y pasto — introducidos en 0.9.27

**Actualización 0.9.28:** [árboles, pasto renovado, iluminación y presets](update_v0928.md).
Las cantidades de esta página corresponden a la entrega 0.9.27.

Abrir **game/project.godot con Godot 4.4.1**. El usuario eligió cambiar de GL Compatibility
a **Forward+** para utilizar niebla volumétrica nativa. El juego necesita una GPU y un
controlador compatibles con Vulkan. El proyecto independiente de geometría no cambia.

En **AJUSTES → IMAGEN**:

| Ajuste | Resultado |
| --- | --- |
| Pasto desactivado / bajo / medio / alto | Densidad y alcance de 0 / 36 / 58 / 78 m |
| Viento en el pasto | Movimiento de las hojas; cero deja el pasto quieto |
| Niebla volumétrica | Intensidad global y local; cero desactiva ambas |

Los cambios se aplican durante la partida y se guardan con las preferencias habituales.
En multijugador son ajustes visuales locales: no alteran colisiones, daño ni el mundo del
anfitrión. El distrito común utiliza la misma semilla para los dos jugadores.

## Generación

`district_greenery.gd` consulta los polígonos originales de Lots. Excluye Roads, Sidewalks,
Parking, las huellas de edificios y rampas, los senderos triangulados y los accesos
ensanchados para mecha. Las máscaras llevan margen para que las hojas y su viento
queden alejados de los bordes. Las esquinas usan contornos conservadores con unión miter.
Se consultan máscaras cercanas mediante una cuadrícula, sin raycasts por hoja.

Con semilla **923** hay **138.623 grupos de hierba** posibles, repartidos en los 19 lotes
y agrupados en **690 MultiMesh** de 16 m. Cada grupo tiene siete hojas modeladas; no son
planos con una textura opaca. La calidad media dibuja aproximadamente el 68 % y un shader
de viento reduce gradualmente el tamaño antes del límite de distancia. No hay Nodes por
hoja ni colisiones nuevas. Las sombras individuales del pasto están desactivadas.
Si el pasto está desactivado al cargar, sus instancias no se construyen hasta activarlo.

La semilla y los edificios efectivamente seleccionados determinan las ubicaciones.
Las variantes de mundo conservan las exclusiones y la misma semilla reproduce las
posiciones. Cada nivel de calidad utiliza un subconjunto distribuido por todo el bloque.

`district_ambience.gd` configura la niebla volumétrica de Environment y añade hasta dos
FogVolume por lote en espacios abiertos, lejos de edificios y accesos. El distrito por
defecto tiene **38 volúmenes**, con un shader de densidad suave que se desplaza lentamente.
Se integran con la luz y profundidad de la escena; no son sprites delante de la cámara.
El color de la bruma cambia entre día y noche. La resolución volumétrica está fijada en
48 para contener el coste. La niebla volumétrica requiere Forward+ y no está disponible
en GL Compatibility.

## Validación reproducible

La evidencia de esta entrega se guarda en `evidence/greenery_v0927/`, separada de versiones
anteriores. Pasaron 17 comprobaciones funcionales, 9 de red ENet, 15 del menú y
26 de cámara/salto de la araña. La auditoría de las 138.623 posiciones no detecta
invasiones en ninguna de sus cinco categorías. Los procesos finales terminan con 0.
El render real exige Forward+ y compara píxeles al desactivar pasto y niebla;
también captura la noche y las cámaras corporales del mecha y la araña.

```sh
GODOT=/workspace/godot441/Godot_v4.4.1-stable_linux.x86_64
"$GODOT" --headless --fixed-fps 60 --path game --script housing/qa/greenery_test.gd
/workspace/punchline-tools/bin/python game/housing/qa/audit_greenery.py \
  /workspace/.local/share/godot/app_userdata/PunchLine/greenery_qa.json
python3 game/housing/qa/run_greenery_network.py
"$GODOT" --headless --fixed-fps 60 --path game --script qa/rustcrawler/camera_jump_test.gd
```

Para capturas, iniciar Xvfb si no hay pantalla y ejecutar sin `--headless`:

```sh
DISPLAY=:99 \
VK_DRIVER_FILES=/workspace/gui-tools/root/usr/share/vulkan/icd.d/lvp_icd.json \
LD_LIBRARY_PATH=/workspace/gui-tools/root/usr/lib/x86_64-linux-gnu \
"$GODOT" --path game --rendering-method forward_plus --rendering-driver vulkan \
  --audio-driver Dummy --resolution 800x500 --fixed-fps 60 \
  --script housing/qa/render_greenery.gd
```

Estos paths corresponden al entorno cloud. En un equipo de juego Godot usa su GPU y
controlador Vulkan. Las capturas cloud usan Mesa/Lavapipe por software y no establecen
FPS para hardware de juego. La primera carga compila materiales; permitir varios minutos.
Las pruebas de red usan el puerto local 17966 y deben ejecutarse sin otro proceso usando
ese puerto. La auditoría Shapely comprueba todas las posiciones de forma independiente
contra los triángulos originales y las exclusiones. No se modifican los datos fuente ni
se vuelven a hornear edificios como parte de esta actualización.
