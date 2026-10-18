"""Exporta con Godot 4.4.1 y una plantilla Windows de esa misma versión."""
import argparse
from pathlib import Path
import subprocess

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot',type=Path,required=True)
    parser.add_argument('--template',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    project=Path(__file__).resolve().parents[1]
    version=subprocess.check_output([str(args.godot.resolve()),'--version'],text=True).strip()
    if not version.startswith('4.4.1.'):
        raise SystemExit('Se requiere Godot 4.4.1 y su plantilla Windows x86_64.')
    presets=project/'export_presets.cfg';original=presets.read_text()
    lines=original.splitlines();section='';preset_name=''
    for i,line in enumerate(lines):
        if line.startswith('['):section=line
        if section=='[preset.0]' and line.startswith('name='):preset_name=line[6:-1]
        if section=='[preset.0.options]' and line.startswith('custom_template/release='):
            lines[i]='custom_template/release="'+args.template.resolve().as_posix()+'"'
    output=args.output.resolve();output.parent.mkdir(parents=True,exist_ok=True)
    try:
        presets.write_text('\n'.join(lines)+'\n')
        return subprocess.call([str(args.godot.resolve()),'--headless','--path',str(project),'--export-release',preset_name,str(output)])
    finally:
        presets.write_text(original)

if __name__=='__main__':raise SystemExit(main())
