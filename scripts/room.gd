extends Node3D
## Warm indoor soft-play room: peach walls, coral pillars, arched sky windows,
## pastel soft blocks. Decoration only (no collision) except the room floor in arena.gd.

const WALL := Color("f7d9c4")
const CORAL := Color("f2857a")
const SKY := Color("9fd8f5")
const FRAME := Color("f6e3b0")
const TEAL := Color("5cc8b5")
const YELLOW := Color("f8cf5a")
const PINK := Color("f59bb0")

const ROOM := 24.0  # half-size of the room
const WALL_H := 12.0


func _ready() -> void:
	_walls()
	for x in [-14.0, 0.0, 14.0]:
		_window(Vector3(x, 0, -ROOM + 0.05), 0.0)
	for z in [-12.0, 2.0]:
		_window(Vector3(-ROOM + 0.05, 0, z), PI / 2)
		_window(Vector3(ROOM - 0.05, 0, z), -PI / 2)
	for x in [-7.0, 7.0, -21.0, 21.0]:
		_cyl(Vector3(x, -1.5 + WALL_H / 2, -ROOM + 0.8), 0.9, WALL_H, CORAL)
	_cyl(Vector3(-16, -1.5 + 0.7, -10), 1.6, 1.4, TEAL)
	_cyl(Vector3(-12.5, -1.5 + 0.5, -6), 1.3, 1.0, YELLOW)
	_cyl(Vector3(-10, -1.5 + 0.4, -14), 1.4, 0.8, TEAL)
	_cyl(Vector3(15, -1.5 + 0.6, -4), 1.4, 1.2, YELLOW)
	_cyl(Vector3(12, -1.5 + 0.9, -15), 1.2, 1.8, TEAL)
	_cyl(Vector3(-15, -1.5 + 0.8, 6), 1.5, 1.6, YELLOW)
	_cyl(Vector3(16, -1.5 + 0.7, 7), 1.6, 1.4, TEAL)
	_arch(Vector3(15, -1.5, -10), PINK)


func _mat(color: Color, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


func _box(pos: Vector3, size: Vector3, color: Color, rot_y := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(color)
	mi.position = pos
	mi.rotation.y = rot_y
	add_child(mi)
	return mi


func _cyl(pos: Vector3, r: float, h: float, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 40
	mi.mesh = cm
	mi.material_override = _mat(color, 0.7)
	mi.position = pos
	add_child(mi)


func _walls() -> void:
	var y := -1.5 + WALL_H / 2
	_box(Vector3(0, y, -ROOM), Vector3(ROOM * 2, WALL_H, 0.2), WALL)
	_box(Vector3(-ROOM, y, 0), Vector3(0.2, WALL_H, ROOM * 2), WALL)
	_box(Vector3(ROOM, y, 0), Vector3(0.2, WALL_H, ROOM * 2), WALL)
	_box(Vector3(0, y, ROOM), Vector3(ROOM * 2, WALL_H, 0.2), WALL)


func _window(base: Vector3, rot_y: float) -> void:
	# Arched window: rectangular pane with a half-disc top, framed in cream.
	var holder := Node3D.new()
	holder.position = base
	holder.rotation.y = rot_y
	add_child(holder)
	var w := 4.0
	var bottom := 1.5
	var h := 3.0
	for layer in [[FRAME, 0.4, 0.0], [SKY, 0.0, 0.05]]:
		var col: Color = layer[0]
		var grow: float = layer[1]
		var z: float = layer[2] + 0.1
		var pane := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(w + grow, h + grow / 2, 0.05)
		pane.mesh = bm
		pane.material_override = _mat(col, 1.0)
		pane.position = Vector3(0, bottom + h / 2, z)
		holder.add_child(pane)
		var arc := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = (w + grow) / 2
		cm.bottom_radius = (w + grow) / 2
		cm.height = 0.05
		cm.radial_segments = 40
		arc.mesh = cm
		arc.material_override = _mat(col, 1.0)
		arc.rotation.x = PI / 2
		arc.position = Vector3(0, bottom + h, z)
		holder.add_child(arc)
	# Mullions
	for i in [-1, 1]:
		var bar := MeshInstance3D.new()
		var bb := BoxMesh.new()
		bb.size = Vector3(0.12, h + w / 2, 0.06)
		bar.mesh = bb
		bar.material_override = _mat(FRAME)
		bar.position = Vector3(i * 0.0, bottom + (h + w / 2) / 2, 0.2)
		holder.add_child(bar)
	var cross := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(w, 0.12, 0.06)
	cross.mesh = cb
	cross.material_override = _mat(FRAME)
	cross.position = Vector3(0, bottom + h * 0.6, 0.2)
	holder.add_child(cross)


func _arch(pos: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.2
	tm.outer_radius = 2.6
	tm.rings = 48
	mi.mesh = tm
	mi.material_override = _mat(color, 0.7)
	mi.rotation = Vector3(PI / 2, 0.4, 0)
	mi.position = pos
	add_child(mi)
