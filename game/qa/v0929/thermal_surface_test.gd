extends SceneTree
func _initialize():run.call_deferred()
func run():
 var world:=Node3D.new();root.add_child(world)
 var factory=load('res://housing/scripts/DistrictHousingGenerator.gd').new();world.add_child(factory)
 factory.part(world,'SolidCeiling',Vector3(6,.25,6),Vector3(0,4,0),null)
 var body:=Node3D.new();world.add_child(body);body.position=Vector3(0,3.825,0)
 var spider=load('res://scripts/head_spider.gd').new();world.add_child(spider);spider.normal=Vector3.DOWN
 var view=load('res://scripts/spider_vision.gd').new();world.add_child(view)
 for i in range(3):await physics_frame
 var camera:=Vector3(0,2.1,2)
 var point:Vector3=view.target_point({'body':body,'spider':spider,'warm':true})
 var proper:=PhysicsRayQueryParameters3D.create(camera,point,1)
 var upright:=PhysicsRayQueryParameters3D.create(camera,body.position+Vector3.UP,1)
 var space:PhysicsDirectSpaceState3D=world.get_world_3d().direct_space_state
 var ok:bool=space.intersect_ray(proper).is_empty() and not space.intersect_ray(upright).is_empty()
 print('PASS ' if ok else 'FAIL ','thermal visibility follows ceiling-walking head instead of sampling through ceiling')
 print('RESULT ',1 if ok else 0,'/1 thermal surface check')
 world.queue_free();await physics_frame;quit(0 if ok else 1)
