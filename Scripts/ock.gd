extends CharacterBody3D

@export var speed := 6.0
@export var jump_velocity := 4.5
@export var mouse_sens := 0.0025

@onready var pivot: Node3D = $Pivot # Optional: a child Node3D for camera pitch
@onready var cam: Camera3D = $Pivot/Camera3D # Optional: camera under Pivot

var gravity := 10

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	# Mouse look 
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sens) # yaw
		pivot.rotate_x(-event.relative.y * mouse_sens) # pitch
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Movement input
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	).normalized()

	# Move relative to where the character is facing
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	move_and_slide()
