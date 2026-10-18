@tool
extends MultiMesh
## Keep an authoritative CPU copy: the headless dummy renderer does not serialize native buffers.
## Upload once after loading. No per-frame work and no dependency on the baking renderer.
@export_storage var source_transforms:Array[Transform3D]=[]:
	set(value):
		source_transforms=value
		call_deferred("upload")

func upload()->void:
	if transform_format!=MultiMesh.TRANSFORM_3D:transform_format=MultiMesh.TRANSFORM_3D
	if instance_count!=source_transforms.size():instance_count=source_transforms.size()
	for i in range(source_transforms.size()):
		set_instance_transform(i,source_transforms[i])
		if has_method("reset_instance_physics_interpolation"):call("reset_instance_physics_interpolation",i)

func source_transform(index:int)->Transform3D:
	return source_transforms[index]
