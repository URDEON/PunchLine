# Repetir las capturas reales

Motor: Godot 4.4.1 adjuntado. Linux requiere Xorg y el driver dummy. No descarga otro motor.

```bash
Xorg :110 -config /ruta/proyecto/qa/pantalla_virtual.conf -logfile /ruta/resultados/Xorg.log -nolisten tcp -noreset -ac
```

Con la pantalla disponible, en otra terminal:

```bash
DISPLAY=:110 LIBGL_ALWAYS_SOFTWARE=1 NAOYA_QA_OUTPUT=/ruta/resultados/capturas XDG_CACHE_HOME=/ruta/resultados/cache XDG_DATA_HOME=/ruta/resultados/data XDG_CONFIG_HOME=/ruta/resultados/config /ruta/al/Godot_adjuntado --path /ruta/proyecto --script res://qa/robot_visual_v0910.gd --display-driver x11 --rendering-method gl_compatibility --resolution 1280x720 --audio-driver Dummy --fixed-fps 60
```

Las rutas deben apuntar a directorios locales escribibles. Se captura el viewport real, sin sintetizar imágenes. El log indica si la física estaba activa y si terminó la recuperación en cada PNG. No se graba video.
