extends CharacterBody3D
## Placeholder bouncer: rounded capsule with little feet.
## WASD / arrows to move, Space to jump. The floor is springy:
## hard landings bounce you back up a little.

signal landed(impact: float)

const CharacterVisual := preload("res://scripts/character_visual.gd")

var body_color := Color("8f5bd8")
var is_out := false

const SPEED := 6.0
const ACCEL := 30.0
const JUMP_VELOCITY := 9.0
const GRAVITY := 22.0
const BOUNCE := 0.45

var _was_on_floor := false
var _last_fall_speed := 0.0
var _visual


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.5
	cap.height = 1.5
	shape.shape = cap
	shape.position.y = 0.75
	add_child(shape)

	_visual = CharacterVisual.new()
	_visual.color = body_color
	add_child(_visual)


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
		_visual.land(impact)
		landed.emit(impact)
		if impact > 4.0 and not is_out:
			velocity.y = impact * BOUNCE
	_was_on_floor = is_on_floor()

	_visual.face(input, delta)
	_visual.set_motion(Vector2(velocity.x, velocity.z).length(), velocity.y, _ground_y())


## Height of whatever is below us (for the blob shadow).
func _ground_y() -> float:
	var from := global_position + Vector3.UP * 0.2
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 30.0)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position.y if hit else global_position.y - 30.0
