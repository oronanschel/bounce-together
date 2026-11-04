extends CanvasLayer
## HUD: title banner, remaining counter, game-over / restart prompt.

const INK := Color("3b1a6b")
const CREAM := Color("fffaf0")

var _remaining: Label
var _center: Label
var _card: PanelContainer
var _toast: Label
var _help: Label
var _touch


func _ready() -> void:
	var title := CloudBanner.new()
	title.text = "BOUNCE TOGETHER"
	add_child(title)

	var counter := _pill("1 remaining", 26)
	counter.grow_horizontal = Control.GROW_DIRECTION_END
	counter.position = Vector2(20, 20)
	add_child(counter)
	_remaining = counter.get_child(0)

	_touch = preload("res://scripts/touch_controls.gd").new()
	add_child(_touch)

	var help := Label.new()
	_help = help
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
	_card = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = CREAM
	sb.border_color = INK
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(48)
	sb.content_margin_left = 48
	sb.content_margin_right = 48
	sb.content_margin_top = 24
	sb.content_margin_bottom = 28
	sb.shadow_color = Color(INK, 0.25)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(0, 10)
	_card.add_theme_stylebox_override("panel", sb)
	_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	_card.visible = false
	_card.add_child(_center)
	add_child(_card)

	_toast = Label.new()
	_toast.add_theme_font_size_override("font_size", 34)
	_toast.add_theme_color_override("font_outline_color", CREAM)
	_toast.add_theme_constant_override("outline_size", 10)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.anchor_left = 0.5
	_toast.anchor_right = 0.5
	_toast.offset_left = -300
	_toast.offset_right = 300
	_toast.offset_top = 130
	_toast.modulate.a = 0.0
	add_child(_toast)


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
	_card.visible = false
	_toast.modulate.a = 0.0
	_touch.restart_enabled = false


func _restart_hint() -> String:
	return "Tap to bounce again" if _touch.visible else "Press R to bounce again"


func _process(_delta: float) -> void:
	_help.visible = not _touch.visible


func show_game_over(message: String) -> void:
	_center.remove_theme_color_override("font_color")
	_center.add_theme_color_override("font_color", INK)
	_center.text = message + "\n" + _restart_hint()
	_pop_card()
	_touch.restart_enabled = true


## Winner overlay for gameplay to call when one bouncer is left.
func show_win(winner_name: String, winner_color: Color = INK) -> void:
	_center.add_theme_color_override("font_color", winner_color.darkened(0.25))
	_center.text = "%s wins!\n%s" % [winner_name, _restart_hint()]
	_pop_card()
	_touch.restart_enabled = true


## Short "<name> is out!" pop under the title while the round continues.
func flash_out(player_name: String, color: Color = INK) -> void:
	_toast.text = "%s is out!" % player_name
	_toast.add_theme_color_override("font_color", color.darkened(0.3))
	_toast.modulate.a = 1.0
	_toast.scale = Vector2(0.6, 0.6)
	_toast.pivot_offset = Vector2(300, 20)
	var t := create_tween()
	t.tween_property(_toast, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(1.2)
	t.tween_property(_toast, "modulate:a", 0.0, 0.4)


func _pop_card() -> void:
	_card.visible = true
	_card.reset_size()
	_card.pivot_offset = _card.size / 2
	_card.scale = Vector2(0.5, 0.5)
	create_tween().tween_property(_card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Cloud-shaped title banner drawn from overlapping circles (no texture needed).
class CloudBanner:
	extends Control
	var text := ""
	const W := 440.0
	const H := 74.0

	func _ready() -> void:
		anchor_left = 0.5
		anchor_right = 0.5
		offset_left = -(W + 120) / 2
		offset_right = (W + 120) / 2
		offset_top = 6
		offset_bottom = 6 + H + 40
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _puffs() -> Array:
		var cx := size.x / 2
		var cy := 12 + H / 2
		var out := []
		var n := 9
		for i in n:
			var t := float(i) / (n - 1)
			var x := cx - W / 2 + t * W
			var r := H * (0.42 + 0.14 * sin(t * PI * 3.0 + 0.5))
			out.append([Vector2(x, cy - H * 0.12), r])
			out.append([Vector2(x + W / n / 2, cy + H * 0.16), H * 0.36])
		return out

	func _draw() -> void:
		var cream := Color("fffaf0")
		var ink := Color("3b1a6b")
		var sun := Color("f8cf5a")
		var cx := size.x / 2
		var cy := 12 + H / 2
		for side in [-1, 1]:
			for k in 3:
				var a: float = (-0.5 + k * 0.5) * 0.7
				var dir := Vector2(side * cos(a), sin(a))
				var start := Vector2(cx + side * (W / 2 + 30), cy) + dir * 6
				draw_line(start, start + dir * 22, sun, 6.0, true)
		for p in _puffs():
			draw_circle(p[0], p[1] + 4, ink.lerp(cream, 0.55))
		for p in _puffs():
			draw_circle(p[0], p[1], cream)
		var font := get_theme_default_font()
		var fs := 44
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos := Vector2(cx - tw / 2, cy + fs * 0.35)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, ink)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
