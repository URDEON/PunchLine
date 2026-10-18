# Lista de correcciones — 0.9.14

- [x] **1. Animaciones:** rig mecánico, activación, idle, caminar, carrera pesada, caída/aterrizaje, M1 y guardia; brazos fuera de T-pose.
- [x] **2. Orientación:** frente del GLB alineado con avance y combate.
- [x] **3. Pasos:** variantes metálicas, apoyo de suela y comprobación de suelo; silencio en reposo/aire.
- [x] **4. Estadísticas:** 300 HP, velocidad 2,35 / 1,05 con Ctrl, altura 4 m, cápsula y alcance adecuados.
- [x] **5. Ultimate:** carga válida en los cuatro chasis, cero por fallo/guardia, persistencia entre reapariciones y consumo de 100 al usar G.
- [x] **6. Sonido de referencia:** fragmentos del walker combinados con Servo; núcleo derivado de inside-the-robot.
- [x] **7. HUD robótico:** gráficos Holo, vida máxima variable, energía, habilidades, cooldowns y restauración de Naoya.
- [x] **8. Propulsores:** chorro blanco/celeste animado, intensidad variable y estela.
- [x] **9. Aros:** sustituidos por polvo al encajar y asentarse.
- [x] **10. Humo/polvo:** ruido procedural, bordes suaves, tres capas, vidas limitadas y presupuesto de partículas.
- [x] **11. Presentación final:** activación articulada, servos, impacto, polvo, vibración y transición al control.
- [x] **12. Integración local:** regresión, paquete exportado, render real y ENet con anfitrión y dos clientes en procesos separados.

## Próxima comprobación manual

- [ ] Probar la 0.9.14 en tu Godot 4.7.2 / Windows y medir rendimiento en tu PC.
- [ ] Revisar apoyo de pies y cámara sobre escaleras, bordes y desniveles del mapa.
- [ ] Jugar entre tres PC con latencia real/VPN y revisar carga, fusión, golpes y reconexión.
- [ ] Ajustar balance y volumen por oído después de tu prueba.

Las habilidades especiales 1–4 del fusionado permanecen pendientes. El rig actual articula piezas rígidas; no es un skin orgánico ni un ragdoll nuevo de Rust Vanguard.

Para reportar un error nuevo: modo Individual/Online, chasis, lugar, pasos para reproducirlo, resultado esperado y captura o video si ayuda. La guía de recorrido está en `qa/mechas/PRUEBA_MANUAL.md`.
