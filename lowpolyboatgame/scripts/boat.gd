#deprecated

extends RigidBody3D

@export var engine_force: float = 200.0
@export var turn_torque: float = 50.0
@export var drag: float = 0.98
@export var steering_resistance: float = 0.5

var input_throttle := 0.0
var input_turn := 0.0

func _ready():
	gravity_scale = 0.0
	#lock_rotation_x = true
	#lock_rotation_z = true

func _physics_process(delta: float) -> void:
	input_throttle = 0.0
	input_turn = 0.0

	if Input.is_action_pressed("ui_up"):
		input_throttle = 1.0
	elif Input.is_action_pressed("ui_down"):
		input_throttle = -0.5

	if Input.is_action_pressed("ui_left"):
		input_turn = 1.0
	elif Input.is_action_pressed("ui_right"):
		input_turn = -1.0

	# Apply forward/back force
	var forward_dir = -transform.basis.z
	apply_central_force(forward_dir * input_throttle * engine_force)

	# Apply torque for turning
	if abs(input_turn) > 0.0 and linear_velocity.length() > 0.1:
		apply_torque(Vector3.UP * input_turn * turn_torque)

	# Apply drag (slows movement gradually)
	linear_velocity *= drag

	# Reduce sideways drift
	var right_dir = transform.basis.x
	var side_speed = right_dir.dot(linear_velocity)
	linear_velocity -= right_dir * side_speed * steering_resistance
