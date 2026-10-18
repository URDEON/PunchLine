from pathlib import Path
import hashlib
import json
import argparse
from empaquetar_v099 import write_zip

parser = argparse.ArgumentParser(description='Empaquetar una exportacion Windows 0.9.15 ya generada')
parser.add_argument('--build-dir', type=Path, required=True)
parser.add_argument('--output-dir', type=Path, required=True)
args = parser.parse_args()
root = args.build_dir.resolve()
project = Path(__file__).resolve().parent.parent
output = args.output_dir.resolve()
output.mkdir(parents=True, exist_ok=True)
data = (root/'Naoya.pck').read_bytes()
parts = [data[:64*1024*1024], data[64*1024*1024:]]
for i, part in enumerate(parts, 1):
    (root/f'Naoya.pck.00{i}').write_bytes(part)
assert b''.join((root/f'Naoya.pck.00{i}').read_bytes() for i in [1, 2]) == data
intro = '''PUNCHLINE / NAOYA 0.9.15 — WINDOWS

1. Crea una carpeta NUEVA.
2. Extrae Windows_1.zip y Windows_2.zip en ESA MISMA carpeta.
3. Dentro de esa carpeta, clic derecho > Abrir en Terminal / PowerShell.
4. Pega este comando ENTERO y pulsa Enter:

cmd /c copy /b /y Naoya.pck.001+Naoya.pck.002 Naoya.pck

5. Espera a que termine. Debe indicar que se copio un archivo.
6. Abre Naoya.exe. Desde ahora basta con abrir ese EXE.

Se usa cmd /c porque copy /b directamente no sirve en PowerShell.
No hay que ejecutar ningun archivo BAT. No necesitas instalar Godot.
Los dos ZIP contienen el juego completo, no solo una demo de fusion.
Conserva las partes hasta comprobar que el juego abre.
La aplicacion no tiene firma comercial. Si Windows bloquea el EXE,
puedes utilizar el proyecto editable con tu instalacion habitual de Godot.

PROBAR RAPIDO
Menu > Fusion G / Demostracion. G repite; Espacio pausa; Esc vuelve.
Juego completo: Jugar > Individual > P > Robot > G en suelo firme.
El fusionado tiene M1 de suelo, guardia, canon y cuatro habilidades. Q: propulsion diagonal.
Esc > Combate > Reiniciar fusion permite volver a la forma base.

'''
(root/'LEEME.txt').write_text(intro + (project/'LEEME.txt').read_text())
for name in ['ACTUALIZACION_0.9.15.md', 'RESULTADOS_0.9.15.md', 'PENDIENTES_ACTUALES.md']:
    (root/name).write_bytes((project/name).read_bytes())
manifest = dict(version='0.9.15', pack_bytes=len(data),
                pack_sha256=hashlib.sha256(data).hexdigest(),
                exe_sha256=hashlib.sha256((root/'Naoya.exe').read_bytes()).hexdigest(),
                parts=[dict(name=f'Naoya.pck.00{i}', bytes=len(part), sha256=hashlib.sha256(part).hexdigest())
                       for i, part in enumerate(parts, 1)])
(root/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
archives = []
for i in [1, 2]:
    files = [(root/f'Naoya.pck.00{i}', f'Naoya.pck.00{i}')]
    if i == 1:
        files += [(root/name, name) for name in ['Naoya.exe', 'LEEME.txt', 'ACTUALIZACION_0.9.15.md',
                  'RESULTADOS_0.9.15.md', 'PENDIENTES_ACTUALES.md', 'manifest.json']]
        files += [(p, 'licenses/'+p.relative_to(project/'licenses').as_posix())
                  for p in (project/'licenses').rglob('*') if p.is_file()]
    result = write_zip(output/f'PunchLine_0.9.15_Windows_{i}.zip', files)
    assert result['bytes'] < 100*1024*1024
    archives.append(result)
    print(json.dumps(result), flush=True)
manifest['archives'] = archives
(output/'PunchLine_0.9.15_Windows_manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
