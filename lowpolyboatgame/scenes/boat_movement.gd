extends RigidBody3D


@export var forward_force: float = 400.0
@export var backward_force: float = 10.0
@export var turn_torque: float = 600.0
@export var linear_drag: float = 2.0
@export var angular_drag: float = 450.0
@export var side_resistance: float = 20.0  # 0 = no sliding, 1 = full sliding
@export var turning_responsiveness: float = 0.05  
@export var max_turn_boost_speed: float = 5.0  # speed at which boost stops growing
@export var base_turning_speed: float = 0.7
@export var turning_speed_threshold: float = 0.027

func _physics_process(delta: float) -> void:
	# Forward / backward
	if Input.is_action_pressed("ui_up"):  # W / Up
		apply_central_force(global_transform.basis.x * forward_force)
	elif Input.is_action_pressed("ui_down"):  # S / Down
		apply_central_force(global_transform.basis.x * -backward_force)


	var speed_factor: float = clamp(1/(linear_velocity.length() / max_turn_boost_speed), 0.0, 1.0)
		
	# Turning (scaled by speed for responsiveness)
	var turning_speed: float = base_turning_speed + speed_factor * turning_responsiveness
	var max_turning_speed: float = base_turning_speed + 1 * turning_responsiveness
	if max_turning_speed - turning_speed < turning_speed_threshold:
		turning_speed = 0.0
	
	print("turning speed: ", turning_speed)
	print("speed_factor: ", speed_factor)
	if Input.is_action_pressed("ui_left"):
		apply_torque(Vector3.UP * turn_torque * turning_speed)
	elif Input.is_action_pressed("ui_right"):
			apply_torque(Vector3.UP * -turn_torque * turning_speed)

	# Apply drag (simulated water resistance)
	#linear_velocity *= pow(linear_drag, delta * 60)
	#angular_velocity *= pow(angular_drag, delta * 60)
	apply_central_force(-linear_velocity * linear_drag)
	apply_torque(-angular_velocity * angular_drag)

	# Reduce sideways drift
	var forward_dir = global_transform.basis.x
	var right_dir = global_transform.basis.z
	var forward_speed = forward_dir.dot(linear_velocity)
	var side_speed = right_dir.dot(linear_velocity)
	#linear_velocity = forward_dir * forward_speed + right_dir * side_speed * side_resistance
	apply_central_force(-right_dir * side_speed * side_resistance)
