extends Node3D
## PunchLine · Habilidad G · Fusión de cuatro mechas.
## Hecho para Godot 4.4+ sin plugins ni animación manual.
## PULSA G para reproducir, ESPACIO para pausar.
## La fusión definitiva mide 2 veces un personaje normal.

signal fusion_finished(fused_character: Node3D)

@export var normal_character_height_m: float = 2.0
@export var fused_height_multiplier: float = 2.0
@export_range(0.1, 3.0, 0.05) var playback_speed: float = 1.0
@export var autoplay: bool = true
@export var standalone: bool = true
@export var automatic_process: bool = true
@export var active_chassis: String = "George"
@export var incoming_lift: float = 0.0
var _thruster_voice: AudioStreamPlayer3D
var model_bounds := AABB()
var original_names: Array[String] = []
var leading_materials: Array[Material] = []
var _jets: Array[Node3D] = []
var assembly_order: Array[String] = []
var _piece_rest_transform: Dictionary = {}
var assembly_revision := 0
signal module_landed(module_name: String, position: Vector3)
signal phase_changed(phase: String)
var _last_phase := ""
var _landed: Dictionary = {}
var articulation: Node3D
var dust: Node3D
var _impact_dust := false
var engine_voice: AudioStreamPlayer3D

const GLB_HEIGHT_M: float = 0.8496092558
const DURATION: float = 11.5
const PIECES_PATH: String = "res://assets/fusion/optimized/Junkyard_Sentinel.glb"
const ORIGINAL_PATHS: Array[String] = [
    "res://assets/fusion/mechas_compartidos/George.gltf",
    "res://assets/fusion/mechas_compartidos/Leela.gltf",
    "res://assets/fusion/mechas_compartidos/Mike.gltf",
    "res://assets/fusion/mechas_compartidos/Stan.gltf",
]
const ORIGINAL_HEIGHTS: Array[float] = [6.528, 5.276, 5.335, 6.462]
const DROP_ORDER: Array[String] = [
    "Pie_Der", "Pie_Izq",
    "Pantorrilla_Der", "Pantorrilla_Izq",
    "Rodilla_Der", "Rodilla_Izq",
    "Muslo_Der", "Muslo_Izq",
    "Pelvis", "Torso_Abdomen", "Torso_Pecho",
    "Hombro_Der", "Hombro_Izq",
    "BrazoSuperior_Der", "BrazoSuperior_Izq",
    "Antebrazo_Der", "Antebrazo_Izq",
    "Mano_Der", "Mano_Izq",
    "Cabeza", "Antena_Der", "Antena_Izq"
]

var _originals: Array[Node3D] = []
var _base_scales: Array[float] = []
var _fusion_root: Node3D
var _pieces: Dictionary = {}
var _piece_rest: Dictionary = {}
var _piece_offset: Dictionary = {}
var _piece_spin: Dictionary = {}
var _energy_core: MeshInstance3D
var _energy_light: OmniLight3D
var _sparks: Array[MeshInstance3D] = []
var _rings: Array[MeshInstance3D] = []
var _clock: float = 0.0
var _is_playing: bool = false
var _done_notified: bool = false
var _title: Label
var _stage_label: Label
var _instructions: Label
var _camera: Camera3D

func _ready() -> void:
    if standalone:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        _create_stage()
    _load_models()
    _create_vfx()
    _thruster_voice = AudioStreamPlayer3D.new(); add_child(_thruster_voice)
    var thruster: AudioStreamOggVorbis = preload("res://assets/audio/thrusterFire_000.ogg").duplicate(); thruster.loop = true
    _thruster_voice.stream = thruster; _thruster_voice.volume_db = -16; _thruster_voice.max_distance = 50; _thruster_voice.unit_size = 8
    _thruster_voice.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
    engine_voice = AudioStreamPlayer3D.new(); add_child(engine_voice)
    var engine: AudioStreamOggVorbis = preload("res://assets/audio/mecha_v0914/core_loop.ogg").duplicate(); engine.loop = true
    engine_voice.stream = engine; engine_voice.volume_db = -27; engine_voice.max_distance = 24; engine_voice.unit_size = 3; engine_voice.position.y = 2.6
    engine_voice.bus = _thruster_voice.bus
    if standalone: _create_hud()
    if autoplay:
        play_fusion()
    else:
        _update_sequence(DURATION)

func _input(event: InputEvent) -> void:
    if not standalone: return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_G:
            play_fusion()
        elif event.keycode == KEY_ESCAPE and ResourceLoader.exists("res://launcher.tscn"):
            _return_to_menu()
        elif event.keycode == KEY_SPACE:
            _is_playing = not _is_playing
            if _thruster_voice != null: _thruster_voice.stream_paused = not _is_playing

## Integración Codex: llama play_fusion() al activar la habilidad G.
## Antes de usarlo en un combate real, coloca este nodo en la posición del jugador.
func play_fusion() -> void:
    if is_instance_valid(articulation):
        articulation.detach(); articulation.queue_free(); articulation = null
    if is_instance_valid(dust): dust.clear()
    _impact_dust = false
    if engine_voice != null: engine_voice.stop()
    _landed.clear(); _last_phase = ""; assembly_revision += 1
    _clock = 0.0
    _done_notified = false
    _is_playing = true
    if _thruster_voice != null: _thruster_voice.stream_paused = false
    _update_sequence(0.0)

func _process(delta: float) -> void:
    if not automatic_process: return
    advance(delta)
    if standalone and _done_notified and articulation != null: articulation.locomotion(delta,0,true,0,0)

func advance(delta: float) -> void:
    if not _is_playing: return
    _clock = minf(_clock + delta * playback_speed, DURATION)
    _update_sequence(_clock)
    if _clock >= DURATION and not _done_notified:
        _is_playing = false
        _done_notified = true
        set_engine_active(true)
        fusion_finished.emit(_fusion_root)

func _return_to_menu() -> void:
    stop(); Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    get_tree().change_scene_to_file.call_deferred("res://launcher.tscn")

func _clamp01(x: float) -> float:
    return clampf(x, 0.0, 1.0)

func _smooth(x: float) -> float:
    var v: float = _clamp01(x)
    return v * v * (3.0 - 2.0 * v)

func _bounce_down(p: float) -> float:
    # Llegada rápida, pequeño rebote al encajar.
    var v: float = _clamp01(p)
    if v < 0.82:
        return 1.03 * (1.0 - pow(1.0 - v / 0.82, 3.0))
    return 1.03 - 0.03 * _smooth((v - 0.82) / 0.18)

func _update_sequence(t: float) -> void:
    _animate_originals(t)
    _animate_parts(t)
    _animate_energy(t)
    _animate_rings(t)
    _animate_jets(t)
    if standalone: _animate_camera(t)
    _update_hud(t)

func _animate_originals(t: float) -> void:
    var starts: Array[Vector3] = [
        Vector3(0.0, 0.0, 0.0),
        Vector3(-10.0, 3.5, -5.0),
        Vector3(10.0, 4.0, -5.0),
        Vector3(1.0, 3.0, 11.0),
    ]
    for i in range(1,starts.size()): starts[i].y += incoming_lift
    for i in range(_originals.size()):
        var robot: Node3D = _originals[i]
        var arrival_delay: float = 0.15 if i == 0 else 0.55 + float(i - 1) * 0.20
        var takeoff: float = _smooth((t - arrival_delay) / (1.9 if i == 0 else 1.65))
        var p: Vector3 = starts[i].lerp(Vector3(0.0, 5.6, 0.0), takeoff)
        p.y += sin(takeoff * PI) * (0.7 + float(i) * 0.13)
        if i > 0 and incoming_lift > 0:
            p.y = lerpf(starts[i].y,5.6,_smooth((takeoff-.55)/.45)) + sin(takeoff*PI)*.4
        var shrink: float = 1.0
        if t > 2.6:
            var merge: float = _smooth((t - 2.6) / 1.15)
            var a: float = float(i) * TAU / 4.0 + t * 3.2
            var radius: float = 2.0 * (1.0 - merge)
            p = Vector3(cos(a) * radius, 5.7 + sin(t * 6.0 + float(i)) * 0.30, sin(a) * radius)
            shrink = lerpf(1.0, 0.02, merge)
        robot.position = p
        var flight: Vector3 = Vector3(0,5.6,0)-starts[i]
        var heading: float = PI if i == 0 else atan2(flight.x,flight.z)
        robot.rotation = Vector3(-sin(takeoff*PI)*.26, heading + (t-2.6)*2.0 if t > 2.6 else heading + sin(t*2+i)*.06, sin(takeoff*PI)*(.25 if i%2 else -.25))
        robot.scale = Vector3.ONE * _base_scales[i] * shrink
        robot.visible = t < 3.69 and (i == 0 or t >= arrival_delay - 0.14)
        for player in robot.find_children("*","AnimationPlayer",true,false):
            player.active = robot.visible
            var clip_key: String = ""
            for key in player.get_animation_list():
                if String(key).get_file().to_lower() == "jump": clip_key = key; break
            if not clip_key.is_empty():
                if player.current_animation != clip_key: player.play(clip_key)
                player.seek(player.get_animation(clip_key).length*(.28+.045*sin(t*3+i)),true)
                player.speed_scale = 0

func _animate_parts(t: float) -> void:
    var final_scale: float = normal_character_height_m * fused_height_multiplier / maxf(model_bounds.size.y,.001)
    _fusion_root.scale = Vector3.ONE * final_scale
    _fusion_root.visible = t >= 4.0
    _fusion_root.position.y = -model_bounds.position.y*final_scale
    _fusion_root.rotation.y = PI
    if is_instance_valid(articulation):
        if t >= 8.7: articulation.activation(t-8.7)
        return
    for i in range(assembly_order.size()):
        var name: String = assembly_order[i]
        if not _pieces.has(name):
            continue
        var part: MeshInstance3D = _pieces[name]
        var arrive_start: float = 4.00 + float(i) * (3.675/maxf(1,assembly_order.size()-1))
        var progress: float = (t - arrive_start) / 0.9
        part.visible = t >= arrive_start
        if not part.visible:
            continue
        var interp: float = _bounce_down(progress)
        var rest: Vector3 = _piece_rest[name]
        var scatter: Vector3 = _piece_offset[name]
        part.position = rest + scatter * (1.0 - interp) / final_scale
        # Las piezas rotan durante la caída; su orientación final es idéntica al modelo original.
        var spin: Vector3 = _piece_spin[name]
        var rest_transform: Transform3D = _piece_rest_transform[name]
        part.basis = Basis.from_euler(spin * (1.0 - _smooth(progress))) * rest_transform.basis
        if progress >= 1.0 and not _landed.has(name):
            _landed[name] = true
            module_landed.emit(name, part.global_position)
            if dust != null:
                dust.puff(part.global_position,.24,Color(.68,.63,.53),false)
                if name.begins_with("Pie_"):
                    var floor_point := part.global_position; floor_point.y = global_position.y+.04
                    dust.puff(floor_point,.6)
    if t >= 8.7:
        articulation = preload("res://scripts/sentinel_articulation.gd").new()
        _fusion_root.add_child(articulation); articulation.setup(_pieces)
        articulation.activation(t-8.7)

func _animate_energy(t: float) -> void:
    var active: bool = t >= 2.30 and t <= 4.35
    _energy_core.visible = active
    _energy_light.visible = active
    var timepulse: float = absf(sin(t * 17.0))
    if active:
        var burst: float = 1.0
        if t >= 3.5:
            burst = 1.0 + 4.0 * sin(PI * _clamp01((t - 3.5) / 0.85))
        _energy_core.position = Vector3(0.0, 5.65, 0.0)
        _energy_core.scale = Vector3.ONE * (0.18 + 0.20 * timepulse) * burst
        _energy_light.position = _energy_core.position
        _energy_light.light_energy = (1.6 + 2.8 * timepulse) * burst
    for i in range(_sparks.size()):
        var vfx: MeshInstance3D = _sparks[i]
        vfx.visible = active
        if active:
            var angle: float = float(i) * TAU / float(_sparks.size()) + t * (1.8 + float(i % 3) * 0.3)
            var r: float = 1.3 + 0.55 * sin(t * 3.0 + i)
            vfx.position = Vector3(cos(angle) * r, 5.6 + sin(t * 4.4 + i * 1.6) * 0.85, sin(angle) * r)
            vfx.scale = Vector3.ONE * (0.55 + 0.45 * absf(sin(t * 8.0 + i)))

func _animate_rings(t: float) -> void:
    if t >= 10.65 and not _impact_dust:
        _impact_dust = true
        dust.clear() # Prioridad al impacto final, incluso al avanzar la demo por pasos.
        dust.crown(global_position,1.45)
        for i in range(5):
            var angle := float(i)*TAU/5
            dust.puff(global_position+Vector3(cos(angle)*.45,.06,sin(angle)*.45),1.25)

func _animate_camera(t: float) -> void:
    var shake: float = 0.0
    if t > 8.85 and t < 9.55:
        shake = (1.0 - _smooth((t - 8.85) / .70)) * .10
    var arc: float = 0.09 * sin(t * .35)
    _camera.position = Vector3(-6.1 + arc, 5.0 + sin(t * 37.0) * shake, -12.5 + cos(t * 31.0) * shake)
    _camera.look_at(Vector3(0.0, 2.60, 0.0), Vector3.UP)

func _update_hud(t: float) -> void:
    if _stage_label == null:
        return
    if t < 2.6:
        _stage_label.text = "01 / 04 · ASCENSO DE LOS CUATRO MECHAS"
    elif t < 4.0:
        _stage_label.text = "02 / 04 · CONVERGENCIA Y NÚCLEO DE FUSIÓN"
    elif t < 8.85:
        _stage_label.text = "03 / 04 · CAÍDA Y ENSAMBLAJE DE JUNKYARD"
    else:
        _stage_label.text = "04 / 04 · JUNKYARD SENTINEL · FORMA FINAL 2×"
    _instructions.text = "ESC MENÚ PRINCIPAL      G REPETIR      ESPACIO PAUSA      TIEMPO  %.1f / %.1f s" % [t, DURATION]

func _load_models() -> void:
    original_names.assign(["George","Leela","Mike","Stan"])
    if active_chassis not in original_names: active_chassis = "George"
    original_names.erase(active_chassis); original_names.push_front(active_chassis)
    for i in range(original_names.size()):
        var model_path: String = "res://assets/fusion/mechas_compartidos/"+original_names[i]+".gltf"
        var packed: PackedScene = load(model_path) as PackedScene
        if packed == null:
            push_error("No se pudo cargar el mecha: " + model_path)
            continue
        var robot: Node3D = packed.instantiate() as Node3D
        if robot == null:
            push_error("La escena del robot no tiene raíz Node3D")
            continue
        robot.name = original_names[i]
        add_child(robot)
        _originals.append(robot)
        var bounds: AABB = bounds_of(robot)
        _base_scales.append(normal_character_height_m / maxf(bounds.size.y,.001))
        if i == 0 and not leading_materials.is_empty():
            var mesh_index := 0
            for mesh in robot.find_children("*","MeshInstance3D",true,false):
                if mesh_index < leading_materials.size(): mesh.material_override = leading_materials[mesh_index]
                mesh_index += 1
        var jets := preload("res://scripts/mecha_thruster.gd").new(); jets.name = "Propulsores_"+robot.name; jets.seed = float(i)*3.7; add_child(jets); _jets.append(jets)
        for player in robot.find_children("*", "AnimationPlayer", true, false):
            var anim_player: AnimationPlayer = player as AnimationPlayer
            for clip in anim_player.get_animation_list():
                if String(clip).get_file().to_lower() == "idle":
                    anim_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
                    anim_player.play(clip); break
    var final_model: PackedScene = load(PIECES_PATH) as PackedScene
    if final_model == null:
        push_error("Falta Junkyard_Sentinel.glb")
        return
    _fusion_root = Node3D.new()
    _fusion_root.name = "Fusion_Final_2x"
    add_child(_fusion_root)
    var loaded: Node3D = final_model.instantiate() as Node3D
    loaded.name = "Despiece_Rust_Vanguard"
    _fusion_root.add_child(loaded)
    model_bounds = bounds_of(loaded)
    for candidate in loaded.find_children("*", "MeshInstance3D", true, false):
        var part: MeshInstance3D = candidate as MeshInstance3D
        var name: String = part.name
        _pieces[name] = part
        _piece_rest[name] = part.position
        _piece_rest_transform[name] = part.transform
        var idx: int = DROP_ORDER.find(name)
        if idx < 0:
            idx = _pieces.size()-1
        # Valores deterministas para facilitar reproducir la misma animación.
        var a: float = float(idx) * 2.39996
        var radius: float = 1.7 + float(idx % 4) * .38
        _piece_offset[name] = Vector3(cos(a) * radius, 6.8 + float(idx % 5) * .4, sin(a) * radius)
        _piece_spin[name] = Vector3(1.2 + float(idx % 3) * .55, -1.7 + float(idx % 4) * 1.2, 1.3 - float(idx % 5) * .43)
        part.visible = false
    assembly_order.assign(_pieces.keys())
    assembly_order.sort_custom(func(a: String,b: String) -> bool:
        var pa: MeshInstance3D = _pieces[a]; var pb: MeshInstance3D = _pieces[b]
        return pa.get_aabb().get_center().y < pb.get_aabb().get_center().y)
    print("PunchLine · módulos de fusión cargados: ", _pieces.size())

func _make_material(color: Color, emissive: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = 0.35
    m.roughness = 0.38
    if emissive:
        m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = 3.0
    return m

func _create_stage() -> void:
    var env := WorldEnvironment.new()
    var resource := Environment.new()
    resource.background_mode = Environment.BG_COLOR
    resource.background_color = Color(0.014, .020, .034)
    resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    resource.ambient_light_color = Color(.45, .56, .72)
    resource.ambient_light_energy = 0.45
    env.environment = resource
    add_child(env)

    var stage := MeshInstance3D.new()
    stage.name = "Plataforma"
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 5.8
    cylinder.bottom_radius = 5.9
    cylinder.height = 0.28
    stage.mesh = cylinder
    stage.position.y = -0.17
    stage.material_override = _make_material(Color(.075, .093, .112))
    add_child(stage)

    var floor := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(90.0, 90.0)
    floor.mesh = plane
    floor.position.y = -0.32
    floor.material_override = _make_material(Color(.025, .034, .047))
    add_child(floor)


    var sunlight := DirectionalLight3D.new()
    sunlight.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
    sunlight.light_color = Color(.75, .88, 1.0)
    sunlight.light_energy = 1.7
    sunlight.shadow_enabled = true
    add_child(sunlight)

    var backlight := OmniLight3D.new()
    backlight.position = Vector3(-4.0, 5.0, -3.5)
    backlight.omni_range = 20.0
    backlight.light_color = Color(1.0, .40, .14)
    backlight.light_energy = 2.7
    add_child(backlight)

    _camera = Camera3D.new()
    _camera.name = "Camara_Cinematica"
    _camera.current = true
    _camera.fov = 58.0
    add_child(_camera)
    _camera.position = Vector3(6.1, 5.0, 12.5)
    _camera.look_at(Vector3(0, 2.5, 0), Vector3.UP)

func _create_vfx() -> void:
    _energy_core = MeshInstance3D.new()
    _energy_core.name = "Nucleo_De_Fusion"
    var sphere := SphereMesh.new()
    sphere.radius = 0.6
    sphere.height = 1.2
    _energy_core.mesh = sphere
    _energy_core.material_override = _make_material(Color(.46, 1.0, .96), true)
    add_child(_energy_core)
    _energy_light = OmniLight3D.new()
    _energy_light.light_color = Color(.18, 1.0, .89)
    _energy_light.omni_range = 17.0
    add_child(_energy_light)
    var spark_mesh := SphereMesh.new()
    spark_mesh.radius = 0.095
    spark_mesh.height = .19
    for i in range(18):
        var spark := MeshInstance3D.new()
        spark.name = "Particula_Energia_%02d" % i
        spark.mesh = spark_mesh
        spark.material_override = _make_material(Color(1.0, .55, .13) if i % 3 == 0 else Color(.25, 1.0, .91), true)
        add_child(spark)
        _sparks.append(spark)
    dust = preload("res://scripts/mecha_dust.gd").new(); add_child(dust)

func _create_hud() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)
    var screen := Control.new()
    canvas.add_child(screen)
    screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var panel := PanelContainer.new()
    screen.add_child(panel)
    panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    panel.offset_left = 18; panel.offset_right = -18; panel.offset_top = 18
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(.025,.045,.055,.82)
    skin.border_width_left = 3; skin.border_color = Color("b19a66")
    skin.content_margin_left = 14; skin.content_margin_right = 14
    skin.content_margin_top = 10; skin.content_margin_bottom = 10
    panel.add_theme_stylebox_override("panel",skin)
    var vb := VBoxContainer.new()
    panel.add_child(vb)
    _title = Label.new()
    _title.text = "PUNCHLINE  /  FUSIÓN G"
    _title.add_theme_font_size_override("font_size", 24)
    _title.add_theme_color_override("font_color", Color("e7d2a3"))
    _title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vb.add_child(_title)
    _stage_label = Label.new()
    _stage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vb.add_child(_stage_label)
    _instructions = Label.new()
    var exit := Button.new(); exit.text = "VOLVER AL MENÚ · ESC"; screen.add_child(exit)
    exit.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
    exit.offset_left = -210; exit.offset_top = -48; exit.offset_right = -16; exit.offset_bottom = -12
    exit.pressed.connect(_return_to_menu)
    _instructions.add_theme_font_size_override("font_size", 12)
    _instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vb.add_child(_instructions)

func bounds_of(root: Node3D) -> AABB:
    var result := AABB(); var first := true
    for mesh in root.find_children("*","MeshInstance3D",true,false):
        if mesh.mesh == null: continue
        var bounds: AABB = root.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
        result = bounds if first else result.merge(bounds); first = false
    return result

func _animate_jets(t: float) -> void:
    if _thruster_voice != null:
        _thruster_voice.position = Vector3.UP*(2.0+minf(t/2.6,1)*3.6)
        if t >= .15 and t < 3.69:
            if not _thruster_voice.playing: _thruster_voice.play()
            _thruster_voice.volume_db = -15-20*_smooth((t-3.2)/.49)
        else: _thruster_voice.stop()
    for i in range(_jets.size()):
        var jet: Node3D = _jets[i]; var robot: Node3D = _originals[i]
        jet.visible = robot.visible and t >= (.15 if i == 0 else .55+float(i-1)*.2)
        jet.position = robot.position; jet.rotation = robot.rotation
        var pulse := .9+sin(t*42+i)*.08+sin(t*71+i)*.06
        jet.scale = Vector3(1,pulse,1)
        jet.animate(t,(1.15 if t < 2.3 else .8)*(1-_smooth((t-3.2)/.49)) if jet.visible else 0)
    var phase := "ascent" if t < 2.6 else ("merge" if t < 4 else ("assembly" if t < 8.7 else ("activation" if t < 10.65 else "impact")))
    if phase != _last_phase: _last_phase = phase; phase_changed.emit(phase)

func seek(time: float) -> void:
    _clock = clampf(time,0,DURATION); _update_sequence(_clock)

func stop() -> void:
    _is_playing = false
    if _thruster_voice != null: _thruster_voice.stop()
    for jet in _jets: jet.hide()
    if engine_voice != null: engine_voice.stop()

func set_engine_active(value: bool, speed: float = 0.0) -> void:
    if engine_voice == null: return
    if value and not engine_voice.playing: engine_voice.play()
    if not value: engine_voice.stop()
    engine_voice.volume_db = -27+clampf(speed/2.35,0,1)*3
    engine_voice.pitch_scale = .98+clampf(speed/2.35,0,1)*.04
