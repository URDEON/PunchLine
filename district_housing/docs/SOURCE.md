# PunchLine — Construcción procedural de viviendas en Distrito500

Entregables principales:
- `district_lots.json`: 19 MACRO-lotes reales transformados desde `tools/layout_vector.geojson` del paquete Distrito500; contiene polígonos X,Z en metros, categorías y reglas de acceso del mecha.
- `PROMPT_CODEX_PUNCHLINE_CASAS_PROCEDURALES.md`: instrucción completa para implementar el generador en Codex.

Archivos auxiliares:
- `PLANO_LOTES_NUMERADOS.png`: sobreimpresión de identificadores y propuestas de uso, sobre el mapa existente.
- `layout_vector.geojson`: fuente vectorial original copiada para que Codex pueda verificar los polígonos y excluir calles/estacionamiento.

## Cómo usar
1. Usa el paquete base `PunchLine_Distrito500_Godot4_COMPLETO.zip` como proyecto Godot.
2. Copia `district_lots.json` a `res://data/district_lots.json` o ajusta el path de tu generador.
3. Mantén `layout_vector.geojson` dentro de `res://tools/` (incluido en el paquete original).
4. Comparte al agente de Codex el proyecto real, el JSON y el prompt.
5. Primero construye y prueba el lote piloto; después genera el distrito entero.

## Precisión
- Derivado de los **19 macro-lotes** de la geometría existente (NO son huellas de casas). Las opciones de zonificación/edificios son propuestas nuevas, no propiedades del mapa original ni levantamiento de Melipilla.
- Coordenadas geográficas NO incluidas: X,Z son coordenadas LOCALES del Godot map 500x500 m.
- Las dimensiones de mecha de pie/agachado están sin fijar: se deben medir en el proyecto PunchLine para evitar puertas falsas.
- NO es un generador terminado: es la definición técnica y especificación para que Codex lo implemente.
