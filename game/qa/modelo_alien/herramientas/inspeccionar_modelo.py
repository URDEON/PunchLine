"""Inspección y renders del GLB real; ejecutar mediante Blender --background."""
import argparse
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector


def arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('--model', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--rig', type=Path)
    return parser.parse_args(sys.argv[sys.argv.index('--') + 1:])


def bounds(objects):
    points = [obj.matrix_world @ Vector(v) for obj in objects for v in obj.bound_box]
    return Vector(tuple(min(p[i] for p in points) for i in range(3))), Vector(tuple(max(p[i] for p in points) for i in range(3)))


def camera_at(scene, position, target, scale):
    camera_data = bpy.data.cameras.new('Camera')
    camera = bpy.data.objects.new('Camera', camera_data)
    scene.collection.objects.link(camera)
    camera.location = position
    camera.rotation_euler = (Vector(target) - camera.location).to_track_quat('-Z', 'Y').to_euler()
    camera_data.type = 'ORTHO'
    camera_data.ortho_scale = scale
    camera_data.lens = 50
    scene.camera = camera
    return camera


def area_light(name, position, energy, size, target):
    data = bpy.data.lights.new(name, 'AREA')
    data.energy = energy
    data.shape = 'DISK'
    data.size = size
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = position
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat('-Z', 'Y').to_euler()


def main():
    args = arguments()
    args.output.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(args.model))
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    low, high = bounds(meshes)
    report = {'source': str(args.model), 'bounds_blender': [list(low), list(high)], 'meshes': [], 'images': []}
    for obj in meshes:
        obj.data.calc_loop_triangles()
        report['meshes'].append({'name': obj.name, 'vertices': len(obj.data.vertices), 'polygons': len(obj.data.polygons), 'triangles': len(obj.data.loop_triangles), 'materials': [s.material.name for s in obj.material_slots], 'vertex_groups': len(obj.vertex_groups)})
    for image in bpy.data.images:
        report['images'].append({'name': image.name, 'size': list(image.size), 'channels': image.channels, 'packed': image.packed_file is not None})
    if args.rig:
        previous = set(bpy.context.scene.objects)
        bpy.ops.import_scene.gltf(filepath=str(args.rig))
        rig_objects = set(bpy.context.scene.objects) - previous
        report['rigs'] = []
        for obj in rig_objects:
            if obj.type == 'ARMATURE':
                report['rigs'].append({'name': obj.name, 'matrix': [list(row) for row in obj.matrix_world], 'bones': [{'name': b.name, 'parent': b.parent.name if b.parent else None, 'head': list(obj.matrix_world @ b.head_local), 'tail': list(obj.matrix_world @ b.tail_local)} for b in obj.data.bones], 'actions': [a.name for a in bpy.data.actions]})
            obj.hide_render = True
    (args.output/'inspeccion.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 16
    scene.cycles.use_denoising = False
    scene.render.threads_mode = 'FIXED'
    scene.render.threads = 4
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.world.use_nodes = True
    scene.world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.24, 0.27, 0.32, 1)
    scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.5
    center = (low + high) * 0.5
    height = high.z - low.z
    area_light('Key', (2, -3, 4), 450, 3, center)
    area_light('Fill', (-3, -1, 2), 200, 3, center)
    area_light('Rim', (1, 2, 3), 350, 2, center)
    bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, low.z - 0.005))
    plane = bpy.context.object
    material = bpy.data.materials.new('StudioFloor')
    material.diffuse_color = (0.12, 0.14, 0.18, 1)
    plane.data.materials.append(material)
    for name, angle in [('frente', 0), ('tres_cuartos', 35), ('espalda', 180)]:
        radians = math.radians(angle)
        position = center + Vector((math.sin(radians)*4, -math.cos(radians)*4, 0.05))
        camera = camera_at(scene, position, center, height*1.24)
        scene.render.filepath = str(args.output/(name+'.png'))
        bpy.ops.render.render(write_still=True)
        bpy.data.objects.remove(camera, do_unlink=True)


if __name__ == '__main__':
    main()
