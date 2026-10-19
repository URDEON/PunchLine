# PunchLine 0.9.31

La semilla **923**, con densidad alta, genera **139 construcciones** frente a 87
en 0.9.29. Incluye **29 edificios de varias plantas**, 34 comercios y 41 viviendas
con patio. Se prueban candidatos adicionales entre parcelas y se conectan accesos
nuevos a la red peatonal existente. Las calles y datos fuente conservan su geometría;
se mantienen las seis casas medidas para el mecha y las seis torres de referencia.
La densidad baja tiene un presupuesto menor para conservar una diferencia visible.

## Equipamiento de edificios

Las plantas bajas tienen mostrador de conserjería, dos monitores de control,
silla ergonómica con respaldo, brazos, pistón y ruedas, sofá de espera, mesa de
centro, casilleros de correspondencia, espejo, acceso peatonal con torniquete y
maceteros. Las plantas superiores incorporan bancas y plantas. Se conserva libre
el recorrido central del mecha y la escalera en U.

Cada planta añade cámara CCTV, gabinete de extintor, basurero, reciclaje,
iluminación de muro, alfombra de acceso y baño para público/personal. El baño tiene
puerta abierta de tamaño humano, mesón con lavamanos cóncavo, grifo, jabón,
dispensador de papel, secador de manos, espejo y WC; los lockers quedan en la
galería lateral. Los espejos usan un acabado metálico pulido. Las luminarias aportan
luz cálida y las piezas grandes tienen colisión. El piso comercial tiene baldosas
y su cara inferior se pinta como techo, usando la misma geometría destructible.

## Patio de carga

La explanada `Parking_00` se equipa sobre su superficie original: vallado, dos
accesos para vehículos, rieles, zonas de carga y **29 contenedores metálicos** de
6.06 o 12.2 m. Tienen paredes independientes, suelo, techo y puertas; algunos están
abiertos y contienen pallets y cajas. Se puede entrar en los abiertos y caminar
por sus techos. Las posiciones de aparición quedan despejadas.

La consola de la grúa está en el extremo norte del patio, junto al cartel
**DESPACHO DE CARGA**. Acercarse y presionar **H** abre su cámara de trabajo:

| Tecla | Acción |
| --- | --- |
| I / K | Desplazar la grúa por los rieles |
| J / L | Mover el carro lateral |
| U / O | Subir / bajar el aparejo |
| Enter | Enganchar un contenedor alineado o soltarlo al llegar al suelo |
| H | Salir de los controles |

La grúa alcanza los contenedores de las filas centrales. Solo un jugador la maneja
a la vez. El host valida cercanía a la consola, vida, propiedad y límites del
movimiento; replica operador, carga y posiciones. Abandonar la consola o perder
conexión detiene el movimiento. Reiniciar el mundo devuelve las cargas a su lugar.

## Techos y araña

Los techos inclinados tienen colisión por ambos lados. Los laterales de cubierta
y la cumbrera también tienen soporte físico. Se vinculan los adornos a una pieza
de apoyo; al perderla se ocultan, incluyendo los detalles de ventanas y tejados.

Antes, un techo que dejaba de caer se sustituía por una malla sin colisión. Ahora
el host asienta su forma convexa completa sobre geometría duradera y conserva un
cuerpo estático sólido. Su pose se comparte y se reconstruye para conexiones nuevas.
El presupuesto mantiene hasta 64 restos estructurales grandes, además de las
acumulaciones físicas existentes. Reiniciar restaura las piezas y sus detalles.
En derrumbes grandes, las cubiertas tienen prioridad sobre los pequeños elementos
interiores para entrar en el presupuesto de cuerpos físicos. Un asentamiento
recibido antes del paquete de daño no crea una segunda copia móvil del techo.

La araña usa el movimiento gradual de 0.9.30. El cristal se sitúa junto al plano de
fachada y los marcos y alféizares tienen colisión. Varios rayos bajo la huella
mantienen el apoyo al cruzar juntas pequeñas; el contacto se proyecta al eje del
cuerpo para evitar tirones laterales. Los salientes de ventana se recorren como
un paso hacia fuera, conservando la orientación de pared.

## Acabados y menú

Las veredas usan losas de **60 × 40 cm**, juntas con suavizado según el tamaño en
pantalla y variación por pieza. Se conserva la malla y colisión geográfica original.
El día usa cielo físico con reducción de bandas y la noche un cielo procedural,
sin ampliar la panorámica anterior. Las nubes y el modo sin niebla permanecen.

Los menús usan filtrado lineal, vistas 3D completas con MSAA y actualización continua.
Al pasar de un modelo a una ilustración, se oculta la textura del viewport anterior:
la transparencia de la ilustración deja de revelar aquel modelo. El fondo elimina
el grano animado y corrige la máscara de viñeta.

## Validación

```sh
python game/qa/v0931/run_checks.py
python game/qa/v0931/run_network.py
```

Las pruebas usan el controlador real, incluyen la ventana completa y la subida y
bajada de las escaleras con personajes y mecha, la grúa y los techos asentados.
Para la auditoría independiente de parcelas:

```sh
Godot --headless --path game --script qa/v0931/layout_export.gd
/workspace/punchline-tools/bin/python game/qa/v0931/audit_layout.py
```

Los resultados y capturas están en [la evidencia de esta versión](evidence/update_v0931/README.md).
El render se valida con Forward+ nativo sobre Vulkan por software; no mide el
rendimiento de una GPU de escritorio.
