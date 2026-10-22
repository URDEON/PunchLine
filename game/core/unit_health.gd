extends Node
signal changed(current: float,maximum: float)
signal incapacitated
@export var maximum := 100.0
var current := 100.0
var alive: bool:
	get: return current>0

func apply_damage(amount: float) -> void:
	if not alive or amount<=0 or not is_finite(amount): return
	current = maxf(0,current-amount)
	changed.emit(current,maximum)
	if not alive: incapacitated.emit()

func restore() -> void:
	current = maximum
	changed.emit(current,maximum)
