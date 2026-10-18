extends Control
# Niebla, tinta y planos de profundidad originales para PunchLine.
var clock := 0.0
var pointer := Vector2.ZERO
var mist: ShaderMaterial
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new(); shader.code = """shader_type canvas_item;
uniform float clock = 0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 a=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(a),hash(a+vec2(1,0)),f.x),mix(hash(a+vec2(0,1)),hash(a+vec2(1,1)),f.x),f.y);}
void fragment(){vec2 uv=UV;float fog=noise(uv*5.0+vec2(clock*.025,-clock*.013))*.65+noise(uv*13.0-vec2(clock*.009,0.0))*.25;float vignette=smoothstep(.8,.15,length(uv-vec2(.5)));vec3 c=mix(vec3(.018,.03,.039),vec3(.09,.15,.17),fog*vignette);float grain=hash(FRAGCOORD.xy+fract(clock)*71.0)*.012;COLOR=vec4(c+grain,.90);}"""
	mist = ShaderMaterial.new(); mist.shader = shader
	var fog := ColorRect.new(); add_child(fog); fog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); fog.mouse_filter = Control.MOUSE_FILTER_IGNORE; fog.material = mist
func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	clock += delta*float(Engine.get_meta("punchline_ui_motion",1.0)); mist.set_shader_parameter("clock",clock)
	pointer = pointer.lerp((get_global_mouse_position()/size.clamp(Vector2.ONE,Vector2(10000,10000))-Vector2(.5,.5))*12,1-exp(-delta*3)); queue_redraw()
func _draw() -> void:
	var width := size.x; var height := size.y
	for i in range(11):
		var x: float = width*(.57+i*.047)+pointer.x*(i*.14)
		var points := PackedVector2Array([Vector2(x,-30),Vector2(x+width*.06,-10),Vector2(x-width*.12,height+30),Vector2(x-width*.22,height+20)])
		draw_colored_polygon(points,Color(.10,.18,.20,.035 if i%2 else .08))
		if i%3 == 0: draw_line(points[0],points[2],Color(.58,.70,.69,.13),1,true)
	for i in range(15):
		var x := fmod(i*173.1+clock*(3+i%4),maxf(1,width)); var y := fmod(i*113.7-clock*(5+i%3)+height*10,maxf(1,height))
		draw_circle(Vector2(x,y),1.0+i%2,Color(.6,.78,.77,.10))
