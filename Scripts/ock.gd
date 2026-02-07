extends CharacterBody3D

@export var mouse_sens: float = 0.0025

@onready var pivot: Node3D = $Pivot

@export var push_speed: float = 12.0
@export var push_time: float = 0.14
@export var push_cooldown: float = 0.18
@export var friction: float = 14.0
@export var air_control: float = 0.25
@export var jump_velocity: float = 4.5
@export var require_floor_for_push: bool = true

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var _push_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _pushing_dir: Vector3 = Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# Timers
	if _push_timer > 0.0:
		_push_timer -= delta
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

	# Gravity
	if not is_on_floor():
		velocity.y -= _gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Movement input
	var input_vec := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	).normalized()

	var desired_dir := Vector3.ZERO
	if input_vec != Vector2.ZERO:
		desired_dir = (transform.basis * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()

	# Start a push (dash)
	var can_push := desired_dir != Vector3.ZERO and _push_timer <= 0.0 and _cooldown_timer <= 0.0
	if require_floor_for_push and not is_on_floor():
		can_push = false

	if Input.is_action_just_pressed("dash") and can_push:
		_push_timer = push_time
		_cooldown_timer = push_cooldown
		_pushing_dir = desired_dir

	# Apply movement
	if _push_timer > 0.0:
		velocity.x = _pushing_dir.x * push_speed
		velocity.z = _pushing_dir.z * push_speed
	else:
		# Slow down when not pushing
		var f := friction
		if not is_on_floor():
			f *= air_control

		velocity.x = move_toward(velocity.x, 0.0, f * delta)
		velocity.z = move_toward(velocity.z, 0.0, f * delta)

		# Small steering (optional)
		if desired_dir != Vector3.ZERO:
			var steer_mult := 1.0
			if not is_on_floor():
				steer_mult = air_control

			var steer := 8.0 * steer_mult
			velocity.x = move_toward(velocity.x, desired_dir.x * push_speed, steer * delta)
			velocity.z = move_toward(velocity.z, desired_dir.z * push_speed, steer * delta)
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Rotate player left/right
		rotate_y(-event.relative.x * mouse_sens)

		# Rotate pivot up/down
		pivot.rotate_x(-event.relative.y * mouse_sens)

		# Clamp vertical look
		pivot.rotation.x = clamp(
			pivot.rotation.x,
			deg_to_rad(-60),
			deg_to_rad(45)
		)
		
# Load Minion script so Godot knows its type
const Minion = preload("res://Scripts/minion.gd")

@export var ring_radius: float = 2.2

var minions: Array[Minion] = []

# ----------------------------------------------------
# ADD MINION
# ----------------------------------------------------
func add_minion(minion_scene: PackedScene) -> void:
	print("add_minion() called")

	var m: Minion = minion_scene.instantiate() as Minion
	get_tree().current_scene.add_child(m)

	minions.append(m)
	print("Total minions:", minions.size())

	_update_minion_slots()


# ----------------------------------------------------
# UPDATE FOLLOW POSITIONS
# ----------------------------------------------------
func _update_minion_slots() -> void:
	var count: int = minions.size()

	if count == 0:
		return

	# --- Assign follow offsets ---
	for i in range(count):
		var angle: float = TAU * float(i) / float(count)

		var local_offset: Vector3 = Vector3(
			sin(angle),
			0.0,
			cos(angle)
		) * ring_radius

		# Push them slightly behind player
		local_offset.z += 2.0

		var minion: Minion = minions[i]
		minion.target = self
		minion.slot_offset = local_offset

	# --- Assign neighbors (for separation) ---
	for i in range(count):
		var nlist: Array[CharacterBody3D] = []

		for j in range(count):
			if i != j:
				nlist.append(minions[j])

		minions[i].neighbors = nlist
