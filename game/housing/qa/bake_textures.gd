extends SceneTree
## Deterministic tileable material maps; code-generated textures, not facade photographs.
func _initialize()->void:
	var rng:=RandomNumberGenerator.new();rng.seed=923
	for kind in ["plaster","brick","clay_tiles","wood","pavers"]:
		var image:=Image.create(256,256,false,Image.FORMAT_RGB8)
		for y in range(256):
			for x in range(256):
				var noise:=rng.randf_range(-.035,.035)
				var value:=.91+noise
				if kind=="brick":
					var offset:=32 if (y/32)%2 else 0
					value=.60 if (x+offset)%64<3 or y%32<3 else .91+noise+sin(float((x+offset)/64)*7+float(y/32)*3)*.035
				elif kind=="clay_tiles":
					value=.76+.16*cos(float(x%32)/32*TAU)+noise
					if y%64>58:value*=.66
				elif kind=="wood":
					value=.83+sin(float(x)*.19+sin(float(y)*.04))*.065+noise
					if x%64<2:value=.46
				elif kind=="pavers":
					value=.65 if x%64<3 or y%64<3 else .93+noise
				image.set_pixel(x,y,Color(value,value,value))
		var status:=image.save_png("res://housing/textures/"+kind+".png")
		if status!=OK:quit(1);return
	print("TEXTURES deterministic seed=923, five material maps baked")
	quit(0)
