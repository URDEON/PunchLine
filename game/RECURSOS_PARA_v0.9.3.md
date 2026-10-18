# Recursos y estado de integración

Actualización 0.9.3 — Prueba de modelo: el usuario eligió conservar el alien y envió una versión con nuevas texturas. Ese modelo ya está integrado en BASE, optimizado a 12.000 triángulos y con un rig preparado localmente sobre el pack original. No hace falta descargar el modelo Quaternius ni obtener un rig de pago para esta entrega. Los candidatos siguientes quedan como referencias opcionales para las tareas pendientes; no se han incorporado nuevos packs de animación ni sonidos.

## Investigación anterior

Estos recursos se investigaron en sus páginas oficiales; **no se descargaron ni integraron en 0.9.1**. El proyecto actual conserva el rig y audio que ya traía. Se pueden enviar por un enlace de Drive con el ZIP completo; no hace falta trocearlo si es accesible mediante el conector o un enlace de descarga.

## Modelo humano con cara y esqueleto

[Universal Base Characters — Quaternius](https://quaternius.com/packs/universalbasecharacters.html), [descarga oficial en itch.io](https://quaternius.itch.io/universal-base-characters).

Solicitado: versión Standard gratuita, personaje masculino Regular que esté incluido, con rig Humanoid, texturas y licencia CC0. Preferir GLB o glTF + BIN + texturas; FBX rigged también sirve. OBJ por sí solo no trae un esqueleto para animar. No es un modelo oficial de Naoya y no se promete un rig facial expresivo: comprobar cara, huesos y posibles blend shapes cuando llegue. La edición Source con archivos .blend y proyectos/shaders completos es de pago; no necesitas comprarla para empezar.

## Animaciones sobre rig compatible

[Universal Animation Library — Quaternius](https://quaternius.com/packs/universalanimationlibrary.html), [descarga oficial en itch.io](https://quaternius.itch.io/universal-animation-library).

Solicitado: Standard gratuita en GLB o FBX, archivo de licencia CC0 y lista de clips. Prioridad: idle, locomoción en direcciones, salto/caída, dash, guardia, punches/kick, reacción fuerte y levantarse. Deben usar el mismo esqueleto o llegar con una pose de referencia para retargeting. El catálogo completo anuncia más de 120 animaciones, pero la descarga gratuita es un subconjunto: inventariar lo recibido antes de afirmar que contiene todos los ataques requeridos. Pro/Source amplían la oferta y no son obligatorios.

Alternativa opcional si faltan golpes: [Mixamo](https://www.mixamo.com/), con [condiciones oficiales de Adobe](https://helpx.adobe.com/es/creative-cloud/faq/mixamo-faq.html). Requiere cuenta Adobe; sus recursos se permiten en proyectos personales y comerciales, pero **no son CC0**. Entregar FBX del personaje en T-pose con skin y cada animación separada/in-place en el mismo rig, con nombres y procedencia. Revisar condiciones del archivo recibido antes de empaquetar recursos para redistribución.

## Impactos distintos a los actuales

Candidato pequeño: [Punch SFX de DavidW](https://opengameart.org/content/punch-sfx). Nueve archivos `punch_1.wav` a `punch_9.wav`; la página ofrece, entre otras, CC BY 4.0. Si se elige esa licencia habrá que incluir autor, enlace, licencia y descripción de ediciones en los créditos. Enviar los WAV originales y la licencia seleccionada. Es una alternativa para audicionar, no una afirmación de calidad sonora ya comprobada.

Alternativa CC0: [37 hits/punches de Independent.nu, publicado por qubodup](https://opengameart.org/content/37-hitspunches), archivo `independent_nu_ljudbank-hits_and_punches.7z` de aproximadamente 1,7 MB. Puede servir como capa corporal para diferenciar sonidos; es un recurso antiguo y hay que escucharlo para decidir si mejora los actuales.

No hace falta reenviar Kenney Impact Sounds: ese pack ya está presente. Después de recibir candidatos, seleccionar impactos ligeros/fuertes, comprobar inicio y duración, recortar silencios si procede, variar muestras y volumen, y sincronizarlos con contactos del rig. Frame, dash y dominio también necesitarán una audición propia; no se consideran resueltos por cambiar solo la altura tonal.

## Qué enviar junto a cada pack

ZIP original o archivos completos, nombre de edición, fuente exacta y LICENSE/README; para GLTF incluir BIN y texturas; para humanoide conservar esqueleto/skin/pose de referencia. Las transformaciones malditas requieren además modelos específicos con rig adecuado o una nueva construcción artística: un humanoide de este listado no sustituye automáticamente esas dos formas.

Para revisar visualmente lo ya hecho, enviar video o capturas del combate y HUD. La integración del siguiente rig exige una ejecución gráfica que permita revisar poses, filtros de guardia, colisiones de huesos y transición a recuperación.
