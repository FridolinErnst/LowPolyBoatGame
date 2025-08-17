extends RigidBody3D

@export var lifetime: float = 10.0

func _ready():
	# Connect to hit signal from the HitBox child
	var hitbox = $HitBox
	hitbox.connect("hit", _on_hit)

	# Auto-destruct after lifetime seconds
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_hit(body: Node) -> void:
	queue_free()
