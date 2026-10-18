# Resultados 0.9.9

**1.122/1.122 comprobaciones automatizadas aprobadas**: 22 suites y ocho demostraciones sin imagen, ejecutadas por el Godot 4.4.1 Linux adjuntado, Jolt y Compatibility. No se descargó otro motor ni se grabó un video.

Las pruebas ejercitan mecánicas reales: contacto, daño, bloqueo, counter, doble golpe, avance, rigs de los cuatro robots, caída física, longitudes de huesos, recuperación, selección por clic, reaparición, HUD, emotes, Eco, calles transitables y subida andando por la rampa. También se ejecutó toda la regresión anterior de Naoya.

| Prueba | Resultado |
| --- | --- |
| combat_test | 38/38 |
| polish_test | 25/25 |
| presentation_test | 23/23 |
| assets_test | 23/23 |
| revision_test | 60/60 |
| video_feedback_test | 60/60 |
| hud_test | 97/97 |
| hud_feedback_test | 74/74 |
| modelo_alien_test | 86/86 |
| visual_revision_test | 59/59 |
| crystal_v095_test | 22/22 |
| integration_v095_test | 48/48 |
| ragdoll_v095_test | 11/11 |
| update_v096_test | 66/66 |
| update_v097_test | 75/75 |
| preferences_migration_v097_test | 6/6 |
| update_v098_test | 49/49 |
| preferences_migration_v098_test | 6/6 |
| robot_test_v099 | 47/47 |
| robot_skills_v099_test | 79/79 |
| map_crystal_v099_test | 87/87 |
| preferences_migration_v099_test | 4/4 |
| demo | 9/9 |
| hud_demo | 10/10 |
| modelo_demo | 10/10 |
| v094_demo | 13/13 |
| v095_demo | 7/7 |
| v096_demo | 5/5 |
| v097_demo | 10/10 |
| v098_demo | 13/13 |

## Alcance

Son pruebas headless del motor real. No prueban píxeles renderizados, las dos fotografías del vidrio, orientación visual final, calidad de las transiciones, materiales ni rendimiento de GPU. PRUEBA_MANUAL_0.9.9.md describe su revisión. Godot 4.7.2 Windows queda por probar. El ragdoll de las formas de maldición sigue siendo el derribo anterior.

La importación headless termina sin fallos de recursos o de GDScript. El editor del contenedor registra intentos de sockets de depuración restringidos y mensajes de almacenamiento de texturas del renderizador Dummy durante miniaturas; los registros de ejecución de las pruebas no presentan errores. Estos avisos no constituyen una comprobación gráfica.

## Repetir

```text
python qa/repetir_pruebas_v099.py --godot "/ruta/al/Godot_que_adjuntaste" --output "/ruta/nueva/resultados"
```

El runner importa, aísla preferencias mediante carpetas XDG, ejecuta el motor y conserva comandos, códigos de salida, logs y resumen JSON. En Windows adapta las rutas al ejecutable y carpeta local. Para empaquetar:

```text
python qa/empaquetar_v099.py --output "/ruta/Naoya_v0.9.9.zip" --sources "/ruta/Naoya_v0.9.9_Fuentes.zip"
```

Se conserva intacto Naoya 0.9.8 como respaldo. Los recursos fuente opcionales se conservan en Fuentes.zip. Los 16 colores WebP tienen exactamente los mismos píxeles y dimensiones que sus PNG originales; reporte en resultados_v099/texturas_robot_v099.json.
