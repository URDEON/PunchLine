"""Rig local de alas y cola; el GLB original permanece intacto."""
from pathlib import Path
import bpy,sys,json
from mathutils import Vector
root=Path(sys.argv[sys.argv.index('--')+1])
def smooth(a,b,x):
 t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(root/'assets/companions/SkullWisp.glb'))
mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH')
assert not any(o.type=='ARMATURE' for o in bpy.context.scene.objects)
mesh.name='SkullWispVisual'
data=bpy.data.armatures.new('KoganeArmature');arm=bpy.data.objects.new('KoganeArmature',data);bpy.context.collection.objects.link(arm)
bpy.context.view_layer.objects.active=arm;arm.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
for name,head,tail in [('Body',(0,0,.5),(0,0,.85)),('WingL',(.19,0,.83),(.39,0,.96)),('WingR',(-.19,0,.83),(-.39,0,.96)),('Tail',(0,0,.45),(0,0,.1))]:
 b=data.edit_bones.new(name);b.head=head;b.tail=tail
 if name!='Body':b.parent=data.edit_bones['Body']
bpy.ops.object.mode_set(mode='OBJECT')
groups={n:mesh.vertex_groups.new(name=n) for n in ['Body','WingL','WingR','Tail']}
counts={n:0 for n in groups}
for v in mesh.data.vertices:
 p=mesh.matrix_world@v.co
 wing=smooth(.22,.29,abs(p.x))*smooth(.74,.82,p.z)
 tail=(1-smooth(.25,.48,p.z))*(1-wing)
 body=1-wing-tail
 for name,w in [('Body',body),('WingL' if p.x>0 else 'WingR',wing),('Tail',tail)]:
  if w>1e-6:groups[name].add([v.index],w,'REPLACE');counts[name]+=1
mod=mesh.modifiers.new('KoganeWingRig','ARMATURE');mod.object=arm;mesh.parent=arm
bpy.ops.export_scene.gltf(filepath=str(root/'assets/companions/SkullWispRig.glb'),export_format='GLB',export_animations=False,export_skins=True,export_def_bones=False)
(root/'assets/companions/kogane_rig_report.json').write_text(json.dumps({'bones':list(groups),'weighted_vertices':counts,'original_preserved':True,'technique':'soft weights from actual wing/tail regions; head rigid'},indent=2))
print('KOGANE_RIG',counts)
