extends Node3D
## User-supplied skinned X Bot + original military equipment, shared by FPS and TPS.
const Rig = preload("res://assets/animation_sources/shooter/fbx/x_bot.fbx")
const Animations = preload("res://units/soldiers/soldier_animations.gd")
const Pose = preload("res://units/soldiers/soldier_pose.gd")
const Gun = preload("res://combat/weapon_visual.gd")
var skeleton: Skeleton3D
var bones: Dictionary = {}
var attachments: Dictionary = {}
var head: BoneAttachment3D
var rig: Node3D
var animations: Node
var modifier: SkeletonModifier3D
var phase := 0.0
var weapon_mount: Node3D
var weapons: Array[Node3D] = []
var weapon_index := 0
var initialized := false
var recoil := 0.0

func _ready() -> void:
 rig = Rig.instantiate();rig.name="Rig";add_child(rig)
 skeleton=rig.find_children("*","Skeleton3D",true,false)[0]
 for animator in rig.find_children("*","AnimationPlayer",true,false):animator.queue_free()
 var cloth:=ShaderMaterial.new();cloth.shader=preload("res://units/soldiers/uniform.gdshader")
 var dark:=material(Color("172624"));var armor:=material(Color("3c5147"));var accent:=material(Color("79c9c2"))
 for mesh in rig.find_children("*","MeshInstance3D",true,false):mesh.material_override=dark if "Joints" in String(mesh.name) else cloth
 var aliases:Dictionary={"pelvis":"Hips","spine":"Spine1","chest":"Spine2","neck":"Neck","head":"Head","upper_arm_l":"LeftArm","forearm_l":"LeftForeArm","hand_l":"LeftHand","upper_arm_r":"RightArm","forearm_r":"RightForeArm","hand_r":"RightHand","thigh_l":"LeftUpLeg","shin_l":"LeftLeg","foot_l":"LeftFoot","thigh_r":"RightUpLeg","shin_r":"RightLeg","foot_r":"RightFoot"}
 for i in range(skeleton.get_bone_count()):bones[skeleton.get_bone_name(i)]=i
 for alias in aliases:
  bones[alias]=skeleton.find_bone("mixamorig_"+aliases[alias])
  var attachment:=BoneAttachment3D.new();attachment.name=alias;skeleton.add_child(attachment);attachment.bone_name="mixamorig_"+aliases[alias];attachments[alias]=attachment
 head=attachments.head
 gear("chest",Vector3(.35,.29,.075),Vector3(0,1.38,.145),armor)
 gear("chest",Vector3(.30,.34,.12),Vector3(0,1.36,-.14),dark)
 for x in [-.12,0.0,.12]:gear("chest",Vector3(.095,.13,.06),Vector3(x,1.27,.21),dark)
 for x in [-.145,.145]:gear("chest",Vector3(.045,.30,.025),Vector3(x,1.40,.194),dark)
 gear("chest",Vector3(.08,.035,.012),Vector3(0,1.46,.19),accent)
 gear("pelvis",Vector3(.34,.055,.22),Vector3(0,1.02,0),dark)
 var helmet:=SphereMesh.new();helmet.radius=.14;helmet.height=.27;helmet.radial_segments=20;helmet.rings=10
 gear_mesh("head",helmet,Transform3D(Basis.IDENTITY,Vector3(0,1.70,.015)),armor)
 gear("head",Vector3(.23,.075,.035),Vector3(0,1.69,.14),dark)
 gear("head",Vector3(.19,.055,.012),Vector3(0,1.695,.162),material(Color("345b60")))
 gear("head",Vector3(.07,.045,.065),Vector3(0,1.835,.02),dark)
 rig.rotation.y=PI
 animations=Animations.new();add_child(animations);animations.setup(self)
 modifier=Pose.new();modifier.visual=self;skeleton.add_child(modifier)
 skeleton.modifier_callback_mode_process=Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_PHYSICS
 weapon_mount=Node3D.new();attachments.hand_r.add_child(weapon_mount)
 for data in [preload("res://combat/m4a1.tres"),preload("res://combat/mp5a5.tres")]:
  var gun:=Gun.new();weapon_mount.add_child(gun);gun.setup(data);weapons.append(gun)
 set_weapon(0)
 calibrate_weapon.call_deferred()

func material(color:Color)->StandardMaterial3D:
 var surface:=StandardMaterial3D.new();surface.albedo_color=color;surface.roughness=.8;return surface

func gear_mesh(alias:String,mesh:Mesh,world_rest:Transform3D,surface:Material)->void:
 var node:=MeshInstance3D.new();node.mesh=mesh;node.material_override=surface
 attachments[alias].add_child(node)
 node.transform=skeleton.get_bone_global_rest(bones[alias]).affine_inverse()*world_rest

func gear(alias:String,size:Vector3,point:Vector3,surface:Material)->void:
 var mesh:=BoxMesh.new();mesh.size=size;gear_mesh(alias,mesh,Transform3D(Basis.IDENTITY,point),surface)

func calibrate_weapon()->void:
 if not is_inside_tree():return
 animations.tree.advance(.05)
 skeleton.force_update_all_bone_transforms()
 var hand_world:Transform3D=skeleton.global_transform*skeleton.get_bone_global_pose(bones.hand_r)
 # BoneAttachment receives its pose later in the frame; calibrate from the actual
 # evaluated bone rather than its previous, possibly still-resting transform.
 weapon_mount.transform=hand_world.affine_inverse()*Transform3D(global_basis,hand_world.origin-global_basis.z*.16)
 initialized=true

func set_weapon(index:int)->void:
 weapon_index=clampi(index,0,maxi(0,weapons.size()-1))
 for i in range(weapons.size()):weapons[i].visible=i==weapon_index

func muzzle_position()->Vector3:
 return weapons[weapon_index].muzzle_position() if not weapons.is_empty() else global_position

func set_local_first_person(enabled:bool)->void:
 if head!=null:head.visible=not enabled
 if modifier!=null:modifier.first_person=enabled

func animate(body:CharacterBody3D,command:RefCounted,delta:float)->void:
 phase=fposmod(phase+body.movement.locomotion_speed*delta*TAU/1.5,TAU)
 modifier.crouch=move_toward(modifier.crouch,1.0 if body.movement.crouched else 0.0,delta*7)
 modifier.pitch=body.view.pitch
 recoil=move_toward(recoil,0,delta*.2);modifier.recoil=recoil
 animations.tick(body,command)

func shot()->void:
 recoil=minf(.045,recoil+.025)
 animations.play_action("fire")

func reload(duration:float)->void:
 animations.play_action("reload",duration)

func hit()->void:
 animations.play_action("hit")
