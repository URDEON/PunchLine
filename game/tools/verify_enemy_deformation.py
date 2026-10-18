"""Inspecciona deformación real en Blender y renders de recursos, no gameplay."""
from pathlib import Path
import bpy,sys,json,numpy as np
from mathutils import Vector
root=Path(sys.argv[sys.argv.index('--')+1]);out=root/'resultados_v095'/'recursos_blender';out.mkdir(parents=True,exist_ok=True)
sys.path.insert(0,str(root/'qa/modelo_alien/herramientas'))
from inspeccionar_modelo import camera_at,area_light
args=sys.argv[sys.argv.index('--')+1:];artifacts=Path(args[1]) if len(args)>1 else root.parent/'naoya_preparation'
bpy.ops.wm.open_mainfile(filepath=str(artifacts/'UrbanShadow_Rig.blend'))
arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH')
arm.animation_data.use_nla=False;arm.data.pose_position='POSE'
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=8;scene.cycles.use_denoising=False
scene.render.threads_mode='FIXED';scene.render.threads=2
scene.render.resolution_x=640;scene.render.resolution_y=720;scene.render.resolution_percentage=100
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.09,.11,.15,1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.65
center=Vector((0,0,1.25));area_light('key',(3,4,5),500,3,center);area_light('fill',(-3,2,3),250,3,center)
camera_at(scene,Vector((0,6,1.5)),center,3.1)
report=[];rest=None
for label,part,frame in [('reposo','IdleAlert1',5),('carrera','RunForward',5),('golpe','AttackR1',8),('caida','Knockdown1',12),('recuperacion','Getup1',10)]:
 action=next(a for a in bpy.data.actions if part in a.name)
 arm.animation_data.action=action;scene.frame_set(frame)
 deps=bpy.context.evaluated_depsgraph_get();ev=mesh.evaluated_get(deps);m=ev.to_mesh()
 coords=np.array([list(ev.matrix_world@v.co) for v in m.vertices]);ev.to_mesh_clear()
 if rest is None: rest=coords.copy()
 displacement=np.linalg.norm(coords-rest,axis=1)
 record={'pose':label,'action':action.name,'frame':frame,'finite':bool(np.isfinite(coords).all()),'bounds':[coords.min(0).tolist(),coords.max(0).tolist()],'changed_vertices':int((displacement>.01).sum()),'max_displacement':float(displacement.max())}
 report.append(record)
 scene.render.filepath=str(out/(label+'.png'));bpy.ops.render.render(write_still=True)
assert all(r['finite'] for r in report)
assert all(r['changed_vertices']>1500 for r in report[1:])
(out/'deformacion.json').write_text(json.dumps(report,indent=2));print('DEFORMATION_VERIFIED',report)
