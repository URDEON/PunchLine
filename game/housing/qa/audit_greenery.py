"""Independent Shapely audit of placements exported by the running Godot game."""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
import shapely
from shapely.geometry import Polygon, LineString
from shapely.ops import unary_union

parser = argparse.ArgumentParser()
parser.add_argument("input", type=Path)
parser.add_argument("--output", type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
data = json.loads(args.input.read_text())
vector = json.loads((root / "housing/data/vector_meshes.json").read_text())
lots, protected = [], []
for feature in vector["features"]:
    # Triangulation is independent of the runtime's offset-polyline and winding tests.
    region = unary_union([Polygon(triangle) for triangle in feature["triangles"]])
    (lots if feature["layer"] == "Lots" else protected).append(region)
green = unary_union(lots).buffer(-0.48)
hard = unary_union(protected).buffer(0.48)
buildings, paths, entries = [], [], []
for b in data["plan"]["buildings"]:
    buildings.append(Polygon(b.get("validated_envelope", b["support_footprint"])).buffer(0.67))
    paths.extend(Polygon(t).buffer(0.57) for t in b.get("path_triangles", []))
    width = b["door_width"]
    if b["access"] == "player_only":
        width = max(width, 3.36824901406764 + (0.20 if b.get("style", {}).get("palette", 0) in (3, 6) else 0.55))
    entries.append(LineString([b["entry"], b["sidewalk"]]).buffer(max(width, b["route_width"]) / 2 + 0.68, cap_style="flat"))
points = np.asarray(data["points"])
x, z = points[:, 0], points[:, 1]
violations = {
    "outside_green_inset": int((~shapely.contains_xy(green, x, z)).sum()),
    "on_roads_sidewalks_parking": int(shapely.contains_xy(hard, x, z).sum()),
    "under_buildings_or_ramps": int(shapely.contains_xy(unary_union(buildings), x, z).sum()),
    "on_paths": int(shapely.contains_xy(unary_union(paths), x, z).sum()),
    "in_widened_door_routes": int(shapely.contains_xy(unary_union(entries), x, z).sum()),
}
report = {
    "seed": data["seed"],
    "instances": len(points),
    "lots_with_grass": sum(bool(shapely.contains_xy(lot, x, z).any()) for lot in lots),
    "violations": violations,
    "input_sha256": hashlib.sha256(args.input.read_bytes()).hexdigest(),
    "passed": not any(violations.values()),
}
print(json.dumps(report, indent=2))
if args.output:
    args.output.write_text(json.dumps(report, indent=2) + "\n")
raise SystemExit(0 if report["passed"] else 1)
