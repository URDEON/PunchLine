extends RefCounted
## Shared command contract for human input and, later, AI. No networking yet.
var move := Vector2.ZERO
var yaw := 0.0
var sprint := false
var walk := false
var crouch := false
var jump := false
