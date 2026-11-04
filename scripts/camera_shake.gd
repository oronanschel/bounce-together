extends Camera3D
## Small trauma-based camera shake for big hits and hard landings.
## Call shake(0..1); several calls stack up to 1 and fade out quickly.

const MAX_OFFSET := 0.35  # metres at full trauma
const DECAY := 2.5  # trauma lost per second

var _trauma := 0.0
var _base := Vector3.ZERO
var _t := 0.0


func _ready() -> void:
	_base = position


func shake(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	_t += delta * 40.0
	_trauma = move_toward(_trauma, 0.0, DECAY * delta)
	var k := _trauma * _trauma * MAX_OFFSET
	h_offset = sin(_t * 1.3) * k
	v_offset = cos(_t * 1.7) * k
