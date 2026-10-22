extends Node3D
## Reuses the saved district verbatim. No fighter host, regeneration or fusion dependency.
const Ground = preload("res://housing/scenes/District500.tscn")
const Buildings = preload("res://housing/scenes/GeneratedHousing.tscn")
const Ambience = preload("res://scripts/district_ambience.gd")
var housing: Node3D
var ambience: Node3D
var spawn := Vector3(-85,0.35,-40)

func _ready() -> void:
	var ground := Ground.instantiate()
	add_child(ground)
	housing = Buildings.instantiate()
	add_child(housing)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	var sky := ProceduralSkyMaterial.new()
	sky.sky_top_color = Color("284756")
	sky.sky_horizon_color = Color("bac9c5")
	sky.ground_horizon_color = Color("bac9c5")
	sky.ground_bottom_color = Color("45534c")
	environment.sky.sky_material = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b4ccd0")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-32,0)
	sun.light_color = Color("ffe2b9")
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 100
	add_child(sun)
	ambience = Ambience.new()
	add_child(ambience)
	var plan: Dictionary = housing.load_plan("res://housing/data/generated_plan.json")
	ambience.setup(plan,{"seed":"923"},WarfareSettings.values)
	ambience.configure_environment(environment,false)
	WarfareSettings.changed.connect(_apply_settings)

func _apply_settings() -> void:
	ambience.apply_settings(WarfareSettings.values)
