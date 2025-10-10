extends RigidBody3D

@export var player_index : int = 3

enum InputType {
	MOUSE_KEYBOARD, # 0
	CONTROLLER,	 	# 1
	TOUCH			# 2
}

signal input_type_changed(new_type)

var current_input_type: InputType:
	set(value):
		if current_input_type != value:
			current_input_type = value
			input_type_changed.emit(value)
	get:
		return current_input_type
#this indicates the player or controller/device used for this script
#positiv integer, should be the same as in script name

@export var forward_force: float = 400.0 # how much force pushes it forward
@export var backward_force: float = 80.0 # how much force pushes it backward
@export var turn_torque: float = 600.0 # rotational force
@export var linear_drag: float = 2.0 # to fake water resistance and make it slow down
@export var angular_drag: float = 450.0 # to stop the turning force and make it  go straight again
@export var slide_resistance: float = 20.0  # small means more sliding and vice versa, maybe call drift resistance
@export var turning_responsiveness: float = 0.05  # close to zero makes turn slower and vice versa
@export var max_turn_boost_speed: float = 5.0  # bigger means sharper turns when boat is fast
@export var base_turning_speed: float = 0.7 # so boat can turn even when slow, but not when too slow
@export var turning_speed_threshold: float = 0.027 # when boat is too slow deny turning

## Called when there is an input event.
func _input(event: InputEvent) -> void:

	# Check if the input is a keyboard or mouse event
	if event is InputEventKey or event is InputEventMouse:

		# Set the current input type to Mouse and Keyboard
		current_input_type = InputType.MOUSE_KEYBOARD

	# Check if the input is a controller event
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:

		# Set the current input type to Controller
		current_input_type = InputType.CONTROLLER

	# Check if the input is a touch event
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:

		# Set the current input type to Touch
		current_input_type = InputType.TOUCH


func _physics_process(delta: float) -> void:

	if current_input_type == InputType.MOUSE_KEYBOARD:
		handle_mouse_keyboard_input()
		return


func handle_mouse_keyboard_input() -> void:
	# Forward / backwards
	if Input.is_action_pressed("ui_up"):
		apply_central_force(global_transform.basis.x * forward_force)
	elif Input.is_action_pressed("ui_down"):
		apply_central_force(global_transform.basis.x * -backward_force)

	# Reduce sideways drift/slide
	var forward_dir = global_transform.basis.x
	var right_dir = global_transform.basis.z
	var forward_speed = forward_dir.dot(linear_velocity)
	var side_speed = right_dir.dot(linear_velocity)
	#linear_velocity = forward_dir * forward_speed + right_dir * side_speed * side_resistance
	apply_central_force(-right_dir * side_speed * slide_resistance)


		# Turning
		# consists of base turning speed and inverse scaling part dependant on velocity
		# deny turning when too slow
	var speed_factor: float = clamp(max_turn_boost_speed / linear_velocity.length(), 0.0, 1.0)
	var turning_speed: float = base_turning_speed + speed_factor * turning_responsiveness
	var max_turning_speed: float = base_turning_speed + 1 * turning_responsiveness

	# so boat can turn even when slow, but not when too slow
	if max_turning_speed - turning_speed < turning_speed_threshold:
		turning_speed = 0.0

	# we need this because torque depends on global axis and therefore we need to reverse it when
	# going backwards
	var moving_backward = forward_dir.dot(linear_velocity) < 0
	var steer_dir = 1.0
	if moving_backward:
		steer_dir = -1.0

	if Input.is_action_pressed("ui_left"):
		apply_torque(Vector3.UP * turn_torque * turning_speed * steer_dir)
	elif Input.is_action_pressed("ui_right"):
		apply_torque(Vector3.UP * -turn_torque * turning_speed * steer_dir)

	# Apply drag (simulated water resistance)
	apply_central_force(-linear_velocity * linear_drag)
	apply_torque(-angular_velocity * angular_drag)
