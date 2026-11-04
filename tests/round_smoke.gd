extends SceneTree

func _initialize() -> void:
	call_deferred("check_round")

func check_round() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	assert(game.players.size() == 7 and game._remaining() == 7)
	assert(not game.players[0].is_bot and game.players[1].is_bot)
	var original = game.players[0]
	var tap := InputEventAction.new()
	tap.action = "restart"
	tap.pressed = true
	game._input(tap)
	tap.pressed = false
	game._input(tap)
	game._physics_process(1.0 / 60.0)
	assert(game.players[0] != original, "A short restart tap was lost")
	var a = game.players[0]
	var jump_tap := InputEventAction.new()
	jump_tap.action = "jump"
	jump_tap.pressed = true
	a._input(jump_tap)
	jump_tap.pressed = false
	a._input(jump_tap)
	assert(a._jump_buffer > 0.0, "A short jump tap was lost")
	Input.action_press("dash")
	await physics_frame
	await physics_frame
	Input.action_release("dash")
	assert(Vector2(a.velocity.x, a.velocity.z).length() > 0.0)
	a.velocity = Vector3.ZERO
	var b = game.players[1]
	a.position = Vector3(0, 1, 0)
	b.position = Vector3(1, 1, 0)
	a.velocity = Vector3(6, 0, 0)
	a.impact_velocity = a.velocity
	game._resolve_bumps()
	assert(a.velocity.x < 6.0 and b.velocity.x > 2.0)
	var tuning = load("res://scripts/physics_tuning.gd")
	a.position = Vector3(tuning.ARENA_RADIUS - 0.2, 0.2, 0)
	a.velocity = Vector3(4, 0, 0)
	game._resolve_rim()
	assert(a.velocity.x < 0.0)
	game.rim_cooldowns.clear()
	a.velocity = Vector3(tuning.RIM_BREAK_SPEED + 1.0, 0, 0)
	game._resolve_rim()
	assert(a.velocity.x > tuning.RIM_BREAK_SPEED)
	a.position.y = -1
	game._physics_process(0.016)
	assert(a.is_out and game.hud._spectating.visible and game.hud._touch.restart_enabled)
	game.start_round()
	assert(not game.hud._spectating.visible and not game.hud._touch.restart_enabled)
	for i in range(1, 7):
		game.players[i].position.y = -1
	game._physics_process(0.016)
	assert(game._remaining() == 1 and game.round_over)
	game.start_round()
	assert(game.players.size() == 7 and game._remaining() == 7 and not game.round_over)
	for i in range(5):
		game.players[i].is_out = true
	game._update_bots()
	assert(not game.players[5].bot_jump and not game.players[6].bot_jump)
	game.start_round()
	for p in game.players:
		p.position.y = -1
	game._physics_process(0.016)
	assert(game._remaining() == 0 and game.round_over)
	print("ROUND CHECK PASSED")
	quit()
