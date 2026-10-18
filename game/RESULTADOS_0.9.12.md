# Verificación de Naoya 0.9.12

Editor adjuntado: Godot 4.4.1, Compatibility/Jolt. Acciones automatizadas.

| Comprobación | Resultado | Alcance |
|---|---:|---|
| Regresión del juego individual | 1205/1205 | Combate, HUD, materiales, rigs, robots, vidrio, mapa y demos sin imagen |
| Formulario y teclado | 16/16 | Cinco tamaños, nombre editable, espacios, Ñ, P y persistencia |
| Controladores online y réplicas | 28/28 | Contactos/daño reales, counter, vidrio, formas, dominio, Kogane, emote, Stan, huesos, cooldowns y paquetes de tres actores |
| Exportación Windows | Generada | EXE + PCK completos; ambos modos incluidos |
| PCK exportado con runtime Linux | 28/28 + 16/16 | Mismo PCK destinado a Windows; no es una ejecución Windows |
| ENet entre procesos | Bloqueado | Crear socket UDP falla: ERR_CANT_CREATE (20) |
| Imagen y video nuevos | Bloqueado | X11 no disponible; Wayland tampoco |

Los actores y la réplica se ejecutan localmente con controladores y física del juego. La prueba no se presenta como una sesión de red real ni como gameplay grabado. Las 51 pruebas ENet de 0.9.11 son históricas y no certifican 0.9.12.

## Repetir

Con la carpeta del proyecto como directorio de trabajo y las rutas XDG configuradas dentro de un directorio escribible:

```sh
GODOT=/ruta/al/Godot_4.4.1
"$GODOT" --headless --max-fps 60 --path . --script res://qa/network/ui_test.gd
NAOYA_NET_QA=1 "$GODOT" --headless --max-fps 60 --path . --script res://qa/network/full_local.gd
python qa/repetir_pruebas_v0912.py --godot "$GODOT" --output /tmp/naoya_regresion_nueva
python qa/network/repeat.py --godot "$GODOT" --output /tmp/naoya_enet_nueva
```

El último comando requiere UDP permitido; conserva su script aunque no pueda ejecutarse en este contenedor. Los archivos de `resultados_v0912/bloqueos` incluyen los registros originales de los impedimentos.

El cierre nativo se corrigió para limpiar el nodo RPC sin dejar una sesión fuera del árbol. `native_validado.log` concluye 28/28 sin SCRIPT ERROR, ERROR ni objetos filtrados. El registro anterior se conserva únicamente como diagnóstico.
