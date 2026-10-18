# PunchLine 0.9.14 — Mechas articulados

Rust Vanguard ahora tiene un rig mecánico de 22 pivotes, locomoción, sonido de apoyo de pies, 300 HP y un HUD holográfico. La 0.9.13 permanece separada como respaldo. Se conservaron los modelos, proporciones, texturas y clips originales de los cuatro chasis.

## Movimiento y combate básico

`scripts/mecha_articulation.gd` articula las piezas rígidas existentes. Los pivotes de hombros, codos, caderas, rodillas y tobillos se obtuvieron de los vértices que comparten los módulos. La información está en `assets/fusion/articulacion_v0914.json` y su copia de ejecución `articulacion_data.gd`.

- La activación ocupa el tramo final de la secuencia original de 11,5 s: baja los brazos, flexiona y asienta el cuerpo antes de entregar el control. El menú también muestra la pose articulada.
- Idle, marcha, carrera pesada, caída y aterrizaje usan poses procedurales con interpolación de cuaterniones. Las piernas utilizan IK de dos segmentos; el ciclo avanza por distancia recorrida, no solo por tiempo. La suela del pie de apoyo corrige pequeñas diferencias de altura durante la mezcla.
- El eje visual se gira 180° para que el frente del GLB coincida con `facing_forward()`, tanto localmente como en la réplica.
- Altura nominal de pie: **4 m**. Vida máxima: **300 HP**. Velocidad: **2,35 m/s**, o **1,05 m/s con Ctrl**. La cápsula conserva 4 m de altura y radio 0,88 m.
- La transformación conserva el porcentaje de vida: 50/100 pasa a 150/300. Salir vuelve a 50/100. No añade una curación completa.
- **M1 pesado**: golpe básico alternando brazos, alcance 4,2 m, daño 14, contacto a 0,50 s y recuperación de 1,15 s. Respeta guardia, obstáculos, daño y derribo existentes. **F** activa guardia frontal con su pose. Las habilidades especiales 1–4, salto y dash del fusionado siguen reservadas para una iteración posterior.

Este rig es una jerarquía de piezas rígidas; no se añadieron pesos orgánicos ni retopología. Los vértices y UV del GLB permanecen intactos. Los ragdolls y clips de las formas base continúan usando sus sistemas anteriores.

## Ultimate de los cuatro robots

Había tres causas del fallo: las llamadas de ataque enviaban carga cero, `add_charge()` descartaba a los robots y el HUD ocultaba la energía.

Ahora M1 válido otorga 2 puntos; remates y habilidades usan 3,5, repartidos cuando tienen varios contactos. Los golpes fallidos, bloqueados o rechazados no dan energía. Los cuatro chasis usan la misma barra y conservan la carga al reaparecer como otro robot. Cambiar de personaje reinicia su energía.

G requiere 100 puntos y los consume al iniciar. Los botones de laboratorio pueden preparar una prueba con carga completa; están restringidos al modo Individual. En multijugador las acciones, golpes y energía los valida el anfitrión.

## Audio y efectos

- Tres pasos derivados combinan los niveles pesados de **Servo: Robots and Mechs** con impactos del archivo `3-legged-robot-walker`. Se eliminaron entradas/salidas bruscas y se alternan las variaciones.
- El paso se emite al apoyar la suela, con el cuerpo en el suelo y desplazándose. Hay una comprobación de suelo por rayo. No se emite al estar quieto, bloqueado por una pared, cristalizado o suspendido.
- `inside-the-robot` aporta un bucle espacial suave del núcleo. Los servos acompañan activación y M1; metal y vibración acompañan el asentamiento. Se mantiene la sacudida atenuada a menos de 4 m.
- `mecha_thruster.gd` reemplaza los conos sólidos por un chorro con núcleo blanco, capas celestes/azules, ruido animado y estela de partículas. La intensidad sigue el vuelo y se apaga después de la convergencia.
- Se retiraron los aros de ensamblaje. Los encajes generan pequeñas nubes y el impacto final genera polvo gris/beige en expansión.
- `mecha_dust.gd` y `mecha_cloud.gdshader` generan capas suaves con ruido procedural, variación de tamaño/rotación y densidad decreciente. Las vidas son 0,55 / 1,15 / 1,65 s. Hay un límite de 10 grupos y 440 partículas por sistema. Forward+ dispone de la ruta GPU; **Compatibility utiliza el fallback CPU**, que es la ruta comprobada aquí.

## HUD y multijugador

Los robots base y la fusión adoptan los gráficos del paquete **Sci-Fi Holo Interface FREE Sample**: barra de vida, medidor radial, botones y marco visual. Las habilidades conservan dibujos, teclas, cooldowns e indicadores. Hay cuatro tarjetas en fila en escritorio y distribución 2×2 en ventanas pequeñas. El selector, configuración, emotes y nombres siguen disponibles. Al elegir Naoya se restaura su HUD.

Los snapshots transmiten el ciclo de marcha, ataque/guardia, fase y vida máxima. Cada cliente reconstruye las poses; los sonidos se envían desde el anfitrión. Las pruebas usaron tres procesos ENet reales. Se corrigió además el timeout de entrada: la conexión de transporte y la carga inicial de modelos tienen plazos distintos, con renovación al recibir actores.

## Entrega completa y recursos

`PunchLine_0.9.14_Proyecto_Completo.zip` incluye todos los recursos necesarios. Los GLTF derivados de `assets/fusion/mechas_compartidos/` comparten las texturas existentes: el compactador verifica igualdad de cada bloque de geometría/animación y de todos los píxeles. El GLB de las 22 piezas no se modificó; sus imágenes quedan embebidas al importar. Los originales recibidos se conservan en el respaldo opcional.

Ver `LISTA_CORRECCIONES_0.9.14.md`, `RESULTADOS_0.9.14.md` y `qa/mechas/PRUEBA_MANUAL.md`.
