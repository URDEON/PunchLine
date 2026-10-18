"""Blender 4.3 eliminó GLTF_EMBEDDED del menú: empaquetar JSON/bin/imágenes estándar."""
import base64,json,mimetypes,tempfile
from pathlib import Path
import bpy
def export_embedded(path,**kwargs):
 with tempfile.TemporaryDirectory() as directory:
  folder=Path(directory); source=folder/'scene.gltf'
  bpy.ops.export_scene.gltf(filepath=str(source),export_format='GLTF_SEPARATE',**kwargs)
  content=json.loads(source.read_text())
  for b in content.get('buffers',[]):
   b['uri']='data:application/octet-stream;base64,'+base64.b64encode((folder/b['uri']).read_bytes()).decode()
  for im in content.get('images',[]):
   if 'uri' not in im or im['uri'].startswith('data:'):continue
   p=folder/im['uri'];mime=im.get('mimeType',mimetypes.guess_type(p)[0] or 'image/png')
   im['uri']='data:'+mime+';base64,'+base64.b64encode(p.read_bytes()).decode()
  Path(path).write_text(json.dumps(content,separators=(',',':')))
