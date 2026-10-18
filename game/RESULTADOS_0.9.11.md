# Verificación de la primera base online

Motor de importación y pruebas: Godot **4.4.1.stable.official.49a5bc7b6**, el ejecutable proporcionado por el usuario. Exportaciones mediante plantillas oficiales de esa misma versión. No se descargó otro editor.

## Resultado

- **Individual: 1205/1205**. Regresión completa repetida; laboratorio anterior y prueba PunchLine se mantienen. El registro especifica qué suites usan el laboratorio anterior y cuál usa el mapa nuevo.
- **Online: 51/51**, con tres procesos reales de Godot conectados mediante ENet. Comprueba controles separados, replicación, caminar/salto/dash, M1 de anfitrión y cliente, frente/espalda de guardia, daño, física y recuperación, cuatro robots, muerte/reaparición, selector, salida y reconexión.
- **Admisión y cierre: 6/6**. Tres plazas, cuarto cliente rechazado, versión incompatible, dirección sin servidor, cierre del anfitrión y limpieza de réplicas.
- **Interfaz: 13/13**. 360×360, 360×640, 640×360, 1280×720 y 1920×1080; IP/puerto/nombre.
- Aplicación exportada: prueba adicional con tres procesos del ejecutable Linux, a través de su entrada normal. Ver `resultados_v0911/native_verified` para resultado y comandos.

Las acciones de estas pruebas fueron **automatizadas**. Se usan posiciones iniciales controladas para verificar alcance; los desplazamientos, contactos, daño y física los resuelve el código real del juego.

## Gráficos y límites prácticos

Se ejecutó un cliente gráfico real, con dos compañeros headless, mediante pantalla virtual Xorg y **Mesa llvmpipe / GL Compatibility**, a 1280×720. Las capturas muestran el mapa y los tres personajes, y observan la postura recibida por el cliente. No son imágenes generadas ni gameplay simulado. **No se grabó un video.**

La corrida gráfica dio **49/51**: quedaron sin confirmar dos comprobaciones con ventanas temporales cortas (distancia de una caminata y lectura de postura durante el ragdoll). El renderizador por software bloqueó frames y las comprobaciones no coincidieron con la ventana esperada. Se conservan los fallos en el registro; esa corrida no se presenta como aprobada. Las pruebas ENet headless verifican esas mecánicas por separado.

**Pendiente manual:** ejecutar `Naoya.exe` en Windows, comprobar sensación de control/ragdoll y jugar con dos amigos a través de Radmin VPN. No se probó Windows 4.7.2 ni una conexión entre ciudades. No hay medición certificada de FPS en una GPU de usuario, predicción completa ni compensación de lag.

## Corrección de cierre en la exportación 4.4.1

Se encontró un error de `tree_exited` al limpiar la caché de RPC en una exportación. El código oficial de Godot 4.4.1 conecta el callback con `bind(ObjectID)` y lo desconecta sin ese argumento al limpiar. La sesión libera su entrada saliendo temporalmente del árbol durante el cierre y vuelve a su misma ruta de forma diferida. No se alteran los rigs ni sus huesos; el ajuste ocurre con la conexión terminando.

Fuente revisada: https://github.com/godotengine/godot/blob/4.4.1-stable/modules/multiplayer/scene_cache_interface.cpp (conexión y `clear`). Los avisos de sockets del editor durante importación/exportación corresponden al sandbox; no se presentan como errores de importación o de la partida.

## Repetir

```sh
python qa/repetir_pruebas_v0911.py --godot /ruta/al/Godot --output /ruta/nueva/regresion
python qa/network/repeat.py --godot /ruta/al/Godot --output /ruta/nueva/red
python qa/network/lifecycle.py --godot /ruta/al/Godot --output /ruta/nueva/admisiones
python qa/network/native_repeat.py --binary /ruta/a/Naoya.x86_64 --output /ruta/nueva/exportado
```

Los runners crean directorios XDG aislados y conservan comandos, salidas y códigos de proceso. En Linux se requiere permiso para escuchar y conectar por UDP local. Para la comprobación visual, con una pantalla gráfica autorizada:

```sh
DISPLAY=:110 python qa/network/repeat.py --godot /ruta/al/Godot --output /ruta/nueva/graficos --graphics-role client2
```

`qa/network/templates.py` conserva el origen oficial y CRC de las plantillas. `export_presets.cfg` incluye los recursos necesarios para la distribución online. El ZIP del proyecto conserva todas las mecánicas individuales y los recursos originales utilizados.
