extends SceneTree
var game:Node3D
var checks:=0
var failures:=0
func _initialize():run.call_deferred()
func frames(n:int):
 for i in range(n):await physics_frame
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print('PASS ' if ok else 'FAIL ',label)
func run():
 Engine.set_meta('punchline_world',load('res://scripts/world_config.gd').DEFAULTS.duplicate())
 game=load('res://main.tscn').instantiate();game.preferences.values.grass_quality=0;root.add_child(game)
 while game.loading:await process_frame
 await frames(5)
 for enemy in game.enemies:game.set_dummy_mode(enemy,0)
 var d:Node3D=game.arena.punchline.destruction;var original_count:int=d.parts.size();var key:=''
 for id in d.parts:
  var p:Dictionary=d.parts[id]
  if p.category=='Walls' and p.size.y>2.5 and p.size.x>2.4 and p.size.z<.3:key=id;break
 check(not key.is_empty(),'real generated masonry wall selected')
 var original:Dictionary=d.parts[key];var centre:Vector3=original.box.get_center()
 var packet:Dictionary=d.damage_area(centre,.22,12,Vector3.FORWARD);await frames(2)
 check(d.fractures.has(key) and d.fractures[key].size()>4,'first impact fractures only the struck wall into deterministic cells')
 var partial:=0;var untouched:=0
 for id in d.fractures.get(key,[]):
  var p:Dictionary=d.parts[id]
  if p.hp>0 and p.hp<p.max_hp:partial+=1
  if is_equal_approx(p.hp,p.max_hp):untouched+=1
 check(partial>0 and untouched>0 and d.cracks.size()>0,'weak local hit creates cracks while neighbouring masonry remains intact')
 d.damage_area(centre,.3,90,Vector3.FORWARD);await frames(3)
 var broken:='';untouched=0
 for id in d.fractures.get(key,[]):
  if d.parts[id].broken:broken=id
  else:untouched+=1
 check(not broken.is_empty() and untouched>0,'strong hit opens a local hole rather than erasing the whole wall')
 var piece:Dictionary=d.parts[broken];var normal:Vector3=piece.pose.basis[piece.size.min_axis_index()].normalized()
 var query:=PhysicsRayQueryParameters3D.create(piece.box.get_center()+normal*.19,piece.box.get_center()-normal*.19,1)
 check(game.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),'broken cell removes actual wall collision')
 check(d.debris.size()>0 and d.debris.size()<=64,'fracture creates a bounded physical debris pool')
 var triangles:=true;var material_match:=false;var world_only:=true
 for body in d.debris:
  triangles=triangles and body.get_child(0).mesh.get_faces().size()>=3
  material_match=material_match or body.get_child(0).material_override==original.material
  world_only=world_only and body.collision_layer==64 and body.collision_mask==(1|64) and body.continuous_cd
 check(triangles and material_match and world_only,'solid convex rubble retains source material and collides with world and other rubble')
 var saved:Dictionary=d.state();var saved_ids:Array=d.fractures[key].duplicate();var revision:int=d.revision
 d.apply_packet(packet,true);check(d.revision==revision,'duplicate damage packets cannot replay fracture')
 d.reset_world();await frames(3)
 check(d.parts.size()==original_count and d.fractures.is_empty() and not original.collision.disabled,'reset removes fracture cells and restores original physical wall')
 d.accept_state(saved);await frames(3)
 check(d.fractures[key]==saved_ids and d.parts[broken].broken and d.parts[broken].collision.disabled,'late-join state reconstructs the identical fracture IDs and holes')
 d.reset_world();await frames(2)
 var building:Dictionary=d.buildings[original.building];var bearing:Array=[]
 for id in building.parts.duplicate():
  var p:Dictionary=d.parts[id]
  if int(p.get('bearing_level',-1))!=0:continue
  if d.can_fracture(p):
   for cell_id in d.fracture(id):
    if d.parts[cell_id].has('bearing_level'):bearing.append(cell_id)
  else:bearing.append(id)
 var roof_key:=''
 for id in building.parts:
  if d.parts[id].category=='Roof':roof_key=id;break
 var victim:Dictionary=game.enemies[0];victim.body.global_position=building.node.to_global(Vector3(0,.025,1.8));victim.hp=100;victim.ragdoll=false;victim.wakeup_protection=0
 var detached:=0;var start:=Time.get_ticks_msec()
 for id in bearing:
  if d.parts[id].broken:continue
  var p:Dictionary=d.parts[id];var hit:Dictionary=d.damage_area(p.box.get_center(),.08,160,Vector3.RIGHT)
  detached+=hit.get('detached',[]).size()
 await frames(3)
 print('SUPPORT_RUNTIME_MS ',Time.get_ticks_msec()-start,' bearing=',bearing.size(),' detached=',detached)
 check(detached>0 and d.parts[roof_key].broken,'removing bearing masonry drops the supported roof through the support graph')
 check(d.support_checks>0 and d.debris.size()<=64 and d.rubble.size()<=192,'collapse evaluates support and respects debris and persistent rubble budgets')
 var roofs:=0
 for body in d.debris:
  if not is_instance_valid(body):continue
  var source:String=body.get_meta('structural_source','')
  if d.parts.has(source) and d.parts[source].category=='Roof' and original_roof(body,d.parts[source]):roofs+=1
 for id in d.settled_nodes:
  if d.parts[id].category=='Roof' and original_roof(d.settled_nodes[id],d.parts[id]):roofs+=1
 print('RETAINED_ROOFS ',roofs,' dynamic=',d.debris.size(),' settled=',d.settled_nodes.size())
 # A large collapse can fill the body pool in the same frame. Evicted complete
 # roofs must already be solid settled structures rather than disappearing.
 check(roofs>0,'unsupported roofs retain source geometry and collision through falling and settling')
 var floating_windows:=false
 for id in building.parts:
  var value:Dictionary=d.parts[id]
  if value.category=='Windows' and not value.broken:floating_windows=true
 check(not floating_windows,'unsupported glass panes do not remain floating after structural collapse')
 d.set_paused(true);var frozen:=true
 for body in d.debris:frozen=frozen and body.freeze
 check(frozen,'single-player pause freezes physical demolition debris')
 d.set_paused(false)
 check(d.physical_rubble.has(original.building) and d.physical_rubble[original.building].find_children('*','StaticBody3D',true,false).size()==3,'collapse leaves deterministic walkable rubble independent of visual debris quality')
 var rubble_state:Dictionary=d.state()
 var rubble_sites:Array=d.physical_rubble.keys()
 check(rubble_state.rubble_buildings==rubble_sites,'late-join state includes persistent physical rubble locations')
 await frames(100)
 check(victim.hp<100 and victim.ragdoll,'falling structural pieces cause authoritative environmental damage and ragdoll')
 d.fall_hazards.clear();game.preferences.values.debris_enabled=false
 var fake:Dictionary=d.parts[roof_key];var saved_box:AABB=fake.box
 fake.box=AABB(Vector3(600,3,-1),Vector3(2,.25,2))
 d.schedule_falls({'revision':900,'detached':[roof_key],'damaged':{roof_key:0.0}})
 check(d.fall_hazards.size()==1,'gameplay collapse hazards exist even when cosmetic debris is disabled')
 fake.box=saved_box;d.fall_hazards.clear()
 d.reset_world();await frames(3)
 check(d.cracks.is_empty() and d.rubble.is_empty() and d.fractures.is_empty() and d.physical_rubble.is_empty() and d.parts.size()==original_count,'world restart clears cracks, rubble and temporary geometry')
 d.enabled=false;check(d.damage_area(centre,5,999,Vector3.UP).is_empty() and d.fractures.is_empty(),'indestructible-world option prevents all fracture')
 print('RESULT ',checks-failures,'/',checks,' fracture, physical rubble, support and late-join checks')
 game.queue_free();await frames(8);quit(1 if failures else 0)
func original_roof(body:PhysicsBody3D,part:Dictionary)->bool:
 var geometry:MeshInstance3D=body.get_child(0)
 var collision:CollisionShape3D=body.get_child(1)
 if geometry.material_override!=part.material or collision.disabled or collision.shape==null:return false
 if part.collision.shape is BoxShape3D:
  return geometry.mesh is BoxMesh and geometry.mesh.size.is_equal_approx(part.size) and collision.shape is BoxShape3D
 var source:Array=part.body.find_children('*','MeshInstance3D',true,false)
 return not source.is_empty() and geometry.mesh==source[0].mesh and collision.shape is ConvexPolygonShape3D
