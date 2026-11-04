extends SceneTree

const Tuning := preload("res://scripts/physics_tuning.gd")

func _initialize() -> void:
	call_deferred("check_bounces")

func check_bounces() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	for i in range(1, game.players.size()):
		game.players[i].set_physics_process(false)
		game.players[i].position = Vector3(30 + i * 2, 1, 0)
	var p = game.players[0]
	p.position = Vector3(0, 0.5, 0)
	p.velocity = Vector3(0, -6, 0)
	var normal := await _wait_for_rebound(p)
	assert(normal >= Tuning.MIN_BOUNCE_VELOCITY - 0.01)
	# Fresh bouncer state so prior floor contacts cannot affect the timing check.
	game.start_round()
	p = game.players[0]
	for i in range(1, game.players.size()):
		game.players[i].set_physics_process(false)
		game.players[i].position = Vector3(30 + i * 2, 1, 0)
	p.position = Vector3(0, 0.5, 0)
	p.velocity = Vector3(0, -6, 0)
	Input.action_press("jump")
	var boosted := await _wait_for_rebound(p)
	Input.action_release("jump")
	assert(boosted > normal + 1.0)
	print("BOUNCE CHECK PASSED: normal=%.2f timed=%.2f" % [normal, boosted])
	quit()

func _wait_for_rebound(p: CharacterBody3D) -> float:
	for i in 60:
		await physics_frame
		if p.velocity.y > 0.0:
			return p.velocity.y
	assert(false, "No rebound observed")
	return 0.0
