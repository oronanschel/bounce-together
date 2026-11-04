extends SceneTree

const Tuning := preload("res://scripts/physics_tuning.gd")
var launches: Array[float] = []
var pressed := false
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	for i in range(1, game.players.size()):
		game.players[i].set_physics_process(false)
		game.players[i].position = Vector3(30 + i * 2, 1, 0)
	var p = game.players[0]
	p.position = Vector3(0, 2, 0)
	p.velocity = Vector3.ZERO
	p.launched.connect(func(speed: float, timed: bool):
		if timed:
			launches.append(speed)
		pressed = false
	)
	for i in 1200:
		await physics_frame
		if p.velocity.y < 0 and p.position.y < 0.85 and not pressed:
			Input.action_press("jump")
			pressed = true
		elif Input.is_action_pressed("jump"):
			Input.action_release("jump")
		if launches.size() >= 3:
			break
	print("CHAIN CHECK PASSED: ", launches)
	assert(launches.size() >= 3 and launches[1] > launches[0] and launches[2] >= launches[1] and launches[2] <= Tuning.MAX_TIMED_BOUNCE_VELOCITY)
	quit()
