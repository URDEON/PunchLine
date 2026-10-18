# Naoya 0.9.11

Primera base online para un anfitrión y dos amigos. Se conserva una copia intacta de 0.9.10 y el laboratorio individual completo.

## Implementado

- Crear/unirse por IP, nombre, personaje y puerto UDP configurable.
- Naoya y Robot con estado, animaciones, vida y materiales independientes.
- Movimiento, caminar, salto, aterrizaje, dash, M1 y bloqueo validados por anfitrión.
- M1 propios de los cuatro robots; combinación y variantes aéreas de Naoya.
- Ragdoll físico en anfitrión y postura interpolada en clientes, con recuperación.
- Reaparición sincronizada; chasis/color de Robot elegidos por anfitrión.
- Mapa PunchLine, apariciones alrededor de plaza y cámara que evita paredes.
- Menú online responsive que mantiene la partida activa.
- Desconexión, reconexión, incompatibilidad de versión y timeout con retorno al menú.
- Snapshots comprimidos en partes menores que MTU; estados viejos descartados.
- Proyecto completo y exportación Windows del modo online, sin exigir Godot a los amigos.

## No implementado en red aún

Habilidades 1–4, cristalización/counter de Naoya, transformaciones, dominio, NPC, Kogane y emotes. Permanecen en el laboratorio individual. Tampoco se incluyen matchmaking, servidor público, migración del anfitrión, predicción completa ni compensación de lag.

Consultar `MULTIJUGADOR_0.9.11.md` para conexión, controles, límites y pruebas manuales. Los resultados automatizados y comandos quedan en `resultados_v0911` y `qa/network`.
