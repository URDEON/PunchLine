from pathlib import Path
import bpy,sys,json,math
from mathutils import Vector
root=Path(sys.argv[sys.argv.index('--')+1]);out=root.parent/'naoya_preparation/asset_previews';out.mkdir(parents=True,exist_ok=True)
sys.path.insert(0,str(root/'qa/modelo_alien/herramientas'))
from inspeccionar_modelo import bounds,camera_at,area_light
for label,path in [('enemy',root/'assets/enemies/y2k/original/UrbanShadow_original.glb'),('kogane',root/'assets/companions/SkullWisp.glb')]:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=str(path))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];low,high=bounds(meshes);center=(low+high)/2
 h=high.z-low.z
 print('ASSET',label,'BOUNDS',list(low),list(high),'MESHES',[(o.name,len(o.data.vertices)) for o in meshes],'ARMS',[(o.name,len(o.data.bones)) for o in bpy.context.scene.objects if o.type=='ARMATURE'])
 scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=12;scene.cycles.use_denoising=False;scene.render.threads_mode='FIXED';scene.render.threads=2
 scene.render.resolution_x=640;scene.render.resolution_y=720;scene.render.resolution_percentage=100
 scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.17,.19,.23,1);scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.65
 area_light('key',(center.x+2*h,center.y+2*h,center.z+3*h),250*h*h,2*h,center)
 area_light('fill',(center.x-2*h,center.y-2*h,center.z+h),100*h*h,2*h,center)
 for side,y in [('front',-1),('back',1),('side',0)]:
  location=center+Vector((2.5*h if side=='side' else 0,y*2.5*h,0))
  camera_at(scene,location,center,h*1.22)
  scene.render.filepath=str(out/(label+'_'+side+'.png'));bpy.ops.render.render(write_still=True)
