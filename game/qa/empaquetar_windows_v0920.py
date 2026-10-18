"""Empaqueta el ejecutable 0.9.20 con nombres inequívocos y PCK verificable."""
from pathlib import Path
import argparse,hashlib,json
from empaquetar_v099 import write_zip
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--build-dir',type=Path,required=True);p.add_argument('--output-dir',type=Path,required=True);a=p.parse_args()
r=a.build_dir.resolve();out=a.output_dir.resolve();out.mkdir(parents=True,exist_ok=True);project=Path(__file__).resolve().parent.parent
name='PunchLine_0.9.20';data=(r/(name+'.pck')).read_bytes();exe=r/(name+'.exe');assert exe.read_bytes()[:2]==b'MZ'
parts=[data[:64*1024*1024],data[64*1024*1024:]];assert all(parts)
manifest={'version':'0.9.20','pack_bytes':len(data),'pack_sha256':hashlib.sha256(data).hexdigest(),'exe_sha256':hashlib.sha256(exe.read_bytes()).hexdigest(),'parts':[]}
for index,part in enumerate(parts,1):
 filename=name+f'.pck.00{index}';(r/filename).write_bytes(part);manifest['parts'].append({'name':filename,'bytes':len(part),'sha256':hashlib.sha256(part).hexdigest()})
assert b''.join((r/item['name']).read_bytes() for item in manifest['parts'])==data
for doc in ['LEEME.txt','ACTUALIZACION_0.9.20.md','RESULTADOS_0.9.20.md','PENDIENTES_ACTUALES.md']:(r/doc).write_bytes((project/doc).read_bytes())
(r/'LEEME.txt').write_text((r/'LEEME.txt').read_text()+f'\nPCK completo: {len(data)} bytes. SHA-256: {manifest["pack_sha256"]}\n')
(r/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
archives=[]
for index in [1,2]:
 files=[(r/(name+f'.pck.00{index}'),name+f'.pck.00{index}')]
 if index==1:
  files += [(r/file,file) for file in [name+'.exe','LEEME.txt','ACTUALIZACION_0.9.20.md','RESULTADOS_0.9.20.md','PENDIENTES_ACTUALES.md','manifest.json']]
  files += [(f,'licenses/'+f.relative_to(project/'licenses').as_posix()) for f in sorted((project/'licenses').rglob('*')) if f.is_file()]
 result=write_zip(out/f'PunchLine_0.9.20_Windows_{index}.zip',files);assert result['bytes']<104857600
 archives.append(result);print(json.dumps(result),flush=True)
manifest['archives']=archives;(out/'PunchLine_0.9.20_Windows_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
