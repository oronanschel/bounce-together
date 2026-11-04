extends SceneTree

func _initialize() -> void:
	call_deferred("check_round")

func check_round() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	assert(game.players.size() == 7 and game._remaining() == 7)
	assert(not game.players[0].is_bot and game.players[1].is_bot)
	var a = game.players[0]
	var b = game.players[1]
	a.position = Vector3(0, 1, 0)
	b.position = Vector3(1, 1, 0)
	game._resolve_bumps()
	assert(a.knockback.x < 0 and b.knockback.x > 0)
	for i in range(1, 7):
		game.players[i].position.y = -1
	game._physics_process(0.016)
	assert(game._remaining() == 1 and game.round_over)
	game.start_round()
	assert(game.players.size() == 7 and game._remaining() == 7 and not game.round_over)
	for p in game.players:
		p.position.y = -1
	game._physics_process(0.016)
	assert(game._remaining() == 0 and game.round_over)
	print("ROUND CHECK PASSED")
	quit()
