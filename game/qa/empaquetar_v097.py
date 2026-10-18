#!/usr/bin/env python3
"""Empaqueta Naoya 0.9.7 sin cachés, con rutas relativas y directorios explícitos."""
import argparse
import hashlib
from pathlib import Path
import zipfile


def main(default_results='resultados_v097'):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--results', default=default_results)
    args = parser.parse_args()
    root, output = args.project.resolve(), args.output.resolve()
    if output.exists():
        parser.error('El destino ya existe; usar otro nombre para conservarlo')
    if output.is_relative_to(root):
        parser.error('Guardar el ZIP fuera de la carpeta del proyecto')
    ignored = {'.godot', '.git', '.cache', '__pycache__'}
    historical_images = ('qa/modelo_alien/poses_blender/', 'qa/vistas_hud_historial_v092/')
    files = sorted(p for p in root.rglob('*') if p.is_file() and
                   not p.relative_to(root).as_posix().startswith(historical_images) and
                   not any(part in ignored for part in p.relative_to(root).parts) and
                   not any(part.startswith('resultados_') and part != args.results
                           for part in p.relative_to(root).parts))
    directories = set()
    for path in files:
        for parent in path.relative_to(root).parents:
            if str(parent) != '.':
                directories.add(parent.as_posix() + '/')
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, 'x', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name in sorted(directories, key=lambda x: (x.count('/'), x)):
            info = zipfile.ZipInfo(name)
            info.create_system = 0
            info.external_attr = 0x10
            archive.writestr(info, b'')
        for path in files:
            archive.write(path, path.relative_to(root).as_posix())
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
        names = archive.namelist()
        assert 'project.godot' in names
        assert len({name.casefold() for name in names}) == len(names)
        for name in names:
            assert not name.startswith('/') and '\\' not in name
            assert '..' not in Path(name).parts and ':' not in name
    print(output)
    print('Archivos:', len(files), 'Bytes:', output.stat().st_size)
    print('SHA256:', hashlib.sha256(output.read_bytes()).hexdigest())


if __name__ == '__main__':
    main()
