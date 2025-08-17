extends Node


func _on_health_health_depleted() -> void:
	queue_free()
