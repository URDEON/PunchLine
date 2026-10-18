"""Reconstruct the four supplied vector layers, without claiming to restore missing map meshes."""
import json
from pathlib import Path
from shapely import constrained_delaunay_triangles, make_valid
from shapely.geometry import shape, Polygon, Point, mapping
ROOT=Path(__file__).resolve().parents[1]

def export():
    geo=json.loads((ROOT/'tools/layout_vector.geojson').read_text())
    features=[]
    for f in geo['features']:
        original=shape(f['geometry'])
        repaired=not original.is_valid
        geometry=make_valid(original) if repaired else original
        polygons=[geometry] if isinstance(geometry,Polygon) else [g for g in geometry.geoms if isinstance(g,Polygon)]
        tops=[];rings=[]
        def world(coords):return [[round((x-625)*.4,6),round((z-625)*.4,6)] for x,z in coords]
        for p in polygons:
            for tri in constrained_delaunay_triangles(p).geoms:
                tops.append(world(list(tri.exterior.coords)[:3]))
            rings.extend([world(p.exterior.coords),*[world(r.coords) for r in p.interiors]])
        features.append(dict(label=f['properties']['label'],layer=f['properties']['layer'],triangles=tops,rings=rings,repaired_mask=repaired))
    parking=next(f for f in geo['features'] if f['properties']['layer']=='Parking')
    polygon=Polygon([((x-625)*.4,(z-625)*.4) for x,z in parking['geometry']['coordinates'][0]]).buffer(-8)
    x0,z0,x1,z1=polygon.bounds
    points=[]
    for fx,fz in [(.25,.25),(.75,.25),(.25,.75),(.75,.75),(.5,.5),(.5,.25)]:
        p=Point(x0+(x1-x0)*fx,z0+(z1-z0)*fz)
        if polygon.covers(p):points.append([p.x,p.y])
    return dict(origin='Four-layer reconstruction from supplied GeoJSON; original District500.tscn not supplied',features=features,spawns=points,missing_layers=['Curbs','RoadMarkings','ParkingMarkings'])

if __name__=='__main__':
    output=ROOT/'data/vector_meshes.json'
    output.write_text(json.dumps(export(),separators=(',',':'))+'\n')
    print('Wrote',output)
