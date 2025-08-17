class_name HitBox
extends Area3D

signal hit(target: Node)

@export var damage: int = 1 : set = set_damage, get = get_damage

func set_damage(value: int):
	damage = value

func get_damage() -> int:
	return damage

func _ready():
	connect("area_entered", _on_area_entered)

func _on_area_entered(body: Node) -> void:
	print("sending signal")
	emit_signal("hit", body)
