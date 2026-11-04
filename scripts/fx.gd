extends RefCounted
## Small one-shot visual effects (landing puffs). Static helpers so gameplay
## code can call Fx.landing_puff(parent, pos, impact) without owning any FX nodes.


static func landing_puff(parent: Node, pos: Vector3, impact: float) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = int(clamp(impact * 1.5, 6, 24))
	p.lifetime = 0.45
	p.explosiveness = 1.0
	p.direction = Vector3(0, 0.3, 0)
	p.spread = 90.0
	p.flatness = 0.85
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 1.5 + impact * 0.25
	p.gravity = Vector3(0, -2, 0)
	p.damping_min = 3.0
	p.damping_max = 4.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	mesh.radial_segments = 8
	mesh.rings = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("fff7ea")
	mat.roughness = 1.0
	mesh.material = mat
	p.mesh = mesh
	parent.add_child(p)
	p.global_position = pos + Vector3(0, 0.1, 0)
	p.emitting = true
	p.finished.connect(p.queue_free)
