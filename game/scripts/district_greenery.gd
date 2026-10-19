extends RefCounted
## Decorative placements use the vector lots; protected surfaces and access routes are masks.
const CELL:=.70
const CHUNK:=16.0
const CLEARANCE:=.50
var lots:Array=[]
var masks:Dictionary={}
var chunks:Dictionary={}
var seed_value:=0
var count:=0

func polygon(points:Array)->PackedVector2Array:
	var result:=PackedVector2Array()
	for p in points:result.append(Vector2(p[0],p[1]))
	return result
func bounds(rings:Array)->Rect2:
	var box:=Rect2(rings[0][0],Vector2.ZERO)
	for ring in rings:
		for point in ring:box=box.expand(point)
	return box
func key(point:Vector2)->Vector2i:return Vector2i(floori(point.x/CHUNK),floori(point.y/CHUNK))
func contains(point:Vector2,rings:Array)->bool:
	var inside:=false
	for ring in rings:
		if Geometry2D.is_point_in_polygon(point,ring):inside=not inside
	return inside
func near_edge(point:Vector2,rings:Array,margin:float)->bool:
	for ring in rings:
		for i in range(ring.size()):
			if point.distance_squared_to(Geometry2D.get_closest_point_to_segment(point,ring[i],ring[(i+1)%ring.size()]))<margin*margin:return true
	return false
func borders(rings:Array,margin:float)->Array:
	var regions:Array=[]
	for source in rings:
		var ring:PackedVector2Array=source.duplicate()
		if ring[0]==ring[-1]:ring.remove_at(ring.size()-1)
		# Miter joins conservatively cover corner clearance; coarse rounded offsets
		# can cut inside the requested distance at the small scale of a grass tuft.
		regions.append(Geometry2D.offset_polyline(ring,margin,Geometry2D.JOIN_MITER,Geometry2D.END_JOINED))
	return regions
func in_border(point:Vector2,regions:Array)->bool:
	for region in regions:
		if contains(point,region):return true
	return false
func add_mask(rings:Array,margin:float)->void:
	var box:Rect2=bounds(rings).grow(margin)
	var mask:Dictionary={"rings":rings,"bounds":box,"margin":margin,"borders":borders(rings,margin)}
	var lo:Vector2i=key(box.position);var hi:Vector2i=key(box.end)
	for x in range(lo.x,hi.x+1):
		for z in range(lo.y,hi.y+1):
			var cell:=Vector2i(x,z)
			if not masks.has(cell):masks[cell]=[]
			masks[cell].append(mask)
func blocked(point:Vector2,extra:=0.0)->bool:
	# Wider queries are used only for the few mist banks, never for every grass blade.
	var candidates:Array=[]
	if extra>0:
		var lo:Vector2i=key(point-Vector2.ONE*extra);var hi:Vector2i=key(point+Vector2.ONE*extra)
		for x in range(lo.x,hi.x+1):
			for z in range(lo.y,hi.y+1):candidates.append_array(masks.get(Vector2i(x,z),[]))
	else:candidates=masks.get(key(point),[])
	for mask in candidates:
		if not mask.bounds.grow(extra).has_point(point):continue
		if contains(point,mask.rings):return true
		if in_border(point,mask.borders) if extra==0 else near_edge(point,mask.rings,mask.margin+extra):return true
	return false
func safe_in_lot(point:Vector2,lot:Dictionary,margin:=CLEARANCE)->bool:
	return contains(point,lot.rings) and not (in_border(point,lot.borders) if margin==CLEARANCE else near_edge(point,lot.rings,margin))
func prepare(plan:Dictionary,seed_text:String)->void:
	lots.clear();masks.clear();chunks.clear();count=0
	seed_value=seed_text.sha256_text().substr(0,15).hex_to_int()
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/vector_meshes.json"))
	for feature in data.features:
		var rings:Array=[]
		for ring in feature.rings:rings.append(polygon(ring))
		if feature.layer=="Lots":lots.append({"label":feature.label,"rings":rings,"bounds":bounds(rings),"borders":borders(rings,CLEARANCE)})
		elif feature.layer in ["Roads","Parking","Sidewalks"]:add_mask(rings,CLEARANCE)
	var generator=preload("res://housing/scripts/DistrictHousingGenerator.gd").new()
	for b in plan.get("buildings",[]):
		add_mask([polygon(b.get("plot_footprint",b.get("validated_envelope",b.support_footprint)))],.70)
		for tri in b.get("path_triangles",[]):add_mask([polygon(tri)],.60)
		# Old narrow paths must still leave the widened mecha door and porch clear.
		var a:=Vector2(b.entry[0],b.entry[1]);var end:=Vector2(b.sidewalk[0],b.sidewalk[1])
		var side:Vector2=(end-a).normalized().orthogonal()*(maxf(float(b.route_width),generator.access_profile(b).width)/2+.55)
		add_mask([PackedVector2Array([a+side,a-side,end-side,end+side])],.15)
	generator.free()
func generate()->void:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	for lot in lots:
		var box:Rect2=lot.bounds
		for x in range(floori(box.position.x/CELL),ceili(box.end.x/CELL)):
			for z in range(floori(box.position.y/CELL),ceili(box.end.y/CELL)):
				var point:=Vector2((x+rng.randf_range(.18,.82))*CELL,(z+rng.randf_range(.18,.82))*CELL)
				if not safe_in_lot(point,lot) or blocked(point):continue
				var cell:Vector2i=key(point)
				if not chunks.has(cell):chunks[cell]=PackedVector2Array()
				chunks[cell].append(point);count+=1
