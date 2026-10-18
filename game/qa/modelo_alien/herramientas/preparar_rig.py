"""Añade el rig existente del juego a una copia del personaje enviado."""
import argparse
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector, kdtree

sys.path.insert(0, str(Path(__file__).resolve().parent))
from inspeccionar_modelo import bounds, camera_at, area_light


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--model', required=True, type=Path)
    parser.add_argument('--rig', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
    args.output.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(args.model))
    mesh = next(o for o in bpy.context.scene.objects if o.type == 'MESH')
    mesh.name = 'AlienCharacter'
    low, high = bounds([mesh])
    model_scale = 2.57286/(high.z-low.z)
    # El rig RPG mira hacia +Y en Blender (-Z en Godot).
    for vertex in mesh.data.vertices:
        vertex.co = Vector((-vertex.co.x*model_scale, -vertex.co.y*model_scale, (vertex.co.z-low.z)*model_scale))
    mesh.data.update()
    # El GLB separa vértices por UV y normales. Volvemos a soldar posiciones
    # antes de calcular pesos para que las costuras se deformen juntas.
    bpy.context.view_layer.objects.active = mesh
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.remove_doubles(threshold=0.00001)
    bpy.ops.object.mode_set(mode='OBJECT')
    previous = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(args.rig))
    imported = set(bpy.context.scene.objects)-previous
    armature = next(o for o in imported if o.type == 'ARMATURE')
    for obj in list(imported):
        if obj.type == 'MESH':
            bpy.data.objects.remove(obj, do_unlink=True)
    report = {'source': str(args.model), 'rig_source': str(args.rig), 'height': 2.57286, 'bones': len(armature.data.bones), 'retarget_method': 'same animation rig; rest positions fitted to shorter arms and wider legs', 'weights_method': 'Blender bone heat', 'warnings': []}
    armature.animation_data.action = None
    armature.animation_data.use_nla = False
    armature.data.pose_position = 'REST'
    bpy.ops.object.select_all(action='DESELECT')
    armature.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.mode_set(mode='EDIT')
    original = {b.name: (b.matrix.copy(), b.head.copy()) for b in armature.data.edit_bones}
    # Conservamos orientación de cada eje: los clips existentes siguen usando
    # sus rotaciones originales; solo cambian las posiciones de reposo.
    for bone in armature.data.edit_bones:
        matrix, head = original[bone.name]
        if any(token in bone.name for token in ('Clavicle', 'UpperArm', 'Forearm', 'Hand', 'Finger')):
            head.x *= 0.74
        elif any(token in bone.name for token in ('Thigh', 'Calf', 'Foot', 'Toe')):
            head.x *= 1.35
        matrix.translation = head
        bone.use_connect = False
        bone.matrix = matrix
    for bone in armature.data.edit_bones:
        # El importador genera colas muy largas; ajustamos longitud sin cambiar
        # los ejes. Motion conserva su pista para el árbol de animaciones.
        children = list(bone.children)
        if children:
            distance = min((child.head-bone.head).length for child in children)
        else:
            distance = 5.0 if 'Finger' in bone.name else 10.0
        bone.length = max(1.0, distance)
        bone.use_deform = bone.name != 'Motion'
    bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='DESELECT')
    mesh.select_set(True)
    armature.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.parent_set(type='ARMATURE_AUTO', keep_transform=True)
    zero_vertices = []
    for vertex in mesh.data.vertices:
        if sum(g.weight for g in vertex.groups) < 0.0001:
            zero_vertices.append(vertex.index)
    if zero_vertices:
        # Detalles aislados (antenas, cordones y bolsillos) pueden quedar fuera
        # del cálculo de calor. Heredan pesos de la superficie corporal más
        # próxima, conservando su posición; después se revisan en poses reales.
        valid = [v for v in mesh.data.vertices if v.index not in set(zero_vertices)]
        tree = kdtree.KDTree(len(valid))
        for vertex in valid:
            tree.insert(vertex.co, vertex.index)
        tree.balance()
        max_distance = 0.0
        for index in zero_vertices:
            _, nearest, distance = tree.find(mesh.data.vertices[index].co)
            max_distance = max(max_distance, distance)
            for group in mesh.data.vertices[nearest].groups:
                if group.weight > 0:
                    mesh.vertex_groups[group.group].add([index], group.weight, 'REPLACE')
        report['attachment_vertices_assigned'] = len(zero_vertices)
        report['attachment_max_distance'] = max_distance
        report['weights_method'] += '; nearest body weights for detached details'
    bpy.ops.object.select_all(action='DESELECT')
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = mesh
    bpy.ops.object.mode_set(mode='WEIGHT_PAINT')
    bpy.ops.object.vertex_group_limit_total(limit=4)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    bpy.ops.object.mode_set(mode='OBJECT')
    weight_sums = [sum(g.weight for g in v.groups) for v in mesh.data.vertices]
    report['weighted_vertices'] = len(weight_sums)
    report['weight_sum_min'] = min(weight_sums)
    report['weight_sum_max'] = max(weight_sums)
    report['max_influences'] = max(len(v.groups) for v in mesh.data.vertices)
    mesh.data.calc_loop_triangles()
    report['triangles'] = len(mesh.data.loop_triangles)
    report['actions'] = [a.name for a in bpy.data.actions]
    report['nla_tracks'] = [t.name for t in armature.animation_data.nla_tracks]
    armature.data.pose_position = 'POSE'
    for bone in armature.pose.bones:
        bone.matrix_basis.identity()
    # Exportamos los clips NLA del recurso recibido con el proyecto original.
    # No se generan movimientos de combate sintéticos.
    bpy.ops.export_scene.gltf(filepath=str(args.output/'Alien_Naoya_Rig_Combat.glb'), export_format='GLB', export_animations=True, export_animation_mode='NLA_TRACKS', export_skins=True, export_def_bones=False, export_image_format='AUTO', export_materials='EXPORT')
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output/'Alien_Naoya_Rig_Combat.blend'))
    (args.output/'rig_informe.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')

    # Renders de las poses del modelo real, fuera del motor de juego.
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 24
    scene.cycles.use_denoising = False
    scene.render.threads_mode = 'FIXED'
    scene.render.threads = 4
    scene.render.resolution_x = 960
    scene.render.resolution_y = 960
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.world.use_nodes = True
    scene.world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.24,0.27,0.32,1)
    scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.5
    center = Vector((0,0,1.28643))
    area_light('Key',(2,3,4),450,3,center)
    area_light('Fill',(-3,1,2),200,3,center)
    area_light('Rim',(1,-2,3),350,2,center)
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-0.005))
    floor = bpy.context.object
    material = bpy.data.materials.new('StudioFloor')
    material.diffuse_color = (0.12,0.14,0.18,1)
    floor.data.materials.append(material)
    camera_at(scene, (3.0,5.0,1.6), center, 3.2)
    poses = [('reposo',None,0),('guardia','UnarmedBlock_Armature',5),('carrera','UnarmedRunForward_Armature',5),('golpe','UnarmedAttackR1_Armature',8),('patada','UnarmedAttackKickR1_Armature',10)]
    for label, name, frame in poses:
        for bone in armature.pose.bones:
            bone.matrix_basis.identity()
        armature.animation_data.action = bpy.data.actions.get(name) if name else None
        scene.frame_set(frame)
        scene.render.filepath = str(args.output/(label+'.png'))
        bpy.ops.render.render(write_still=True)
    print(json.dumps(report, ensure_ascii=False))


if __name__ == '__main__':
    main()
