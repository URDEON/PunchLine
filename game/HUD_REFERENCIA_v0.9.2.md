Actualización 0.9.2.1: lista bajo el retrato mediante triángulo dorado relleno; etiqueta P·PJ retirada; Naoya y dos Coming Soon deshabilitados; tamaño guardado entre 50–100%, inicialmente 80%; dibujos de Fase 1 y Fase 2. Esta instrucción posterior prevalece sobre el texto histórico siguiente. Se conservan Q dash y P selector. Ver CAMBIOS_v0.9.2.1.md y PENDIENTES_ACTUALES.md.

# Referencia recibida y próxima etapa

Actualización 0.9.2: la geometría, dibujos, estados, vida segmentada y cabeceras azules ya están implementados. P abre el selector de Naoya y Q conserva dash. La distribución se comprobó por coordenadas y con vistas vectoriales exportadas; falta revisión gráfica sobre el juego. Ver `CAMBIOS_v0.9.2.md` y `RESULTADOS_v0.9.2.md`. El texto siguiente conserva la referencia recibida antes de implementar.

El dibujo enviado en el chat manda en geometría y distribución. No se ha rediseñado el HUD en 0.9.1; conserva sus tarjetas y menú, con textos/temporizadores actualizados. Este documento evita perder la referencia al pasar a la siguiente versión.

La última respuesta del usuario reemplaza la tecla de la nota antigua: **Q sigue siendo dash y P será selector de personaje**. Números 1–4 para habilidades. Azul identifica cooldown.

Arriba izquierda: retrato circular de Kogane/personaje con base ornamental para selector; cuatro iconos de estado circulares con pequeños indicadores trapezoidales inferiores; tres segmentos de salud largos, inclinados y separados. Marcar/romper cada segmento vacío conservando la lectura del HP.

Abajo derecha: un conjunto conectado de cuatro polígonos irregulares, con pequeños espacios entre sus bordes. Proyección ocupa la pieza superior y lleva monito entre paneles fragmentados; Counter está abajo izquierda y muestra monito frente a pose plana de enemigo en frame; Golpe veloz queda abajo centro con puño y líneas de velocidad; Patada es la pieza alta derecha con monito pateando. Los números viven en pequeñas esquinas y los nombres sobre las franjas superiores. El azul del Counter del dibujo muestra la franja de cooldown, manteniendo nombre e ilustración visibles.

Implementación prevista: Control personalizado con polígonos y trazos simples, escala uniforme de cada grupo para preservar silueta, anclaje superior izquierdo/inferior derecho y márgenes seguros. Reflujo del menú y separación de ambos grupos en pantallas estrechas. Probar 1280×720, 1920×1080, 1024×768 y ventana estrecha, incluyendo nombres, números y texto de ajustes. No reemplazar los monitos por imágenes generativas o una cuadrícula.

Conectar dibujos/azul/segmentos con HP, cooldowns y estados reales. P requiere un roster definido; los perfiles de color de Kogane del proyecto no cuentan como personajes jugables. Con un solo personaje, el menú deberá mostrar únicamente ese personaje y no aparentar cambios de moveset que no existen. El roster adicional será una decisión posterior a la prueba de 0.9.1.
