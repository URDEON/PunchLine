# PunchLine 0.9.21 — Parche experimental: Ruined City y combate

**Base:** proyecto editable 0.9.21 + el parche experimental de HUD, locomoción, chispas, brazo desprendido y cámara. **No es una versión estable certificada.**

## Implementado en archivos (sin afirmar pruebas de juego)
- `assets/environment/ruined_city/ruined_city_free_5.glb`: mapa aportado por el usuario sin alterar sus mallas, texturas, colores ni escala.
- `scripts/punchline_map.gd`, `scripts/arena.gd`: sustituido el mapa 5.4 del modo individual por Ruined City, colisiones basadas en las geometrías del GLB, nueva selección de puntos de aparición.
- `network/online_arena.gd`, `network/terrain_adapter.gd`, `network/player.gd`: mismo escenario para online, puntos de aparición dentro de los límites y inicialización del controlador de altura.
- `scripts/robot_clearance.gd`: sondas verticales con exclusión del personaje; contrae cápsula cuando detecta techo y no permite expandirla si hay colisión. Admite chasis y fusión. Radio físico no se reduce arbitrariamente.
- `scripts/mecha_articulation.gd`, `scripts/robot_character.gd`: flexión de articulaciones y postura mecánica en función del espacio libre; la recuperación es suave. Requiere verificación de pies y animaciones visuales.
- `scripts/main.gd`: validación de recarga y duración del dash, sin bloquear el propulsor del mecha fusionado. Comprobación por barrido de la habilidad 3 de Naoya, con línea de visión y validación de daño del servidor existente.
- `scripts/presentation.gd`: corrección de orientación local de la segunda forma de Naoya. Su eje delantero permanece en -Z, sin eje lateral fijo.
- `scripts/robot_character.gd`, `scripts/mecha_move_catalog.gd`: Mike obtiene **Paso de flanco** (3): movimiento lateral con velocidad 8 m/s durante 0,24 s, recarga de 7 s, sin invulnerabilidad ni atravesar colisiones.
- `scripts/route_trial.gd`, `scripts/punchline_interactions.gd`, `scripts/interface.gd`: recorridos, accesos e instrucciones adaptados al nuevo mapa.
- Se preservaron las optimizaciones experimentales del HUD, las partículas, el brazo y la cámara del parche anterior; **no hay datos de FPS medidos en esta entrega**.

## Límites conocidos
- **No se ejecutó Godot ni un cliente Windows en este entorno.** Los cambios son modificaciones de código, no correcciones certificadas.
- El GLB tiene geometría aproximada de 20 x 50 m. Las entradas e interiores explorables dependen de los huecos reales del modelo: no se han construido habitaciones que no existan en el GLB.
- Un mecha de 4 m solo se agacha hasta una cápsula de 2,2 m de alto y diámetro de 2,1 m. No debe atravesar puertas más estrechas.
- Colisiones de geometría 3D pueden consumir CPU; hay que medir FPS y memoria gráfica con el nuevo escenario.
- Multijugador real entre varios PC, desync de habilidades, animaciones de fase 2 y ragdoll requieren pruebas.
- Verificar licencia del GLB con la página donde se obtuvo; al distribuir el juego, conservar los créditos y términos exigidos por el autor.

## Pruebas recomendadas
1. Importar `project.godot` con **Godot 4.4.1**; esperar a que importe la nueva malla GLB.
2. Ejecutar con F5, seleccionar robot y entrar en un edificio. Observar la flexión bajo un techo y que no atraviese paredes.
3. Ejecutar `godot --headless --path . --script res://qa/ruined_city_smoke_v0921_exp.gd` y revisar sus resultados.
4. Probar dash hasta agotar enfriamiento, fusión, varias transformaciones y pausa/reanudación durante al menos diez minutos.
5. En modo online probar la habilidad 3 desde 3 ángulos, cerca de paredes y con 100+ ms de latencia.
6. Con Naoya fase 2, dar vueltas 360° y golpear hacia delante, atrás y lateral.
7. Con Mike, usar tecla 3 en movimiento y detenido, verificar las colisiones y recarga.

## Distribución
Esta entrega es **editable** y no contiene ejecutable Windows recompilado. Exportar en Godot genera los recursos `.import` requeridos para la malla nueva y un PCK fiable. No se debe afirmar que un PCK parcheado a mano funciona con un recurso GLB nuevo sin importar.
