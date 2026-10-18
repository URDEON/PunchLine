"""Exporta el rig válido del jugador sin reparentar ni recalcular pesos."""
from pathlib import Path
import bpy,sys,json
root=Path(sys.argv[sys.argv.index('--')+1]);sys.path.insert(0,str(root/'tools'))
from gltf_embedded import export_embedded
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(root/'assets/characters/alien/Alien_Naoya_Rig_Combat.glb'))
arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE');meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
print('PLAYER_SOURCE',len(arm.data.bones),[(o.name,len(o.vertex_groups)) for o in meshes])
weighted=[o for o in meshes if o.vertex_groups]
assert len(arm.data.bones)>=53 and weighted
arm.animation_data.action=None;arm.animation_data.use_nla=False
for track in arm.animation_data.nla_tracks:
 track.mute=not ('IdleAlert1' in track.name)
out=root/'assets/physics';out.mkdir(exist_ok=True)
export_embedded(out/'PlayerRagdollSource.gltf',export_animations=True,export_animation_mode='NLA_TRACKS',export_skins=True,export_def_bones=False)
(out/'player_export_report.json').write_text(json.dumps({'original':'assets/characters/alien/Alien_Naoya_Rig_Combat.glb','bones':len(arm.data.bones),'weighted_meshes':len(weighted),'auxiliary_unskinned_meshes':len(meshes)-len(weighted),'reparented':False,'weights_recalculated':False,'export':'glTF Embedded (JSON with embedded buffers and images)','reason':'standalone ragdoll test source; main player retains validated GLB'},indent=2))
print('PLAYER_EMBEDDED_EXPORTED')
