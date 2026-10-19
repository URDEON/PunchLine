extends SceneTree
func _initialize():run.call_deferred()
func run():
 if DisplayServer.get_name()=='headless':push_error('Native renderer required');quit(1);return
 RenderingServer.set_render_loop_enabled(false)
 var scene:=Node3D.new();root.add_child(scene)
 var rig=load('res://scripts/rustcrawler_rig.gd').new();scene.add_child(rig)
 var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-30,0);sun.light_energy=1.4;scene.add_child(sun)
 var world:=WorldEnvironment.new();world.environment=Environment.new();world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color('263238');world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_color=Color('b6c1ca');world.environment.ambient_light_energy=.65;scene.add_child(world)
 var camera:=Camera3D.new();scene.add_child(camera);camera.position=Vector3(1.45,1.20,1.8);camera.look_at(Vector3(0,.38,0));camera.current=true;camera.fov=48
 for i in range(5):await process_frame
 RenderingServer.set_render_loop_enabled(true)
 for i in range(4):await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png('res://housing/docs/evidence/update_v0928/spider_front_reference.png')
 RenderingServer.set_render_loop_enabled(false)
 for i in range(6):rig.solve_leg(i,rig.feet_rest[i]+Vector3(.06 if i%2 else -.06,.09 if i%2 else 0,.02))
 for i in range(5):await process_frame
 RenderingServer.set_render_loop_enabled(true)
 for i in range(4):await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png('res://housing/docs/evidence/update_v0928/spider_front_step.png');print('RIG_RENDER_DONE');scene.queue_free();await process_frame;quit()
