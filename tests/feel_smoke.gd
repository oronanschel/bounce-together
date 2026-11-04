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
	for i in 240:
		await physics_frame
		if not rebound and p.velocity.y > 0.0:
			rebound = true
			low_y = p.position.y
			apex = low_y
		elif rebound:
			apex = maxf(apex, p.position.y)
			if p.velocity.y <= 0.0:
				break
	assert(rebound and apex - low_y <= 1.2, "Passive rebound exceeded 60% of a 2-unit drop")
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
	for i in 30:
		await physics_frame
	assert(absf(p.velocity.x) < 0.5, "Player kept sliding after release")
	print("FEEL CHECK PASSED: rebound height=%.2f; rim hold and stop passed" % (apex - low_y))
	quit()
