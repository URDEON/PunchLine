# Naoya 0.9.2.1 — Correcciones del HUD

Esta copia parte de 0.9.2 y responde a las capturas del usuario. Las versiones anteriores se conservan separadas. El combate mantiene daño, tiempos, autoapuntado, ventanas de esquiva y fases.

- El triángulo debajo del retrato está completamente relleno de dorado. Al tocarlo se despliega una lista vertical oscura: Naoya seleccionado y dos casillas «Coming Soon», deshabilitadas. Se quitó «P · PJ» del retrato.
- P abre/cierra esa misma lista; Enter elige Naoya; clic fuera o Esc la cierran. El selector pausa reloj, recursos y enemigos. Si se abrió desde Ajustes/Pruebas, Esc o P devuelven al menú anterior; elegir Naoya reanuda sin reiniciar vida ni habilidades.
- Mantener Alt libera el cursor para alcanzar el triángulo durante el combate. Soltar Alt solicita de nuevo su captura para la cámara. Recorrer el HUD con el cursor libre no gira la cámara ni activa M1. Después de cerrar interfaz con clic mantenido, M1 espera que se suelte el botón. Alt queda reservado en la reasignación.
- Esc → Ajustes → Tamaño del HUD: 50–100%, inicialmente 80%. Modifica en vivo retrato, estados, barras y fichas; conserva anclajes y adaptación a la resolución. Menús y lista mantienen un tamaño independiente. La elección se guarda en preferencias.
- Los dibujos cambian por forma: humano conserva los monitos del boceto; Fase 1 muestra una criatura segmentada; Fase 2 usa otra silueta con coraza. Embestida, Tentáculos, Aceleración y Dominio tienen sus dibujos correspondientes. Las habilidades bloqueadas en Fase 1 siguen bloqueadas y explican «FASE 2».
- Se corrigió el grosor usado al dibujar círculos rellenos para eliminar avisos repetidos en el registro.

Q sigue siendo dash; P selector; 1–4 habilidades; G transformación/evolución. La elección posterior del usuario prevalece sobre la indicación antigua de Q del documento original.

Las vistas en `qa/vistas_hud` son diseños vectoriales estáticos exportados del código del HUD. No son capturas del juego. Ver `RESULTADOS_v0.9.2.1.md` para pruebas y limitación gráfica. Modelos, animaciones, audio, ragdoll, Counter 2D y dominio conservan pendientes, detallados en `PENDIENTES_ACTUALES.md`.
