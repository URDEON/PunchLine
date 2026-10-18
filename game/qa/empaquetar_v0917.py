"""Entrega completa en un ZIP importable; fuentes originales sin uso van aparte."""
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
    groups = {'Proyecto_Completo': [], 'Fuentes_respaldo': []}
    for path in sorted(root.rglob('*')):
        if not path.is_file(): continue
        name = path.relative_to(root).as_posix()
        if any(part in {'.godot','.git','.cache','__pycache__'} or
               (part.startswith('resultados_') and part != 'resultados_v0917') for part in path.relative_to(root).parts): continue
        if name.startswith(('qa/modelo_alien/poses_blender/','qa/vistas_hud_historial_v092/','qa/inspect_v0916.gd')): continue
        raw_fusion = name.startswith(('assets/originales/','assets/fusion/Rust_Vanguard_original','assets/fusion/Rust_Vanguard_piezas.glb','assets/forms/Image_4.png','assets/fusion/sentinel_v8/'))
        extracted = name.startswith('assets/fusion/Rust_Vanguard_piezas_')
        group = 'Fuentes_respaldo' if is_source(name) or raw_fusion or extracted else 'Proyecto_Completo'
        groups[group].append((path,name))
    runtime_names = {name for _,name in groups['Proyecto_Completo']}
    for name in ['project.godot','FusionDemo.tscn','assets/fusion/optimized/Junkyard_Sentinel.glb','assets/fusion/optimized/Rustwing_56_Original.glb',
                 'assets/fusion/mechas_compartidos/Stan.gltf','assets/fusion/mechas_compartidos/Stan_0.bin']:
        assert name in runtime_names,name
    for path,name in groups['Proyecto_Completo']:
        if name.startswith(('scripts/','network/')) and name.endswith('.gd'):
            content=path.read_text()
            for _,source in groups['Fuentes_respaldo']: assert 'res://'+source not in content,(name,source)
    report={}
    for group,files in groups.items():
        report[group]=write_zip(args.output_dir/f'PunchLine_0.9.17_{group}.zip',files)
        print(json.dumps(report[group]),flush=True)
    (args.output_dir/'PunchLine_0.9.17_source_manifest.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__': main()
