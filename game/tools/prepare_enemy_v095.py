"""Optimizar y riggear el único modelo texturado, conservando original y UV."""
from pathlib import Path
import bpy,sys,json,math
from mathutils import Vector,kdtree
root=Path(sys.argv[sys.argv.index('--')+1]);out=root/'assets/enemies/y2k';out.mkdir(exist_ok=True)
args=sys.argv[sys.argv.index('--')+1:]
artifacts=Path(args[1]) if len(args)>1 else root.parent/'naoya_preparation'
artifacts.mkdir(parents=True,exist_ok=True)
sys.path.insert(0,str(root/'tools'))
from gltf_embedded import export_embedded
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(out/'original/UrbanShadow_original.glb'))
mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH');mesh.name='UrbanShadow'
assert not any(o.type=='ARMATURE' for o in bpy.context.scene.objects)
points=[mesh.matrix_world@v.co for v in mesh.data.vertices];low=min(p.z for p in points);high=max(p.z for p in points)
factor=2.57286/(high-low)
for v,p in zip(mesh.data.vertices,points):v.co=Vector((-p.x*factor,-p.y*factor,(p.z-low)*factor))
mesh.matrix_world.identity();mesh.data.update()
bpy.context.view_layer.objects.active=mesh
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.remove_doubles(threshold=1e-5);bpy.ops.object.mode_set(mode='OBJECT')
mesh.data.calc_loop_triangles();before=len(mesh.data.loop_triangles)
protect=mesh.vertex_groups.new(name='ProtectFaceAndJoints')
for v in mesh.data.vertices:
 z=v.co.z;x=abs(v.co.x)
 w=.9 if z>2.10 else (.65 if (1.80<z<2.05 and x>.40) or .90<z<1.15 else .05)
 protect.add([v.index],w,'REPLACE')
mod=mesh.modifiers.new('TiempoReal','DECIMATE');mod.ratio=18000/before;mod.vertex_group=protect.name;mod.vertex_group_factor=.75;mod.use_collapse_triangulate=True
bpy.ops.object.modifier_apply(modifier=mod.name)
if mesh.vertex_groups.get('ProtectFaceAndJoints'): mesh.vertex_groups.remove(mesh.vertex_groups['ProtectFaceAndJoints'])
mesh.data.calc_loop_triangles();after=len(mesh.data.loop_triangles)
objects=set(bpy.context.scene.objects)
bpy.ops.import_scene.gltf(filepath=str(root/'assets/rpg_animations/Unarmed.glb'))
new=set(bpy.context.scene.objects)-objects;arm=next(o for o in new if o.type=='ARMATURE')
for o in list(new):
 if o.type=='MESH':bpy.data.objects.remove(o,do_unlink=True)
arm.name='UrbanRig';arm.animation_data.action=None;arm.animation_data.use_nla=False;arm.data.pose_position='REST'
bpy.ops.object.select_all(action='DESELECT');arm.select_set(True);bpy.context.view_layer.objects.active=arm;bpy.ops.object.mode_set(mode='EDIT')
original={b.name:(b.matrix.copy(),b.head.copy()) for b in arm.data.edit_bones}
# Se conserva la orientación del rig de combate; se ajustan posiciones al cuerpo.
for b in arm.data.edit_bones:
 matrix,head=original[b.name]
 if any(s in b.name for s in ['Clavicle','UpperArm','Forearm','Hand','Finger']):head.x*=.79
 elif any(s in b.name for s in ['Thigh','Calf','Foot','Toe']):head.x*=1.08
 matrix.translation=head;b.use_connect=False;b.matrix=matrix
for b in arm.data.edit_bones:
 b.length=max(1.0,min((c.head-b.head).length for c in b.children) if b.children else (5 if 'Finger' in b.name else 10))
 b.use_deform=b.name!='Motion'
bpy.ops.object.mode_set(mode='OBJECT')
bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);arm.select_set(True);bpy.context.view_layer.objects.active=arm
bpy.ops.object.parent_set(type='ARMATURE_AUTO',keep_transform=True)
unweighted=[v.index for v in mesh.data.vertices if sum(g.weight for g in v.groups)<1e-6]
bad=set(unweighted);valid=[v for v in mesh.data.vertices if v.index not in bad];tree=kdtree.KDTree(len(valid))
for v in valid:tree.insert(v.co,v.index)
tree.balance()
for idx in unweighted:
 _,nearest,_=tree.find(mesh.data.vertices[idx].co)
 for g in mesh.data.vertices[nearest].groups:mesh.vertex_groups[g.group].add([idx],g.weight,'REPLACE')
bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);bpy.context.view_layer.objects.active=mesh
bpy.ops.object.mode_set(mode='WEIGHT_PAINT');bpy.ops.object.vertex_group_limit_total(limit=4);bpy.ops.object.vertex_group_normalize_all(lock_active=False);bpy.ops.object.mode_set(mode='OBJECT')
arm.data.pose_position='POSE'
for b in arm.pose.bones:b.matrix_basis.identity()
# Exportar glTF Embedded para preparar ragdoll, en el orden solicitado.
export_embedded(out/'UrbanShadow_Rig.gltf',export_animations=True,export_animation_mode='NLA_TRACKS',export_skins=True,export_def_bones=False,export_image_format='AUTO')
# Datos de clasificación: geometría + UV + color original, usados sin servicios externos.
mesh.data.calc_loop_triangles()
geometry={'vertices':[list(v.co) for v in mesh.data.vertices],
          'triangles':[{'v':list(t.vertices),'uv':[list(mesh.data.uv_layers.active.data[loop].uv) for loop in t.loops]} for t in mesh.data.loop_triangles]}
(artifacts/'enemy_geometry.json').write_text(json.dumps(geometry))
report={'original_triangles':before,'optimized_triangles':after,'vertices':len(mesh.data.vertices),'bones':len(arm.data.bones),'uv_layers':len(mesh.data.uv_layers),'original_preserved':True,'automatic_weights_only_new_enemy':True,'unweighted_details_assigned':len(unweighted),'weight_min':min(sum(g.weight for g in v.groups) for v in mesh.data.vertices),'weight_max':max(sum(g.weight for g in v.groups) for v in mesh.data.vertices),'export':'glTF Embedded','source':'UrbanShadow_original.glb'}
(out/'preparation_report.json').write_text(json.dumps(report,indent=2));print('ENEMY_PREPARED',report)
bpy.ops.wm.save_as_mainfile(filepath=str(artifacts/'UrbanShadow_Rig.blend'))
