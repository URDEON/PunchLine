#!/usr/bin/env python3
"""Entrega el proyecto importable y un respaldo separado de fuentes sin uso en runtime."""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

SOURCE_PREFIXES = (
    'assets/enemies/y2k/original/',
    'assets/animation_sources/mixamo/converted/',
    'assets/animation_sources/ual2/UAL2_Standard.glb',
    'assets/forms/evolved.glb',
)

def is_source(path):
    return path.startswith(SOURCE_PREFIXES) or (
        path.startswith('assets/animation_sources/mixamo/') and
        (path.endswith('.fbx') or path.endswith('.fbx.import'))
    ) or (
        path.startswith('assets/characters/robots/') and
        '/color_' in path and (path.endswith('.png') or path.endswith('.png.import'))
    )

def write_zip(output, files):
    directories = set()
    for _, name in files:
        for parent in Path(name).parents:
            if str(parent) != '.': directories.add(parent.as_posix()+'/')
    with zipfile.ZipFile(output,'x',zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
        for directory in sorted(directories):
            info = zipfile.ZipInfo(directory); info.create_system = 0; info.external_attr = 0x10
            archive.writestr(info,b'')
        for path,name in files: archive.write(path,name)
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
        names = archive.namelist()
        assert len(names) == len({name.casefold() for name in names})
        assert all(not name.startswith('/') and '\\' not in name and ':' not in name and '..' not in Path(name).parts for name in names)
    return {'file':output.name,'bytes':output.stat().st_size,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'files':len(files)}

def main(default_results="resultados_v099"):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project',type=Path,default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--sources',type=Path,required=True)
    parser.add_argument('--results',default=default_results)
    args = parser.parse_args()
    root = args.project.resolve()
    for output in [args.output,args.sources]:
        if output.exists() or output.resolve().is_relative_to(root): parser.error('Usar destinos nuevos fuera del proyecto')
        output.parent.mkdir(parents=True,exist_ok=True)
    runtime, sources = [],[]
    for path in sorted(root.rglob('*')):
        if not path.is_file(): continue
        name = path.relative_to(root).as_posix()
        if any(part in {'.godot','.git','.cache','__pycache__'} or (part.startswith('resultados_') and part != args.results) for part in path.relative_to(root).parts): continue
        if name.startswith(('qa/modelo_alien/poses_blender/','qa/vistas_hud_historial_v092/')): continue
        (sources if is_source(name) else runtime).append((path,name))
    assert 'project.godot' in [name for _,name in runtime]
    for _,name in runtime:
        if name.startswith(('scripts/','shaders/','materials/')):
            text = (root/name).read_text(errors='replace')
            assert not any('res://'+source_name in text for _,source_name in sources), name
    report = {'project':write_zip(args.output,runtime),'sources':write_zip(args.sources,sources)}
    args.output.with_suffix('.manifest.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))

if __name__ == '__main__': main()
