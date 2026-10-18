# PunchLine 0.9.16 — Junkyard Sentinel / Rustwing

Versión de trabajo basada en la última 0.9.15 disponible. La 0.9.15 se conserva intacta en el entorno como respaldo. Los cambios se hicieron en una copia independiente, sin Git.

## Cambios de esta entrega

1. **Emotes del invitado.** La rueda B comprueba el suelo enviado por el anfitrión. La animación se solicita y valida en la autoridad; después se replica a los demás. La rueda sigue sin pausar el mundo.
2. **Dash del mega.** Q respeta WASD: adelante, atrás y ambos lados. Impulso diagonal ascendente, propulsores en posiciones constantes, frenado de velocidad extra al tocar suelo y polvo/sonido/sacudida de aterrizaje. La sacudida online se envía a los observadores próximos.
3. **Recuperación de los cuatro robots.** Se restauran los canales de reposo antes de mezclar la pose física con la animación. Se evita acumular giros en Body y controles sin pistas; se mantienen los pies unidos a sus cadenas.
4. **Vidrio contra el mega.** El counter/proyección de Naoya puede cristalizarlo, incluso durante el M1 protegido. Se conservan cinco segundos, frente/espalda diferentes, rotura con un golpe y restauración exclusiva del 3D. La resistencia del M1 frente a M1 normales continúa; otro mega puede interrumpirlo.
5. **Muerte modular.** El mega deja grupos de sus mallas reales como restos físicos que colisionan solo con el mundo. Sin colisiones internas entre grupos ni daño adicional; se desvanecen y eliminan a los 3,6 s. Las réplicas reproducen el desarme.
6. **Fusión.** Los cuatro chasis siguen siendo únicos e incluyen el del piloto. Ahora usan una pose del salto original de cada pack durante el vuelo, con variación y balanceo. Se conserva la secuencia G de 11,5 s y la corona final de polvo.
7. **Propulsores.** Anclajes estables de mochila en la forma base y final. Núcleo y estelas existentes, apagados cuando no están activos, al cristalizarse o morir.
8. **Salida.** Esc permite regresar al menú principal desde la partida individual y online, cerrando la sesión. La demo G también ofrece un botón visible y Esc, con detección de recursos compatible con exportaciones.
9. **Escudo.** Mantener F en la forma final muestra una barrera de energía frontal de 3,2 × 3,8 m. Se conserva la dirección real de bloqueo; no convierte la guardia en protección por la espalda.
10. **Escalones.** Barridos de la cápsula y consulta de superficie permiten subir hasta 42 cm. No atraviesan paredes ni techos. Se conserva el ajuste de bajada y la cámara suavizada. Se comprueban personaje normal y mega de cuatro metros.
11. **Cañón mantenido.** Mantener 1 despliega el Rustwing original, permite caminar al 65 % de la velocidad del mega y seguir apuntando con el ratón. El láser muestra el destino físico del disparo. Soltar dispara tras completar el despliegue mínimo de 1,1 s; la transformación inversa dura 0,95 s. La recarga es de 2 s desde el disparo. No incrementa daño por mantener más tiempo. Paredes interceptan la bala y la explosión; no hay autoapuntado.
12. **Golpes al suelo.** En bordes se busca un apoyo válido entre el puño y los pies. Si desapareció todo el apoyo, se devuelve la recarga y se muestra el motivo, sin daño ficticio.
13. **Capas.** Huesos/restos: capa 4, máscara 1. Volumen de daño del mega: capa 8. Cañón y mira: máscara 11 (mundo, jugadores y volumen vivo), excluyendo el ragdoll y el propio tirador.
14. **Guardia base.** Se crea una pose de guardia para cada chasis usando Idle/Walk_Holding reales. Leela conserva su anatomía de piernas y adopta una postura de apoyo; no se le añaden brazos.
15. **Dash base.** Usa una postura compacta del Jump del pack del propio modelo y los propulsores; no una animación humanoide retargeteada a los robots.
16. **HUD.** Las figuras vectoriales de habilidades se sustituyen por miniaturas de los modelos y poses reales renderizadas en Blender. Cada chasis y cada forma tiene imágenes propias. Se conservan nombre, tecla, disponibilidad, recarga, estadísticas y descripciones. Los menús mantienen sus transiciones y fondo con profundidad; los botones de volver/salir comparten fila para caber en pantallas pequeñas.
17. **Locomoción de Naoya.** Caminar y correr utilizan direcciones del mismo conjunto UAL ya disponible, evitando mezclar poses de referencia distintas según la velocidad. Continúan las mezclas de cadencia, guardia y transición.
18. **Modelos nuevos.** Junkyard Sentinel reemplaza la apariencia final. Se usan sus 112 piezas originales, sin cambiar proporciones, colores ni texturas. Rustwing aporta 31 piezas útiles del cañón; se omiten sus siete piezas de hombro redundantes conforme a V8. Tamaño nominal final: 4 m, frente a 2 m de los chasis base; 300 HP y velocidad pesada conservados.

## Estructura técnica

- `scripts/sentinel_cannon.gd`: adaptación de la animación editable del ZIP V8. Se conserva la copia original en `qa/junkyard_rustwing_transform_V8_original.gd.txt`.
- `scripts/sentinel_articulation.gd`: jerarquía de pivotes para el modelo rígido. **No es skinning ni un esqueleto importado.** No se atribuyen huesos o pesos inexistentes a los GLB.
- `scripts/mecha_combat.gd`: estados de carga/disparo/repliegue, láser, proyectiles y recuperación de recarga sin suelo.
- `scripts/fusion_controller.gd`: movimiento, escudo/ciclo final, aterrizaje, daño y réplica de estados.
- `scripts/mecha_wreck.gd`: desarme de muerte acotado y temporal.
- `scripts/terrain_steps.gd`: asistencia de escalones mediante comprobaciones físicas.
- `scripts/robot_ragdoll.gd`: recuperación de las poses originales sin acumular desviaciones.
- `CannonDemo.tscn`: taller independiente de la transformación V8; accesible desde Esc → Combate. Espacio despliega/retrae, R restaura, 1–4 cambian la cámara y Esc vuelve al menú principal.
- `FusionDemo.tscn`: demostración de G, con botón de retorno.

## Recursos y rendimiento

Los dos GLB nuevos no tienen Skin, Skeleton ni clips. La articulación es mecánica por nodos, basada en sus piezas; no se regeneraron modelos ni se usaron créditos de IA. Junkyard tiene 311.756 triángulos; el Rustwing completo de origen, 132.826. Se mantienen las importaciones con LOD y colisiones simples, sin convertir esos triángulos en colisiones de combate. Conviene medir FPS en tu equipo con tres fusiones simultáneas.

La captura del vidrio comparte las mallas rígidas en la fotografía 3D, evitando reconstruir sus triángulos y tangentes. Las siluetas y los personajes con skin conservan su ruta existente. Los restos se agrupan, no se crean 143 cuerpos físicos por muerte. El humo conserva el límite de partículas y el soporte Compatibility.

La textura `Image_4.webp` de la forma gusano es una copia **sin pérdida**, comparada píxel a píxel con `Image_4.png`. La fuente PNG original permanece en el respaldo opcional. No se bajó resolución ni calidad para reducir el tamaño de la entrega.

## Multijugador

Protocolo `naoya-0.9.16-mecha-2`. Todos deben utilizar esta versión. Entrada de mantener 1, soltar, estado de despliegue, objetivo del láser, recargas, vuelo y muerte se coordinan con la autoridad. El cliente no decide impactos ni daño. Las pruebas incluidas usan controladores y réplicas reales en mundos separados; no equivalen a una prueba por Internet.

Consulta `RESULTADOS_0.9.16.md` y `qa/mechas/PRUEBA_MANUAL_0.9.16.md` para resultados y limitaciones verificadas.
