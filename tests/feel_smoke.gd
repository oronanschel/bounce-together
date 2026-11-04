extends SceneTree

func _initialize() -> void:
	call_deferred("check_feel")

func check_feel() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(1, game.players.size()):
		game.players[i].set_physics_process(false)
		game.players[i].position = Vector3(30 + i * 2, 1, 0)
	var p = game.players[0]
	p.position = Vector3(0, 2, 0)
	p.velocity = Vector3.ZERO
	var rebound := false
	var low_y := 0.0
	var apex := 0.0
	var max_sink := 0.0
	for i in 240:
		await physics_frame
		max_sink = maxf(max_sink, -p._visual.position.y)
		if not rebound and p.velocity.y > 0.0:
			rebound = true
			low_y = p.position.y
			apex = low_y
		elif rebound:
			apex = maxf(apex, p.position.y)
			if p.velocity.y <= 0.0:
				break
	assert(rebound and apex - low_y <= 1.2, "Passive rebound exceeded 60% of a 2-unit drop")
	assert(max_sink >= 0.12 and max_sink <= 0.4, "Cushion sink is outside its intended range")
	game.start_round()
	p = game.players[0]
	for i in range(1, game.players.size()):
		game.players[i].set_physics_process(false)
		game.players[i].position = Vector3(30 + i * 2, 1, 0)
	p.position = Vector3(0, 0.1, 0)
	Input.action_press("move_right")
	var midpoint := 0.0
	for i in 180:
		await physics_frame
		if i == 89:
			midpoint = p.position.x
	Input.action_release("move_right")
	assert(p.position.x >= midpoint - 0.5, "Holding toward the rim pushed the player backward")
	var max_backward := 0.0
	for i in 30:
		await physics_frame
		max_backward = maxf(max_backward, -p.velocity.x)
	assert(max_backward <= 2.0, "Rim pushed backward too strongly after release")
	assert(absf(p.velocity.x) < 0.5, "Player kept sliding after release")
	p.position = Vector3(0, 2, 0)
	p.velocity = Vector3.ZERO
	p.apply_impulse(Vector3(15, 0, 0))
	Input.action_press("move_left")
	for i in 36:
		await physics_frame
	Input.action_release("move_left")
	assert(p.velocity.x <= 0.0 and p._hit_control_time <= 0.0, "Player could not steer against a hit within 0.6 seconds")
	game.start_round()
	p = game.players[0]
	for i in range(1, game.players.size()):
		game.players[i].set_physics_process(false)
		game.players[i].position = Vector3(30 + i * 2, 1, 0)
	p.position = Vector3(10, 1, 0)
	p.velocity = Vector3.ZERO
	for i in 120:
		await physics_frame
		if p.is_out:
			break
	assert(p.is_out and game._remaining() == 6, "A bouncer falling beyond the arena was not eliminated")
	print("FEEL CHECK PASSED: rebound=%.2f sink=%.2f; rim, stop and outside fall passed" % [apex - low_y, max_sink])
	quit()
