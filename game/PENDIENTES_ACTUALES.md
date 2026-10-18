# Pendientes tras 0.9.24

- Calidad visual definitiva y FPS de la lente, cuello, contactos del suelo y partículas en Windows/Godot 4.7.2. El entorno ejecuta Godot 4.4.1 Linux sin pantalla gráfica accesible.
- Partida WAN entre PC reales. Se prueba ENet con tres procesos separados en la misma máquina; no mide latencia de Internet ni configuración de Radmin/firewall del usuario.
- Cuerpo visible completo en primera persona para The Proyected y robots base. La solución actual completa corresponde al Sentinel.
- Apoyos del resto de formas de The Proyected. Los nuevos apoyos de robots base ajustan altura al terreno manteniendo los clips originales; no sustituyen toda la marcha por generación procedural.
- Sentinel sigue formado por piezas rígidas, sin un nuevo rig de pesos. El daño modular contempla dos brazos y dos trenes inferiores.
- El esparcimiento final del cadáver es cosmético local, con duración sincronizada. Las piezas destruidas en vida usan el estado físico del anfitrión.
- El agache tiene límites anatómicos: conserva el ancho y no permite al Sentinel atravesar un hueco humano demasiado bajo. Mínimos de cápsula: 1,30 m en chasis base y 2,70 m en Sentinel.
- La corrección de The Proyected se comprueba numéricamente; su percepción visual y los FPS con GPU deben validarse manualmente. No se garantiza una cifra de FPS en Windows a partir de pruebas headless.
