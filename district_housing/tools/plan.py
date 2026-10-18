"""Offline polygon planner. No map meshes or gameplay files are modified."""
import argparse
import hashlib
import json
import math
import random
from pathlib import Path
from shapely.geometry import Polygon, LineString, Point, box
from shapely import make_valid, constrained_delaunay_triangles
from shapely.ops import nearest_points, unary_union

ROOT = Path(__file__).resolve().parents[1]


def sources():
    data = json.loads((ROOT / 'data/district_lots.json').read_text())
    geo = json.loads((ROOT / 'tools/layout_vector.geojson').read_text())
    layers = {}
    features = {}
    for f in geo['features']:
        assert f['geometry']['type'] == 'Polygon'
        rings = [[((x - 625) * .4, (z - 625) * .4) for x, z in ring]
                 for ring in f['geometry']['coordinates']]
        p = Polygon(rings[0], rings[1:])
        if not p.is_valid:
            # Repair derived exclusion masks only; source GeoJSON is kept byte-for-byte.
            p = make_valid(p)
        layers.setdefault(f['properties']['layer'], []).append(p)
        features[f['properties']['label']] = p
    assert len(data['lots']) == 19
    for lot in data['lots']:
        p = Polygon(lot['polygon_xz_m'])
        assert p.is_valid and all(-250 <= v <= 250 for xy in p.exterior.coords for v in xy)
        assert p.hausdorff_distance(features[lot['source_feature']]) < .001
    return data, layers


def plan(profile=None, scope='pilot', seed=923):
    data, layers = sources()
    forbidden = unary_union([p for layer, ps in layers.items()
                             if layer != 'Lots' for p in ps])
    sidewalks = unary_union(layers['Sidewalks'])
    blockers = []
    overrides = []
    if profile:
        for key in ('standing_height', 'crouched_height', 'width', 'player_height', 'player_width'):
            if not isinstance(profile.get(key), (int, float)) or profile[key] <= 0:
                raise ValueError('Missing positive measured dimension: ' + key)
        if profile['crouched_height'] + .3 >= profile['standing_height']:
            raise ValueError('Crouched height plus head margin must be below standing height')
        if not profile.get('measurement_source'):
            raise ValueError('measurement_source must identify the measured collider/rig')
    lots = data['lots'] if scope == 'district' else [l for l in data['lots'] if l['id'] == 'lot_04']
    buildings = []
    rejected = {}
    for lot in lots:
        rng = random.Random(f'{seed}:{lot["id"]}')
        boundary = Polygon(lot['polygon_xz_m'])
        available = boundary.buffer(-data['generation_defaults']['setback_to_lot_boundary_m'])
        occupied = []
        routes = []
        required = lot['access_distribution']['requested_mecha_access']
        if required and not profile:
            blockers.append(f'{lot["id"]}: {required} blocked: real robot measurements absent')
        # One pilot only until tested against the real robot. District is an explicit later step.
        target = lot['plot_subdivision']['target_buildings_max'] if scope == 'district' else 1
        candidates = []
        minx, minz, maxx, maxz = available.bounds
        step = lot['plot_subdivision']['min_plot_width_m']
        # Internal parcels are clipped to the inset polygon, not a replacement grid of lots.
        for ix in range(math.ceil((maxx-minx)/step)):
            for iz in range(math.ceil((maxz-minz)/step)):
                cell = available.intersection(box(minx+ix*step, minz+iz*step,
                                                 minx+(ix+1)*step, minz+(iz+1)*step))
                if cell.area > step*step*.8:
                    candidates.append(cell)
        rng.shuffle(candidates)
        for cell in candidates:
            if len(occupied) >= target:
                break
            is_mecha = bool(required and not occupied)
            if is_mecha and not profile:
                rejected['if is_mecha and not profile:'] = rejected.get('if is_mecha and not profile:', 0) + 1
                continue
            if is_mecha:
                archetype = 'workshop_crouch' if required == 'mecha_crouch' else 'warehouse_standing'
                if archetype not in lot['permitted_archetypes']:
                    overrides.append(f'{lot["id"]}: explicit required mecha access takes precedence; add {archetype} to effective zoning (source preserved)')
                access = required
                door_h = profile['crouched_height' if access == 'mecha_crouch' else 'standing_height'] + .3
                door_w = profile['width'] + .7
            else:
                allowed = [a for a in lot['permitted_archetypes']
                           if a in ('small_residential', 'corner_shop', 'commercial_hall', 'facade_only')]
                archetype = rng.choice(allowed)
                # All production houses are now genuinely enterable, as requested.
                if profile and archetype == 'facade_only':
                    archetype = 'small_residential'
                access = 'inaccessible' if archetype == 'facade_only' else 'player_only'
                # Player entrances also need measured dimensions; no made-up production body sizes.
                if access != 'inaccessible' and not profile:
                    archetype, access = 'facade_only', 'inaccessible'
                door_h = profile['player_height'] + .3 if profile else 0
                door_w = profile['player_width'] + .7 if profile else 0
            width = max(door_w + 3, rng.uniform(7, 10))
            depth = max(door_w + 3, rng.uniform(7, 10))
            height = (door_h + profile['standing_height'])/2 if access == 'mecha_crouch' else max(door_h + .6, 3.4)
            center = cell.centroid
            # Choose a real sidewalk point; entire access corridor must stay in this macro-lot
            # until its final sidewalk connection, with no crossing of roads or parking.
            curb = nearest_points(center, sidewalks)[1]
            dx, dz = curb.x-center.x, curb.y-center.y
            angle = math.atan2(dx, dz)
            u, v = (math.cos(angle), -math.sin(angle)), (math.sin(angle), math.cos(angle))
            def pt(x, z):
                return (center.x + u[0]*x + v[0]*z, center.y + u[1]*x + v[1]*z)
            footprint = Polygon([pt(-width/2,-depth/2), pt(width/2,-depth/2),
                                 pt(width/2,depth/2), pt(-width/2,depth/2)])
            if not available.covers(footprint) or footprint.intersects(forbidden):
                rejected['if not available.covers(footprint) or footprint.intersects(forbidden):'] = rejected.get('if not available.covers(footprint) or footprint.intersects(forbidden):', 0) + 1
                continue
            if any(footprint.distance(p) < 3 for p in occupied):
                rejected['if any(footprint.distance(p) < 3 for p in occupied):'] = rejected.get('if any(footprint.distance(p) < 3 for p in occupied):', 0) + 1
                continue
            entry = pt(0, depth/2)
            ramp = Polygon([pt(-door_w/2,depth/2),pt(door_w/2,depth/2),pt(door_w/2,depth/2+1.2),pt(-door_w/2,depth/2+1.2)]) if access != 'inaccessible' else footprint
            # Tiny outward tolerance joins collinear rotated edges robustly.
            support = footprint.union(ramp.buffer(1e-7,join_style=2))
            if not available.covers(support) or not cell.covers(support) or support.intersects(forbidden):
                continue
            if any(support.distance(p) < 3 for p in occupied):
                continue
            route_width = max(1.8, door_w)
            route = LineString([entry, (curb.x,curb.y)]).buffer(route_width/2, cap_style=2)
            # Allow only the final connector on existing sidewalk; generate no path mesh there.
            # Vector source leaves sub-metre unclassified seams between lot and sidewalk.
            # Permit at most 0.5 m of connector across that seam, never another lot.
            if not boundary.union(sidewalks).buffer(.5).covers(route):
                rejected['if not boundary.union(sidewalks).buffer(.5).covers(route):'] = rejected.get('if not boundary.union(sidewalks).buffer(.5).covers(route):', 0) + 1
                continue
            # No generated geometry is placed on roads. A virtual pedestrian connector
            # may cross at most a 0.5 m vector seam to the adjacent sidewalk, not a street.
            if route.intersects(unary_union(layers['Parking'])) or route.intersection(unary_union(layers['Roads'])).area > route_width*.5:
                rejected["if route.intersects(unary_union(layers['Roads'] + layers['Parking'])):"] = rejected.get("if route.intersects(unary_union(layers['Roads'] + layers['Parking'])):", 0) + 1
                continue
            if any(route.intersects(p) for p in layers['Lots'] if p.hausdorff_distance(boundary) > .001):
                rejected["if any(route.intersects(p) for p in layers['Lots'] if p.hausdorff_distance(boundary) > .001):"] = rejected.get("if any(route.intersects(p) for p in layers['Lots'] if p.hausdorff_distance(boundary) > .001):", 0) + 1
                continue
            if any(route.intersects(p) for p in occupied):
                rejected['if any(route.intersects(p) for p in occupied):'] = rejected.get('if any(route.intersects(p) for p in occupied):', 0) + 1
                continue
            if any(support.intersects(r) for r in routes):
                rejected['if any(footprint.intersects(r) for r in routes):'] = rejected.get('if any(footprint.intersects(r) for r in routes):', 0) + 1
                continue
            occupied.append(support)
            routes.append(route)
            buildings.append(dict(lot=lot['id'], id=f'Building_{len(occupied):02}',
                archetype=archetype, access=access, center=[center.x,center.y],
                rotation=angle, width=width, depth=depth, height=height,
                door_width=door_w, door_height=door_h,
                footprint=list(footprint.exterior.coords)[:-1],
                support_footprint=list(support.exterior.coords)[:-1],
                road_seam_area_m2=route.intersection(unary_union(layers['Roads'])).area,
                parcel=list(cell.exterior.coords)[:-1],
                entry=list(entry), sidewalk=[curb.x,curb.y], route_width=route_width,
                style=architecture_style(seed,lot['id'],len(occupied),archetype),
                path_triangles=path_triangles(route,boundary,forbidden)))
        if required and not occupied and profile:
            blockers.append(f'{lot["id"]}: no validated {required} candidate found by heuristic search; no placement forced')
    return dict(seed=seed, scope=scope, profile=profile, buildings=buildings,
                blockers=sorted(set(blockers)), zoning_overrides=sorted(set(overrides)), rejected=rejected, source_sha256=hashlib.sha256(
                    (ROOT/'data/district_lots.json').read_bytes() + (ROOT/'tools/layout_vector.geojson').read_bytes()).hexdigest())


def path_triangles(route,boundary,forbidden):
    # Decorative paving has no extra colliders and never covers a protected map layer.
    path = route.intersection(boundary).difference(forbidden)
    polygons = [path] if path.geom_type == 'Polygon' else [p for p in path.geoms if p.geom_type == 'Polygon']
    return [list(tri.exterior.coords)[:3] for polygon in polygons
            for tri in constrained_delaunay_triangles(polygon).geoms]


def architecture_style(seed, lot_id, index, archetype):
    # Independent stream: visual variation never consumes placement random numbers.
    r = random.Random(f'{seed}:{lot_id}:{index}:architecture-2')
    return dict(palette=r.randrange(8),roof_palette=r.randrange(5),
                roof='gable' if archetype in ('workshop_crouch','warehouse_standing') else r.choice(['gable','hip']),
                roof_rise=round(r.uniform(.85,1.35) if 'workshop' in archetype or 'warehouse' in archetype else r.uniform(1.25,1.95),3),
                porch=r.random()<.62,shutters=r.random()<.78,chimney=r.random()<.66,
                furniture_side=r.randrange(2),sign=r.randrange(4))


def overlay(result):
    data, layers = sources()
    pieces = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="-255 -255 510 510">',
              '<rect x="-255" y="-255" width="510" height="510" fill="#16202a"/>']
    colors = {'Lots':'#2e5545','Roads':'#56616c','Parking':'#8b718c','Sidewalks':'#acb3af'}
    for layer, ps in layers.items():
        for geom in ps:
          for p in ([geom] if geom.geom_type == 'Polygon' else [q for q in geom.geoms if q.geom_type == 'Polygon']):
            pieces.append(f'<path d="M'+ ' L'.join(f'{x},{y}' for x,y in p.exterior.coords)+f' Z" fill="{colors[layer]}"/>')
    for b in result['buildings']:
        points = ' '.join(f'{x},{z}' for x,z in b['footprint'])
        pieces.append(f'<polygon points="{points}" fill="#e2b963" stroke="#fff" stroke-width=".3"><title>{b["lot"]}/{b["id"]} {b["archetype"]} {b["access"]}</title></polygon>')
        pieces.append(f'<path d="M{b["entry"][0]},{b["entry"][1]} L{b["sidewalk"][0]},{b["sidewalk"][1]}" stroke="#fff" fill="none" stroke-width=".6"/>')
    for lot in data['lots']:
        x,z=lot['center_xz_m']
        pieces.append(f'<text x="{x}" y="{z}" fill="white" font-size="4">{lot["id"]}</text>')
    return '\n'.join(pieces+['</svg>'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile', type=Path)
    parser.add_argument('--scope', choices=['pilot','district'], default='pilot')
    parser.add_argument('--seed', type=int, default=923)
    parser.add_argument('--output', type=Path, default=ROOT/'data/generated_plan.json')
    args = parser.parse_args()
    result = plan(json.loads(args.profile.read_text()) if args.profile else None, args.scope, args.seed)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2)+'\n')
    args.output.with_suffix('.svg').write_text(overlay(result))
    print(f'{len(result["buildings"])} buildings; blockers: {result["blockers"]}')
