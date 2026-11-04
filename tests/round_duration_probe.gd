extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for round_no in 10:
		if round_no > 0:
			game.start_round()
		var ticks := 0
		while not game.round_over and ticks < 5400:
			await physics_frame
			ticks += 1
		print("ROUND ", round_no + 1, " elapsed=", ticks / 60.0, " remaining=", game._remaining())
	quit()
