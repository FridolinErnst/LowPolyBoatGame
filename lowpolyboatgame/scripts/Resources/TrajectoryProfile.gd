extends Resource
class_name TrajectoryProfile

@export var gravity: float = -9.8
@export var speed: float = 30.0
@export var trail_length: float = 30.0
@export var width_start: float = 1.5
@export var width_end: float = 0.1
@export var color: Color = Color(1, 1, 1, 1) # optional, for future shader use

func compute_point(t: float, direction: Vector3) -> Vector3:
	var v0 = direction * speed
	var g = Vector3(0, gravity, 0)
	return v0 * t + 0.5 * g * t * t
