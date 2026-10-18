# Balance inicial y parámetros ajustables

Daño contra blanco sin guardia, 100 HP. Se compara con 0.9. Los valores indican una secuencia completa que conecta; una pared, guardia, pérdida de contacto o dash puede cortarla. No son daño garantizado ni combos inevitables.

| Acción | Daño 0.9 | Daño 0.9.1 | Cooldown 0.9 → 0.9.1 |
|---|---:|---:|---|
| M1 primero/segundo/tercero | 7 cada uno | 5 cada uno | Cadencia existente |
| Cuarto M1 normal | 12 | 8 | Cadencia existente |
| Cuarto M1 uppercut | 13 | 9 | Cadencia existente |
| Cuarto M1 downslam | 14 | 10 | Cadencia existente |
| Combo M1 normal | 33 | 23 | — |
| Combo M1 con uppercut | 34 | 24 | — |
| Combo M1 con downslam | 35 | 25 | — |
| 1 humana normal | 24 (8+8+8) | 18 (4 de entrada +4+4+6) | 10 → 11 s |
| 1 humana cercana | No existía | 18 (4 de entrada +2+2+2+2+6) | Comparte los 11 s del 1 |
| 2 Counter | 14 | 8 | 8 → 11 s |
| 3 Rush | 19 (7+6+6) | 14 (4+5+5) | 7 s |
| 4 Patada | 17 | 12 | 6 s |
| 1 FORM1 | 23 | 18, un contacto | 6 → 7 s |
| 1 FORM2 | 28 | 22, un contacto | 6 → 7 s |
| 2 Tentáculos FORM2 | 24 (8+16) | 18 (6+12) | 9 s |
| 3 Aceleración FORM2 | 36 | 26 | 12 s |
| 4 Dominio, penalización por tick | 7 | 4 | Un uso por FORM2 |
| M1 NPC / remate NPC | 9 / 14 | 6 / 10 | Cadencia existente |

El dominio conserva 14 s de actividad y un intervalo mínimo de 0,8 s entre penalizaciones. Un objetivo quieto no recibe esos ticks; movimiento/ataque voluntario sí puede activarlos. El estado frame dura 5 s en Counter; todavía no se añade una imagen plana.

## Guiado y ventanas

Editar `balance_v091.tres` en el Inspector de Godot. Los valores por defecto se declaran en `scripts/combat_tuning.gd`; cada instancia del juego duplica el Resource para que los cambios temporales de un test no contaminen otro. Las cifras son una primera propuesta, no un equilibrio final validado con jugadores.

| Parámetro exportado | Inicial | Función |
|---|---:|---|
| aim_range | 18 m | Límite para seleccionar al iniciar |
| aim_half_angle_degrees | 50° | Semicono horizontal respecto a cámara |
| turn_rate | 5,5 rad/s | Máximo giro por segundo en aproximación |
| camera_influence | 0,18 | Peso de cámara al seguir un blanco |
| velocity_prediction | 0,08 s | Predicción limitada de la velocidad actual |
| projection_windup | 0,12 s | Anticipación inicial |
| approach_timeout | 1,15 s | Máximo seguimiento antes de comprometer rumbo |
| initial_speed / maximum_speed | 8 / 22 m/s | Avance progresivo |
| acceleration | 18 m/s² | Aceleración hasta el máximo |
| commit_distance | 2,5 m | Inicio de compromiso cerca del blanco |
| commit_duration | 0,14 s | Rumbo fijo; cámara y blanco dejan de corregir |
| impact_reach / impact_radius | 1,3 / 0,6 m | Segmento delantero de contacto al terminar compromiso |
| miss_recovery | 0,38 s | Recuperación al fallar/interrumpir |
| close_activation_range | 2,2 m | Elegir variante cercana al activar |
| orbit_radius / orbit_speed | 1,15 m / 12 m/s | Destino circular y límite de velocidad física |
| barrage_interval | 0,12 s | Separación entre anticipaciones de golpes |
| strike_anticipation | 0,045 s | Contacto después de iniciar la pose de cada golpe |
| wakeup_protection | 0,35 s | NPC levantándose protegido |
| dummy_dodge_delay | 0,04 s | Inicio de dash del evasor tras compromiso |

Dash real: 24 m/s, duración 0,18 s y cooldown 1,2 s. La evasión depende de quedar fuera del segmento delantero de contacto, no de una inmunidad añadida. Counter mantiene 0,10 s de preparación, ventana frontal 0,45 s y recuperación al fallar 0,35 s. El 1 humano que termina conectado recupera 0,25 s; embestida evolucionada 0,28 s.

Carga inicial: M1 2 por golpe, remate 3,5; 1 humana completa 14 en ambas variantes; Counter 10; Rush 14; Patada 12; embestida evolucionada 18. FORM1 convierte ganancias de carga de evolución a ×1,5. Vida de las formas: 60 s FORM1, 45 s FORM2. Renacimiento por muerte: 60 HP en FORM1 con evolución cero.

Corrección documental en 0.9.1.1: Counter ya concedía 10 en el código de 0.9.1; el texto anterior decía 12 por error. No se cambia esa ganancia.

## Afinación segura

Mantener `strike_anticipation < barrage_interval`; probar dash y paredes después de cambiar velocidad, radio o compromiso juntos. Subir el radio o el alcance vuelve más difícil esquivar; aumentar el seguimiento después de comprometerse quitaría la defensa solicitada. Los arrays de daño y entrada suman 18 por defecto: cambiar esos valores también cambia el total, no existe un límite oculto e independiente de 18.

La dirección usa yaw horizontal y limita diferencia de altura a 2,2 m; esta entrega no añade persecución aérea ilimitada. Cuando se pierde el blanco no selecciona otro durante la misma activación. El círculo se resuelve con `move_and_slide`, por lo que obstáculos o un contacto perdido pueden cancelar la secuencia; revisar visualmente esa cancelación.

## Profundidad para siguientes iteraciones

Propuestas todavía sin implementar: escalado por secuencia para reducir combos prolongados; una señal corta de Kogane cuando un blanco visible entre en el cono del 1; reacción al compromiso y al fallo para enseñar el momento de dash; una orden de apoyo de Kogane con coste de energía/cooldown que marque brevemente amenazas visibles, sin daño automático ni revelación detrás de paredes. Primero conviene validar alcance y daño actuales, después elegir y probar una de estas interacciones.

Referencia consultada: [Head of the Hei / Jujutsu Shenanigans Wiki](https://jujutsushenaniganswiki.com/wiki/head-of-the-hei/). Decisive Strike orienta la lectura de avance, primer contacto y ráfaga. Su variante aérea y Top Speed ofrecen referencias de seguimiento y velocidad. Aquí se aplican las reglas pedidas por el usuario: compromiso esquivable, Counter de 5 s y conservación de uppercut/downslam. No se copia literalmente el daño ni las pasivas de la wiki.
