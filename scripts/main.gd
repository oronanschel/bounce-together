extends Node3D
## Round manager for Last One Bouncing (first basic build).
## Builds the room, arena, player, camera and HUD from code so the scene
## file stays tiny and easy to merge. Falling off the arena = out; R restarts.

const Arena := preload("res://scripts/arena.gd")
const Player := preload("res://scripts/player.gd")
const Hud := preload("res://scripts/ui.gd")
const Fx := preload("res://scripts/fx.gd")

const ARENA_RADIUS := 8.0
const OUT_HEIGHT := -0.8  # below the arena top (y = 0) means you fell off

var players: Array = []
var hud
var arena
var round_over := false


func _ready() -> void:
	_setup_input()
	_build_environment()
	arena = Arena.new()
	arena.radius = ARENA_RADIUS
	add_child(arena)
	hud = Hud.new()
	add_child(hud)
	_build_camera()
	start_round()


func _setup_input() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE],
		"restart": [KEY_R],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("f6dccd")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fff1e6")
	env.ambient_light_energy = 0.25
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_color = Color("fff4e8")
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	add_child(sun)


func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.fov = 50
	cam.position = Vector3(0, 11, 17)
	add_child(cam)
	cam.look_at(Vector3(0, -0.5, 0.5), Vector3.UP)
	cam.current = true


func start_round() -> void:
	for p in players:
		p.queue_free()
	players.clear()
	round_over = false
	var p := Player.new()
	p.body_color = preload("res://scripts/character_visual.gd").PALETTE[0]
	p.set_meta("display_name", preload("res://scripts/character_visual.gd").NAMES[0])
	p.position = Vector3(0, 1.5, 0)
	add_child(p)
	p.landed.connect(_on_player_landed.bind(p))
	players.append(p)
	hud.show_playing(_remaining())


func _on_player_landed(impact: float, p: Node3D) -> void:
	if impact < 2.0:
		return
	Fx.landing_puff(self, p.global_position, impact)
	if p.global_position.y > -0.2:
		arena.add_dent(p.global_position, impact / 12.0)


func _remaining() -> int:
	var n := 0
	for p in players:
		if not p.is_out:
			n += 1
	return n


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		start_round()
		return
	if round_over:
		return
	for p in players:
		if not p.is_out and p.global_position.y < OUT_HEIGHT:
			p.is_out = true
			hud.set_remaining(_remaining())
			if _remaining() > 0:
				hud.flash_out(p.get_meta("display_name", "Someone"), p.body_color)
	if _remaining() == 0:
		round_over = true
		hud.show_game_over("You bounced out!")
