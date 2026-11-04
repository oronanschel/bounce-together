extends Node3D
## Soft Play arena: round teal floor (top at y = 0), coral/cream rim,
## and a warm room floor below to land on once you are out.

var radius := 8.0

const TEAL := Color("3fc1b0")
const CORAL := Color("f2766b")
const CREAM := Color("fbecd3")
const ROOM_FLOOR := Color("f3cdb9")


func _ready() -> void:
	_build_floor()
	_build_rim()
	_build_room_floor()


func _mat(color: Color, rough := 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


func _build_floor() -> void:
	var body := StaticBody3D.new()
	body.name = "ArenaFloor"
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = 1.0
	shape.shape = cyl
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = 1.0
	cm.radial_segments = 64
	mesh.mesh = cm
	mesh.material_override = _mat(TEAL)
	body.add_child(mesh)
	body.position.y = -0.5
	add_child(body)


func _build_rim() -> void:
	# Visual-only inflatable rim: a torus with coral/cream stripes.
	var rim := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = radius - 0.45
	tm.outer_radius = radius + 0.45
	tm.rings = 96
	tm.ring_segments = 24
	rim.mesh = tm
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://shaders/rim_stripes.gdshader")
	rim.material_override = sm
	rim.position.y = 0.1
	add_child(rim)


func _build_room_floor() -> void:
	var body := StaticBody3D.new()
	body.name = "RoomFloor"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mesh.mesh = bm
	mesh.material_override = _mat(ROOM_FLOOR)
	body.add_child(mesh)
	body.position.y = -2.0
	add_child(body)
