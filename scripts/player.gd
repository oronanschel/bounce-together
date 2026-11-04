extends CharacterBody3D
## Placeholder bouncer: rounded capsule with little feet.
## WASD / arrows to move, Space to jump. The floor is springy:
## hard landings bounce you back up a little.

signal landed(impact: float)
signal launched(speed: float, timed: bool)

const CharacterVisual := preload("res://scripts/character_visual.gd")
const Tuning := preload("res://scripts/physics_tuning.gd")

var body_color := Color("8f5bd8")
var is_out := false
var is_bot := false
var bot_direction := Vector2.ZERO
var bot_jump := false
var impact_velocity := Vector3.ZERO
var _hit_control_time := 0.0

var _was_on_floor := false
var _last_fall_speed := 0.0
var _jump_buffer := 0.0
var _cushion_active := false
var _cushion_elapsed := 0.0
var _cushion_depth := 0.0
var _cushion_rebound := 0.0
var _cushion_timed := false
var _dash_requested := false
var _dash_cooldown := 0.0
var _last_direction := Vector2.DOWN
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


func _input(event: InputEvent) -> void:
	if is_bot or is_out or event.is_echo():
		return
	if event.is_action_pressed("jump"):
		_jump_buffer = Tuning.JUMP_BUFFER_SECONDS
	if event.is_action_pressed("dash"):
		_dash_requested = true


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		var gravity := Tuning.RISE_GRAVITY
		if velocity.y < 0.0:
			gravity *= Tuning.FALL_GRAVITY_MULTIPLIER
		velocity.y = maxf(-Tuning.TERMINAL_FALL_SPEED, velocity.y - gravity * delta)
		_last_fall_speed = max(_last_fall_speed, -velocity.y)

	var input := Vector2.ZERO
	if not is_out:
		if is_bot:
			input = bot_direction
		else:
			input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input.length_squared() > 0.01:
		_last_direction = input.normalized()
	_dash_cooldown = maxf(0.0, _dash_cooldown - delta)
	if not is_out and not is_bot and (_dash_requested or Input.is_action_just_pressed("dash")):
		try_dash(_last_direction)
	_dash_requested = false
	var target := Vector3(input.x, 0, input.y) * Tuning.MOVE_SPEED
	_hit_control_time = maxf(0.0, _hit_control_time - delta)
	var acceleration := Tuning.GROUND_ACCEL if is_on_floor() else Tuning.AIR_ACCEL
	if is_on_floor() and input.length_squared() < 0.01:
		acceleration = Tuning.GROUND_DECEL
	if _hit_control_time > 0.0:
		acceleration *= Tuning.HIT_CONTROL_FACTOR
	if _cushion_active:
		acceleration *= Tuning.CUSHION_ACCEL_FACTOR
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)

	_jump_buffer = maxf(0.0, _jump_buffer - delta)
	if not is_out and (bot_jump if is_bot else Input.is_action_just_pressed("jump")):
		_jump_buffer = Tuning.JUMP_BUFFER_SECONDS
	if _cushion_active:
		if _jump_buffer > 0.0 and not _cushion_timed:
			_cushion_rebound = minf(Tuning.MAX_TIMED_BOUNCE_VELOCITY, _cushion_rebound + Tuning.TIMED_BOUNCE_BONUS)
			_cushion_timed = true
			_jump_buffer = 0.0
		_cushion_elapsed += delta
		var phase := minf(_cushion_elapsed / Tuning.CUSHION_DURATION, 1.0)
		_visual.position.y = -_cushion_depth * sin(PI * phase)
		velocity.y = 0.0
		if phase >= 1.0:
			_cushion_active = false
			_visual.position.y = 0.0
			velocity.y = _cushion_rebound
			if velocity.y > 0.0:
				launched.emit(velocity.y, _cushion_timed)
	if is_on_floor() and not is_out and not _cushion_active and _was_on_floor and _jump_buffer > 0.0:
		velocity.y = Tuning.JUMP_VELOCITY
		_jump_buffer = 0.0
		launched.emit(velocity.y, false)

	impact_velocity = velocity
	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		var impact := _last_fall_speed
		_last_fall_speed = 0.0
		_visual.land(impact)
		landed.emit(impact)
		if not is_out:
			_cushion_active = true
			_cushion_elapsed = 0.0
			_cushion_depth = clampf(impact * Tuning.CUSHION_DEPTH_PER_SPEED, Tuning.CUSHION_MIN_DEPTH, Tuning.CUSHION_MAX_DEPTH)
			_cushion_rebound = impact * Tuning.BOUNCE_RATIO if impact >= Tuning.MIN_BOUNCE_IMPACT else 0.0
			_cushion_timed = _jump_buffer > 0.0
			if _cushion_timed:
				_cushion_rebound = minf(Tuning.MAX_TIMED_BOUNCE_VELOCITY, _cushion_rebound + Tuning.TIMED_BOUNCE_BONUS)
				_jump_buffer = 0.0
			velocity.y = 0.0
	_was_on_floor = is_on_floor()

	_visual.face(input, delta)
	_visual.set_motion(Vector2(velocity.x, velocity.z).length(), velocity.y, _ground_y())


## The same dash and cooldown apply to both player and computer opponents.
func try_dash(direction: Vector2) -> void:
	if is_out or _dash_cooldown > 0.0 or direction.length_squared() < 0.01:
		return
	var dash_dir := direction.normalized()
	apply_impulse(Vector3(dash_dir.x, 0, dash_dir.y) * Tuning.DASH_IMPULSE)
	_dash_cooldown = Tuning.DASH_COOLDOWN


## Impulses become velocity so steering can counter them instead of fighting wind.
func apply_impulse(impulse: Vector3) -> void:
	velocity += impulse
	_hit_control_time = Tuning.HIT_CONTROL_SECONDS


## Height of whatever is below us (for the blob shadow).
func _ground_y() -> float:
	var from := global_position + Vector3.UP * 0.2
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 30.0)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position.y if hit else global_position.y - 30.0
