# PunchLine 0.9.21 — Apoyos y daño coherente

## Robots base

Los cuatro chasis conservan sus clips Idle, Walk y Run originales, los materiales, las proporciones y los pesos del Mech Pack. Se añade un SkeletonModifier3D posterior a la animación para ajustar la altura de los apoyos al terreno.

- Leela y George utilizan sus tres tramos UpperLeg/MidLeg/LowerLeg; Stan y Mike, sus dos tramos UpperLeg/LowerLeg. Se mantiene el pie virtual original de cada rig.
- Los controles Foot.L/R de Leela y George sí deforman su malla y son independientes de la cadena. Ahora siguen al extremo corregido dentro del mismo modificador, antes de actualizar el skin; se incluyen en la pose transmitida.
- El ajuste mantiene longitudes y limita la corrección por articulación a 0,24 radianes. No mueve el CharacterBody, ni cambia velocidad, alcance o daño de los robots base.
- Se aparta al atacar, hacer emotes, saltar, propulsarse, quedar en vidrio, entrar en ragdoll o recuperar control. Los robots ocultos y las réplicas no realizan las consultas de terreno.
- Ajustes > Cámara > Apoyos de robots base permite volver a los clips sin la corrección. Preferencias y teclas de 0.9.20 se migran al nuevo directorio.

Este ajuste es de contacto vertical con el suelo. No se presenta como un nuevo paquete de animaciones ni como locomoción completamente generada desde cero. Las otras formas de The Proyected siguen pendientes de adaptación.

## Pérdida de miembros durante combate

- Un M1 que ya estaba comenzando se cancela al perder el brazo o la pierna que lo ejecuta. Ya no puede llegar al contacto usando una extremidad invisible.
- Perder el brazo opuesto conserva el M1 del miembro intacto. La protección de M1 del Sentinel frente a golpes normales continúa funcionando; destruir su miembro ejecutor es una pérdida estructural.
- El Pisotón sísmico elige la pierna izquierda cuando falta la derecha. Si pierde la pierna elegida durante la preparación se interrumpe correctamente.
- Una pierna destruida deja de emitir pasos, polvo e impulsos de cámara. No se añaden fragmentos o recursos pesados nuevos.
- El láser y el punto de mira del cañón se ocultan inmediatamente al interrumpir o morir, aunque el controlador ya haya entrado en la espera de reaparición.
- Reiniciar la transformación limpia los buffers de ataque y libera el despiece que está fuera del actor, evitando estados de ataque residuales y restos de la generación anterior.

## Réplicas y coste de CPU

- El estado de muerte transmite el tiempo de despiece que queda. Una réplica que llega tarde no reinicia toda la animación ni restaura las colisiones de un cuerpo vivo.
- El despiece se elimina cuando desaparece el actor o cambia su generación. El esparcimiento final sigue siendo cosmético local; la duración se sincroniza. Las extremidades destruidas en vida conservan la física autoritativa de 0.9.20.
- Las réplicas reutilizan una cápsula del Sentinel en vez de crear y asignar un recurso físico nuevo en cada actualización visual.
- Los apoyos de cada robot local consultan como máximo dos rayos cada 0,05 s. Las réplicas reciben la pose final y no ejecutan otro ajuste encima.

Se conservan la cabina, el lock configurable, la lente, la estabilidad, los menús, Extras y todas las habilidades anteriores. No se añadieron modelos ni sonidos nuevos. No se afirma una mejora de FPS sin medir una GPU real.
