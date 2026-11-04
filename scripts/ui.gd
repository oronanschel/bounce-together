extends CanvasLayer
## HUD: title banner, remaining counter, game-over / restart prompt.

const INK := Color("3b1a6b")
const CREAM := Color("fffaf0")

var _remaining: Label
var _center: Label


func _ready() -> void:
	var title := _pill("BOUNCE TOGETHER", 40)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.position.y = 16
	add_child(title)

	var counter := _pill("1 remaining", 26)
	counter.grow_horizontal = Control.GROW_DIRECTION_END
	counter.position = Vector2(20, 20)
	add_child(counter)
	_remaining = counter.get_child(0)

	var help := Label.new()
	help.text = "WASD / arrows: move   Space: jump   R: restart"
	help.add_theme_color_override("font_color", INK)
	help.add_theme_font_size_override("font_size", 18)
	help.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	help.grow_horizontal = Control.GROW_DIRECTION_BOTH
	help.position.y -= 40
	add_child(help)

	_center = Label.new()
	_center.add_theme_color_override("font_color", INK)
	_center.add_theme_color_override("font_outline_color", CREAM)
	_center.add_theme_constant_override("outline_size", 12)
	_center.add_theme_font_size_override("font_size", 48)
	_center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_center.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_center)


func _pill(text: String, size: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = CREAM
	sb.border_color = INK
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(40)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", sb)
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", INK)
	label.add_theme_font_size_override("font_size", size)
	panel.add_child(label)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	return panel


func set_remaining(n: int) -> void:
	_remaining.text = "%d remaining" % n


func show_playing(n: int) -> void:
	set_remaining(n)
	_center.text = ""


func show_game_over(message: String) -> void:
	_center.text = message + "\nPress R to bounce again"
