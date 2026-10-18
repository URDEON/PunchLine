# Comparación del pack adjuntado con Naoya 0.9.8

El ZIP contiene Universal Animation Library 1 Standard (Quaternius), con 43 animaciones y licencia CC0. Incluye GLB y FBX con y sin root motion. Se examinaron directamente los clips de ambos GLB y los AnimationStack de ambos FBX; los cuatro archivos contienen 43 clips y ninguno incluye Dodge. No se dedujo su contenido a partir del nombre del ZIP ni del visor externo.

## Dash y dodge

En UAL1 Standard no hay clips cuyos nombres contengan Dodge o Dash. Su evasión es `Roll`, una voltereta de 1,467 s. El rig actual del alien ya incorpora `UnarmedDodgeLeft`, `UnarmedDodgeRight`, `UnarmedDodgeBackward` y cuatro rolls direccionales. El jugador utiliza los tres dodges según la dirección; el dash frontal selecciona `UnarmedRunForward` acelerado.

El dash real dura 0,18 s. Ajustar el Roll completo de UAL1 a esa duración exigiría aproximadamente 8,15× de velocidad. Por ello no se recomienda como reemplazo directo del dash de proyección. Conviene primero mejorar la selección/mezcla del dash frontal y revisar el retorno a locomoción. Se detectó además que los NPC seleccionan siempre `UnarmedDodgeRight` durante su dash; la selección por dirección merece corregirse en la próxima actualización.

UAL2 Standard, ya disponible, contiene `Shield_Dash`, `Sword_Dash` y tres fases de slide. Las poses con arma o escudo necesitan evaluación para un luchador desarmado.

La captura posterior del usuario muestra explícitamente `Dodge_Left`, `Dodge_Left_RM`, `Dodge_Right` y `Dodge_Right_RM`. Estos nombres identifican los clips que quiere comparar, pero su archivo fuente no está en el ZIP Standard recibido. Se necesita el GLB/FBX correspondiente para analizar esos movimientos exactos; no se atribuye su contenido a una edición del pack sin verificarla.

## Comparación y selección

| Sistema | Actualmente | Aporte de UAL1 | Recomendación |
| --- | --- | --- | --- |
| Salto | NinjaJump Start/Idle/Land de UAL2, Falling de Mixamo tras cuatro segundos | Jump_Start, Jump_Loop, Jump_Land | Comparar manualmente una variante más natural, conservando el salto expresivo para habilidades |
| Reacciones | Aturdimiento y reacción a bloqueo del rig original | Hit_Chest, Hit_Head | Prioridad alta para variar la respuesta al impacto sin desplazar el controlador |
| Emotes | Running Man y siete gestos/poses | Dance_Loop | Añadir una alternativa de baile después de revisar su loop y transición |
| Interacción | Estaciones E funcionales | Interact | Gesto opcional adaptado; mantener inmediata la interacción |
| Locomoción | Mezcla de Mixamo y rig original, con guardia por capas | Idle, Walk, Jog, Sprint | Comparar antes de reemplazar clips que funcionan |
| Evasión | Dodges laterales/trasero y carrera frontal | Roll | Candidato para una evasión distinta; no sustituir automáticamente el dash |

## Compatibilidad y laboratorio

UAL1 y UAL2 tienen los mismos 65 huesos, orden, nombres y transformaciones de reposo. El alien usa 53 huesos y requiere retargeting. Se reutilizó el adaptador existente: 52 huesos mapeados, reposo del destino conservado, sin modificar sus pesos.

Se prepararon ocho clips en un proyecto separado: Jump_Start, Jump_Loop, Jump_Land, Dance_Loop, Hit_Chest, Hit_Head, Interact y Roll. `lab/adapted_ual1.tres` contiene la biblioteca candidata. **19/19 comprobaciones** pasaron con el Godot 4.4.1 adjuntado: presencia del rig/mallas, cantidad de clips, pistas dirigidas a los huesos existentes, vértices finitos y tamaño acotado en trece poses de cada clip, y conservación del reposo. Registros en `validation.log` y `lab/validation.json`.

Esta es una validación geométrica sin imagen; la calidad visual, contactos, transiciones y posibles intersecciones locales siguen pendientes de revisión manual. Los clips activos del juego permanecen en la configuración de 0.9.8. No se grabó video.

Se utilizó la versión sin `_RM`: sus root tracks no presentan desplazamiento horizontal. En la versión RM, Roll desplaza la raíz unos 4,99 m y Sprint unos 5,5 m por ciclo. La física del juego ya mueve CharacterBody3D; incorporar esos desplazamientos requiere un sistema explícito de root motion para evitar movimientos duplicados.

## Próxima fase

Mantener primero la corrección del mapa y los errores pendientes de 0.9.9. Incorporar después la selección de dash por dirección, reacciones nuevas, baile y comparación manual de salto, por separado y con regresión de combate. El material disponible alcanza; no se necesita generar modelos nuevos para aprovechar este pack.

## Repetir el laboratorio

```text
GODOT --headless --path /ruta/qa_pack_ual1/lab --editor --import --quit
GODOT --headless --path /ruta/qa_pack_ual1/lab --script res://retarget_candidate.gd
GODOT --headless --path /ruta/qa_pack_ual1/lab --script res://validate.gd
```

En el entorno se utilizaron carpetas XDG de cache, data y config dentro de qa_pack_ual1. El laboratorio conserva los GLB fuente/destino, adaptador, licencia e inventario completo.


Estado 0.9.9: se corrigió la elección del dash de los NPC por dirección. El jugador conserva los dodges existentes; las ocho variantes UAL1 permanecen en su laboratorio separado.
