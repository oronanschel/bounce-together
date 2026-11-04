extends Node3D
## Round manager for Last One Bouncing (first basic build).
## Builds the room, arena, player, camera and HUD from code so the scene
## file stays tiny and easy to merge. Falling off the arena = out; R restarts.

const Arena := preload("res://scripts/arena.gd")
const Player := preload("res://scripts/player.gd")
const Hud := preload("res://scripts/ui.gd")
const Fx := preload("res://scripts/fx.gd")

const ARENA_RADIUS := 8.0
const BOUNCER_COUNT := 7
const HIT_DISTANCE := 1.12
const HIT_COOLDOWN := 0.55
const OUT_HEIGHT := -0.8  # below the arena top (y = 0) means you fell off

var players: Array = []
var hud
var arena
var round_over := false
var hit_cooldowns := {}
var bot_think_time := 0.0


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
		remove_child(p)
		p.queue_free()
	players.clear()
	hit_cooldowns.clear()
	bot_think_time = 0.0
	round_over = false
	var visual := preload("res://scripts/character_visual.gd")
	for i in BOUNCER_COUNT:
		var p := Player.new()
		p.body_color = visual.PALETTE[i]
		p.set_meta("display_name", "You" if i == 0 else visual.NAMES[i])
		p.is_bot = i != 0
		var angle := TAU * float(i) / BOUNCER_COUNT
		p.position = Vector3(cos(angle) * 3.5, 1.5, sin(angle) * 3.5)
		add_child(p)
		if i == 0:
			var marker := Label3D.new()
			marker.text = "YOU"
			marker.position.y = 2.1
			marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			marker.font_size = 40
			marker.pixel_size = 0.02
			marker.outline_size = 8
			marker.modulate = Color.WHITE
			p.add_child(marker)
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


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		start_round()
		return
	if round_over:
		return

	bot_think_time -= delta
	if bot_think_time <= 0.0:
		_update_bots()
		bot_think_time = 0.3
	for key in hit_cooldowns.keys():
		hit_cooldowns[key] -= delta
		if hit_cooldowns[key] <= 0.0:
			hit_cooldowns.erase(key)
	_resolve_bumps()

	# Mark all falls first so simultaneous knockouts can produce a draw.
	var newly_out: Array = []
	for p in players:
		if not p.is_out and p.global_position.y < OUT_HEIGHT:
			p.is_out = true
			newly_out.append(p)
	if newly_out.is_empty():
		return
	var remaining := _remaining()
	hud.set_remaining(remaining)
	if remaining <= 1:
		round_over = true
		if remaining == 0:
			hud.show_game_over("Everyone bounced out!")
		else:
			for p in players:
				if not p.is_out:
					if p.is_bot:
						hud.show_win(p.get_meta("display_name", "Someone"), p.body_color)
					else:
						hud.show_game_over("You win!")
					break
	else:
		var p = newly_out.back()
		hud.flash_out(p.get_meta("display_name", "Someone"), p.body_color)


func _update_bots() -> void:
	for bot in players:
		if not bot.is_bot or bot.is_out:
			continue
		var nearest = null
		var nearest_distance := INF
		for other in players:
			if other == bot or other.is_out:
				continue
			var distance: float = bot.global_position.distance_squared_to(other.global_position)
			if distance < nearest_distance:
				nearest = other
				nearest_distance = distance
		if nearest == null:
			bot.bot_direction = Vector2.ZERO
			continue
		var toward: Vector3 = nearest.global_position - bot.global_position
		var steering := Vector2(toward.x, toward.z).normalized()
		var radial := Vector2(bot.global_position.x, bot.global_position.z)
		# Turn inward near the edge, but momentum from a bump can still knock out a bot.
		if radial.length() > ARENA_RADIUS - 2.0:
			steering -= radial.normalized() * 1.5
		bot.bot_direction = steering.normalized()
		bot.bot_jump = nearest_distance < 5.0 and randf() < 0.2


func _resolve_bumps() -> void:
	for i in players.size():
		var a = players[i]
		if a.is_out:
			continue
		for j in range(i + 1, players.size()):
			var b = players[j]
			if b.is_out:
				continue
			var key := Vector2i(i, j)
			if hit_cooldowns.has(key):
				continue
			var separation: Vector3 = b.global_position - a.global_position
			var horizontal := Vector2(separation.x, separation.z)
			if horizontal.length() > HIT_DISTANCE or abs(separation.y) > 1.2:
				continue
			var direction := horizontal.normalized() if horizontal.length() > 0.001 else Vector2.RIGHT
			var impulse := Vector3(direction.x, 0, direction.y) * 6.5
			a.knockback -= impulse
			b.knockback += impulse
			a.velocity.y = maxf(a.velocity.y, 2.0)
			b.velocity.y = maxf(b.velocity.y, 2.0)
			hit_cooldowns[key] = HIT_COOLDOWN
