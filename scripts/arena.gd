extends Node3D
## Soft Play arena: round teal floor (top at y = 0), coral/cream rim,
## and a warm room floor below to land on once you are out.

var radius := 8.0

const TEAL := Color("3fc1b0")
const CORAL := Color("f2766b")
const CREAM := Color("fbecd3")
const ROOM_FLOOR := Color("e9b9a0")


const MAX_DENTS := 8

var _floor_mat: ShaderMaterial
var _dents: Array[Vector4] = []
var _next_dent := 0


func _ready() -> void:
	for i in MAX_DENTS:
		_dents.append(Vector4(0, 0, 0, 0))
	_build_floor()
	_build_rim()
	_build_room_floor()
	add_child(preload("res://scripts/room.gd").new())


## Press a soft dent into the quilted floor where someone landed (fades out).
func add_dent(world_pos: Vector3, strength: float) -> void:
	_dents[_next_dent] = Vector4(world_pos.x, world_pos.y, world_pos.z, clamp(strength, 0.0, 1.0))
	_next_dent = (_next_dent + 1) % MAX_DENTS


func _process(delta: float) -> void:
	for i in MAX_DENTS:
		var d := _dents[i]
		d.w = move_toward(d.w, 0.0, delta * 1.5)
		_dents[i] = d
	_floor_mat.set_shader_parameter("dents", _dents)


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
	mesh.material_override = _mat(TEAL.darkened(0.15))
	body.add_child(mesh)
	# Quilted top surface as a thin disc so the shader only covers the top.
	var top := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = radius - 0.05
	tm.bottom_radius = radius - 0.05
	tm.height = 0.02
	tm.radial_segments = 64
	top.mesh = tm
	_floor_mat = ShaderMaterial.new()
	_floor_mat.shader = preload("res://shaders/quilted_floor.gdshader")
	top.material_override = _floor_mat
	top.position.y = 0.5
	body.add_child(top)
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
