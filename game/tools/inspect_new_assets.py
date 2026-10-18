"""Inspección y conversión local de FBX; originales conservados."""
from pathlib import Path
import bpy, json, sys, struct
from mathutils import Vector

root=Path(sys.argv[sys.argv.index('--')+1])
sources=root/'assets/animation_sources/mixamo'
converted=sources/'converted'; converted.mkdir(exist_ok=True)
report=[]
for path in sorted(sources.glob('*.fbx')):
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    for action in list(bpy.data.actions): bpy.data.actions.remove(action)
    bpy.ops.import_scene.fbx(filepath=str(path),use_anim=True,automatic_bone_orientation=False)
    arms=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
    assert len(arms)==1,path.name
    arm=arms[0]
    actions=list(bpy.data.actions)
    entry={'file':path.name,'armature':arm.name,'bone_count':len(arm.data.bones),'bones':[b.name for b in arm.data.bones],
           'scale':list(arm.scale),'rotation':list(arm.rotation_euler),'fps':bpy.context.scene.render.fps,
           'meshes':[(o.name,len(o.data.vertices)) for o in bpy.context.scene.objects if o.type=='MESH'],
           'actions':[{'name':a.name,'frames':list(a.frame_range),'duration':float(a.frame_range[1]-a.frame_range[0])/bpy.context.scene.render.fps} for a in actions],
           'rest':{b.name:[list(row) for row in b.matrix_local] for b in arm.data.bones}}
    # La malla X Bot es una referencia de esqueleto, no reemplaza a Naoya.
    for o in list(bpy.context.scene.objects):
        if o.type=='MESH': bpy.data.objects.remove(o,do_unlink=True)
    if actions:
        clip_name=path.stem.replace(' ','_')
        actions[0].name=clip_name
        arm.animation_data.action=actions[0]
        bpy.context.scene.frame_start=int(actions[0].frame_range[0])
        bpy.context.scene.frame_end=int(actions[0].frame_range[1])
        bpy.ops.export_scene.gltf(filepath=str(converted/(clip_name+'.glb')),export_format='GLB',
              export_animations=True,export_animation_mode='ACTIONS',export_skins=True,export_def_bones=False,export_materials='NONE')
        entry['converted']=(converted/(clip_name+'.glb')).relative_to(root).as_posix()
    report.append(entry)
(sources/'inspection.json').write_text(json.dumps(report,indent=2))
print('INSPECCION_FBXS',[(x['file'],x['bone_count'],x['actions']) for x in report])

# Extraer imágenes originales del bandido para inspeccionar atlas y regiones.
path=root/'assets/enemies/y2k/original/UrbanShadow_original.glb'
raw=path.read_bytes();size=struct.unpack_from('<I',raw,12)[0];j=json.loads(raw[20:20+size]);start=20+size+8
out=root/'assets/enemies/y2k/textures';out.mkdir(exist_ok=True)
for i,im in enumerate(j.get('images',[])):
    v=j['bufferViews'][im['bufferView']];a=start+v.get('byteOffset',0)
    ext='.png' if im['mimeType']=='image/png' else '.jpg'
    (out/('original_'+str(i)+ext)).write_bytes(raw[a:a+v['byteLength']])
print('ENEMY_MATERIAL',j.get('materials'))
