extends Control
## On-screen controls for touch screens: drag anywhere on the left half to move
## (a soft stick appears under your thumb), tap the round button on the right to
## jump. Drives the existing input actions, so gameplay code needs no changes.
## Hidden until the first touch, so desktop players never see it.

const INK := Color("3b1a6b")
const CREAM := Color("fffaf0")
const CORAL := Color("f2766b")
const STICK_RADIUS := 80.0
const JUMP_RADIUS := 70.0
const DASH_RADIUS := 55.0

var _stick_finger := -1
var _stick_origin := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _jump_finger := -1
var _dash_finger := -1
## Set by the HUD while the game-over / win overlay is showing.
var restart_enabled := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _screen() -> Vector2:
	return get_viewport_rect().size


func _jump_center() -> Vector2:
	return _screen() - Vector2(130, 140)


func _dash_center() -> Vector2:
	return _screen() - Vector2(285, 115)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		visible = true
		if event.pressed:
			if event.position.distance_to(_jump_center()) < JUMP_RADIUS * 1.4:
				_jump_finger = event.index
				Input.action_press("jump")
			elif event.position.distance_to(_dash_center()) < DASH_RADIUS * 1.25:
				_dash_finger = event.index
				Input.action_press("dash")
			elif event.position.x < _screen().x * 0.5 and _stick_finger == -1:
				_stick_finger = event.index
				_stick_origin = event.position
				_stick_pos = event.position
			elif restart_enabled:
				# Any other tap restarts once the round is over.
				_tap_restart()
		else:
			if event.index == _jump_finger:
				_jump_finger = -1
				Input.action_release("jump")
			if event.index == _dash_finger:
				_dash_finger = -1
				Input.action_release("dash")
			if event.index == _stick_finger:
				_stick_finger = -1
				_apply_stick(Vector2.ZERO)
		queue_redraw()
	elif event is InputEventScreenDrag and event.index == _stick_finger:
		_stick_pos = event.position
		var v: Vector2 = (_stick_pos - _stick_origin) / STICK_RADIUS
		_apply_stick(v.limit_length(1.0))
		queue_redraw()


func _tap_restart() -> void:
	var ev := InputEventAction.new()
	ev.action = "restart"
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = "restart"
	up.pressed = false
	Input.call_deferred("parse_input_event", up)


func _apply_stick(v: Vector2) -> void:
	_set_axis("move_left", "move_right", v.x)
	_set_axis("move_forward", "move_back", v.y)


func _set_axis(neg: String, pos: String, value: float) -> void:
	if value < -0.15:
		Input.action_press(neg, -value)
		Input.action_release(pos)
	elif value > 0.15:
		Input.action_press(pos, value)
		Input.action_release(neg)
	else:
		Input.action_release(neg)
		Input.action_release(pos)


func _draw() -> void:
	var dc := _dash_center()
	draw_circle(dc, DASH_RADIUS, CORAL if _dash_finger != -1 else CREAM)
	draw_arc(dc, DASH_RADIUS, 0, TAU, 40, INK, 4.0, true)
	var dash_font := get_theme_default_font()
	var dash_width := dash_font.get_string_size("DASH", HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	draw_string(dash_font, dc + Vector2(-dash_width / 2, 8), "DASH", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
	var jc := _jump_center()
	var pressed := _jump_finger != -1
	draw_circle(jc + Vector2(0, 6), JUMP_RADIUS, INK.lerp(CREAM, 0.5))
	draw_circle(jc + (Vector2(0, 4) if pressed else Vector2.ZERO), JUMP_RADIUS, CORAL if pressed else CREAM)
	draw_arc(jc, JUMP_RADIUS, 0, TAU, 48, INK, 4.0, true)
	var font := get_theme_default_font()
	var fs := 26
	var tw := font.get_string_size("JUMP", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, jc + Vector2(-tw / 2, fs * 0.35), "JUMP", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)

	var base := _stick_origin if _stick_finger != -1 else Vector2(150, _screen().y - 150)
	var knob := base + (_stick_pos - _stick_origin).limit_length(STICK_RADIUS) if _stick_finger != -1 else base
	draw_circle(base, STICK_RADIUS, Color(CREAM, 0.45))
	draw_arc(base, STICK_RADIUS, 0, TAU, 48, Color(INK, 0.6), 3.0, true)
	draw_circle(knob, 34, CREAM)
	draw_arc(knob, 34, 0, TAU, 32, INK, 3.0, true)
