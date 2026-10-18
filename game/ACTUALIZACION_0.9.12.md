# Naoya 0.9.12

La aplicación 0.9.11 arrancaba un prototipo online separado que solo tenía M1. Esta entrega incluye ambos modos, el HUD original y las habilidades originales dentro de los controladores online.

- `network/player.gd` hereda el controlador individual. Reutiliza locomoción, ataques, formas, presentación y rigs; las entradas de cada jugador se leen por separado.
- Las habilidades originales de Naoya y los cuatro robots resuelven contactos, guardia, daño, carga, counter, cristalización y física en el anfitrión. Los clientes envían acciones, nunca daño ni posiciones.
- Se transmiten huesos del rig, cooldowns, forma, vidrio, dominio, Kogane y emotes. La réplica visual no ejecuta otra simulación del ragdoll ni aplica daño.
- La Proyección usa el avance guiado, ráfaga, fotogramas delanteros y ecos existentes. El vidrio mantiene exclusión entre 2D y 3D, un golpe y cinco segundos.
- El HUD conserva retrato, barra segmentada, estados, dibujos de habilidades por forma, selector animado, rueda de emotes y ajustes.
- El nombre acepta escritura con espacios y acentos, se guarda y se puede cambiar conectado. El formulario queda por encima del HUD y escribir P no lo cierra.
- El menú online bloquea solo entradas locales; no detiene el mundo ni da invulnerabilidad. Las pruebas que preparan NPC se hacen en el laboratorio individual.
- Se corrige el cierre de la sesión nativa para no dejar un nodo RPC huérfano. Se limpian blancos y dominios al desconectar/recrear actores. Cada dominio usa una ubicación separada por jugador.
- La exportación incluye el juego individual y sus recursos; se elimina la exclusión que dejó fuera HUD/habilidades en 0.9.11.

## Límites de esta entrega

El escenario online es de combate entre jugadores: no añade NPC de entrenamiento ni los ejercicios E del laboratorio. Esos sistemas siguen disponibles en Individual. Las formas malditas conservan su derribo anterior; no se creó un ragdoll nuevo para ellas. Las partidas siguen requiriendo IP/red VPN; no se agregó matchmaking ni un servidor público.

El contenedor actual bloquea UDP y la conexión a X11. Por eso la validación 0.9.12 es local, sin imagen, y no certifica una sesión ENet entre PCs. Se conserva el impedimento exacto en resultados_v0912/bloqueos. No se afirma que las pruebas de red de 0.9.11 validen esta versión.
