extends Node3D
var controller: Node
var sk: Skeleton3D
var rig: Node3D

func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D: return node
	for child in node.get_children():
		var found := find_skeleton(child)
		if found != null: return found
	return null

func _ready() -> void:
	var floor_body := StaticBody3D.new(); add_child(floor_body)
	var shape := BoxShape3D.new(); shape.size = Vector3(20,1,20)
	var collision := CollisionShape3D.new(); collision.shape = shape; collision.position.y = -.5; floor_body.add_child(collision)
	var floor_mesh := MeshInstance3D.new(); var box := BoxMesh.new(); box.size = shape.size; floor_mesh.mesh = box; floor_mesh.position.y = -.5; floor_body.add_child(floor_mesh)
	var actor := CharacterBody3D.new(); actor.name = "TestActor"; add_child(actor); actor.position.y = .3
	var holder := Node3D.new(); actor.add_child(holder); holder.scale = Vector3.ONE*.76
	rig = load("res://assets/physics/PlayerRagdollSource.gltf").instantiate(); holder.add_child(rig)
	sk = find_skeleton(rig)
	controller = load("res://scripts/physical_ragdoll.gd").new(); add_child(controller)
	controller.setup(actor,holder,sk,null)
	var camera := Camera3D.new(); add_child(camera); camera.position = Vector3(4,2,4); camera.look_at(Vector3(0,1,0)); camera.current = true
	var light := DirectionalLight3D.new(); add_child(light); light.rotation_degrees = Vector3(-45,-30,0)
	if not "--qa-controlled" in OS.get_cmdline_user_args(): controller.start(Vector3(2,1,0))
