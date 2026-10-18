# Resultado de pruebas — Naoya 0.9.6

**739/739 comprobaciones pasaron**, en 14 suites y seis demostraciones automatizadas. Motor: `4.4.1.stable.official.49a5bc7b6`, el ejecutable adjuntado por el usuario. Ejecución real headless: no son pruebas gráficas.

| Suite | Resultado |
|---|---:|
| Combate | 38/38 |
| Pulido | 25/25 |
| Presentación | 23/23 |
| Recursos | 23/23 |
| Revisión de mecánicas | 60/60 |
| Regresión de videos anteriores | 60/60 |
| HUD | 97/97 |
| HUD y selección | 74/74 |
| Modelo alien | 86/86 |
| Revisión de movimiento y vidrio | 59/59 |
| Cristalización | 22/22 |
| Integración 0.9.5 | 48/48 |
| Ragdoll físico aislado | 11/11 |
| Actualización 0.9.6 | 59/59 |
| Seis demos | 54/54 |

Se actualizaron las expectativas de las pruebas que antes requerían cinco fotogramas, baile inmediato con B o reposo horizontal. Se conserva la verificación del combate, daño, counters, cinco segundos del vidrio, rig, materiales independientes y controles anteriores.

Las 59 comprobaciones nuevas incluyen: longitudes y escala del rig durante caída desde cuatro animaciones distintas; física finita; recuperación; tres bandidos sobre azotea; fase 2 con cabeza arriba/al frente; caminar/correr; superficies y ascensor; caída prolongada real; seis emotes y cancelación; entrada/retirada de Kogane; vidrio móvil; decoración y ambiente del dominio; grabación de poses del eco; finalización y limpieza; menú a 1280×720 y 640×360.

Registros completos y comandos ejecutados: `resultados_v096/pruebas_godot/resumen.json`. Para repetir con una carpeta de salida nueva:

```text
python qa/repetir_pruebas_v096.py --godot /ruta/Godot --project /ruta/proyecto --output /ruta/resultados_nuevos
```

La importación de recursos se completó. El editor headless imprime errores al intentar abrir sockets de depuración restringidos; se conservan en su log. Las suites y demos certificadas no tienen errores de ejecución ni recursos pendientes al salir.

Xorg no pudo abrir una pantalla virtual: `failed to bind listener` / `Cannot establish any listening sockets`. Registro: `resultados_v096/pantalla/`. **No se produjo video real ni capturas de Godot.** La demo usa mecánicas reales, con preparativos de laboratorio anunciados. Los PNG de `resultados_v096/recurso_fase2/` son renders del modelo exportado en Blender, útiles para revisar cabeza/cola, y no son gameplay.

No se ejecutó Godot 4.7.2 ni se midió rendimiento gráfico. Sigue pendiente la validación visual del conjunto en un equipo con pantalla.
