# Procedencia de la revisión

Se conservaron las fuentes recibidas antes de modificar el proyecto y se creó
la rama `repair/0.9.24`. La base recuperada combina las fuentes completas 0.9.21,
la ciudad y las correcciones editables posteriores, contrastadas con el paquete
de corrección 0.9.23 que estaba en Drive. Ese paquete conservaba internamente
el nombre `PunchLine_0.9.21.pck`; su nombre no se usó como indicador de actualidad.

Se recuperaron de ese PCK las últimas revisiones de los siete scripts que diferían:
`main`, `robot_clearance`, `robot_procedural_motion`, `punchline_map`, `robot_character`,
`robot_locomotion` y `mecha_articulation`. El primer commit preserva esa base completa.
Las correcciones 0.9.24 se desarrollan encima de ella y la exportación se reconstruye
con Godot a partir del proyecto editable. Se conserva el origen sin alteraciones
en el respaldo de trabajo y el historial de Git.
