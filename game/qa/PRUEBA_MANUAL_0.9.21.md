# Prueba manual 0.9.21

1. Confirmar versión y conservación de tecla lock, HUD y volumen de 0.9.20.
2. Esc > Combate: elegir los cuatro robots; caminar y correr, girar y pasar pendientes. Comparar Apoyos de robots base activado/desactivado en Ajustes > Cámara.
3. En Leela y George revisar la unión visual de pies y piernas. En los cuatro, hacer emotes, dash, salto, ragdoll y recuperación; comprobar que no se acumulan poses.
4. Preparar Sentinel y atacar con M1. Otro jugador debe golpear el miembro ejecutor hasta destruirlo antes del contacto; el ataque se interrumpe. Si destruye el opuesto, continúa el miembro intacto.
5. Destruir pierna derecha, usar 3 y comprobar pisotón izquierdo. No debe sonar un paso de la pierna que falta.
6. Morir mientras mantiene cañón: láser y punto se apagan; no hay reaparecer antes de finalizar restos.
7. Online: observar una muerte desde otro cliente y cambiar generación/reaparecer; no deben reaparecer colisiones vivas ni quedar despieces de otro cuerpo.
8. Medir FPS con la misma escena y GPU. Las pruebas sin imagen no sustituyen esta revisión.

Scripts automatizados: repetir_pruebas_v0921_revision.py, repetir_mechas_v0921_revision.py y verificar_exportacion_v0921_revision.py, con --godot y --output en una carpeta nueva.
