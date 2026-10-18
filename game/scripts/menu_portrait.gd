extends SubViewportContainer
## Galería local de reparto y arte de habilidades, con cortes cinematográficos suaves.
const SUBJECTS := [
    ["SENTINEL / ACERO PESADO","res://assets/fusion/optimized/Junkyard_Sentinel.glb","mecha"],
    ["THE PROYECTED / PROYECCIÓN","res://assets/characters/alien/Alien_Naoya_Rig_Combat.glb","naoya"],
    ["STAN / IMPACTO","res://assets/characters/robots/Stan/model.gltf","robot"],
    ["ESTUDIO / CAÑÓN SENTINEL","res://assets/ui/gallery/sentinel_study.png","art"],
    ["LEELA / MOVILIDAD","res://assets/characters/robots/Leela/model.gltf","robot"],
    ["MIKE / DEFENSA","res://assets/characters/robots/Mike/model.gltf","robot"],
    ["ESTUDIO / PROYECCIÓN","res://assets/ui/gallery/naoya_study.png","art"],
    ["GEORGE / ALCANCE","res://assets/characters/robots/George/model.gltf","robot"],
 ["THE PROYECTED / FOTOGRAMAS","res://assets/ui/skill_renders/projection.png","art"],
 ["ESTUDIO / CONTRAATAQUE","res://assets/ui/skill_renders/counter.png","art"],
 ["ESTUDIO / IMPULSO","res://assets/ui/skill_renders/rush.png","art"],
 ["SENTINEL / CAÑÓN","res://assets/ui/skill_renders/cannon.png","art"],
 ["SENTINEL / MARTILLO","res://assets/ui/skill_renders/ground_slam.png","art"],
 ["SENTINEL / PISOTÓN","res://assets/ui/skill_renders/stomp.png","art"],
 ["SENTINEL / ARIETE","res://assets/ui/skill_renders/ram.png","art"],
 ["EVOLUCIÓN / DOMINIO","res://assets/ui/skill_renders/evolved_domain.png","art"],
 ["EVOLUCIÓN / TENTÁCULOS","res://assets/ui/skill_renders/evolved_tendrils.png","art"],
 ["LEELA / TALÓN","res://assets/ui/skill_renders/leela2.png","art"],
 ["STAN / PRENSA","res://assets/ui/skill_renders/stan1.png","art"],
 ["MIKE / BASTIÓN","res://assets/ui/skill_renders/mike1.png","art"],
 ["GEORGE / IMPULSO","res://assets/ui/skill_renders/george2.png","art"],
 ["FOTOGRAMA / MODELO","res://assets/projection/GlassPane.glb","model"],
 ["FORMA 1 / MODELO","res://assets/forms/worm_rig.tscn","model"],
 ["FORMA 2 / MODELO","res://assets/forms/evolved_rig.tscn","model"],["KOGANE / MODELO","res://assets/companions/SkullWispRig.glb","model"]]
var viewport: SubViewport
var pivot: Node3D
var camera: Camera3D
var clock := 0.0
var camera_position := Vector3(0,1.9,6.1)
var articulation: Node3D
var model: Node3D
var caption: Label
var artwork: TextureRect
var index := 0
var shot_time := 0.0
var render_time := 0.0
var transition: Tween
var changing := false
var auto_cycle:=true
var interactive:=false
var dragging:=false
var manual_yaw:=0.0
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE; stretch = true
    viewport = SubViewport.new(); viewport.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF; viewport.size = Vector2i(540,640); viewport.transparent_bg = true; viewport.world_3d = World3D.new(); viewport.handle_input_locally = false; add_child(viewport)
    pivot = Node3D.new(); viewport.add_child(pivot)
    var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-30,-40,0); light.light_color = Color("c6e1df"); light.light_energy = 1.5; viewport.add_child(light)
    var rim := OmniLight3D.new(); rim.position = Vector3(2,3,-2); rim.light_color = Color("eaa568"); rim.light_energy = 2.0; rim.omni_range = 12; viewport.add_child(rim)
    var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_CLEAR_COLOR; env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color("5d767b"); env.environment.ambient_light_energy = .55; viewport.add_child(env)
    camera = Camera3D.new(); camera.current = true; camera.fov = 48; viewport.add_child(camera)
    artwork = TextureRect.new(); add_child(artwork); artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
    caption = Label.new(); add_child(caption); caption.anchor_top = .88; caption.anchor_bottom = .88; caption.anchor_left = .15; caption.anchor_right = .95; caption.add_theme_font_size_override("font_size",15); caption.modulate = Color("b3c8c7"); caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    show_subject(3 if auto_cycle else 0)
func show_subject(value: int) -> void:
    index = posmod(value,SUBJECTS.size()); shot_time = 0;manual_yaw=0
    if is_instance_valid(model): model.free()
    model = null; articulation = null
    var subject: Array = SUBJECTS[index]; caption.text = "%02d / %02d    %s" % [index+1,SUBJECTS.size(),subject[0]]
    artwork.visible = subject[2] == "art"
    if artwork.visible:
        var path: String = subject[1]
        if not ResourceLoader.exists(path): path = "res://assets/ui/skill_renders/naoya_base1.png"
        if not ResourceLoader.exists(path): path = "res://assets/ui/skill_renders/cannon.png"
        artwork.texture = load(path); pivot.hide(); return
    pivot.show(); model = load(subject[1]).instantiate(); pivot.add_child(model)
    var bounds := AABB(); var first := true
    for mesh in model.find_children("*","MeshInstance3D",true,false):
        var box: AABB = mesh.global_transform*mesh.get_aabb(); bounds = box if first else bounds.merge(box); first = false
    model.scale = Vector3.ONE*(3.5/maxf(bounds.size.y,.1)); model.position = -(bounds.position+Vector3(bounds.size.x*.5,0,bounds.size.z*.5))*model.scale.x
    if subject[2] == "mecha":
        var pieces: Dictionary = {}
        for module in model.find_children("*","MeshInstance3D",true,false): pieces[String(module.name)] = module
        articulation = preload("res://scripts/sentinel_articulation.gd").new(); model.add_child(articulation); articulation.setup(pieces); articulation.activation(2.8)
    else:
        for player in model.find_children("*","AnimationPlayer",true,false):
            for clip in player.get_animation_list():
                if "idle" in String(clip).to_lower():
                    player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR; player.play(clip); break
    pivot.rotation.y = PI-.35 if subject[2] == "naoya" else -.35
func next_subject() -> void:
    if changing: return
    changing = true
    var motion: float = float(Engine.get_meta("punchline_ui_motion",1.0))
    transition = create_tween(); transition.tween_property(self,"modulate:a",0,.32*motion+.001)
    transition.tween_callback(func() -> void: show_subject(index+1))
    transition.tween_property(self,"modulate:a",1,.65*motion+.001)
    transition.tween_callback(func() -> void: changing = false)
func _process(delta: float) -> void:
    if viewport == null: return
    if not is_visible_in_tree(): viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED; return
    var motion: float = float(Engine.get_meta("punchline_ui_motion",1.0))
    clock += delta*motion; shot_time += delta*motion; render_time += delta
    if auto_cycle and shot_time > 7 and not changing: next_subject()
    # La galería no necesita renderizar a la frecuencia completa del juego.
    if artwork.visible:viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
    elif render_time >= .05:
        render_time = 0; viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
    if is_instance_valid(articulation): articulation.locomotion(delta*motion,0,true,0,0,true)
    var heading := PI-.35 if SUBJECTS[index][2] == "naoya" else -.35
    pivot.rotation.y = heading+sin(clock*.12)*.10+manual_yaw
    var pointer := (get_local_mouse_position()/size.clamp(Vector2.ONE,Vector2(10000,10000))-Vector2(.5,.5))*motion
    camera.position = camera.position.lerp(camera_position+Vector3(pointer.x*.12,pointer.y*.08,sin(shot_time*.20)*.16),1-exp(-delta*3)); camera.look_at(Vector3(0,1.85,0))

func _gui_input(event:InputEvent)->void:
 if not interactive:return
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_RIGHT:dragging=event.pressed
  if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_UP:camera_position.z=maxf(3,camera_position.z-.3)
  if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_DOWN:camera_position.z=minf(10,camera_position.z+.3)
 if event is InputEventMouseMotion and dragging:manual_yaw+=event.relative.x*.008
