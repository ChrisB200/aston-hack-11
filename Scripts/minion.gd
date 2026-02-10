extends CharacterBody3D

@export var max_speed: float = 6.0
@export var accel: float = 20.0
@export var arrive_radius: float = 1.2
@export var stop_radius: float = 0.35
@export var separation_radius: float = 1.1
@export var separation_strength: float = 6.0

var target: Node3D
var slot_offset: Vector3 = Vector3.ZERO
var neighbors: Array[CharacterBody3D] = []

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
	if target == null:
		return

	# Gravity (only if using floor physics)
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	# Desired position relative to player
	var desired_pos: Vector3 = target.global_transform.origin \
		+ target.global_transform.basis * slot_offset

	var to_desired: Vector3 = desired_pos - global_transform.origin
	var dist: float = to_desired.length()

	# --- ARRIVE STEERING ---
	var desired_vel: Vector3 = Vector3.ZERO

	if dist > stop_radius:
		var speed: float = max_speed
		if dist < arrive_radius:
			speed = lerp(0.0, max_speed, dist / arrive_radius)

		desired_vel = to_desired.normalized() * speed

	# --- SEPARATION (avoid clumping) ---
	var sep: Vector3 = Vector3.ZERO

	for n in neighbors:
		if n == null:
			continue

		var away: Vector3 = global_transform.origin - n.global_transform.origin
		var d: float = away.length()

		if d > 0.001 and d < separation_radius:
			sep += away.normalized() * (1.0 - d / separation_radius)

	if sep != Vector3.ZERO:
		desired_vel += sep.normalized() * separation_strength

	# --- SMOOTH ACCELERATION ---
	velocity.x = move_toward(velocity.x, desired_vel.x, accel * delta)
	velocity.z = move_toward(velocity.z, desired_vel.z, accel * delta)

	# --- FACE MOVEMENT ---
	var flat: Vector3 = Vector3(velocity.x, 0.0, velocity.z)

	if flat.length() > 0.1:
		look_at(global_transform.origin + flat, Vector3.UP)

	move_and_slide()
