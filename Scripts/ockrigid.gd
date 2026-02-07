extends RigidBody3D

@export var push_impulse: float = 3.0
@export var turn_speed: float = 8.0

func _physics_process(delta):

	var input_vec := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	).normalized()

	if input_vec != Vector2.ZERO:
		var dir := (global_transform.basis * Vector3(input_vec.x, 0, input_vec.y)).normalized()
		var target_yaw := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)

	if Input.is_action_just_pressed("dash"):
		var forward := -global_transform.basis.z
		apply_central_impulse(forward * push_impulse)
