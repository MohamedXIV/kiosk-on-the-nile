class_name BoatView
extends Node2D
var _config: Dictionary
var _mapping: SpatialMapping
var _x: float
func configure(data: Dictionary, projection: SpatialMapping) -> void:
 _config = data
 _mapping = projection
 _x = float(data.initial_x)
 position = _mapping.to_canvas(Vector2(_x,float(_config.depth)))
func _process(delta: float) -> void:
 if _mapping == null or not is_visible_in_tree(): return
 _x += delta*float(_config.speed)
 if _x > float(_config.wrap_right): _x = float(_config.wrap_left)
 position = _mapping.to_canvas(Vector2(_x,float(_config.depth)))
func _draw() -> void:
 draw_line(Vector2(-34,15),Vector2(35,15),Color(0.61,0.65,0.61,0.1),2,true)
 draw_line(Vector2(-20,20),Vector2(27,20),Color(0.61,0.65,0.61,0.05),1,true)
 draw_colored_polygon(PackedVector2Array([Vector2(-42,0),Vector2(42,0),Vector2(28,12),Vector2(-28,12)]),Color("4e4031"))
 draw_line(Vector2(-38,2),Vector2(38,2),Color("8c7855"),2,true)
 draw_line(Vector2(-6,0),Vector2(26,-68),Color("60594b"),2,true)
 draw_colored_polygon(PackedVector2Array([Vector2(-6,-3),Vector2(24,-65),Vector2(-28,-10)]),Color("c7c2af"))
 draw_line(Vector2(-20,-11),Vector2(21,-59),Color("a4a08e"),1,true)
