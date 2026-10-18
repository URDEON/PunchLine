from pathlib import Path
import bpy, math
from mathutils import Vector, Matrix
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath='/workspace/qa_v096/phase2_raw.glb')
objects=list(bpy.context.scene.objects)
root=bpy.data.objects.new('VisualBasis',None);bpy.context.collection.objects.link(root)
for obj in objects:
 if obj.parent is None: obj.parent=root
scene=bpy.context.scene; scene.render.engine='CYCLES';scene.cycles.samples=12;scene.cycles.use_denoising=False
scene.render.threads_mode='FIXED';scene.render.threads=2
scene.render.resolution_x=640;scene.render.resolution_y=640;scene.render.resolution_percentage=100
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.7
light=bpy.data.lights.new('Key','AREA');light.energy=900;light.size=5
obj=bpy.data.objects.new('Key',light);scene.collection.objects.link(obj);obj.location=(3,-4,6)
camera=bpy.data.cameras.new('Camera');cam=bpy.data.objects.new('Camera',camera);scene.collection.objects.link(cam)
camera.type='ORTHO';camera.ortho_scale=4;scene.camera=cam
cam.location=(4,-5,3);cam.rotation_euler=(Vector((0,0,0))-cam.location).to_track_quat('-Z','Y').to_euler()
out=Path('/workspace/qa_v096/phase2_views');out.mkdir(exist_ok=True)
# Importación glTF convierte (x,y,z) Godot a (x,-z,y) Blender.
convert=Matrix(((1,0,0),(0,0,-1),(0,1,0)))
for name, columns in [('raw',((1,0,0),(0,1,0),(0,0,1))),('idle',((0,0,-1),(1,0,0),(0,-1,0))),('travel',((0,-1,0),(1,0,0),(0,0,1)))]:
 basis=Matrix(columns).transposed()
 root.matrix_world=(convert@basis@convert.inverted()).to_4x4()
 scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
