# Evidencia de casas para mecha y contactos procedurales

`features.txt`: controlador fusionado real, entrada/salida de amarilla y azul, profundidad
agachada distinta, techo/pared, pies, cañón y recuperación; 20/20. También comprueba 71
entradas, tabiques y rutas interiores con el ancho conservador medido de 3,37 m.

`network/`: dos procesos ENet reales, 13/13, finalizan con 0. El anfitrión decide
presión, altura y puntos de contacto; el cliente reproduce la mano mediante IK y
corrige una alteración local. No representa una auditoría exhaustiva antitrampas.

`architecture.txt`: 11/11; 568 ventanas, texturas, accesos, envolventes y visibilidad.
Regresiones: taller 14/14, Rustcrawler 28/28, postura original 37/37, Python 6/6.
`district_validation.json`: 71 edificios y senderos, cero invasiones de capas protegidas.

`graphics.txt` y cuatro PNG: OpenGL real en Mesa por software. Se usan el mecha, HUD,
casas y físicas originales, con la simulación pausada solo al tomar cada captura.
Los errores de mano registrados miden la articulación respecto del objetivo geométrico;
no equivalen a una simulación física individual de cada dedo. No se midieron FPS de GPU.

Las escenas del distrito y prefabs se regeneraron expresamente para esta corrección.
El arranque del inspector independiente y la importación del editor finalizaron con 0.
Los avisos benignos de interpolación se conservan. Los logs normalizan espacios finales.
