# Autocrítica de la revisión 0.9.7

Tu reporte de deformaciones era válido. La comprobación anterior de huesos, longitudes y escalas no alcanzaba para demostrar que la malla se veía bien durante el ragdoll. La documentación anterior daba demasiada confianza a esos resultados. Ahora se prueba la deformación de los vértices, se revisan poses exportadas y se distingue claramente entre pruebas sin imagen, renders de recursos y gameplay real.

También faltaba verificar las unidades y ejes de las articulaciones. Encontré límites pasados con la unidad equivocada, anclajes débiles al saltar huesos auxiliares y una inestabilidad física dependiente del motor. Esta entrega corrige las unidades y los anclajes, usa Jolt explícitamente y añade límites visuales anatómicos. Conserva el esqueleto y los pesos del personaje.

El mapa anterior tenía desniveles útiles, pero no suficientes elementos para parecer un lugar ni suficientes interacciones. Estación 24 aporta recorridos elevados, calles, edificios, mobiliario y pruebas activables con E. Sigue siendo un escenario de laboratorio; todavía necesita una revisión artística y de iluminación con el juego visible.

La rueda de emotes anterior ocultaba demasiado el escenario y algunas entradas sólo variaban la velocidad del mismo movimiento. Se sustituyó por vidrio con una vista previa del rig, se incorporaron clips distintos del paquete recibido y se añadieron finales automáticos. No hay ocho bailes diferentes: el catálogo mezcla un baile con gestos y poses. Para ampliar los bailes hacen falta más clips compatibles o animación manual.

La proyección también necesitaba menos ruido: conserva el rastro que pediste, pero lo limita a cuatro paneles muy breves y dos delanteros móviles. Las siluetas se obtienen de la pose real. Hay que revisar visualmente la superposición transparente en el renderizador y resolución de tu equipo.

La pantalla virtual continúa bloqueada por sus conexiones locales. Haber dejado una solicitud de permisos esperando retrasó la entrega; no fue tiempo dedicado a mejorar el juego. No se produjo un video real ni se deben presentar estos renders como gameplay.

Lo que queda por comprobar es concreto: apariencia final de recuperación y articulaciones, lectura del vidrio y del menú, rendimiento gráfico y compatibilidad con Godot 4.7.2 Windows. Los resultados automatizados de esta versión acotan errores reproducibles; no prueban que ninguna combinación posible de golpe, suelo y pose pueda fallar.
