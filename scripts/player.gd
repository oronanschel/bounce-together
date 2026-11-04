extends CharacterBody3D
## Placeholder bouncer: rounded capsule with little feet.
## WASD / arrows to move, Space to jump. The floor is springy:
## hard landings bounce you back up a little.

signal landed(impact: float)

var body_color := Color("8f5bd8")
var is_out := false

const SPEED := 6.0
const ACCEL := 30.0
const JUMP_VELOCITY := 9.0
const GRAVITY := 22.0
const BOUNCE := 0.45

var _was_on_floor := false
var _last_fall_speed := 0.0
var _visual: Node3D
var _squash := 0.0


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.5
	cap.height = 1.5
	shape.shape = cap
	shape.position.y = 0.75
	add_child(shape)

	_visual = Node3D.new()
	add_child(_visual)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.45
	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.5
	cm.height = 1.4
	body.mesh = cm
	body.material_override = mat
	body.position.y = 0.85
	_visual.add_child(body)
	for side in [-1, 1]:
		var foot := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.17
		sm.height = 0.26
		foot.mesh = sm
		foot.material_override = mat
		foot.position = Vector3(0.2 * side, 0.12, 0.05)
		_visual.add_child(foot)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		_last_fall_speed = max(_last_fall_speed, -velocity.y)

	var input := Vector2.ZERO
	if not is_out:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var target := Vector3(input.x, 0, input.y) * SPEED
	velocity.x = move_toward(velocity.x, target.x, ACCEL * delta)
	velocity.z = move_toward(velocity.z, target.z, ACCEL * delta)

	if is_on_floor() and not is_out and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		var impact := _last_fall_speed
		_last_fall_speed = 0.0
		_squash = clamp(impact / 15.0, 0.0, 0.5)
		landed.emit(impact)
		if impact > 4.0 and not is_out:
			velocity.y = impact * BOUNCE
	_was_on_floor = is_on_floor()

	if input.length() > 0.1:
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(input.x, input.y), 12.0 * delta)

	# Squash and stretch: squash on landing, stretch while moving fast vertically.
	_squash = move_toward(_squash, 0.0, 3.0 * delta)
	var stretch: float = clamp(abs(velocity.y) / 40.0, 0.0, 0.2) - _squash
	_visual.scale = Vector3(1.0 - stretch * 0.5, 1.0 + stretch, 1.0 - stretch * 0.5)
