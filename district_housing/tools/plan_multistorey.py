"""Add six towers in validated free space, preserving every original placement."""
import json
import math
from shapely.geometry import Polygon, Point, LineString
from shapely.ops import nearest_points, unary_union
from plan import ROOT, sources, path_triangles, architecture_style


def create():
    original = json.loads((ROOT / 'data/generated_plan.json').read_text())
    data, layers = sources()
    forbidden = unary_union([g for name, gs in layers.items() if name != 'Lots' for g in gs])
    sidewalks = unary_union(layers['Sidewalks'])
    roads = unary_union(layers['Roads'])
    parking = unary_union(layers['Parking'])
    occupied = [Polygon(b['support_footprint']) for b in original['buildings']]
    routes = [LineString([b['entry'], b['sidewalk']]).buffer(b['route_width']/2, cap_style=2)
              for b in original['buildings']]
    result = []
    for lot_id in ['lot_03', 'lot_04', 'lot_07', 'lot_12', 'lot_14', 'lot_16']:
        lot = next(lot for lot in data['lots'] if lot['id'] == lot_id)
        boundary = Polygon(lot['polygon_xz_m'])
        area = boundary.buffer(-2.5)
        minx, minz, maxx, maxz = area.bounds
        chosen = None
        for x in range(math.ceil(minx+8), math.floor(maxx-8), 5):
            for z in range(math.ceil(minz+8), math.floor(maxz-8), 5):
                curb = nearest_points(Point(x, z), sidewalks)[1]
                angle = math.atan2(curb.x-x, curb.y-z)
                def pt(a, b):
                    return [x+math.cos(angle)*a+math.sin(angle)*b,
                            z-math.sin(angle)*a+math.cos(angle)*b]
                footprint = Polygon([pt(-7, -7), pt(7, -7), pt(7, 7), pt(-7, 7)])
                ramp = Polygon([pt(-2.04, 6.995), pt(2.04, 6.995),
                                pt(2.04, 8.205), pt(-2.04, 8.205)])
                support = footprint.union(ramp)
                if not area.covers(support) or support.intersects(forbidden):
                    continue
                if any(support.distance(other) < 3 for other in occupied):
                    continue
                if any(support.intersects(route) for route in routes):
                    continue
                entry = pt(0, 7)
                route = LineString([entry, [curb.x, curb.y]]).buffer(2.04, cap_style=2)
                if not boundary.union(sidewalks).buffer(.5).covers(route):
                    continue
                if route.intersects(parking) or route.intersection(roads).area > 4.08*.5:
                    continue
                if any(route.intersects(other) for other in occupied):
                    continue
                if any(route.intersects(other) for other in layers['Lots']
                       if other.hausdorff_distance(boundary) > .001):
                    continue
                storeys = 3 if len(result) % 2 == 0 else 4
                chosen = dict(lot=lot_id, id=f'Building_Tower_{storeys}',
                              archetype=f'apartment_{storeys}', access='shared_building',
                              storeys=storeys, storey_height=3.6, width=14.0, depth=14.0,
                              height=3.4+(storeys-1)*3.6, door_width=4.08, door_height=3.22,
                              center=[x, z], rotation=angle, entry=entry,
                              sidewalk=[curb.x, curb.y], route_width=4.08,
                              footprint=list(footprint.exterior.coords)[:-1],
                              support_footprint=list(support.exterior.coords)[:-1],
                              style=architecture_style(923, lot_id, 100+len(result), 'apartment'),
                              path_triangles=path_triangles(route, boundary, forbidden))
                occupied.append(support)
                routes.append(route)
                break
            if chosen:
                break
        if chosen is None:
            raise RuntimeError('No safe tower placement in '+lot_id)
        result.append(chosen)
    return dict(seed=923, revision='multistorey-1', source_sha256=original['source_sha256'],
                buildings=result)


if __name__ == '__main__':
    value = create()
    path = ROOT / 'data/multistorey_plan.json'
    path.write_text(json.dumps(value, indent=2)+'\n')
    print(f'{len(value["buildings"])} validated additional towers; original 71 unchanged')
