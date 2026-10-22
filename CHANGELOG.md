# Cambios de PunchLine

## 0.9.29 — Menú recuperado, animaciones, armamento y Sentinel directo

- Reutiliza el lanzador original, su fondo, botones Ink, audio y galería; recupera selección y Extras.
- Integra el rig skinned X Bot y 24 clips de los dos paquetes FBX aportados, incluido Stepping Backward.
- AnimationTree con locomoción y acciones filtradas; selección Basic/Slim y cuerpo compartido FPS/TPS.
- Modelos originales aportados de M4A1 y MP5A5, con texturas, reservas AR/SMG separadas y Resources editables.
- Apuntado, cadencia automática media/rápida, recarga, caída de daño abstracta y bloqueo por obstáculos.
- Reacciones de impacto temporales y pools acotados de trazas/audio; balizas físicas y captura de práctica.
- HUD militar con distribución de la referencia, minimapa vectorial real, salud, puntuación y munición.
- Sentinel aparece directamente desde selección; reutiliza modelo, articulación, cañón y sonidos originales.
- Recupera el HUD Sci-Holo del Sentinel; no se instancian la fusión ni los cuatro robots anteriores.
- Conserva District500 y los recursos anteriores. Informe y evidencia en `docs/warfare/release-0.9.29.md`.

## 0.9.28 — Warfare:District500, Fase 0 / primera parte de Fase 1

- Base 0.9.27 protegida con etiqueta Git y bundle completo verificado mediante restauración.
- Nuevo arranque, menú, práctica y opciones independientes del juego de lucha.
- District500 y sus 77 edificios cargados desde las escenas existentes, sin regeneración.
- Soldado provisional original: entrada, movimiento, representación, cámara y salud separados.
- Movimiento configurable, caminata/carrera, salto, agachado con comprobación de techo y escaleras.
- FPS/TPS con un mismo esqueleto y cuerpo, cambio de hombro y protección TPS ante paredes.
- Base bodycam configurable, accesibilidad y lente opcional, apagada por defecto.
- Salud, observación al incapacitarse, reaparición, pausa y registrador desacoplado.
- Sentinel y recursos compartidos conservados; fusión y luchadores fuera del arranque activo.
- Evidencia y límites en `docs/warfare/phase0-phase1.md`; no se declara alcanzado un objetivo de FPS.

## 0.9.27

- Renderizado Forward+ para niebla volumétrica nativa, por elección del usuario.
- Niebla ambiental y 38 bancos volumétricos animados en los espacios verdes libres.
- Pasto procedural por semilla, agrupado en MultiMesh, con viento y distancia limitada.
- Exclusiones de edificios, accesos, senderos, calles, veredas y estacionamiento.
- Ajustes de calidad, viento e intensidad de niebla en IMAGEN.

## 0.9.26

- Cámara de la araña sin superposición con su modelo al caminar.
- Primera/tercera persona con V, distancia con rueda y protección contra paredes.
- Salto desde suelo, paredes y techos, con aterrizaje y patas recogidas en el aire.
- Controles, estado aéreo y orientación sincronizados en multijugador.

## 0.9.25

- Edificios procedurales de tres y cuatro plantas con interiores y escaleras.
- Versión centralizada en el proyecto, visible en menú, HUD, ventana y multijugador.
- Nombre estable para los datos guardados y recuperación de ajustes de 0.9.24.

## 0.9.24 y entregas anteriores

- Integración de District500 y viviendas accesibles con texturas y ventanas reales.
- Semillas editables, densidad, día/noche y cabeza araña Rustcrawler.
- Accesos para el mecha y contactos procedurales con techo y paredes.

Las entregas anteriores conservaron el mismo número de versión. Desde 0.9.25,
cada actualización entregada incrementa la versión y registra sus cambios aquí.
