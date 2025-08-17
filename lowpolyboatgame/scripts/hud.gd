extends CanvasLayer

@onready var health_label: Label = $HealthLabel

func set_health(value: int) -> void:
	health_label.text = "Health: %d" % value
