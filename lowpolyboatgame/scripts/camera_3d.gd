extends Camera3D

@export var target_path: NodePath        # Drag the Boat node here
@export var follow_height: float = 20.0  # You can change in Inspector
@export var follow_distance: float = 50.0
@export var follow_speed: float = 5.0    # Higher = snappier camera

var target: Node3D

func _ready():
	if target_path != null:
		target = get_node(target_path)

func _process(delta):
	if target:
		var target_pos = target.global_transform.origin
		var desired_pos = target_pos + Vector3(0, follow_height, follow_distance)
		
		# Smoothly move towards desired position
		global_transform.origin = global_transform.origin.lerp(desired_pos, follow_speed * delta)
		
		# Look at the boat
		look_at(target_pos, Vector3.UP)
