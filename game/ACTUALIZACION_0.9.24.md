# PunchLine 0.9.24 — Postura, colisiones y estabilidad

Esta versión integra las correcciones en el proyecto editable y en una exportación
Windows completa. El ejecutable y su PCK se construyen juntos con Godot 4.4.1;
no se modifican bytes del PCK ni se necesita aplicar un parche con CMD.

## Agache y movimiento

- El robot detecta superficies sobre la cabeza y reduce su cápsula antes de moverse.
  Conserva el ancho y la posición de los pies. Solo se incorpora cuando hay espacio.
- Los cuatro chasis usan sus clips originales de idle, caminar y correr. Se eliminó
  una configuración que reproducía Idle en todos los puntos de locomoción.
- Un único modificador físico añade adaptación al terreno, agache y postura de dash.
  La pose final se transmite al resto de jugadores.
- El Sentinel baja torso, pelvis y cabeza y conserva los apoyos de los pies.
  La cápsula y el volumen que recibe daño acompañan la misma postura.
- La nueva cápsula se vuelve a detectar incluso al reaparecer con el mismo chasis.
- The Proyected conserva los ciclos originales. Se retiró el balanceo independiente
  que competía con las animaciones y se limitó la corrección de apoyo de cada pie.
- Fase 2: cabeza arriba y cara al frente en reposo; cabeza al frente y cara abajo
  durante desplazamiento, con transición gradual.

## Daño del Sentinel y primera persona

- Los brazos desprendidos tienen dos cuerpos rígidos unidos por un codo limitado.
  No colisionan con los controladores de los jugadores, sí con el escenario.
- Pausar conserva y congela sus velocidades; reanudar devuelve la simulación.
- El muñón tiene cables y chispas con emisor compatible con OpenGL/Compatibility.
- El modo cañón desplaza y abre gradualmente el encuadre de primera persona.
  Se mantiene la cámara fuera del pecho y el abdomen; el resto del cuerpo sigue visible.
- Se conservan integridad modular, pérdida de habilidades por miembro destruido,
  estabilidad proporcional a la vida, espera de muerte y recuperación.

## Ciudad y distribución

- La ciudad usa la importación nativa de Godot, también en multijugador.
- La escala se calibra con un vehículo del recurso: aproximadamente 4,4 m de largo.
  Tres edificios de cuatro plantas reciben una corrección vertical independiente
  para evitar pisos demasiado bajos sin deformar sus huellas en el suelo.
- Se conservan entradas y huecos mediante colisiones de la geometría de edificios.
  Los vehículos pequeños usan colisiones simples; se comprueban 29 colisionadores.
- Spawns, zonas, orientación y puntos de recorrido utilizan la misma escala.
  Se separan los récords antiguos del recorrido que usaban otra escala.

## Multijugador

- La carga inicial se confirma antes de enviar snapshots a cada invitado.
- La confirmación incluye las generaciones de todos los actores; reaparecer,
  cambiar de personaje, entrar y salir actualizan esta sincronización.
- Se amplían los tiempos de espera durante la carga de modelos para evitar
  desconexiones prematuras en equipos lentos. Protocolo propio de la 0.9.24.
- Se conserva la autoridad del anfitrión sobre movimiento, golpes y daño.

## Rendimiento y mantenimiento

- Iconos y tamaños de texto del HUD se reutilizan en lugar de reconstruirse cada frame.
- Los volúmenes de contacto por hueso se preparan de antemano para los rigs conocidos;
  un esqueleto diferente conserva la generación de respaldo.
- Se elimina una dependencia obligatoria de un archivo QA ausente en exportaciones.
- Pausa > Combate permite registrar 60 segundos de rendimiento y abrir los registros.
  Se guarda un JSON acotado con CPU, física, FPS, objetos, memoria y llamadas de dibujo.
- Se conservan los recursos originales. El Sentinel actual es un conjunto articulado
  de piezas rígidas, no se afirma que tenga un nuevo rig de pesos.

Las comprobaciones automáticas y sus límites se detallan en RESULTADOS_0.9.24.md.
