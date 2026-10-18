Actualización 0.9.2.1: se atendió el feedback del HUD en una copia separada. El estado por requisito está actualizado en PENDIENTES_ACTUALES.md. El informe siguiente conserva el historial de la base y 0.9.2.

# Inspección de Naoya 0.9 y plan incremental

Estado actual: el usuario validó 0.9.1.1. En 0.9.2 se implementaron HUD poligonal, retrato/estados/segmentos, selector P (solo Naoya) y menús adaptables. Pruebas de lógica/distribución y vistas vectoriales aprobadas; pendiente revisión con gráficos en el equipo del usuario. Siguiente etapa, después de su feedback: 0.9.3 modelos, animaciones, audio y ragdoll. La inspección y tablas siguientes conservan el estado histórico de la base.

Base: `Naoya_0.9_IMPORTAR_GODOT.zip`. Se conserva intacta; el trabajo se realiza en otra carpeta. Este informe procede de leer el código, no de ver gameplay renderizado.

| Sistema | Lo que realmente existe en 0.9 | Falta o fallo comprobable en el código |
|---|---|---|
| Habilidad 1 humana | Ruta de cinco cuadros, avance automático, tres impactos de 8 y freeze de 0,8 s | No selecciona ni sigue al objetivo; la ruta penaliza desviaciones; no hay ventana final de compromiso |
| Habilidad 1 evolucionada | Preparación y barrido de colisiones, un impacto | Dirección fijada al activar; sin autoapuntado dinámico |
| Counter | Ventana frontal, daño, detención y rectángulo 3D | Congela 0,85 s; el modelo sigue siendo 3D, no una pose plana |
| M1 | Cuatro golpes y variantes normal, uppercut y downslam | `resolve_punch_hit()` no excluye enemigos derribados; falta recuperación protegida de los NPC |
| Fases | BASE, FORM1 y FORM2; transición y carga de evolución | `on_player_death()` llama a `rebirth_phase2()` cuando `ult_ready()` es verdadero: BASE + 100% salta directamente a FORM2 |
| Dash | Movimiento con colisión durante 0,18 s; sin invulnerabilidad propia | Los NPC no usan dash; Q está asignada a dash en la base |
| Dummies | Quieto, bloqueador y atacante que persigue | No hay atacante estacionario ni evasor; el menú solo cambia NPC 03 |
| Ragdoll | Caída del CharacterBody y pose de knockdown del rig | No es un ragdoll articulado: faltan PhysicalBoneSimulator3D, cuerpos y límites de articulaciones |
| Animación | GLB real, esqueleto humano, locomoción AnimationTree y clips; formas con 7 huesos | Guardia reproduce un clip completo y detiene las piernas; las transformaciones dependen de aura/escalado |
| HUD | CanvasLayer adaptable, cuatro tarjetas rectangulares, ajustes y reasignación | No reproduce el boceto poligonal; no hay roster real de personajes; los perfiles de Kogane no son personajes jugables |
| Dominio | Arena separada, envolvente esférica visible desde dentro y penalización al moverse | Suelo BoxMesh/cuadrado; la envolvente solo dibuja caras interiores y no representa la barrera exterior en el mapa |
| Mapa/audio | Laboratorio, iluminación, feedback y buses | Algunos muros son solo visuales; impactos conservan los recursos originales |

## Pendientes por prioridad y dependencia

| Pendiente | Criticidad | Dificultad | Dependencia | Versión |
|---|---|---|---|---|
| Selección por cámara, alcance y paredes; seguimiento con giro limitado | Alta | Alta | Raycasts y estados de la habilidad | 0.9.1 |
| Compromiso final, dash posicional y ausencia de refijación | Alta | Alta | Autoapuntado y dummy evasor | 0.9.1 |
| Variante cercana con inmovilización limitada y órbita con colisiones | Alta | Alta | Contacto válido y cancelación segura | 0.9.1 |
| M1 excluye knockdown/recuperación; balance legible | Alta | Media | Estado compartido de daño | 0.9.1 |
| Regla de renacimiento sin salto a FORM2 | Alta | Media | Máquina de fases | 0.9.1 |
| Counter de 5 s y cinco modos de dummy | Alta | Media | Temporizadores y menú de laboratorio | 0.9.1 |
| HUD con polígonos y dibujos del boceto | Alta | Alta | Boceto recibido; validación visual real | 0.9.2, tras feedback |
| P para cambiar personaje; Q para dash | Alta | Media | Preferencia confirmada por el usuario. Requiere roster jugable real; no sustituir personajes por cambios de color | 0.9.2 |
| Pose 2D capturada de jugador y NPC | Alta | Alta | SubViewport/cámara, captura de pose y prueba gráfica | 0.9.2/0.9.3 |
| Guardia superior mezclada con locomoción inferior | Alta | Alta | Filtros por hueso y prueba de poses | 0.9.3 |
| Modelos con cara, rig mejorado y transformaciones corporales | Alta | Alta | Recursos licenciados entregados y retargeting | 0.9.3 |
| Ragdoll articulado/híbrido y recuperación animada | Alta | Alta | Límites/colliders sobre el esqueleto humano | 0.9.3 |
| Nuevos impactos y sonidos del frame/dominio | Media | Media | Pack con licencia y contactos sincronizados | 0.9.3 |
| Barrera exterior esférica, cúpula y suelo circular | Media | Alta | Entrada/salida y cámara probadas | 0.9.4 |
| Mapa completo, navegación entre obstáculos y varios enemigos | Media | Alta | Navegación y modos de dummy | 0.9.4 |
| Escalado de combos e interacciones de Kogane | Media | Alta | Feedback del balance y reglas de defensa | 0.9.4 |

## Regla propuesta e implementada para la muerte en 0.9.1

BASE con energía completa renace en **FORM1**, consume la energía, empieza evolución desde cero y conserva la intención original de revivir con 60 HP. FORM2 requiere estar en FORM1 y completar su barra de evolución. Morir durante cualquiera de las formas termina la transformación y reaparece en BASE; la muerte no regala otra evolución. Los botones de laboratorio pueden preparar FORM2 explícitamente y quedan separados de la progresión normal.

## Validación visual y frame 2D

El entorno sigue denegando `AF_UNIX bind` con `Operation not permitted`; no hay pantalla virtual ni revisión visual. Los tests sin imagen comprobarán reglas, no la calidad artística.

La técnica prevista para el frame 2D es capturar una copia de la pose esquelética en un SubViewport con mundo propio y fondo transparente, detener su actualización y mostrar la textura en un QuadMesh/billboard. Durante ese estado se ocultaría la malla original, manteniendo su collider; al salir se restaurarían visibilidad, animación y controles. Esto debe probarse con gráficos antes de integrarlo como resultado visual terminado. **0.9.1 todavía conserva la representación 3D del frame; no se afirma que sea la captura plana solicitada.**

Se entrega primero 0.9.1 y se espera feedback antes del rediseño grande del HUD y los rigs.
