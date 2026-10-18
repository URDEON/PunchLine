# PunchLine — Habilidad G: Fusión de Mechas

## Qué contiene

Este proyecto **reproducible y editable en Godot 4.4+** crea una secuencia programada de 11,5 segundos:

1. George asciende desde el suelo; Leela, Mike y Stan entran volando desde los lados.
2. Los cuatro convergen en el aire hacia un núcleo brillante.
3. El Rust Vanguard aparece **separado en 22 módulos rígidos** que caen escalonados.
4. Las piezas giran, rebotan ligeramente y encajan una a una hasta formar el mecha definitivo.
5. Una onda de choque confirma la fusión.

**Altura:** personaje normal = 2 m; Rust Vanguard completo = 4 m (**exactamente x2**).

## Cómo verlo

1. Descomprime el ZIP.
2. Abre `project.godot` en **Godot 4.4 o superior**.
3. Espera a que el editor importe los 4 `.gltf` y el `.glb`.
4. Pulsa **F6** teniendo abierta `FusionDemo.tscn`, o **F5** para ejecutar el proyecto.
5. Pulsa **G** para repetir. **Espacio** para pausar/reanudar.

La transformación es una animación **programada en `scripts/fusion_g.gd`**, no un video incrustado. Puedes cambiar tiempos, trayectorias, escala, efectos y el orden de ensamblaje.

## Archivos importantes

- `FusionDemo.tscn`: escena principal.
- `scripts/fusion_g.gd`: lógica de toda la animación G.
- `assets/originales/{George,Leela,Mike,Stan}.gltf`: originales con sus animaciones propias.
- `assets/fusion/Rust_Vanguard_original.glb`: archivo de Meshy sin modificar.
- `assets/fusion/Rust_Vanguard_piezas.glb`: nueva versión con **22 nodos-malla independientes**, usando las texturas originales.
- `assets/fusion/despiece_info.json`: lista y estadísticas de piezas.
- `docs/PROMPT_PARA_CODEX.txt`: instrucciones listas para copiar a Codex.
- `tools/generate_pieces.py`: regenerar el despiece desde el GLB original (requiere Python y NumPy).

## Atención: dos límites importantes

1. **Despiece prototipo:** el modelo de Meshy tenía una sola malla y todos sus vértices estaban asignados al mismo hueso raíz. Las 22 piezas se separaron mediante cortes automáticos de triángulos según su posición. Se conserva el aspecto ensamblado, pero **las uniones cortadas pueden tener bordes abiertos y necesitan una revisión en Blender** si quieres que cada pieza sea perfecta desde todos los ángulos. Este sistema es una prueba de la fusión, no un rig de combate definitivo.
2. **Validación:** se revisó el archivo GLB y se generó la secuencia de Godot, pero **no se pudo ejecutar Godot en este entorno**. Puede haber ajustes que Codex deba hacer cuando abra la escena en tu versión concreta de Godot.

## Diferencia entre la fusión y el combate

La animación de transformación **sí mueve las piezas**. Una vez ensambladas, el robot tiene su forma definitiva, pero el modelo **todavía no está riggeado para correr y golpear**: ese será otro paso. El esqueleto Mixamo dentro del Meshy original no funciona como rig útil porque todos los vértices están vinculados al mismo hueso.

## Integrar en PunchLine

- Copiar las carpetas `assets/originales`, `assets/fusion` y el script `scripts/fusion_g.gd` al proyecto real, conservando rutas o actualizándolas.
- Colocar una instancia de `FusionDemo.tscn` o un nodo `Node3D` con `fusion_g.gd` junto al controlador del jugador.
- Al detectar la G, desactivar temporalmente los controles del jugador, llamar a `play_fusion()`, y esperar `fusion_finished(fused_character)`.
- En esa señal, activar la forma de combate fusionada cuando su controlador, hitbox, cámara y locomoción estén listos.
- Alinear posición mundo del nodo de fusión con el personaje original. Este demo incluye plataforma, cámara y HUD; Codex debe adaptar o eliminar esos elementos al moverlo al mapa real.

## Derechos

Los cuatro modelos animados originales son de Quaternius y se distribuyen bajo **CC0 1.0 Universal**, conforme al archivo `LICENCIA_QUATERNIUS.txt` incluido. Rust Vanguard proviene del archivo que tú proporcionaste.
