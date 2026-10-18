"""Renders de inspección de máscaras y colores; no son capturas del juego."""
from pathlib import Path
import bpy,sys,numpy as np
from PIL import Image
from mathutils import Vector
root=Path(sys.argv[sys.argv.index('--')+1]);out=root/'resultados_v095/recursos_blender';out.mkdir(parents=True,exist_ok=True)
sys.path.insert(0,str(root/'qa/modelo_alien/herramientas'))
from inspeccionar_modelo import camera_at,area_light
args=sys.argv[sys.argv.index('--')+1:];artifacts=Path(args[1]) if len(args)>1 else root.parent/'naoya_preparation'
bpy.ops.wm.open_mainfile(filepath=str(artifacts/'UrbanShadow_Rig.blend'))
arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE');mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH')
arm.animation_data.use_nla=False;arm.animation_data.action=None
for bone in arm.pose.bones: bone.matrix_basis.identity()
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=8;scene.cycles.use_denoising=False;scene.render.threads_mode='FIXED';scene.render.threads=2
scene.render.resolution_x=960;scene.render.resolution_y=800;scene.render.resolution_percentage=100
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.08,.10,.14,1);scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.8
area_light('key',(2,5,6),550,4,Vector((0,0,1.3)));area_light('fill',(-3,3,3),200,3,Vector((0,0,1.3)))
material=mesh.data.materials[0];bsdf=next(n for n in material.node_tree.nodes if n.type=='BSDF_PRINCIPLED');image=next(n.image for n in material.node_tree.nodes if n.type=='TEX_IMAGE' and any(l.to_socket==bsdf.inputs['Base Color'] for l in n.outputs[0].links))
width,height=image.size;values=np.array(image.pixels[:]).reshape(height,width,4)
# Blender pixels de imágenes sRGB contienen muestras sRGB; conversión explícita al shader lineal.
rgb=values[:,:,:3][::-1];rgb=rgb**2.2
def packed_mask(path):
 # Son cuatro datos independientes: redimensionar RGBA como color destruiría RGB cuando A=0.
 return np.stack([np.asarray(channel.resize((width,height))) for channel in Image.open(path).split()],2).astype(float)/255
ma=packed_mask(root/'assets/enemies/y2k/textures/regions_a.png')
mb=packed_mask(root/'assets/enemies/y2k/textures/regions_b.png')
weights=[ma[:,:,i] for i in range(4)]+[mb[:,:,i] for i in range(3)]
palettes=[['282b33','555961','20232b','bfc3ca','b4bac6'],['7c2636','342d35','4c1826','b7a4a5','5c3c45'],['254e88','394b66','223b68','b1c7dd','aac6e5'],['485f3b','414839','34442b','a1a991','737e65'],['b5b7bc','72777e','969aa3','dcdfe5','d1d6df'],['563370','383044','412552','c4b1d1','776487']]
lum=rgb@np.array([.2126,.7152,.0722]);protection=np.clip((lum-.25)/.4,0,1);protection=protection**2*(3-2*protection)
def color(h):return (np.array([int(h[i:i+2],16) for i in (0,2,4)])/255)**2.2
for index,palette in enumerate(palettes):
 c=rgb.copy()
 for i,h in enumerate(palette+['281e18',['d9a47b','b47850','855439','efc5a1'][index%4]]):
  tint=color(h)
  if i<3: derived=tint*np.clip(lum/.075,.25,2.8)[:,:,None];derived=derived*(1-protection[:,:,None])+rgb*protection[:,:,None]
  elif i in [3,4]:derived=tint*np.clip(lum/(.65 if i==3 else .6),0,1.4)[:,:,None]
  elif i==5:derived=tint*np.clip(lum/.045,.3,2)[:,:,None]
  else:derived=rgb*tint/np.array([.68,.47,.30])
  c=c*(1-weights[i][:,:,None])+derived*weights[i][:,:,None]
 c=np.clip(c,0,1)**(1/2.2);pixels=values.copy();pixels[:,:,:3]=c[::-1]
 replacement=bpy.data.images.new('PreviewPalette'+str(index),width,height,alpha=True)
 replacement.pixels.foreach_set(pixels.astype(np.float32).ravel());replacement.update()
 tex=bpy.data.materials.new('PreviewRegional'+str(index));tex.use_nodes=True
 node=tex.node_tree.nodes.new('ShaderNodeTexImage');node.image=replacement
 tex.node_tree.links.new(node.outputs['Color'],tex.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
 tex.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.8
 dup=mesh.copy();dup.data=mesh.data;scene.collection.objects.link(dup);dup.modifiers.clear();dup.material_slots[0].link='OBJECT';dup.material_slots[0].material=tex
 dup.location.x=(index%3-1)*2.8;dup.location.z=-(index//3)*3.0
mesh.hide_render=True
camera_at(scene,Vector((0,10,.0)),Vector((0,0,0)),8.5)
scene.render.filepath=str(out/'seis_paletas.png');bpy.ops.render.render(write_still=True)
print('PALETTE_PREVIEW_RENDERED')
