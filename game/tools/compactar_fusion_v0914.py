"""Externaliza texturas idénticas sin cambiar un byte de geometría o animación.
Los cuatro GLTF recibidos quedan intactos en assets/originales como respaldo.
"""
from pathlib import Path
import base64, copy, json, os
from PIL import Image, ImageChops
ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'assets/fusion/mechas_compartidos'
DEST.mkdir(parents=True,exist_ok=True)
report=[]
for name in ['George','Leela','Mike','Stan']:
    src=ROOT/f'assets/originales/{name}.gltf'
    original=json.loads(src.read_text()); data=copy.deepcopy(original)
    buffers=[base64.b64decode(b['uri'].split(',',1)[1]) for b in data['buffers']]
    dropped=set(); ranges={i:[] for i in range(len(buffers))}
    for image in data.get('images',[]):
        index=image.pop('bufferView'); view=data['bufferViews'][index]
        dropped.add(index); image.pop('mimeType',None)
        extracted=ROOT/f'assets/originales/{name}_{name}_Texture.png'
        shared=ROOT/f'assets/characters/robots/{name}/base.png'
        a=Image.open(extracted).convert('RGBA'); b=Image.open(shared).convert('RGBA')
        assert a.size==b.size and a.tobytes()==b.tobytes()
        image['uri']=os.path.relpath(shared,DEST).replace(os.sep,'/')
        start=view.get('byteOffset',0); end=start+view['byteLength']
        end=min(len(buffers[view['buffer']]),(end+3)//4*4)
        ranges[view['buffer']].append((start,end))
    for accessor in data['accessors']: assert accessor.get('bufferView') not in dropped
    new_buffers=[]
    for i,raw in enumerate(buffers):
        chunks=[]; cursor=0
        for start,end in sorted(ranges[i]):chunks.append(raw[cursor:start]);cursor=end
        chunks.append(raw[cursor:]);new_buffers.append(b''.join(chunks))
    kept=[]; mapping={}
    for i,view in enumerate(data['bufferViews']):
        if i in dropped:continue
        start=view.get('byteOffset',0); buffer=view['buffer']; new_start=start-sum(end-begin for begin,end in ranges[buffer] if end<=start)
        assert buffers[buffer][start:start+view['byteLength']]==new_buffers[buffer][new_start:new_start+view['byteLength']]
        view['byteOffset']=new_start; mapping[i]=len(kept);kept.append(view)
    data['bufferViews']=kept
    def remap(node):
        if isinstance(node,dict):
            for key,value in node.items():
                if key=='bufferView':node[key]=mapping[value]
                else:remap(value)
        elif isinstance(node,list):
            for item in node:remap(item)
    remap(data)
    for i,raw in enumerate(new_buffers):
        file=f'{name}_{i}.bin';(DEST/file).write_bytes(raw)
        data['buffers'][i]={'uri':file,'byteLength':len(raw)}
    (DEST/f'{name}.gltf').write_text(json.dumps(data,separators=(',',':')))
    report.append(dict(model=name,geometry_and_animation_identical=True,texture_pixels_identical=True,original_bytes=src.stat().st_size,runtime_bytes=(DEST/f'{name}.gltf').stat().st_size+sum(len(x) for x in new_buffers)))
(DEST/'verificacion.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
