"""Empaqueta dos ZIP complementarios, sin archivos binarios troceados ni BAT.

Extraer Proyecto y Recursos_Fusion en la misma carpeta nueva.
Los originales sin referencias runtime quedan en Fuentes_respaldo.
"""
import argparse
import json
from pathlib import Path
from empaquetar_v099 import is_source, write_zip


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--output-dir', type=Path, required=True)
    args = parser.parse_args()
    root = args.project.resolve()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    groups = {'Proyecto': [], 'Recursos_Fusion': [], 'Fuentes_respaldo': []}
    for path in sorted(root.rglob('*')):
        if not path.is_file():
            continue
        name = path.relative_to(root).as_posix()
        if any(part in {'.godot', '.git', '.cache', '__pycache__'} or
               (part.startswith('resultados_') and part != 'resultados_v0913')
               for part in path.relative_to(root).parts):
            continue
        if name.startswith(('qa/modelo_alien/poses_blender/', 'qa/vistas_hud_historial_v092/')):
            continue
        # Godot extrae PNG de los GLTF originales. Son dependencias de las escenas importadas.
        if is_source(name) or name.startswith('assets/fusion/Rust_Vanguard_original.glb'):
            group = 'Fuentes_respaldo'
        elif name.startswith(('assets/originales/', 'assets/fusion/')):
            group = 'Recursos_Fusion'
        else:
            group = 'Proyecto'
        groups[group].append((path, name))
    runtime_names = {name for group in ['Proyecto', 'Recursos_Fusion'] for _, name in groups[group]}
    assert 'project.godot' in runtime_names
    assert 'assets/fusion/Rust_Vanguard_piezas.glb' in runtime_names
    for path, name in groups['Proyecto']:
        if name.startswith(('scripts/', 'network/', 'materials/', 'shaders/')) and name.endswith(('.gd', '.tscn', '.tres', '.gltf')):
            content = path.read_text(errors='replace')
            for _, source in groups['Fuentes_respaldo']:
                assert 'res://' + source not in content, (name, source)
    report = {}
    for group, files in groups.items():
        report[group] = write_zip(args.output_dir / f'PunchLine_0.9.13_{group}.zip', files)
        assert report[group]['bytes'] < 100 * 1024 * 1024, 'Supera el límite de subida'
        print(json.dumps(report[group]), flush=True)
    (args.output_dir / 'PunchLine_0.9.13_source_manifest.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
