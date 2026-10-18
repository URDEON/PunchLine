extends Node3D
## Junkyard Sentinel original + original Meshy Rustwing 56 gun pieces.
## V8: SINGLE Rustwing cannon physically anchored at the original forearm/wrist axis. 
## Rotate the muzzle centerline into the very same direction as elbow-to-wrist.
## Original Junkyard plates, hand and Rustwing pieces animate; no second mock barrel.
## All source geometry and textures are the two genuine user-provided GLBs.
const JUNK = preload("res://assets/fusion/optimized/Junkyard_Sentinel.glb")
const RUST = preload("res://assets/fusion/optimized/Rustwing_56_Original.glb")
const HEIGHT := 4.0
const SHOULDER := Vector3(.215,.755,.020)
const ELBOW := Vector3(.275,.595,.055)
const RUST_ROOT := RUST_REAR # barrel centerline at the gun's proximal socket
# Axis measured through proximal Rustwing coupler (-.12,.16,-.08) and muzzle (.48,.10,.21).
const RUST_MUZZLE := Vector3(.48,.10,.21)
const RUST_REAR := Vector3(-.12,.16,-.08)
const GUN_AXIS := Vector3(.8958,-.0896,.4330) # normalized approximate of measured centerline
# V7: diameter was much larger than the native forearm, appearing as an overlaid weapon.
const GUN_SCALE := .43
# Calibrated from transformed ORIGINAL forearm/hand mesh CENTERS, rather than an
# assumed bone-down axis. Their centerline rises in +Y as it travels toward +Z.
const WRIST_SOCKET := Vector3(-.003,-.009,.037) # elbow-local cuff between palm and forearm
const ARM_AXIS := Vector3(-.021,-.57,.82) # measured Junkyard forearm -> hand
const DURATION := 3.2
const LEFTOVER_GUN_SHOULDER_CUTOFF := -.155

var body:Node3D
var model:Node3D
var shoulder:Node3D
var elbow:Node3D
var mount:Node3D
var gun_source:Node3D
var gun_parts:Array[Dictionary]=[]
var hand_pieces:Array[Dictionary]=[]
var forearm_pieces:Array[Dictionary]=[]
var shoulder_pieces:Array[Dictionary]=[]
var shoulder_cap_pieces:Array[Dictionary]=[]
var shoulder_extra_pieces:Array[Dictionary]=[] # 70 + 72: shoulder details were originally static
var one_dot_cap_hinge:Node3D
var exposed_mechanisms:Array[Dictionary]=[]
var progress:float=0.0
var target:float=0.0
var cycle:float=0.0
var autoplay:=true
var extra_elbow_deg:float=0.0 # demo-only manual fine adjustment
var label_phase:Label
var bar:ProgressBar
var cam:Camera3D
var diagnostic:Dictionary={"body":0,"upper":0,"forearm":0,"fingers":0,"gun":0,"gun_omitted":0, "interior":0,"shoulder_caps":0,"shoulder_extras":0,"exposed":0}
var interior_parts:Array[Dictionary]=[]
var piston_rods:Array[MeshInstance3D]=[]
var sliding_braces:Array[MeshInstance3D]=[]
var rotational_rings:Array[MeshInstance3D]=[]
var energy_material:StandardMaterial3D
var action_core:MeshInstance3D
var base_brace_positions:Array[Vector3]=[]

func _ready() -> void:
    set_process(false); set_process_input(false)

func adopt(existing: Node3D, height_root: Node3D) -> void:
    model = existing; body = height_root
    _assemble_sources(); _build_sparse_coupling(); _pose(0)

func _mat(color:Color,metal:float=.65)->StandardMaterial3D:
    var m=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=.42
    return m

func _lights_and_camera()->void:
    var w:=WorldEnvironment.new()
    w.name="StudioWorld"
    var e:=Environment.new()
    e.background_mode=Environment.BG_COLOR
    e.background_color=Color(.035,.045,.064)
    e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color=Color(.70,.75,.86)
    e.ambient_light_energy=1.1
    w.environment=e
    add_child(w)
    var key:=DirectionalLight3D.new()
    key.light_energy=2.1
    key.rotation_degrees=Vector3(-53,-29,0)
    add_child(key)
    var fill:=OmniLight3D.new()
    fill.position=Vector3(-2,3,-2)
    fill.light_energy=3.0
    fill.light_color=Color(.60,.76,1)
    fill.omni_range=15
    add_child(fill)
    var rim:=OmniLight3D.new()
    rim.position=Vector3(3,4,4)
    rim.light_energy=3.5
    rim.light_color=Color(1,.77,.49)
    rim.omni_range=18
    add_child(rim)
    var stage:=MeshInstance3D.new()
    var cyl:=CylinderMesh.new()
    cyl.height=.09
    cyl.top_radius=3.3
    cyl.bottom_radius=3.3
    stage.mesh=cyl
    stage.material_override=_mat(Color(.145,.18,.22),.5)
    stage.position.y=-.09
    add_child(stage)
    cam=Camera3D.new()
    cam.name="Camera"
    cam.fov=41
    cam.position=Vector3(4.65,3.3,7.4)
    add_child(cam)
    cam.look_at(Vector3(.45,2.3,.70))
    if OS.get_cmdline_user_args().has("--closeup"):
        _camera_closeup()

func _camera_closeup()->void:
    cam.position=Vector3(2.9,3.45,5.0)
    cam.fov=35
    cam.look_at(Vector3(.73,2.85,.72))

func _pivot_for(m:MeshInstance3D,parent:Node3D,tag:String)->Node3D:
    var p:=Node3D.new()
    p.name=tag
    parent.add_child(p)
    p.global_position=m.global_transform * m.get_aabb().get_center()
    m.reparent(p,true)
    return p

func _center_local(m:MeshInstance3D)->Vector3:
    return m.transform * m.get_aabb().get_center()

func _assemble_sources()->void:
    shoulder=Node3D.new()
    shoulder.name="ARM_RIGHT_shoulder_corrected_forward_axis"
    shoulder.position=SHOULDER
    model.add_child(shoulder)
    elbow=Node3D.new()
    elbow.name="ARM_RIGHT_elbow"
    elbow.position=ELBOW-SHOULDER
    shoulder.add_child(elbow)
    # V5: Single-dot white shoulder on the CANNON side (+X), NOT the two-dot shoulder on (-X).
    # The cap is made of two main painted body shells and two small trims, and must move
    # TOGETHER around one real hinge to avoid tearing the white armor into pieces.
    one_dot_cap_hinge=Node3D.new()
    one_dot_cap_hinge.name="ONE_DOT_WHITE_SHOULDER_ACTUAL_HINGE"
    one_dot_cap_hinge.position=Vector3(-.054,.038,-.025)
    shoulder.add_child(one_dot_cap_hinge)
    var meshes=model.find_children("*","MeshInstance3D",true,false)
    for m in meshes:
        diagnostic.body+=1
        var c=_center_local(m)
        var gid=str(m.name)
        # EXPLICIT, visually checked Meshy geometry of the WHITE, SINGLE-DOT shoulder.
        # tripo_part_3 is the two-dot shoulder, which MUST remain untouched.
        if gid in ["tripo_part_10","tripo_part_14","tripo_part_62","tripo_part_83"]:
            var cap=_pivot_for(m,one_dot_cap_hinge,"ONE_DOT_ACTUAL_WHITE_SHOULDER_"+gid)
            shoulder_cap_pieces.append({"node":cap,"rest":cap.transform,"idx":shoulder_cap_pieces.size(),"mesh_id":gid})
            diagnostic.shoulder_caps+=1
        elif gid=="tripo_part_70" or gid=="tripo_part_72":
            # These are neighboring shoulder details of the white ONE-DOT assembly.
            # They were mistakenly left below model/ROOT in V6, so never followed the arm.
            # The two are intentionally separate pivots with tightly limited mechanical motion.
            var extra=_pivot_for(m,shoulder,"ONE_DOT_SHOULDER_ARTICULATED_"+gid)
            shoulder_extra_pieces.append({"node":extra,"rest":extra.transform,"mesh_id":gid})
            diagnostic.shoulder_extras+=1
        elif c.x>.219 and c.y>=.405 and c.y<.535:
            var handp=_pivot_for(m,elbow,"ORIGINAL_HAND_TO_CANNON_ARMOR_"+gid)
            hand_pieces.append({"node":handp,"rest":handp.transform,"idx":hand_pieces.size(),"world_center":c})
            diagnostic.fingers+=1
        elif c.x>.205 and c.y>=.535 and c.y<.685:
            var platep=_pivot_for(m,elbow,"ORIGINAL_FOREARM_FOLDOUT_"+gid)
            forearm_pieces.append({"node":platep,"rest":platep.transform,"idx":forearm_pieces.size(),"world_center":c})
            diagnostic.forearm+=1
        elif c.x>.175 and c.y>=.685 and c.y<=.795:
            var upperp=_pivot_for(m,shoulder,"ORIGINAL_UPPER_ARM_"+gid)
            shoulder_pieces.append({"node":upperp,"rest":upperp.transform})
            diagnostic.upper+=1
    # Place real Rustwing pieces along the mecha forearm. This is not a second robot or a whole gun pop-in.
    mount=Node3D.new()
    mount.name="Rustwing_SINGLE_Cannon_Coaxial_WristMount"
    elbow.add_child(mount)
    # Align the true gun bore axis with the original Junkyard forearm from elbow to wrist.
    var arm_axis:Vector3=ARM_AXIS.normalized()
    var q:=Quaternion(GUN_AXIS.normalized(),arm_axis)
    mount.quaternion=q
    mount.scale=Vector3.ONE*GUN_SCALE
    # The source's proximal barrel axis maps exactly onto the original wrist in elbow-local coordinates.
    # Mount inherits elbow rotation: it must NEVER stay attached to shoulder while the
    # original hand / forearm flexes, or the real Rustwing barrel becomes detached.
    mount.position=WRIST_SOCKET-(Basis(q)*RUST_ROOT)*GUN_SCALE
    gun_source=RUST.instantiate()
    gun_source.name="Original_Rustwing56_Mesh38"
    mount.add_child(gun_source)
    var all_gun_meshes=gun_source.find_children("*","MeshInstance3D",true,false)
    for m in all_gun_meshes:
        var source_center:=_center_local(m)
        # Exclude big complete Rustwing shoulder/upper arm - otherwise two shoulders overlap.
        # All other parts remain ORIGINAL Rustwing Meshy triangles and PBR textures.
        if source_center.x<LEFTOVER_GUN_SHOULDER_CUTOFF:
            diagnostic.gun_omitted+=1
            m.queue_free()
            continue
        var p=_pivot_for(m,mount,"GENUINE_RUSTWING_COMPONENT_"+str(m.name))
        var i=gun_parts.size()
        var stage:int=0
        if source_center.x>.325: stage=3
        elif source_center.x>.17: stage=2
        elif source_center.x>.025: stage=1
        # These are genuine Rustwing arm-cannon shell pieces, not generated pistons.
        # Let prominent white/orange external armor slide outward as the weapon unfolds.
        var shell_exterior:bool=source_center.x>.15 and source_center.z>.185 and source_center.y<.20
        gun_parts.append({"node":p,"rest":p.transform,"i":i,"stage":stage,"source_center":source_center,"shell_exterior":shell_exterior})
        diagnostic.gun+=1

# V6 uses three tiny connector parts ONLY to close the seam behind the real Rustwing.
# No long cylinders, secondary muzzle, hoops, external mock-barrels or parallel rails.
func _build_sparse_coupling()->void:
    var hardware:=_mat(Color(.18,.22,.25),.83)
    var steel:=_mat(Color(.40,.43,.43),.76)
    # Three SHORT mounts only; no rail/barrel/piston duplicated over Rustwing.
    _internal_piece("box","SEAM_REAR_COUPLER",Vector3(.039,-.220,.035),Vector3(.064,.045,.064),hardware)
    for side in [-1,1]:
        _internal_piece("box","SEAM_CLAMP_%d"%side,Vector3(.039+side*.032,-.238,.035),Vector3(.012,.054,.016),steel)

# V6: support pieces are deliberately minimal and cannot form a second cannon.
func _internal_piece(kind:String,name:String,location:Vector3,dimensions:Vector3,material:Material)->MeshInstance3D:
    var item:=MeshInstance3D.new()
    item.name=name
    var geo:=BoxMesh.new()
    geo.size=dimensions
    item.mesh=geo
    item.material_override=material
    item.position=location
    shoulder.add_child(item)
    diagnostic.interior+=1
    interior_parts.append({"node":item,"original":location,"name":name,"fixed":true})
    return item

func _smooth(a:float,b:float,x:float)->float:
    var t=clampf((x-a)/(b-a),0.0,1.0)
    return t*t*(3.0-2.0*t)

func _pose(t:float)->void:
    if shoulder==null:return
    var extend:=_smooth(.015,.24,t)
    var hinge:=_smooth(.18,.59,t)
    var fingers:=_smooth(.32,.76,t)
    var lock:=_smooth(.70,1.0,t)
    var shoulder_unlock:=_smooth(.035,.38,t)
    var shoulder_spread:=_smooth(.22,.70,t)
    # The measured native forearm axis has both -Y and +Z components.
    # At -50 degrees the arm AND the barrel are horizontal and point in +Z,
    # instead of one pointing upward and the other downward.
    shoulder.rotation.x=deg_to_rad(-50.0)*extend
    # Elbow now has a clear 25-degree loading bend, settling to 14 degrees in firing pose.
    # All actual hand/forearm meshes AND imported original Rustwing meshes are children
    # of this SAME elbow, so flexing cannot leave an orphan barrel behind.
    var elbow_load:=_smooth(.11,.53,t)
    var elbow_settle:=_smooth(.70,1.0,t)
    var elbow_degrees:=25.0*elbow_load - 11.0*elbow_settle + extra_elbow_deg*extend
    elbow.rotation.x=deg_to_rad(elbow_degrees)
    # Actual WHITE single-dot shoulder cover (including Tripo Part 14) hinges as a
    # SINGLE BOLTED ASSEMBLY around the round shoulder joint: no loose flying panels.
    one_dot_cap_hinge.position=Vector3(-.054,.038,-.025)
    one_dot_cap_hinge.rotation=Vector3(-.13*shoulder_unlock,0.0,.065*shoulder_unlock)
    for d in shoulder_cap_pieces:
        var cap:Node3D=d.node
        cap.transform=d.rest
    # Previously-static Tripo Part 70 and Part 72 now follow the shoulder axis and
    # articulate on their own small center pivots, with no positional detachment.
    for d in shoulder_extra_pieces:
        var detail:Node3D=d.node
        detail.transform=d.rest
        if d.mesh_id=="tripo_part_70":
            detail.rotation=Vector3(-.10*shoulder_unlock,.18*shoulder_spread,.04*shoulder_unlock)
        else: # tripo_part_72 (back-side bracket)
            detail.rotation=Vector3(-.09*shoulder_unlock,-.09*shoulder_spread,-.045*shoulder_unlock)
    for d in shoulder_pieces:
        var upper:Node3D=d.node
        var base:Transform3D=d.rest
        upper.transform=base
        # Upper arm armor stays bolted to the rotating shoulder; no drifting pieces.
    # Re-use ORIGINAL robot plates, NEVER hide them: roll them outward into a sleeve around cannon.
    for d in forearm_pieces:
        var p:Node3D=d.node
        var rest:Transform3D=d.rest
        var i:int=d.idx
        var signv=1.0 if i%2==0 else -1.0
        p.transform=rest
        p.position=rest.origin+Vector3(signv*.031,-.003,signv*.019)*hinge
        p.rotation=Vector3(signv*.08,-signv*.06,signv*.18)*hinge
    for d in hand_pieces:
        var p:Node3D=d.node
        var rest:Transform3D=d.rest
        var i:int=d.idx
        var ang=float(i)*TAU/maxf(1.0,float(hand_pieces.size()))
        p.transform=rest
        p.position=rest.origin+Vector3(-.005,.090,-.010)*fingers # hand withdraws into own forearm behind the expanding barrel
        p.rotation=Vector3(sin(ang)*.12,cos(ang)*.09,cos(ang)*.20)*fingers
    # The mechanical core physically telescopes INTO the forearm in rest pose.
    # This avoids the old V3 test issue of a second full-length mechanism dangling
    # by the thigh when the normal hand should be visible.
    var inner_deploy:=_smooth(.20,.85,t)
    for d in interior_parts:
        var part:MeshInstance3D=d.node
        var base:Vector3=d.original
        if d.fixed:
            part.position=base
            part.scale=Vector3.ONE
            continue
        var packed:=Vector3(.051+(base.x-.051)*.45,-.185+(base.y+.185)*.32,.045+(base.z-.045)*.45)
        part.position=packed.lerp(base,inner_deploy)
        part.scale=Vector3.ONE.lerp(Vector3.ONE,inner_deploy)
        part.scale=Vector3(lerpf(.55,1.0,inner_deploy),lerpf(.43,1.0,inner_deploy),lerpf(.55,1.0,inner_deploy))
        if d.name.begins_with("VISIBLE_PISTON_ROD"):
            part.position.y-=.009*lock
            part.scale.y+=.06*lock
        if d.name.begins_with("TELESCOPIC_INNER_CORE"):
            part.position.y-=.017*lock
        if d.name.begins_with("ARMOURED_LONGITUDINAL_RAIL"):
            part.position.y-=.01*lock
        if d.name.begins_with("ROTATIONAL_DRIVE_RING"):
            part.rotation.z=PI/2.0
            part.rotation.y=.35*lock
    if energy_material!=null:
        energy_material.emission_energy_multiplier=.48+1.0*lock
    # Rustwing PARTS shift from elbow enclosure to muzzle in four timed waves. No mesh swaps/fading.
    for d in gun_parts:
        var p:Node3D=d.node
        var base:Transform3D=d.rest
        var stage:int=d.stage
        var i:int=d.i
        # Higher-stage components are tucked closer to the inner forearm until their turn.
        var deploy:=_smooth(.27+float(stage)*.11,.69+float(stage)*.075,t)
        var source:Vector3=d.source_center
        var ringang:=float(i)*2.3999632
        # Retraction PACK: every individual component of the imported Rustwing assembly
        # folds around the elbow's internal volume instead of hanging below the hand.
        # Real-size pieces cannot fit perfectly because the GLBs were not designed to nest.
        # Rustwing parts fold behind the wrist mount in the original forearm sleeve.
        # Keep each real mesh as a separate rigid part; the barrel only builds outward.
        var parking:=Vector3(cos(ringang)*.029, -.015+float(i%5)*.010, sin(ringang)*.029)
        p.transform=base
        p.position=parking.lerp(base.origin,deploy)
        # Articulated armor rotates out of the compact elbow shell before it locks.
        var roll:float=(.65 if i%2==0 else -.65)*(1.0-deploy)
        p.rotation=Vector3(roll*.38,roll*.27,roll)
        p.position+=Vector3(0,-.004*lock,0)
        # Visible Rustwing ORIGINAL panel geometry opens OUTWARD, away from barrel core.
        if d.shell_exterior:
            p.position+=Vector3(0.0,.006,.007)*_smooth(.48,.94,t)
            p.rotation.x+=deg_to_rad(4)*_smooth(.48,.94,t)

func _build_interface()->void:
    var canvas:=CanvasLayer.new()
    add_child(canvas)
    var panel:=PanelContainer.new()
    panel.position=Vector2(18,16)
    panel.custom_minimum_size=Vector2(730,100)
    canvas.add_child(panel)
    var v:=VBoxContainer.new()
    panel.add_child(v)
    var title:=Label.new()
    title.text="JUNKYARD + RUSTWING V8 | CAÑÓN COAXIAL AL ANTEBRAZO"
    title.add_theme_font_size_override("font_size",18)
    v.add_child(title)
    label_phase=Label.new()
    v.add_child(label_phase)
    bar=ProgressBar.new()
    bar.show_percentage=false
    bar.custom_minimum_size=Vector2(600,12)
    bar.max_value=100
    v.add_child(bar)
    var help:=Label.new()
    help.name="KeyControls"
    help.text="ESPACIO: transformar / retraer   R: restaurar   Flechas ↑↓: flexión extra codo   1/2/3/4: cámaras   ESC: salir"
    help.add_theme_font_size_override("font_size",17)
    help.position=Vector2(18,682)
    canvas.add_child(help)

func _input(event:InputEvent)->void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode==KEY_SPACE:
            autoplay=false
            target=0.0 if target>.5 else 1.0
        elif event.keycode==KEY_R:
            autoplay=false
            target=0.0
            extra_elbow_deg=0.0
        elif event.keycode==KEY_UP:
            autoplay=false
            extra_elbow_deg=clampf(extra_elbow_deg+3.0,-12.0,18.0)
        elif event.keycode==KEY_DOWN:
            autoplay=false
            extra_elbow_deg=clampf(extra_elbow_deg-3.0,-12.0,18.0)
        elif event.keycode==KEY_1:
            cam.position=Vector3(4.65,3.3,7.4)
            cam.look_at(Vector3(.45,2.3,.70))
        elif event.keycode==KEY_2:
            cam.position=Vector3(7.0,3.20,1.1)
            cam.look_at(Vector3(.7,2.15,.6))
        elif event.keycode==KEY_3:
            cam.position=Vector3(.65,2.65,8.0)
            cam.look_at(Vector3(.65,2.2,.65))
        elif event.keycode==KEY_4:
            _camera_closeup()
        elif event.keycode==KEY_ESCAPE:
            get_tree().quit()

func _process(delta:float)->void:
    cycle+=delta
    if autoplay:
        var second=fmod(cycle,11.0)
        target=1.0 if second>=1.15 and second<6.5 else 0.0
    progress=move_toward(progress,target,delta/DURATION)
    _pose(progress)
    bar.value=progress*100
    if progress<.02:
        label_phase.text="00 | Mano normal: hombro de un punto + codo en reposo"
    elif progress<.25:
        label_phase.text="01 | Se articula hombro: Parts 14, 70 y 72 + brazo"
    elif progress<.55:
        label_phase.text="02 | Mano se retrae: Rustwing se despliega desde la muñeca"
    elif progress<.95:
        label_phase.text="03 | Placas Rustwing desplegadas; acoples originales"
    else:
        label_phase.text="04 | Una sola arma: Rustwing alineado con muñeca, antebrazo y codo"
