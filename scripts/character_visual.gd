extends Node3D
## Placeholder bouncer look: chunky rounded capsule with little feet, a soft
## blob shadow, walking feet and squash-and-stretch. Gameplay drives it with
## set_motion() each physics frame and land() on touchdown.

## Soft Play palette (concept order): purple, yellow, red, blue, green, pink, orange.
const PALETTE := [
	Color("9a5be0"), Color("f7cf3c"), Color("ef5b4f"), Color("3f8fea"),
	Color("7fd13b"), Color("f27bbf"), Color("f7962f"),
]
const NAMES := ["Purple", "Yellow", "Red", "Blue", "Green", "Pink", "Orange"]

var color := PALETTE[0]

var _body: MeshInstance3D
var _feet: Array[MeshInstance3D] = []
var _shadow: MeshInstance3D
var _squash := 0.0
var _walk := 0.0
var _speed := 0.0
var _vy := 0.0
var _height := 0.0


func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.35
	mat.rim_enabled = true
	mat.rim = 0.35
	mat.rim_tint = 0.3
	var foot_mat := StandardMaterial3D.new()
	foot_mat.albedo_color = color.darkened(0.12)
	foot_mat.roughness = 0.5

	_body = MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.55
	cm.height = 1.45
	cm.radial_segments = 32
	cm.rings = 12
	_body.mesh = cm
	_body.material_override = mat
	_body.position.y = 0.2 + cm.height / 2
	add_child(_body)

	for side in [-1, 1]:
		var foot := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.19
		sm.height = 0.28
		foot.mesh = sm
		foot.material_override = foot_mat
		foot.position = Vector3(0.22 * side, 0.13, 0.08)
		add_child(foot)
		_feet.append(foot)

	_shadow = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.55
	disc.bottom_radius = 0.55
	disc.height = 0.01
	_shadow.mesh = disc
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.05, 0.2, 0.2, 0.35)
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow.material_override = smat
	_shadow.top_level = true
	add_child(_shadow)


## horizontal_speed in m/s, vertical_velocity in m/s, ground_y = surface height below.
func set_motion(horizontal_speed: float, vertical_velocity: float, ground_y: float) -> void:
	_speed = horizontal_speed
	_vy = vertical_velocity
	_height = global_position.y - ground_y
	_shadow.global_position = Vector3(global_position.x, ground_y + 0.02, global_position.z)


func land(impact: float) -> void:
	_squash = clamp(impact / 14.0, 0.0, 0.55)


func face(direction: Vector2, delta: float) -> void:
	if direction.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.y), 12.0 * delta)


func _process(delta: float) -> void:
	_squash = move_toward(_squash, 0.0, 2.5 * delta)
	var stretch: float = clamp(abs(_vy) / 35.0, 0.0, 0.22) - _squash
	scale = Vector3(1.0 - stretch * 0.5, 1.0 + stretch, 1.0 - stretch * 0.5)

	var grounded := _height < 0.05
	if grounded and _speed > 0.5:
		_walk += delta * (6.0 + _speed * 1.6)
	else:
		_walk = move_toward(_walk, roundf(_walk / PI) * PI, delta * 8.0)
	for i in _feet.size():
		var phase := _walk + PI * i
		_feet[i].position.y = 0.13 + max(0.0, sin(phase)) * 0.14
		_feet[i].position.z = 0.08 + cos(phase) * 0.12 * min(_speed / 6.0, 1.0)
	_body.rotation.z = sin(_walk) * 0.06 * min(_speed / 6.0, 1.0)

	var s: float = clamp(1.0 - _height / 6.0, 0.35, 1.0)
	_shadow.scale = Vector3(s, 1, s)
	_shadow.visible = _height < 8.0
