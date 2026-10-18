"""Validate additional towers and their relation to every preserved house and route."""
import json
from shapely.geometry import Polygon, LineString
from shapely.ops import unary_union
from plan import ROOT, sources
from plan_multistorey import create

saved = json.loads((ROOT/'data/multistorey_plan.json').read_text())
assert saved == json.loads(json.dumps(create())), 'Additional tower plan is not reproducible'
base = json.loads((ROOT/'data/generated_plan.json').read_text())
data, layers = sources()
lots = {lot['id']: Polygon(lot['polygon_xz_m']) for lot in data['lots']}
forbidden = unary_union([g for name, geoms in layers.items() if name != 'Lots' for g in geoms])
all_buildings = base['buildings'] + saved['buildings']
all_shapes = [Polygon(b['support_footprint']) for b in all_buildings]
for i, b in enumerate(saved['buildings'], len(base['buildings'])):
    footprint = all_shapes[i]
    assert lots[b['lot']].buffer(-2.5).covers(footprint)
    assert not footprint.intersects(forbidden)
    assert b['storeys'] in (3, 4) and b['width'] == 14 and b['depth'] == 14
    assert b['height'] == 3.4+(b['storeys']-1)*3.6
    for j, other in enumerate(all_shapes):
        if i != j:
            assert footprint.distance(other) >= 3-1e-6
    paving = unary_union([Polygon(t) for t in b['path_triangles']])
    assert lots[b['lot']].buffer(1e-7).covers(paving)
    assert paving.intersection(forbidden).area < 1e-6
for i, b in enumerate(all_buildings):
    route = LineString([b['entry'], b['sidewalk']]).buffer(b['route_width']/2, cap_style=2)
    for j, shape in enumerate(all_shapes):
        if i != j:
            assert route.intersection(shape).area < 1e-6, (b['lot'], all_buildings[j]['lot'])
assert sum(b['storeys'] == 3 for b in saved['buildings']) == 3
assert sum(b['storeys'] == 4 for b in saved['buildings']) == 3
print(json.dumps(dict(passed=True, total_buildings=len(all_buildings), preserved_houses=71,
                     three_storeys=3, four_storeys=3, excluded_geometry_violations=0,
                     preserved_route_obstructions=0, setback_m=2.5, separation_m=3), indent=2))
