class_name OrderGlyph
extends Control
var kind: String = "plate"
func _init() -> void:
 custom_minimum_size=Vector2(28,26)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
 var ink := Color("e6d6b8")
 match kind:
  "cup":
   draw_style_box(_cup_style(),Rect2(3,6,16,16))
   draw_arc(Vector2(20,12),5,-PI/2,PI/2,12,ink,2,true)
   draw_line(Vector2(8,1),Vector2(8,4),ink,1.5,true)
   draw_line(Vector2(13,0),Vector2(13,3),ink,1.5,true)
  "sandwich":
   draw_rect(Rect2(2,7,24,13),Color("b58951"))
   draw_line(Vector2(3,11),Vector2(25,11),ink,3,true)
   draw_line(Vector2(3,15),Vector2(25,15),Color("6f372b"),3,true)
  _:
   draw_arc(Vector2(14,14),10,0,TAU,24,ink,2,true)
   draw_arc(Vector2(14,14),6,0,TAU,24,ink,1,true)
func _cup_style() -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color=Color("b78e52")
 style.border_color=Color("e6d6b8")
 style.set_border_width_all(2)
 style.corner_radius_bottom_left=4
 style.corner_radius_bottom_right=4
 return style
