extends Resource
## Abstract, editable game balance. These values do not simulate real weapons.
@export var id := ""
@export var display_name := ""
@export var ammo_type := "AR"
@export var shots_per_second := 7.0
@export var magazine_size := 30
@export var reserve_ammo := 150
@export var reload_seconds := 2.3
@export var damage := 24.0
@export var range_limit := 180.0
@export var falloff_start := 60.0
@export var minimum_damage_factor := 0.65
@export var spread_degrees := 0.7
@export var recoil := 0.008
@export var model_path := ""
@export var model_length := 0.82
@export var model_forward := Vector3.RIGHT
@export var model_up := Vector3.BACK

func damage_at(distance: float) -> float:
	var factor := clampf(inverse_lerp(falloff_start,range_limit,maxf(0,distance)),0,1)
	return damage*lerpf(1.0,minimum_damage_factor,factor)
