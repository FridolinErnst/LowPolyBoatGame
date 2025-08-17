extends MeshInstance3D

@export var cannonball_scene: PackedScene
@export var cannonball_speed: float = 30.0 # should equal speed?

# clicking the left mouse button activates attack hitbox, WASD can then be used to aim
# right mouse button to shoot
# code sollte vlt von den canonball shooting getrennt werden
# TODO 
# 	make them hit other boats or objects, for that see _check_collision()
# 	make the canonballs have proper mass and still match indications
#	boats should move when hit by canonball, if that does not work when increasing canonball mass 
#		then apply force at point of impact from where they came
#	add sound, fire or explosion when firing and on impact, canon smoke, screen shake when getting hit by a lot of canons
#	figure out how 2 controllers can play or one controller and one keyboard and mouse
# 	add cooldown between shots
# 	addcontrolls vorschlag:
# 		linker joystick aim, 
# 		rechter joystick movement,
# 		unteren shoulder buttons breit und schmal vom aim
# 		oberen shoulder button sind schiessen
# 		pfeiltasten sind weapon wechseln
# 		wenn man den linken joystick bewegt dsnn soll sofort das aimen erscheinen und es soll immer zurueck defaulten zu einem standart aim wenn man die unteren shoulder buttons laenger los laesst
# 		und aimen mit linkem joystick kann entweder immer relativ von dem bot ausgehen oder fixiert sein. aim erscheint nur in die richtung in die geaimt wird

#region variables

@export var trail_length: float = 30.0
@export var resolution: int = 20
@export var width_start: float = 1.5
@export var width_end: float = 0.1
@export var gravity: float = -9.8
@export var speed: float = 30.0
@export var vertical_rendering_height_end: float = -10
@export var active := false
@export var default_pitch_deg: float = 15.0

@onready var shader_material: ShaderMaterial = preload("res://assets/materials/canonAimMaterial.tres")

# aim variables
var yaw: float = 0.0    # left/right rotation
var pitch: float = 0.0  # up/down rotation
@export var aim_up_limit: float = 45.0   # degrees
@export var aim_down_limit: float = 15.0 # degrees
@export var aim_speed: float = 45.0 # degrees per second
@export var recenter_speed: float = 20.0 # how fast aim returns to default
@export var yaw_limit: float = 30.0  # degrees left/right

# forward direction
var default_angle := Vector3(1, 0, 0) 
var aim_dir := Vector3(1, 0, 0) # actual working angle

var curve := Curve3D.new()

#track aim so we only update when it changes
var last_aim_dir: Vector3


#endregion


func _ready():
	visible = false
	pitch = deg_to_rad(default_pitch_deg)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			active = !active
			visible = active
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_shoot_cannonball()

func _physics_process(delta):


	var yaw_input := 0.0
	var pitch_input := 0.0

	# Collect inputs
	if Input.is_action_pressed("move_left"):   # A
		yaw_input -= 1
	if Input.is_action_pressed("move_right"):  # D
		yaw_input += 1
	if Input.is_action_pressed("move_up"):     # W
		pitch_input += 1
	if Input.is_action_pressed("move_down"):   # S
		pitch_input -= 1
	
	# if no input we don't calculate further
	if yaw_input == 0.0 && pitch_input == 0.0:
		return
		
	# --- Update yaw ---
	if yaw_input != 0.0:
		yaw += yaw_input * aim_speed * delta
	else:
		# recenter yaw toward 0
		yaw = lerp(yaw, 0.0, recenter_speed * delta)

	# --- Update pitch ---
	if pitch_input != 0.0:
		pitch += pitch_input * aim_speed * delta
	else:
		# recenter pitch toward default
		pitch = lerp(pitch, deg_to_rad(default_pitch_deg), recenter_speed * delta)

	# Clamp within limits
	yaw = clamp(yaw, -deg_to_rad(yaw_limit), deg_to_rad(yaw_limit))
	pitch = clamp(pitch, -deg_to_rad(aim_down_limit), deg_to_rad(aim_up_limit))

	# Convert yaw/pitch into direction
	aim_dir = Vector3(
		cos(yaw) * cos(pitch),
		sin(pitch),
		sin(yaw) * cos(pitch)
	).normalized()

	set_aim_direction(aim_dir)
	_check_collision()

func _build_curve():
	curve.clear_points()
	var position = Vector3.ZERO
	var velocity = aim_dir * speed
	var start_height = position.y

	for i in range(resolution):
		curve.add_point(position)
		position += velocity * (trail_length / float(resolution))
		velocity.y += gravity * (trail_length / float(resolution))
		if position.y < start_height + vertical_rendering_height_end:
			break

	curve.bake_interval = trail_length / float(resolution)

func _update_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var baked_points = curve.get_baked_points()
	
	
	if baked_points.size() < 2:
		mesh = null
		return


	for i in range(baked_points.size() - 1):
		var t1 = float(i) / float(baked_points.size() - 1)
		var t2 = float(i + 1) / float(baked_points.size() - 1)

		var width1 = lerp(width_start, width_end, t1)
		var width2 = lerp(width_start, width_end, t2)

		var pos1 = baked_points[i]
		var pos2 = baked_points[i + 1]

		var tangent = (pos2 - pos1).normalized()
		var side = tangent.cross(Vector3.UP).normalized()
		if side.length() < 0.001:
			side = tangent.cross(Vector3.FORWARD).normalized()

		var normal = tangent.cross(side).normalized()

		var v1 = pos1 + side * width1
		var v2 = pos1 - side * width1
		var v3 = pos2 + side * width2
		var v4 = pos2 - side * width2

		# First triangle
		st.set_normal(normal)
		st.set_uv(Vector2(0, t1))
		st.add_vertex(v1)
		st.set_normal(normal)
		st.set_uv(Vector2(1, t1))
		st.add_vertex(v2)
		st.set_normal(normal)
		st.set_uv(Vector2(0, t2))
		st.add_vertex(v3)

		# Second triangle
		st.set_normal(normal)
		st.set_uv(Vector2(0, t2))
		st.add_vertex(v3)
		st.set_normal(normal)
		st.set_uv(Vector2(1, t1))
		st.add_vertex(v2)
		st.set_normal(normal)
		st.set_uv(Vector2(1, t2))
		st.add_vertex(v4)

	mesh = st.commit()
	if mesh:
		mesh.surface_set_material(0, shader_material)

func _check_collision():
	var space = get_world_3d().direct_space_state
	var baked_points = curve.get_baked_points()
	for i in range(baked_points.size() - 1):
		var from = baked_points[i]
		var to = baked_points[i + 1]
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space.intersect_ray(query)

		if result:
			while baked_points.size() > i + 1:
				baked_points.remove_at(baked_points.size() - 1)
			break

func set_aim_direction(dir: Vector3):
	aim_dir = dir.normalized()
	_build_curve()
	_update_mesh()


#should get these variables as input or declared at top and exported or both
# spawns canonballs with individual offsets so it looks more realistic
# spawns them at the aiming origin
func _shoot_cannonball():
	if cannonball_scene == null:
		push_error("Cannonball scene not assigned in Inspector!")
		return
	
	var num_cannons = 5        # number of balls in a volley
	var spacing = 2.0          # side-to-side spacing
	var max_delay = 0.2        # maximum random delay in seconds
	var forward = (global_transform.basis * aim_dir).normalized()
	var side = forward.cross(Vector3.UP).normalized()
	var center = global_transform.origin

	for i in range(num_cannons):
		var offset_side = (i - (num_cannons - 1) / 2.0) * spacing
		var offset_forward = randf_range(-0.5, 0.5)   # add forward/back jitter
		var offset_vertical = randf_range(-0.2, 0.2)  # slight vertical wiggle
		var delay = randf_range(0.0, max_delay)       # random delay for realism

		# Run each spawn as a separate coroutine
		spawn_cannonball_with_delay(offset_side, offset_forward, offset_vertical, delay, forward, side, center)
		
func spawn_cannonball_with_delay(offset_side, offset_forward, offset_vertical, delay, forward, side, center):
	await get_tree().create_timer(delay).timeout

	var ball = cannonball_scene.instantiate()
	get_tree().current_scene.add_child(ball)

	ball.global_transform.origin = center + side * offset_side + forward * offset_forward + Vector3.UP * offset_vertical
	ball.linear_velocity = forward * cannonball_speed
