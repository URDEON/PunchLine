# Naoya 0.9.11 · primera etapa multijugador

## Jugar con dos amigos en Windows

1. Los tres descargan **Naoya_0.9.11_Online_Windows.zip** y lo extraen completamente. Mantener `Naoya.exe` y `Naoya.pck` en la misma carpeta. Ejecutar `Naoya.exe`; no necesitan importar scripts ni instalar Godot.
2. Instalar **Radmin VPN** desde https://www.radmin-vpn.com/. Es gratuito; no necesitan el programa de control remoto Radmin.
3. En Radmin VPN, el anfitrión elige **Red → Crear una red**, define un nombre y una contraseña y los comparte con sus dos amigos. Ellos eligen **Red → Unirse a una red** con esos mismos datos.
4. En Naoya, el anfitrión escribe su nombre, elige personaje y pulsa **Crear partida**. Mantiene abierto tanto el juego como Radmin VPN.
5. Los amigos escriben la **IP de Radmin VPN del anfitrión**, el mismo puerto **7777**, su nombre y personaje, y pulsan **Unirse por IP**. Se admite un anfitrión y dos clientes: tres personas en total.
6. Si Windows solicita acceso de red, permitir `Naoya.exe` en la red utilizada por Radmin. Si la conexión expira, comprobar que el anfitrión tiene la partida abierta, que la IP corresponde a Radmin y que el firewall permite UDP en el puerto elegido. La partida también puede estar completa.

Sin Radmin, sirve la IP de la red local si están en la misma red. `127.0.0.1` sirve únicamente para probar varias ventanas en un mismo computador. Esta versión no incluye búsqueda pública de partidas, servidor en la nube ni migración de anfitrión: si este sale, termina la partida.

## Proyecto completo

`Naoya_v0.9.11.zip` conserva el laboratorio individual completo. Importar `project.godot`, ejecutar y abrir **Esc → Multijugador → Abrir multijugador**. Ambos modos están disponibles en el proyecto. La distribución Windows pequeña se dedica al modo online y entra directamente al menú de conexión.

## Controles y alcance de esta entrega

- WASD: desplazamiento relativo a la cámara. Ctrl: caminar.
- Ratón: cámara. Rueda: zoom entre 2 y 10 metros.
- Espacio: salto. Q: dash con duración/cooldown originales.
- Clic izquierdo: M1; mantener pulsado repite si está habilitado en tus preferencias.
- F: bloqueo frontal. Recibir golpes por detrás evita la guardia.
- Cuarto M1 de Naoya: normal, uppercut o downslam según el estado aéreo.
- P / Esc: menú de personaje y conexión. Abrirlo detiene tus entradas, pero **no pausa la partida ni vuelve invulnerable al personaje**.
- Seleccionar personaje y pulsar **Reaparecer con personaje elegido**: cambio validado por el anfitrión. Espera de 10 segundos entre cambios y 5 segundos tras recibir daño; no se permite durante un golpe, dash, guardia o ragdoll.
- Morir: reaparición automática después de 3 segundos. El Robot cambia de chasis y color; no repite inmediatamente el chasis anterior.

Cada jugador tiene su propia vida, control, cámara, rig y material. Leela usa patadas; Stan puños fuertes y lentos; George alterna y remata con patada; Mike mantiene sus puños más ligeros. Los valores de M1, animaciones y articulaciones proceden de los sistemas existentes.

**Online todavía no incluye habilidades 1–4, transformaciones/dominio, NPC, cristalización, Kogane, emotes ni contramedidas avanzadas contra trampas.** Esos sistemas siguen disponibles en el modo individual. Su integración en red será una fase posterior sobre esta base comprobada. No se presentan como sincronizados.

## Arquitectura

`network/session.gd` administra ENet, registro de versión, tres plazas, entradas y eventos fiables. No acepta posiciones, vida ni daño enviados por clientes. El anfitrión resuelve movimiento, colisiones, alcance, altura, línea de visión, guardia, cooldowns, muerte y reaparición.

Las entradas viajan a 30 Hz y el mundo a 20 Hz. Los snapshots se comprimen y dividen en paquetes de hasta 1000 bytes para evitar fragmentación por MTU. El cliente interpola los estados y las posturas físicas; un estado viejo o de una generación anterior se descarta. Las entradas sin actualizar durante 0,35 segundos se sueltan automáticamente.

`network/player.gd` contiene estado propio por persona. `network/rig.gd` conserva el montaje de los rigs, bibliotecas y mezcla visual del controlador individual sin cargar un dominio/HUD/NPC por cada jugador. Reutiliza `visual_motion.gd`, `robot_character.gd`, `robot_locomotion.gd`, `physical_ragdoll.gd` y `robot_ragdoll.gd`. Las jerarquías y pesos originales no se modifican.

Los ragdolls se simulan únicamente en el anfitrión. Se envía la pose de los huesos y el transform visual; los clientes no ejecutan otra simulación que pueda divergir o desarmar el robot. Se reutiliza el mapa PunchLine con sus colisiones originales y dos zonas de aparición alrededor de la plaza, separadas por plaza de jugador.

**Límite práctico:** esta primera versión todavía no tiene predicción local completa, rollback ni compensación de lag. Con latencia alta se sentirá demora, especialmente en los golpes. Las pruebas locales no certifican el rendimiento entre ciudades; esa comprobación corresponde a la sesión con tus amigos.

## Prueba manual recomendada

1. Abrir las tres copias de la misma entrega y entrar a la partida. Verificar que cada cámara/HUD pertenece a su jugador.
2. Caminar, correr, saltar y hacer dash mientras otro observa; intentar atravesar paredes y salir del mapa.
3. Intercambiar M1, bloquear mirando al atacante y recibir un golpe por detrás. Verificar la misma vida en las tres copias.
4. Completar una cadena de cuatro golpes siguiendo el empuje real del rival; comprobar ragdoll y recuperación en todos los equipos.
5. Probar el Robot, morir y confirmar que las tres copias ven el mismo chasis/color nuevo.
6. Abrir P/Esc durante el combate: el rival debe seguir moviéndose y golpeando.
7. Salir como cliente, volver a entrar y comprobar que no aparece un personaje duplicado.
8. Cerrar el anfitrión: los clientes deben volver al menú con un motivo de desconexión.

Fuentes: Radmin VPN oficial (consulta 14-10-2026); plantillas oficiales de exportación Godot 4.4.1, la misma versión del ejecutable aportado por el usuario. No se instaló otro editor de Godot.
