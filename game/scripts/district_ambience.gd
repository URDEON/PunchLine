extends Node3D
## Seeded scenery. Visual quality never changes tree/park furniture collision.
var placement=preload("res://scripts/district_greenery.gd").new()
var grass:Array[MultiMeshInstance3D]=[]
var mist:Array[FogVolume]=[]
var grass_material:ShaderMaterial
var mist_material:ShaderMaterial
var environment:Environment
var night:=false
var settings:Dictionary={}
var trees:Node3D
var decorations:Node3D
var clouds:MeshInstance3D
var world_seed:="923"
var generation_worker:Thread
var ready_ms:=0

func setup(plan:Dictionary,world_settings:Dictionary,preferences:Dictionary)->void:
	name="DistrictAmbience";physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_to_group("district_ambience")
	var started:=Time.get_ticks_msec()
	world_seed=String(world_settings.seed);placement.prepare(plan,world_seed)
	grass_material=ShaderMaterial.new();grass_material.shader=preload("res://shaders/district_grass.gdshader")
	mist_material=ShaderMaterial.new();mist_material.shader=preload("res://shaders/district_mist.gdshader")
	trees=preload("res://scripts/district_trees.gd").new();add_child(trees);trees.setup(placement,String(world_settings.seed))
	build_decor();build_clouds();build_mist()
	apply_settings(preferences);ready_ms=Time.get_ticks_msec()-started
	set_meta("grass_instances",placement.count);set_meta("generation_ms",ready_ms)
func setup_staged(plan:Dictionary,world_settings:Dictionary,preferences:Dictionary,loading:CanvasLayer)->void:
	name="DistrictAmbience";physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;add_to_group("district_ambience")
	world_seed=String(world_settings.seed);placement.prepare(plan,world_seed)
	grass_material=ShaderMaterial.new();grass_material.shader=preload("res://shaders/district_grass.gdshader")
	mist_material=ShaderMaterial.new();mist_material.shader=preload("res://shaders/district_mist.gdshader")
	trees=preload("res://scripts/district_trees.gd").new();add_child(trees);trees.setup(placement,String(world_settings.seed))
	loading.report(.68,"Plantando árboles y decorando las zonas verdes")
	await get_tree().process_frame
	build_decor();build_clouds();build_mist()
	if int(preferences.get("grass_quality",2))>0:
		loading.report(.72,"Calculando praderas de hierba alta")
		await get_tree().process_frame
		generation_worker=Thread.new();var worker:Thread=generation_worker;worker.start(placement.generate)
		while worker.is_alive():await get_tree().process_frame
		worker.wait_to_finish()
		var mesh:ArrayMesh=tuft_mesh();var cells:Array=placement.chunks.keys()
		for i in range(cells.size()):
			build_grass_chunk(cells[i],mesh)
			if i%8==7:
				loading.report(.76+.13*float(i+1)/cells.size(),"Creando hierba · %d / %d sectores"%[i+1,cells.size()])
				await get_tree().process_frame
	apply_settings(preferences);set_meta("grass_instances",placement.count)

func build_decor()->void:
	decorations=preload("res://scripts/district_decor.gd").new();add_child(decorations);decorations.setup(placement,trees,world_seed)
func build_clouds()->void:
	clouds=MeshInstance3D.new();clouds.name="MovingCloudLayer"
	var plane:=PlaneMesh.new();plane.size=Vector2(1400,1400);clouds.mesh=plane;clouds.position.y=150
	clouds.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat:=ShaderMaterial.new();mat.shader=preload("res://shaders/district_clouds.gdshader");clouds.material_override=mat;add_child(clouds)
func build_grass()->void:
	placement.generate();var mesh:ArrayMesh=tuft_mesh()
	for cell in placement.chunks:build_grass_chunk(cell,mesh)
func build_grass_chunk(cell:Vector2i,mesh:ArrayMesh)->void:
	var points:PackedVector2Array=placement.chunks[cell]
	var rng:=RandomNumberGenerator.new();rng.seed=placement.seed_value+int(cell.x)*73856093+int(cell.y)*19349663
	# A stable shuffle makes every quality prefix spatially uniform.
	for i in range(points.size()-1,0,-1):
		var j:int=rng.randi_range(0,i);var swap:Vector2=points[i];points[i]=points[j];points[j]=swap
	placement.chunks[cell]=points
	var batch:=MultiMeshInstance3D.new();batch.name="Grass_%d_%d"%[cell.x,cell.y]
	batch.position=Vector3(cell.x*placement.CHUNK,.032,cell.y*placement.CHUNK)
	batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var instances:=MultiMesh.new();instances.transform_format=MultiMesh.TRANSFORM_3D;instances.use_colors=true
	instances.mesh=mesh;instances.instance_count=points.size();batch.multimesh=instances;batch.material_override=grass_material
	for i in range(points.size()):
		var patch:float=.83+.15*sin(points[i].x*.14)*sin(points[i].y*.17)
		var scale_value:float=rng.randf_range(.72,1.18)*patch
		var basis:=Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_value)
		instances.set_instance_transform(i,Transform3D(basis,Vector3(points[i].x,0,points[i].y)-Vector3(batch.position.x,0,batch.position.z)))
		instances.set_instance_color(i,Color(rng.randf_range(.78,1.06),rng.randf_range(.87,1.06),rng.randf_range(.78,1.0)))
	instances.custom_aabb=AABB(Vector3(-.5,-.05,-.5),Vector3(placement.CHUNK+1,1.65,placement.CHUNK+1))
	add_child(batch);grass.append(batch)

func tuft_mesh()->ArrayMesh:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(13):
		var angle:float=i*2.39996
		var right:=Vector3(cos(angle),0,sin(angle));var front:=Vector3(-sin(angle),0,cos(angle))
		var root:Vector3=front*(.025+float(i%5)*.032)
		var height:float=.52+float(i%6)*.105;var width:float=.014+float(i%3)*.004
		var middle:Vector3=root+Vector3.UP*height*.55+front*.02
		var tip:Vector3=root+Vector3.UP*height+front*.075
		var positions:Array=[root-right*width,root+right*width,middle+right*width*.65,root-right*width,middle+right*width*.65,middle-right*width*.65,middle-right*width*.65,middle+right*width*.65,tip]
		var uv:Array=[Vector2(0,0),Vector2(1,0),Vector2(1,.55),Vector2(0,0),Vector2(1,.55),Vector2(0,.55),Vector2(0,.55),Vector2(1,.55),Vector2(.5,1)]
		for j in range(positions.size()):
			st.set_normal((Vector3.UP*.6+front*.4).normalized());st.set_uv(uv[j]);st.add_vertex(positions[j])
	return st.commit()
func build_mist()->void:
	if RenderingServer.get_current_rendering_method()!="forward_plus":return
	var rng:=RandomNumberGenerator.new();rng.seed=placement.seed_value+117
	for lot in placement.lots:
		var placed:=0
		for attempt in range(40):
			var point:Vector2=lot.bounds.position+Vector2(rng.randf(),rng.randf())*lot.bounds.size
			if not placement.safe_in_lot(point,lot,7.5) or placement.blocked(point,7.5):continue
			var bank:=FogVolume.new();bank.name="MistBank";bank.size=Vector3(14,2,14);bank.material=mist_material
			bank.position=Vector3(point.x,.85,point.y)
			add_child(bank);mist.append(bank);placed+=1
			if placed>=2:break
func configure_environment(value:Environment,is_night:bool)->void:
	environment=value;night=is_night
	if is_instance_valid(clouds):clouds.material_override.set_shader_parameter("night",night)
	environment.tonemap_mode=Environment.TONE_MAPPER_ACES;environment.tonemap_exposure=1.05
	environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("7187ad") if night else Color("a6b7c7")
	environment.ambient_light_energy=.12 if night else .52
	var sun:DirectionalLight3D=get_parent().game.get_node_or_null("ArenaSun")
	if is_instance_valid(sun):
		sun.light_energy=.16 if night else 1.65;sun.light_color=Color("b3c6ec") if night else Color("fff3df")
		sun.rotation_degrees=Vector3(-38,-30,0) if night else Vector3(-46,-32,0)
		sun.directional_shadow_max_distance=160;sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	if night:
		var sky:=Sky.new();var panorama:=PanoramaSkyMaterial.new();panorama.panorama=preload("res://assets/environment/v098/sky/skybox-night.png");sky.sky_material=panorama;environment.sky=sky
	else:
		var sky:=Sky.new();var physical:=PhysicalSkyMaterial.new();physical.rayleigh_coefficient=2.2;physical.mie_coefficient=.004
		physical.ground_color=Color("556044");physical.energy_multiplier=.85;sky.sky_material=physical;environment.sky=sky
	apply_settings(settings)
func apply_settings(values:Dictionary)->void:
	settings=values.duplicate()
	if is_instance_valid(trees):trees.apply_settings(values)
	var quality:int=clampi(int(values.get("grass_quality",2)),0,3)
	if quality>0 and grass.is_empty():build_grass()
	var distance:float=[0.0,36.0,58.0,78.0][quality]
	for batch in grass:
		batch.visible=quality>0
		batch.multimesh.visible_instance_count=floori(batch.multimesh.instance_count*[0.0,.35,.68,1.0][quality])
		batch.visibility_range_end=maxf(1,distance+12)
	grass_material.set_shader_parameter("fade_start",maxf(1,distance-14))
	grass_material.set_shader_parameter("fade_end",maxf(2,distance))
	grass_material.set_shader_parameter("wind_strength",float(values.get("grass_wind",.55)))
	var amount:float=clampf(float(values.get("fog_amount",.35)),0,1)
	var enabled:bool=amount>.001 and bool(values.get("fog_enabled",true))
	var native_volume:bool=RenderingServer.get_current_rendering_method()=="forward_plus"
	for bank in mist:bank.visible=enabled
	var color:Color=Color("28374c") if night else Color("b3c4c7")
	mist_material.set_shader_parameter("amount",amount)
	mist_material.set_shader_parameter("mist_color",color)
	if environment==null:return
	var preset:int=clampi(int(values.get("graphics_preset",1)),0,2)
	environment.ssao_enabled=preset>0 and native_volume;environment.ssao_radius=1.1;environment.ssao_intensity=1.25;environment.ssao_light_affect=.25
	environment.ssil_enabled=preset==2 and native_volume;environment.ssil_radius=3.0;environment.ssil_intensity=.65
	environment.glow_enabled=preset>0;environment.glow_intensity=.38;environment.glow_bloom=.05
	RenderingServer.directional_shadow_atlas_set_size([1024,2048,4096][preset],true)
	RenderingServer.environment_set_volumetric_fog_volume_size([32,48,64][preset],64)
	environment.fog_enabled=enabled
	environment.fog_density=amount*(.002 if native_volume else .008)
	environment.fog_light_color=color;environment.fog_light_energy=.55 if night else .85
	environment.fog_sky_affect=.22;environment.fog_height=.7;environment.fog_height_density=.08
	environment.fog_sun_scatter=.18
	# Forward+ integrates these volumes with scene lighting and opaque depth.
	environment.volumetric_fog_enabled=enabled and native_volume
	if native_volume:
		environment.volumetric_fog_density=amount*.012
		environment.volumetric_fog_albedo=color;environment.volumetric_fog_length=180
		environment.volumetric_fog_gi_inject=0;environment.volumetric_fog_ambient_inject=.65

func _exit_tree()->void:
	if generation_worker!=null and generation_worker.is_started():generation_worker.wait_to_finish()
