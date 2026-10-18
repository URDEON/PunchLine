# Naoya 0.9.4

Continúa la 0.9.3 que validaste con el alien elegido y sus texturas. Sigue las siete prioridades marcadas en tu lista: locomoción, guardia caminando, M1/patada, pack nuevo, fotograma 2D, dominio y Kogane. Incluye la corrección de postura y orientación de fase 2.

## Animaciones

- Transición desde la pose actual hacia reposo/carrera en 0,14 s, con mezcla de velocidad y dirección. La cadencia acompaña la velocidad real.
- Guardia y reacción a bloqueo se mezclan en columna, cabeza y brazos; las piernas mantienen la locomoción. Caminar con guardia conserva sus 2,2 m/s.
- El tercer M1 usa `Melee_Hook` de Universal Animation Library 2, adaptado a los 53 huesos del alien. Los demás M1 y la patada conservan clips existentes con contacto visual ajustado al instante real del golpe.
- Se conserva la malla, skin, pesos y texturas del personaje validado, los 64 clips originales y Running Man.
- El ZIP recibido contiene 43 clips reales. Se adaptaron cuatro candidatos; el hook se usa en combate y los demás quedan disponibles como recursos.

Daños, ventanas de combate, cooldowns, collider y duración de las formas se conservan.

## Fase 2

El modelo se coloca vertical en reposo y horizontal al moverse, con interpolación de inclinación y altura. Su cara estaba orientada hacia +X; la rotación visual ahora la mantiene hacia el frente en ambas posturas. Los apéndices acompañan el cambio; el collider permanece igual.

## Vidrio y fotograma

`assets/projection/GlassPane.glb` es el archivo enviado, sin modificar sus bytes. Se aplica un ShaderMaterial mediante Material Override: color celeste, transparencia base 0,04 y fuerza de borde 0,92. El Fresnel usa el valor absoluto de normal/vista para evitar volver opaca la cara trasera. Una máscara sobre la geometría original refuerza suavemente sus bordes, sin añadir marcos, partículas ni fragmentos al panel.

Al atrapar un actor, un SubViewport aislado captura su pose y materiales actuales en una textura con fondo transparente. La representación pasa a un plano 2D; el collider y estado de combate pertenecen al actor original. Al terminar se restauran modelo y animadores y se libera la captura. El encuadre crece para poses altas o anchas, conservando la proporción rectangular del panel.

Counter permanece en cinco segundos; otros efectos conservan sus duraciones. Esc > Pruebas incorpora «Fotograma de Naoya · 5 segundos» y «Fotograma del NPC cercano · 5 segundos». La segunda opción usa el NPC vivo más próximo a un máximo de 15 m. Son pruebas explícitas del mismo efecto; no cambian las reglas del juego normal.

## Dominio y Kogane

El dominio añade barrera exterior, suelo circular con colisión cilíndrica y límite circular con colisión. Entrada y salida reinician la interpolación física y la cámara para evitar arrastrar el traslado a la arena. Finalizar o abandonar fase 2 limpia interior y barrera exterior. Duración y penalizaciones se conservan.

Skull Wisp reemplaza a Kogane en Naoya, como confirmaste. K conserva invocación/retirada. Sigue al personaje y muestra transformación/evolución disponible, vida baja, tiempo de fotograma, tiempo del dominio y confirmación de counter según estados reales. No añade daño ni beneficios al combate.

## Repetición y límites

`tools/retarget_ual2.gd` reproduce la adaptación y el ajuste temporal. El informe en `assets/animation_sources/ual2/retarget_report.json` conserva huesos y tiempos de contacto. Se incluyen el GLB de origen y la licencia CC0 de Quaternius.

`qa/visual_revision_test.gd` comprueba las nuevas condiciones; `qa/repetir_pruebas_v094.py` repite las regresiones. `qa/v094_demo.gd` activa mecánicas reales con preparativos de laboratorio explícitos. `GRABACION_REAL.md` explica la prueba gráfica y FFmpeg.

La importación y pruebas sin imagen usan exclusivamente el Godot 4.4.1 adjuntado. Transparencia, imagen capturada y presentación final requieren validación gráfica: Xorg no puede abrir las conexiones locales de la pantalla virtual. No se presenta una prueba sin imagen como video real. Tu Godot 4.7.2 no se ejecutó aquí.
