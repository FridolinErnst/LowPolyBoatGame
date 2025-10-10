extends Node

@export var player_index: int = 0
@export var aim_speed: float = 10.0
@export var recenter_speed: float = 20.0
@export var default_pitch_deg: float = 15.0
@export var aim_up_limit: float = 45.0
@export var aim_down_limit: float = 15.0
@export var yaw_limit: float = 30.0
@export var aim_update_epsilon_deg: float = 0.25

signal aim_direction_updated(player_index: int, aim_direction: Vector3)
signal shoot_pressed(player_index: int)
signal toggle_aim_pressed(player_index: int)

var yaw := 0.0
var pitch := deg_to_rad(default_pitch_deg)
var last_aim_dir := Vector3.ZERO
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta):
	var yaw_input := Input.get_joy_axis(player_index, JOY_AXIS_RIGHT_X)
	var pitch_input := Input.get_joy_axis(player_index, JOY_AXIS_RIGHT_Y)

	#var input_vector := Vector2(yaw_input, pitch_input)
	#var input_strength := input_vector.length() # Between 0.0 and 1.0

	if yaw_input != 0.0:
		yaw += yaw_input * aim_speed * delta
	else:
		yaw = lerp(yaw, 0.0, recenter_speed * delta)

	if pitch_input != 0.0:
		pitch += pitch_input * aim_speed * delta
	else:
		pitch = lerp(pitch, deg_to_rad(default_pitch_deg), recenter_speed * delta)

	yaw = clamp(yaw, -deg_to_rad(yaw_limit), deg_to_rad(yaw_limit))
	pitch = clamp(pitch, -deg_to_rad(aim_down_limit), deg_to_rad(aim_up_limit))

	var new_dir = Vector3(
		cos(yaw) * cos(pitch),
		sin(pitch),
		sin(yaw) * cos(pitch)
	).normalized()

	if last_aim_dir == Vector3.ZERO or new_dir.dot(last_aim_dir) < cos(deg_to_rad(aim_update_epsilon_deg)):
		emit_signal("aim_direction_updated", player_index, new_dir)
		last_aim_dir = new_dir
