# Cambios de PunchLine

## 0.9.30

- La araña recorre los arcos comprobados entre suelo, paredes y techos a lo largo de varios pasos de física, con aceleración y frenado suaves y velocidades limitadas. Se elimina el salto instantáneo al final del recorrido.
- Bordillos, salientes y losas usan el mismo recorrido gradual; las transiciones vuelven a comprobar las colisiones mientras avanzan.
- Cámara y cuerpo comparten la orientación interpolada, también al girar el horizonte en primera persona. Las réplicas online interpolan la orientación entre paquetes.
- Aterrizaje centrado sobre la superficie y margen para girar sin penetrar el suelo. Los saltos pedidos durante un cambio de superficie se conservan hasta completarlo.

## 0.9.29

- Araña: colisión cilíndrica que contiene la armadura, barridos al cambiar de superficie, subida de bordes, aterrizaje desde techos y cámara libre con C/clic central en DEMO y online.
- Caminata: 2.4 m/s, trípodes más lentos y predictivos; mallas rígidas, pies y cámara comparten la pose renderizada. Las réplicas animan las patas cada paso de física.
- Audio: pisadas mecánicas breves disparadas al plantar el pie, sin repetición en reposo; escudo reducido 12 dB.
- Autodestrucción crítica: aviso al 20 % de vida, G mantenida 3 s, alarma y apagado de 3 s, explosión de hasta 23 m, onda expansiva, daño, ragdoll y muerte/reaparición habitual. La autoridad de red valida el temporizador.
- Carga animada por etapas: semilla en un hilo de trabajo, viviendas y hierba construidas por lotes; también al recibir otro mundo online.
- Hierba de 0.52–1.045 m antes de variación de escala, 106 elementos de parque por defecto, nubes y opción persistente Sin niebla.
- Interiores con cocina, camas, sofás, mesas, estantes, alfombras y luminarias cálidas. Diez casas predeterminadas incorporan puertas normales de 1.10 × 2.15 m; se preservan los accesos medidos del mecha y las torres.
- Destrucción por celdas locales, materiales y grietas, conectividad estructural y capacidad de apoyo. Tejados y losas se desprenden físicamente; el derrumbe produce daño ambiental decidido por el host.
- Escombros convexos con fricción, masa e impulso, fragmentos en reposo acotados y acumulaciones físicas de colapso iguales para todos los clientes. Agujeros, escombros y daño se reconstruyen para nuevas conexiones y se limpian al reiniciar.
- Se serializa la recepción de mundos y se confirma el roster después de terminar su generación; el estado destruido no se pierde durante la carga.

## 0.9.28

- Rustcrawler rígido con su geometría original, escala ajustada a la cabeza e IK de alcance limitado.
- Visión nocturna, térmica y rayos X con T, también en multijugador.
- Semillas que generan distribuciones distintas; 87 edificios con semilla 923, comercios, patios y apartamentos de hasta cuatro plantas.
- Configuración del mundo compartida por el anfitrión y opción de edificios destructibles.
- Daño de ataques del mecha: piezas y colisiones se rompen, colapso estructural y estado para nuevos jugadores.
- Cielo físico, iluminación nocturna, ACES, SSAO/SSIL, pasto renovado y árboles por semilla.
- Presets Rendimiento, Equilibrado y Alto con ajustes de luz, vegetación y efectos.
- Ocho sonidos de pasos, impactos y ensamblaje procedentes de los tres vídeos enviados.
- Carga directa de geometría procedural y límite físico ampliado para el distrito mayor.

## 0.9.27

- Renderizado Forward+ para niebla volumétrica nativa, por elección del usuario.
- Niebla ambiental y 38 bancos volumétricos animados en los espacios verdes libres.
- Pasto procedural por semilla, agrupado en MultiMesh, con viento y distancia limitada.
- Exclusiones de edificios, accesos, senderos, calles, veredas y estacionamiento.
- Ajustes de calidad, viento e intensidad de niebla en IMAGEN.

## 0.9.26

- Cámara de la araña sin superposición con su modelo al caminar.
- Primera/tercera persona con V, distancia con rueda y protección contra paredes.
- Salto desde suelo, paredes y techos, con aterrizaje y patas recogidas en el aire.
- Controles, estado aéreo y orientación sincronizados en multijugador.

## 0.9.25

- Edificios procedurales de tres y cuatro plantas con interiores y escaleras.
- Versión centralizada en el proyecto, visible en menú, HUD, ventana y multijugador.
- Nombre estable para los datos guardados y recuperación de ajustes de 0.9.24.

## 0.9.24 y entregas anteriores

- Integración de District500 y viviendas accesibles con texturas y ventanas reales.
- Semillas editables, densidad, día/noche y cabeza araña Rustcrawler.
- Accesos para el mecha y contactos procedurales con techo y paredes.

Las entregas anteriores conservaron el mismo número de versión. Desde 0.9.25,
cada actualización entregada incrementa la versión y registra sus cambios aquí.
