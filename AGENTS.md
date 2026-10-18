# Preferencias del proyecto

- El usuario exige incrementar la versión en cada actualización entregada del juego.
  Actualizar `application/config/version` en `game/project.godot`, `CHANGELOG.md`
  y la versión vigente del README antes del commit/push. No renumerar evidencia histórica.
- Menús, HUD, ventana, multijugador e informes consultan `BuildInfo.version`.
  Mantener `config/name` estable para conservar `user://` entre versiones.
- El proyecto jugable completo es `game/project.godot`; el otro proyecto es un inspector.
- Conservar datos geográficos fuente, calles, estacionamiento y accesos medidos.
  Validar nuevos edificios y sus escaleras con el controlador real antes de entregar.
