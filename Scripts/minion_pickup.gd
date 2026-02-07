extends Area3D

@export var minion_scene: PackedScene

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.has_method("add_minion"):
		body.add_minion(minion_scene)
		queue_free()
