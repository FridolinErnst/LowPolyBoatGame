extends MeshInstance3D

@export var cannonball_scene: PackedScene
@export var trajectory_profile: TrajectoryProfile

@export var resolution: int = 20
@export var vertical_rendering_height_end: float = -10
@export var active := false
@export var default_pitch_deg: float = 15.0

@onready var shader_material: ShaderMaterial = preload("res://assets/materials/canonAimMaterial.tres")

# Aim input
var yaw: float = 0.0
var pitch: float = 0.0
@export var aim_up_limit: float = 45.0
@export var aim_down_limit: float = 15.0
@export var aim_speed: float = 45.0
@export var recenter_speed: float = 20.0
@export var yaw_limit: float = 30.0

# Performance
@export var ray_segment_skip: int = 2
@export var refine_window_segments: int = 4
@export var refine_linear_scan: bool = true
@export var overshoot_distance: float = 0.6
@export var aim_update_epsilon_deg: float = 0.25

# Aiming vectors
var aim_dir := Vector3(1, 0, 0)
var last_aim_dir := Vector3.ZERO

var curve := Curve3D.new()
var _points := PackedVector3Array()

func _ready():
	visible = false
	pitch = deg_to_rad(default_pitch_deg)
	last_aim_dir = aim_dir

func _unhandled_input(event):
	var tmp : bool = Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER)
	var tmp2 : bool =  Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER)

	if (event is InputEventMouseButton and event.pressed):
		if event.button_index == MOUSE_BUTTON_LEFT:
			active = !active
			visible = active
		elif event.button_index == MOUSE_BUTTON_RIGHT || tmp:
			_shoot_cannonball()
	if tmp:
		active = !active
		visible = active
	if tmp2:
		_shoot_cannonball()

func set_aim_direction(dir: Vector3):
	aim_dir = dir.normalized()
	_build_curve()
	_update_mesh()
	_check_collision()

func _build_curve():
	if trajectory_profile == null:
		push_error("Trajectory profile not assigned!")
		return

	curve.clear_points()
	_points.clear()

	var step_t = trajectory_profile.trail_length / float(resolution)
	for i in range(resolution + 1):
		var t = step_t * i
		var p = trajectory_profile.compute_point(t, aim_dir)
		_points.append(p)
		curve.add_point(p)
		if p.y < vertical_rendering_height_end:
			break

	curve.bake_interval = step_t

func _update_mesh():
	var pts = _points
	var n = pts.size()
	if n < 2:
		mesh = null
		return

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(n - 1):
		var t1 = float(i) / float(n - 1)
		var t2 = float(i + 1) / float(n - 1)

		var width1 = lerp(trajectory_profile.width_start, trajectory_profile.width_end, t1)
		var width2 = lerp(trajectory_profile.width_start, trajectory_profile.width_end, t2)

		var pos1 = pts[i]
		var pos2 = pts[i + 1]

		var tangent = (pos2 - pos1).normalized()
		var side = tangent.cross(Vector3.UP).normalized()
		if side.length() < 0.001:
			side = tangent.cross(Vector3.FORWARD).normalized()
		var normal = tangent.cross(side).normalized()

		var v1 = pos1 + side * width1
		var v2 = pos1 - side * width1
		var v3 = pos2 + side * width2
		var v4 = pos2 - side * width2

		st.set_normal(normal)
		st.set_uv(Vector2(0, t1)); st.add_vertex(v1)
		st.set_uv(Vector2(1, t1)); st.add_vertex(v2)
		st.set_uv(Vector2(0, t2)); st.add_vertex(v3)
		st.set_uv(Vector2(0, t2)); st.add_vertex(v3)
		st.set_uv(Vector2(1, t1)); st.add_vertex(v2)
		st.set_uv(Vector2(1, t2)); st.add_vertex(v4)

	mesh = st.commit()
	if mesh:
		mesh.surface_set_material(0, shader_material)

func _check_collision():
	var space = get_world_3d().direct_space_state
	var pts = _points
	var n = pts.size()
	if n < 2: return

	var skip = max(1, ray_segment_skip)
	var coarse_hit_idx = -1
	var coarse_hit_point = Vector3.ZERO

	for i in range(0, n - 1, skip):
		var j = min(i + skip, n - 1)
		var from = global_transform * pts[i]
		var to = global_transform * pts[j]
		var result = space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
		if result:
			coarse_hit_idx = i
			coarse_hit_point = result.position
			break

	if coarse_hit_idx == -1:
		return

	var start_i = max(0, coarse_hit_idx - refine_window_segments)
	var end_i = min(n - 2, coarse_hit_idx + skip + refine_window_segments)
	var final_hit_idx = -1
	var final_hit_point = coarse_hit_point

	for k in range(start_i, end_i + 1):
		var from = global_transform * pts[k]
		var to = global_transform * pts[k + 1]
		var r = space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
		if r:
			final_hit_idx = k
			final_hit_point = r.position
			break

	if final_hit_idx == -1:
		return

	var trimmed = PackedVector3Array()
	for t in range(0, final_hit_idx + 1):
		trimmed.append(pts[t])

	var seg_dir = (pts[final_hit_idx + 1] - pts[final_hit_idx]).normalized()
	var hit_local = global_transform.affine_inverse() * final_hit_point
	trimmed.append(hit_local + seg_dir * overshoot_distance)

	_points = trimmed
	curve.clear_points()
	for p in _points:
		curve.add_point(p)
	curve.bake_interval = trajectory_profile.trail_length / float(max(1, resolution))

	_update_mesh()

func _shoot_cannonball():
	if cannonball_scene == null:
		push_error("Cannonball scene not assigned!")
		return

	var num_cannons = 5
	var spacing = 2.0
	var max_delay = 0.2
	var forward = (global_transform.basis * aim_dir).normalized()
	var side = forward.cross(Vector3.UP).normalized()
	var center = global_transform.origin

	for i in range(num_cannons):
		var offset_side = (i - (num_cannons - 1) / 2.0) * spacing
		var offset_forward = randf_range(-0.5, 0.5)
		var offset_vertical = randf_range(-0.2, 0.2)
		var delay = randf_range(0.0, max_delay)

		spawn_cannonball_with_delay(offset_side, offset_forward, offset_vertical, delay, forward, side, center)

func spawn_cannonball_with_delay(offset_side, offset_forward, offset_vertical, delay, forward, side, center):
	await get_tree().create_timer(delay).timeout

	var ball = cannonball_scene.instantiate()
	get_tree().current_scene.add_child(ball)

	ball.global_transform.origin = center + side * offset_side + forward * offset_forward + Vector3.UP * offset_vertical
	ball.linear_velocity = forward * trajectory_profile.speed
