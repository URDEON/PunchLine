"""Validate the saved production layout, including actual sloped ramp box extents."""
import json, math
from pathlib import Path
from shapely.geometry import Polygon,LineString
from shapely.ops import unary_union
from plan import ROOT,plan,sources

saved=json.loads((ROOT/'data/generated_plan.json').read_text())
profile=json.loads((ROOT/'data/measured_profile.json').read_text())
a=plan(profile,'district',923);b=plan(profile,'district',923)
assert a==b and json.loads(json.dumps(a['buildings']))==saved['buildings'],'Seed 923 does not reproduce saved geometry'
data,layers=sources();lots={lot['id']:Polygon(lot['polygon_xz_m']) for lot in data['lots']}
forbidden=unary_union([g for key,geoms in layers.items() if key!='Lots' for g in geoms])
supports=[]
for building in saved['buildings']:
 p=Polygon(building['footprint'])
 if building['access']!='inaccessible':
  angle=building['rotation'];cx,cz=building['center'];w=building['door_width'];depth=building['depth']
  half=.6*math.cos(math.atan2(.12,1.2))+.04*math.sin(math.atan2(.12,1.2))
  def pt(x,z):return cx+math.cos(angle)*x+math.sin(angle)*z,cz-math.sin(angle)*x+math.cos(angle)*z
  ramp=Polygon([pt(-w/2,depth/2+.6-half),pt(w/2,depth/2+.6-half),pt(w/2,depth/2+.6+half),pt(-w/2,depth/2+.6+half)])
  p=p.union(ramp)
 assert lots[building['lot']].buffer(-2.5).covers(p),building
 assert not p.intersects(forbidden),building
 supports.append(p)
for i,x in enumerate(saved['buildings']):
 corridor=LineString([x['entry'],x['sidewalk']]).buffer(x['route_width']/2,cap_style=2)
 assert not corridor.intersects(unary_union(layers['Parking']))
 assert corridor.intersection(unary_union(layers['Roads'])).area<=x['route_width']*.5
 for j,y in enumerate(saved['buildings']):
  if i!=j:assert corridor.intersection(supports[j]).area<1e-6,(x,y)
  if i<j:assert supports[i].distance(supports[j])>=3-1e-6,(x,y)
for lot in data['lots']:
 required=lot['access_distribution']['requested_mecha_access']
 if required:assert any(b['lot']==lot['id'] and b['access']==required for b in saved['buildings'])
result={'passed':True,'seed':923,'buildings':len(saved['buildings']),'lots_in_source':len(lots),'populated_lots':len(set(b['lot'] for b in saved['buildings'])),'crouch_workshops':sum(b['access']=='mecha_crouch' for b in saved['buildings']),'standing_warehouses':sum(b['access']=='mecha_standing' for b in saved['buildings']),'excluded_geometry_violations':0,'setback_m':2.5,'clearance_m':3.0,'actual_ramp_box_extents_checked':True,'virtual_road_seam_max_m':.5,'zoning_overrides':saved['zoning_overrides']}
print(json.dumps(result,indent=2))
