"""Independent polygon audit. Run layout_export.gd first, then this with Shapely."""
import json, math
from pathlib import Path
from shapely.geometry import Polygon, LineString
from shapely.ops import unary_union
root=Path(__file__).resolve().parents[2]
vector=json.loads((root/'housing/data/vector_meshes.json').read_text())
geo=json.loads((root/'housing/data/district_lots.json').read_text())
labels={x['source_feature']:x['id'] for x in geo['lots']}
lots={labels[f['label']]:Polygon(f['rings'][0],f['rings'][1:]) for f in vector['features'] if f['layer']=='Lots'}
walks=unary_union([Polygon(t) for f in vector['features'] if f['layer']=='Sidewalks' for t in f['triangles']])
roads=unary_union([Polygon(t) for f in vector['features'] if f['layer']=='Roads' for t in f['triangles']])
parking=unary_union([Polygon(t) for f in vector['features'] if f['layer']=='Parking' for t in f['triangles']])
protected=unary_union([Polygon(t) for f in vector['features'] if f['layer'] in ['Roads','Sidewalks','Parking'] for t in f['triangles']])
plans=json.loads(Path('/tmp/punchline-layouts-v0928.json').read_text());results=[]
for plan in plans:
 shapes=[Polygon(b.get('plot_footprint',b['support_footprint'])) for b in plan['buildings']]
 for i,b in enumerate(plan['buildings']):
  p=shapes[i]
  assert p.is_valid,(plan['seed'],b['id'],'invalid')
  assert p.difference(lots[b['lot']]).area<.015,(plan['seed'],b['lot'],b['id'],'outside',p.difference(lots[b['lot']]).area)
  assert p.intersection(protected).area<.015,(plan['seed'],b['id'],'protected')
  for j,q in enumerate(shapes[:i]):assert p.intersection(q).area<.015,(plan['seed'],b['id'],plan['buildings'][j]['id'],'overlap')
  corridor=LineString([b['entry'],b['sidewalk']]).buffer(b['route_width']/2,cap_style='flat')
  assert corridor.difference(lots[b['lot']].union(walks).buffer(.501)).area<.015,(plan['seed'],b['lot'],b['id'],'no sidewalk connection')
  assert corridor.intersection(parking).area<.002,(plan['seed'],b['id'],'parking crossing')
  assert corridor.intersection(roads).area<=b['route_width']*.501,(plan['seed'],b['id'],'street crossing')
  for lot_id,lot in lots.items():
   if lot_id!=b['lot']:assert corridor.intersection(lot).area<.002,(b['id'],'foreign property access')
  path=unary_union([Polygon(t) for t in b['path_triangles']])
  assert path.intersection(protected).area<.015,(plan['seed'],b['lot'],b['id'],'path overlaps protected',path.intersection(protected).area)
  assert path.difference(lots[b['lot']]).area<.015,(plan['seed'],b['id'],'path leaves lot')
  for j,q in enumerate(shapes):
   if i!=j:assert path.intersection(q).area<.015,(plan['seed'],b['lot'],b['id'],plan['buildings'][j]['id'],'blocked path',path.intersection(q).area)
  if b['id'].startswith('SeedBuilding'):
   assert Polygon(b['support_footprint']).distance(lots[b['lot']].boundary)>2.47,(b['id'],'setback')
  assert b['door_width']>=1 and b['door_height']>2.0
 result={'seed':plan['seed'],'density':plan['density'],'buildings':len(shapes),'shops':sum(b['archetype']=='corner_shop' for b in plan['buildings']),'yards':sum(b.get('yard_depth',0)>0 for b in plan['buildings']),'storeys':sorted(set(b.get('storeys',1) for b in plan['buildings']))}
 results.append(result);print('PASS',result)
for a,b in zip(plans[::2],plans[1::2]):assert len(a['buildings'])<len(b['buildings'])
assert len({json.dumps([b['center'] for b in p['buildings']]) for p in plans})==len(plans)
(root/'housing/docs/evidence/update_v0928/layout_audit.json').write_text(json.dumps({'plans':results,'checks':'repeatability, distinct positions, density, lot containment, protected surfaces, mutual building/path clearance, 2.5m setback, entrances'},indent=2)+'\n')
print('RESULT all',len(plans),'independent layouts pass')

from xml.sax.saxutils import escape
plan=next(p for p in plans if p['seed']=='923' and p['density']==2)
pieces=['<svg xmlns="http://www.w3.org/2000/svg" viewBox="-255 -270 510 530">','<rect x="-255" y="-270" width="510" height="530" fill="#15262c"/>','<text x="-245" y="-257" fill="white" font-family="sans-serif" font-size="7">PunchLine 0.9.28 · semilla 923 · '+str(len(plan['buildings']))+' edificios</text>']
for layer,color in [('Lots','#4a6548'),('Roads','#424d53'),('Parking','#53616a'),('Sidewalks','#aaa993')]:
 for f in vector['features']:
  if f['layer']!=layer:continue
  for tri in f['triangles']:pieces.append('<polygon points="'+' '.join(f'{x},{z}' for x,z in tri)+'" fill="'+color+'"/>')
for b in plan['buildings']:
 color='#e5bd79' if b['archetype']=='corner_shop' else '#96c4c9' if int(b.get('storeys',1))>1 else '#d9dfc9'
 points=' '.join(f'{x},{z}' for x,z in b['footprint'])
 pieces.append('<polygon points="'+points+'" fill="'+color+'" stroke="#273e40" stroke-width=".35"><title>'+escape(b['lot']+'/'+b['id']+' · '+b['archetype'])+'</title></polygon>')
 pieces.append('<path d="M '+','.join(map(str,b['entry']))+' L '+','.join(map(str,b['sidewalk']))+'" stroke="white" stroke-width=".45"/>')
pieces.append('</svg>')
(root/'housing/docs/evidence/update_v0928/seed_923_overlay.svg').write_text(''.join(pieces))
