import bpy,json,struct,io,math
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parent.parent; dst=root/'assets/fusion/optimized';dst.mkdir(exist_ok=True)
report=[]
for filename,ratio in [('Junkyard_Sentinel.glb',.22),('Rustwing_56_Original.glb',.30)]:
 src=root/'assets/fusion/sentinel_v8'/filename;b=src.read_bytes();n=struct.unpack_from('<I',b,12)[0];j=json.loads(b[20:20+n]);base=28+n
 images=[]
 for im in j['images']:
  view=j['bufferViews'][im['bufferView']];start=base+view.get('byteOffset',0);images.append(Image.open(io.BytesIO(b[start:start+view['byteLength']])).convert('RGB'))
 width=2048;pad=8;x=y=row=0;positions={}
 for i in sorted(range(len(images)),key=lambda k:-images[k].height):
  im=images[i];w=im.width+pad*2;h=im.height+pad*2
  if x+w>width:y+=row;x=0;row=0
  positions[i]=(x+pad,y+pad);x+=w;row=max(row,h)
 height=2**math.ceil(math.log2(y+row));atlas=Image.new('RGB',(width,height))
 for i,im in enumerate(images):
  px,py=positions[i];atlas.paste(im,(px,py));w,h=im.size
  atlas.paste(im.crop((0,0,1,h)).resize((pad,h)),(px-pad,py));atlas.paste(im.crop((w-1,0,w,h)).resize((pad,h)),(px+w,py))
  atlas.paste(atlas.crop((px-pad,py,px+w+pad,py+1)).resize((w+pad*2,pad)),(px-pad,py-pad));atlas.paste(atlas.crop((px-pad,py+h-1,px+w+pad,py+h)).resize((w+pad*2,pad)),(px-pad,py+h))
 path=dst/(src.stem+'_atlas.png');atlas.save(path)
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=str(src));meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];before=sum(len(o.data.polygons) for o in meshes)
 tex=bpy.data.images.load(str(path),check_existing=False);mat=bpy.data.materials.new('Shared_'+src.stem);mat.use_nodes=True
 bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.9
 node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=tex;mat.node_tree.links.new(node.outputs['Color'],bs.inputs['Base Color'])
 byname={m['name']:i for i,m in enumerate(j['materials'])}
 for o in meshes:
  m=o.data;uv=m.uv_layers.active
  for poly in m.polygons:
   name=m.materials[poly.material_index].name;mi=byname.get(name,byname.get(name.rsplit('.',1)[0]))
   if mi is None:raise ValueError(name)
   ii=j['textures'][j['materials'][mi]['pbrMetallicRoughness']['baseColorTexture']['index']]['source'];im=images[ii];px,py=positions[ii]
   for li in poly.loop_indices:
    u,v=uv.data[li].uv;uv.data[li].uv=((px+u*im.width)/width,(height-py-im.height+v*im.height)/height)
  m.materials.clear();m.materials.append(mat)
  for poly in m.polygons:poly.material_index=0
  bpy.context.view_layer.objects.active=o
  mod=o.modifiers.new('GameLOD','DECIMATE');mod.ratio=ratio
  bpy.ops.object.modifier_apply(modifier=mod.name)
 after=sum(len(o.data.polygons) for o in meshes)
 bpy.ops.export_scene.gltf(filepath=str(dst/filename),export_format='GLB',export_yup=True,export_animations=False,export_materials='EXPORT',export_cameras=False,export_lights=False)
 report.append(dict(model=filename,parts=len(meshes),triangles_before=before,triangles_after=after,materials_before=len(j['materials']),materials_after=1,atlas=[width,height],textures_native_pixels=True,ratio=ratio))
 print('OPTIMIZED',report[-1],flush=True)
(dst/'optimization.json').write_text(json.dumps(report,indent=2)+'\n')
