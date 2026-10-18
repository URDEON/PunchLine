# Naoya 0.9.9 — Robot y revisión del distrito

Segundo personaje jugable en P y en el triángulo dorado del retrato: **Robot**. Al reaparecer se elige otro de los cuatro chasis, evitando repetir el anterior, y uno de sus cinco colores originales. No reemplaza al jugador Naoya ni a los bandidos.

| Chasis | M1 | 1 | 2 | 3 |
| --- | --- | --- | --- | --- |
| Leela | Patadas rápidas | Barrido frontal | Patada ascendente | Salto y caída |
| Stan | Puños fuertes y lentos | Puño cargado | Martillazo de área | Empuje pesado |
| George | Puños y patada final | Dos golpes sucesivos | Avance con contacto durante el recorrido | Remate de patada |
| Mike | Puños cortos | Guardia reforzada | Contragolpe frontal | No disponible |

El cuarto hueco permanece deshabilitado en estos chasis. Mike dispone de dos habilidades; los otros tres, de tres. G queda reservado para las transformaciones de Naoya. Los golpes respetan dirección, distancia, obstáculos, bloqueo, invulnerabilidad, aturdimiento y derribos del combate existente. Mike no hereda la penalización de cristalización del counter de Naoya.

Los cuatro modelos usan sus rigs, pesos y animaciones originales: Idle, Walk, Run, Jump, Kick, Punch cuando hay brazos, HitRecieve, Death y los gestos Dance, Hello, Yes y No. Leela nunca utiliza Punch. Cada robot dispone de su propio simulador y articulaciones: 11, 13, 15 y 13 cuerpos respectivamente, sin borrar huesos del modelo. Las animaciones se suspenden durante física y congelación; la recuperación devuelve el controlador original.

HUD y retrato cambian con el chasis, con dibujos de puño, patada, avance y counter, cooldowns y huecos indisponibles. B presenta cuatro emotes propios con vista previa. Naoya conserva sus ocho gestos. Esc > 02 / COMBATE incluye botones para probar explícitamente cada chasis. El Eco de ruta registra y reproduce el esqueleto del personaje utilizado; la reaparición cancela un recorrido activo para evitar mezclar rigs.

## Distrito y vidrios

- Calzadas de 8 m y aceras de 2 m: texturas de asfalto y pavimento repetidas en metros, cruces y pasos de peatones; se retiraron marcas de carretera ajenas al trazado.
- Se sustituyen los dos bloques laterales provisionales por las casas del distrito: sus colisiones ya no invaden los accesos.
- Fachadas con el mismo estilo e iluminación, materiales mates y mipmaps. Se conservan las ocho casas, 256 módulos de fachada, instancias compartidas y mapa de 160 × 160 m.
- Accesos a azoteas trasladados a los laterales: las rampas ya no cortan el bulevar.
- Azoteas y pasarelas sólidas: la geometría visible coincide con la superficie física, en lugar de una rejilla sobre una colisión invisible.
- Fotografía de cristalización basada en la malla deformada actual, sin un esqueleto animado duplicado. El tamaño se calcula con los vértices reales para incluir cabeza y extremidades.
- Frente y espalda se capturan consecutivamente con una única cámara y se almacenan como dos texturas independientes. Se mantienen las dos caras, duración de cinco segundos, rotura al primer golpe, sonido y limpieza de estados.
- Dash de los NPC selecciona izquierda, derecha, atrás o avance según su dirección, en lugar de utilizar siempre la evasión derecha.
- Ajustes y récord se recuperan primero desde 0.9.8, después 0.9.7 y 0.9.6, sin sobrescribir los datos actuales.

## Recursos y tamaño

Animated Mech Pack de Quaternius, CC0: Leela 2.368 triángulos/17 huesos; Stan 6.110/43; George 7.864/47; Mike 6.062/43. Se preservó el pack original. Los binarios se separaron de las imágenes duplicadas. Los 16 colores adicionales se codificaron como WebP **sin pérdida**, verificando igualdad de todos sus píxeles RGBA con los PNG de origen. Las tres texturas del enemigo siguen utilizando exactamente los mismos JPG, eliminando su copia adicional incrustada en el glTF.

`Naoya_v0.9.9.zip` contiene todos los recursos del juego y las pruebas. `Naoya_v0.9.9_Fuentes.zip` conserva fuentes antiguas de retargeting, modelos originales y PNG previos a la compresión. Este respaldo solo se necesita para repetir herramientas de preparación; se extrae encima de la carpeta del proyecto. No contiene otra parte necesaria para jugar.

## Estado y siguientes pasos

La ejecución automatizada utiliza exclusivamente el Godot 4.4.1 Linux suministrado, Jolt y Compatibility. Consulta RESULTADOS_0.9.9.md para los resultados finales. Las pruebas sin imagen no validan la calidad gráfica, el aspecto de las caras del vidrio ni el rendimiento de GPU. Quedan para la prueba manual del usuario, junto con Godot 4.7.2 Windows. No se graba video en esta entrega por preferencia del usuario.

Se comparó UAL1 con el pack actual: el ZIP recibido no incluye los Dodge_Left/Right de la captura. Conservamos los dodges existentes y el salto activo; no se reemplazan por Roll acelerado. El detalle está en COMPARACION_ANIMACIONES_0.9.9.md.

La siguiente fase debe decidirse después de probar los cuatro chasis y el distrito: ajustar contactos visuales, ritmos y balance; revisar sombras, transparencia y orientación con imágenes del juego; integrar únicamente los clips nuevos que mejoren los existentes. Multijugador continúa aplazado.
