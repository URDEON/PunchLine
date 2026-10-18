#!/usr/bin/env python3
"""Crea un ZIP de proyecto con entradas de carpetas compatibles con el importador de Godot."""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import stat
import tempfile
import zipfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    project, output = args.project.resolve(), args.output.resolve()
    if not (project/'project.godot').is_file():
        parser.error('No hay project.godot en la raíz')
    if output.exists():
        parser.error('El ZIP ya existe; usa otra ruta para conservarlo')
    if output.is_relative_to(project):
        parser.error('Guardar el ZIP fuera del proyecto')
    excluded = {'.godot', '.git', '__pycache__'}
    files = sorted(p for p in project.rglob('*') if p.is_file() and not any(part in excluded for part in p.relative_to(project).parts))
    if any(p.is_symlink() for p in files):
        parser.error('No empaquetar enlaces simbólicos')
    directories = set()
    for path in files:
        for parent in path.relative_to(project).parents:
            if parent != Path('.'): directories.add(parent.as_posix()+'/')
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for name in sorted(directories, key=lambda value: (value.count('/'), value)):
            entry = zipfile.ZipInfo(name)
            entry.create_system = 3
            entry.external_attr = ((stat.S_IFDIR | 0o755) << 16) | 0x10
            archive.writestr(entry, b'')
        for path in files:
            entry = zipfile.ZipInfo(path.relative_to(project).as_posix())
            entry.create_system = 3
            entry.external_attr = ((stat.S_IFREG | 0o644) << 16) | 0x20
            entry.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(entry, path.read_bytes(), compresslevel=6)
    with zipfile.ZipFile(output) as archive, tempfile.TemporaryDirectory(prefix='naoya_zip_') as directory:
        if archive.testzip() is not None: raise RuntimeError('CRC incorrecto')
        names = archive.namelist()
        if len(names) != len(set(names)): raise RuntimeError('Entradas duplicadas')
        extracted = Path(directory)
        for entry in archive.infolist():
            relative = PurePosixPath(entry.filename)
            if relative.is_absolute() or '..' in relative.parts: raise RuntimeError('Ruta no segura')
            target = extracted.joinpath(*relative.parts)
            if entry.is_dir():
                if not entry.external_attr & 0x10: raise RuntimeError('Falta atributo de directorio')
                target.mkdir()  # Los padres deben aparecer antes en el ZIP.
            else:
                if not target.parent.is_dir(): raise RuntimeError('Falta entrada previa de carpeta')
                target.write_bytes(archive.read(entry))
        if not (extracted/'project.godot').is_file(): raise RuntimeError('project.godot no está en raíz')
        for original in files:
            if original.read_bytes() != (extracted/original.relative_to(project)).read_bytes():
                raise RuntimeError('Bytes distintos después de extraer')
    report = {'zip':str(output),'bytes':output.stat().st_size,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),
              'files':len(files),'directories':len(directories),'crc':'OK','ordered_extraction':'OK','byte_comparison':'OK'}
    output.with_suffix('.verificacion.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,ensure_ascii=False))


if __name__ == '__main__':
    main()
