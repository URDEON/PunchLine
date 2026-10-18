# PunchLine 0.9.15 — Arsenal del mega mecha

Se trabajó sobre la 0.9.14 guardada en el entorno. Esa carpeta permanece intacta como respaldo. Se usó el Godot 4.4.1 adjuntado; no se descargó otro editor.

## Rust Vanguard

| Control | Acción | Potencia y ventaja | Coste o desventaja |
|---|---|---|---|
| M1 | Alterna puño al suelo y pisotón | 16/14 de daño; área de 2,4/3 m y derribo desde el primer impacto válido | Preparación de 0,55/0,65 s, recuperación de 1,4/1,5 s; necesita suelo |
| 1 | Cañón de ruptura | Proyectil con barrido físico; alcance máximo 32 m, explosión de 2,8 m, hasta 32 de daño y derribo | Carga de 0,95 s, recarga de 18 s; las paredes lo interceptan; no sigue al enemigo |
| 2 | Martillo tectónico | Ambos brazos golpean delante; 28 de daño, área de 4,4 m y derribo; el centro rompe guardia | Preparación de 1,05 s, recarga de 11 s, poca movilidad y espalda expuesta |
| 3 | Pisotón sísmico | 18 de daño en 5,5 m alrededor; levanta y derriba; centro de 1,5 m rompe guardia | Preparación de 0,7 s, recarga de 10 s; se evita saltando o saliendo del área |
| 4 | Carga de ariete | Propulsión frontal a 8 m/s; 24 de daño y un impacto por objetivo | Recarga de 14 s; dirección fija, frena contra paredes y deja recuperación |
| Q | Despegue diagonal | Impulso hacia delante y arriba, propulsores, humo y corona de despegue | 5,5 s de recarga; no se repite en el aire y no concede invulnerabilidad |
| F | Guardia | Conserva bloqueo frontal | No protege la espalda ni los centros que rompen guardia |

Los M1 del mega tienen armadura durante su ejecución: los impactos de personajes normales restan vida pero no cancelan el ataque ni aplican su empuje/aturdimiento. Otro mega sí puede interrumpirlo. La muerte sigue funcionando. La armadura termina con el M1 y no cubre la recuperación posterior.

El cañón toma el punto de mira del escenario y converge desde la boca del arma, en lugar de disparar una línea paralela desplazada. Yaw y pitch viajan a la autoridad online; las entradas no finitas se rechazan. No hay selección automática de un enemigo. El bloqueo de mira también orienta al mega en reposo y al caminar lateralmente.

## Modelo y volúmenes

- Se conservan las 22 piezas y los bytes del GLB original, sus texturas y proporciones.
- Los hombros dejan de recibir la inclinación que abría la unión del pecho. Los fuelles internos conectan los bordes reales de cada lado de las uniones del brazo (17 y 18 segmentos), sin inflar su silueta. Los vértices de las piezas originales permanecen intactos.
- Los golpes al suelo flexionan piernas y torso, plantan los pies mediante IK y acercan físicamente el puño al suelo. Se añadieron cierres internos dimensionados para cintura, caderas, rodillas y tobillos, para conservar continuidad al flexionar.
- Torso y abdomen incorporan balanceo, contragiro al caminar, preparación y reacción de los golpes, retroceso del cañón e inclinación en propulsión.
- En reposo se midió un AABB de aproximadamente 2,973 × 4 × 1,499 m. El receptor de daño usa una caja orientada de **3 × 4 × 1,5 m**, separada de la cápsula que resuelve el desplazamiento. Los proyectiles pueden colisionar con ella.
- Los cálculos de golpes contra un mega usan su volumen receptor; un atacante elevado puede alcanzar torso/cabeza sin tener que acertar a la posición de los pies.
- Este sigue siendo un rig mecánico de piezas rígidas. Rust Vanguard no incorpora un ragdoll físico nuevo; frente a otro mega recibe interrupción/aturdimiento. Los personajes normales sí usan su ragdoll existente al recibir estos ataques.

## Los cuatro robots base

Se conservan los clips del pack original y sus rigs. Las descripciones del HUD y de Personaje explican preparación, alcance, recarga, ventajas y riesgos.

- **Leela:** rápida y solo de patadas. Barrido vectorial, talón ascendente y meteorito de talón; 13/14/18 de daño. Estelas desde el pie, destellos, impacto y polvo. Alcance corto y aterrizajes expuestos.
- **Stan:** puños lentos y fuertes. Puño de prensa, martillo industrial y pistón lineal; 23/20/16 de daño. Carga térmica, servos, partículas y respuesta de suelo. Preparación larga y baja movilidad.
- **George:** doble percusión, impulso vectorial y corte de retorno. Dos contactos de 8 o golpes de 14 de daño; estelas de brazos y desplazamiento. El avance no persigue al rival.
- **Mike:** bastión frontal y reversión de impacto. Escudo holográfico y aviso de counter. Fallar deja 0,35 s de recuperación vulnerable, sin reutilizar un estado de stun que lo protegiera de daño.

Los M1 base también añaden estelas desde su mano o pie y efectos al contacto. Los efectos cosméticos no deciden el daño. Se retiraron los aros Torus usados por las habilidades robóticas.

## Efectos e interfaz

Shader de energía con bordes suaves, destellos, estelas y patrón de escudo; polvo por capas, fragmentos cosméticos temporales y propulsores animados. La corona final de humo tiene prioridad de presupuesto para que no desaparezca por los impactos anteriores del ensamblaje. No es un aro sólido.

Límites por sistema: 72 elementos de energía/fragmentos y 440 partículas de polvo; los residuos caducan. Se respetan la preferencia de efectos y la pausa individual. Se reutiliza el audio ya adjuntado.

Las ventanas añaden una escena 3D independiente con placas, profundidad, luces y paralaje, debajo de los controles. La apertura combina escala y transparencia; las pestañas hacen transición de contenido. `Movimiento UI` reduce o desactiva el movimiento. Se conservan la entrada de teclado, el scroll y las cinco resoluciones comprobadas por las pruebas de HUD.

## Integración

La autoridad conserva vida, daño, recargas, proyectiles, armadura y movimiento. Los clientes reciben pose, punto de mira, vuelo y efectos; no aplican el daño por su cuenta. El protocolo es 0.9.15: todos deben usar esta versión.

Ver `RESULTADOS_0.9.15.md` para el alcance real de las pruebas y `qa/mechas/PRUEBA_MANUAL_0.9.15.md` para tu recorrido de prueba. La apariencia final de los efectos y del menú necesita revisión manual: la ejecución gráfica de esta sesión quedó bloqueada por el acceso a pantalla.
