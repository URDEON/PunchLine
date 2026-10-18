"""Optimiza una copia del GLB conservando UV y materiales originales."""
import argparse
import json
from pathlib import Path
import sys

import bpy


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--model', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--triangles', default=12000, type=int)
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
    args.output.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(args.model))
    report = {'source': str(args.model), 'target_triangles': args.triangles, 'meshes': []}
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    for obj in meshes:
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        before_vertices = len(obj.data.vertices)
        obj.data.calc_loop_triangles()
        before_triangles = len(obj.data.loop_triangles)
        # La importación duplica vértices en costuras UV; soldar posiciones sin
        # borrar las UV por esquina permite una reducción más uniforme.
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.mesh.remove_doubles(threshold=0.000001)
        bpy.ops.object.mode_set(mode='OBJECT')
        modifier = obj.modifiers.new('Optimizar_para_tiempo_real', 'DECIMATE')
        modifier.decimate_type = 'COLLAPSE'
        modifier.ratio = min(1.0, args.triangles / before_triangles)
        modifier.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        obj.data.calc_loop_triangles()
        report['meshes'].append({'vertices_before': before_vertices, 'triangles_before': before_triangles, 'vertices_after_blender': len(obj.data.vertices), 'triangles_after': len(obj.data.loop_triangles), 'uv_layers': len(obj.data.uv_layers), 'materials': len(obj.data.materials)})
    bpy.ops.export_scene.gltf(filepath=str(args.output/'modelo_optimizado_sin_rig.glb'), export_format='GLB', export_animations=False, export_image_format='AUTO', export_materials='EXPORT')
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output/'modelo_optimizado.blend'))
    (args.output/'optimizacion.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')
    print(json.dumps(report, ensure_ascii=False))


if __name__ == '__main__':
    main()
