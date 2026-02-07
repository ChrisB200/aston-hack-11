extends Node3D

@export var linked_vent: Node3D
@export var cooldown := 0.3

var can_teleport := true

func _on_area_3d_body_entered(body):
	if not can_teleport:
		return

	if body is CharacterBody3D and linked_vent:
		teleport(body)

func teleport(player: CharacterBody3D):
	can_teleport = false
	linked_vent.can_teleport = false

	# Move player to exit
	player.global_position = linked_vent.get_node("ExitPoint").global_position

	# Stop momentum
	player.velocity = Vector3.ZERO

	# Match rotation (optional)
	player.global_rotation = linked_vent.global_rotation

	# Cooldown to prevent re-trigger
	await get_tree().create_timer(cooldown).timeout
	can_teleport = true
	linked_vent.can_teleport = true
