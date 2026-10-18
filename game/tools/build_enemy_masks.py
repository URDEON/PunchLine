"""Máscaras UV semánticas: geometría real, colores de piel y bordes conservadores."""
from pathlib import Path
import json, numpy as np, struct, io, argparse
from PIL import Image, ImageFilter
parser=argparse.ArgumentParser();parser.add_argument('--project',type=Path,required=True);parser.add_argument('--geometry',type=Path,required=True);args=parser.parse_args()
root=args.project; n=1024
data=json.loads(args.geometry.read_text())
verts=np.array(data['vertices']); xyz=np.zeros((n,n,3),dtype=np.float32); covered=np.zeros((n,n),bool)
for t in data['triangles']:
 uv=np.array(t['uv']); uv[:,1]=1-uv[:,1]; p=uv*(n-1)
 lo=np.maximum(0,np.floor(p.min(0)).astype(int)); hi=np.minimum(n-1,np.ceil(p.max(0)).astype(int))
 a,b,c=p; den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
 if abs(den)<1e-8: continue
 xx,yy=np.meshgrid(np.arange(lo[0],hi[0]+1),np.arange(lo[1],hi[1]+1))
 wa=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/den
 wb=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/den; wc=1-wa-wb
 inside=(wa>=0)&(wb>=0)&(wc>=0); v=verts[t['v']]
 xyz[yy[inside],xx[inside]]=wa[inside,None]*v[0]+wb[inside,None]*v[1]+wc[inside,None]*v[2]
 covered[yy[inside],xx[inside]]=True
raw=(root/'assets/enemies/y2k/original/UrbanShadow_original.glb').read_bytes()
length=struct.unpack_from('<I',raw,12)[0];gltf=json.loads(raw[20:20+length]);buffer=raw[28+length:]
view=gltf['bufferViews'][gltf['images'][0]['bufferView']];start=view.get('byteOffset',0)
rgb=np.asarray(Image.open(io.BytesIO(buffer[start:start+view['byteLength']])).resize((n,n))).astype(float)/255
x=np.abs(xyz[:,:,0]); y=xyz[:,:,1]; z=xyz[:,:,2]; ids=np.zeros((n,n),np.uint8)
ids[(z<.27)&covered]=5
ids[(z>=.27)&(z<1.30)&covered]=2
torso=(z>=1.30)&(z<2.12)&covered; ids[torso]=1
hoodie=torso&(((x<.135)&(y>.08))|((z<1.40)&(x<.40))|((z>1.96)&(x<.32)))
ids[hoodie]=4
head=(z>=2.12)&covered; ids[head&(z>2.38)]=3
dark=rgb.max(2)<.22
# Pelo oscuro de sienes/nuca; ojos y cejas frontales se conservan.
ids[head&(z<=2.38)&dark&((y<.025)|(x>.155))]=6
skin_color=(rgb[:,:,0]>.42)&(rgb[:,:,0]>rgb[:,:,1]*1.07)&(rgb[:,:,1]>rgb[:,:,2]*1.10)
skin_area=head|((x>.91)&(z>1.85)&(z<2.08))|((x<.13)&(z>2.00))
ids[covered&skin_color&skin_area]=7
out=root/'assets/enemies/y2k/textures';out.mkdir(exist_ok=True)
channels=[]; coverage={}
for i,name in enumerate(['jacket','pants','hat','hoodie','shoes','hair','skin'],1):
 mask=Image.fromarray(np.uint8(ids==i)*255).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(.4))
 arr=np.asarray(mask);channels.append(arr);coverage[name]=int((arr>128).sum())
Image.fromarray(np.stack(channels[:4],2),'RGBA').save(out/'regions_a.png')
Image.fromarray(np.stack(channels[4:]+[np.full((n,n),255,np.uint8)],2),'RGBA').save(out/'regions_b.png')
Image.fromarray(ids*30).save(args.geometry.parent/'enemy_region_ids.png')
(out/'region_report.json').write_text(json.dumps({'resolution':n,'regions':coverage,'conservative_seams':True,'uncertain_pixels':'original texture retained','selection':'UV triangles + world regions + skin hue; no global tint'},indent=2))
print(coverage)
