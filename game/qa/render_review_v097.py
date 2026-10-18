"""Revisa GLB exportados en Blender. Estos PNG NO son capturas de Godot ni gameplay."""
import argparse
from pathlib import Path
import sys
import bpy
from mathutils import Vector

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--folder', type=Path, required=True)
parser.add_argument('--map', action='store_true')
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
folder = args.folder.resolve()
tags = ['district24'] if args.map else ['skin_rest_0','skin_impact_0','skin_0_0','skin_20_0','skin_60_0','skin_179_0']
for tag in tags:
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(folder/(tag+'.glb')))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
    points = [obj.matrix_world@Vector(v) for obj in meshes for v in obj.bound_box]
    low = Vector(tuple(min(p[i] for p in points) for i in range(3)))
    high = Vector(tuple(max(p[i] for p in points) for i in range(3)))
    center = (low+high)*.5
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 8
    scene.cycles.use_denoising = False
    scene.render.threads_mode = 'FIXED'
    scene.render.threads = 2
    scene.render.resolution_x = 960 if args.map else 480
    scene.render.resolution_y = 540 if args.map else 480
    scene.render.resolution_percentage = 100
    scene.world.use_nodes = True
    background = scene.world.node_tree.nodes['Background']
    background.inputs['Color'].default_value = (.14,.16,.21,1)
    background.inputs['Strength'].default_value = .8
    lamp = bpy.data.lights.new('Review light','SUN' if args.map else 'AREA')
    lamp.energy = 2 if args.map else 900
    if not args.map:
        lamp.size = 5
    light = bpy.data.objects.new('Review light',lamp)
    scene.collection.objects.link(light)
    light.location = center+Vector((3,-4,6))
    light.rotation_euler = (.4,-.4,-.6)
    camera = bpy.data.cameras.new('Resource review camera')
    cam = bpy.data.objects.new('Resource review camera',camera)
    scene.collection.objects.link(cam)
    camera.type = 'ORTHO'
    camera.ortho_scale = 138 if args.map else 3.2
    scene.camera = cam
    if args.map:
        center = Vector((0,5,4))
    cam.location = center+(Vector((52,-72,53)) if args.map else Vector((3,-5,2.5)))
    cam.rotation_euler = (center-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath = str(folder/(tag+'_recurso_blender.png'))
    bpy.ops.render.render(write_still=True)
