class_name SignView
extends Node2D
var _data: Dictionary
var _open: bool = false
var _label: Label
func configure(data: Dictionary, _mapping: SpatialMapping) -> void:
 _data = data
 _label = Label.new()
 _label.position = Vector2(-22,-14)
 _label.size = Vector2(44,26)
 _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 _label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 _label.add_theme_font_override("font",load(data.font_path))
 _label.add_theme_font_size_override("font_size",11)
 add_child(_label)
 present(false)
func present(is_open: bool) -> void:
 _open = is_open
 if _label: _label.text = ItemText.source("location.kiosk.sign."+("open_text" if is_open else "closed_text"),str(_data.open_text if is_open else _data.closed_text))
 queue_redraw()
func _draw() -> void:
 if _data.is_empty(): return
 draw_line(Vector2(-15,-14),Vector2(-8,-23),Color("90816b"),1,true)
 draw_line(Vector2(15,-14),Vector2(8,-23),Color("90816b"),1,true)
 draw_rect(Rect2(-24,-16,48,30),Color("68543c"))
 draw_rect(Rect2(-22,-14,44,26),Color(_data.open_color if _open else _data.closed_color).darkened(0.15))
 draw_line(Vector2(-22,-14),Vector2(22,-14),Color("bba47a"),1)
 for x in [-20,20]:draw_circle(Vector2(x,-12),1,Color("c2b399"))
