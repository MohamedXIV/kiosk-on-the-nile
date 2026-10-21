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
 if _mapping == null: return
 _x += delta*float(_config.speed)
 if _x > float(_config.wrap_right): _x = float(_config.wrap_left)
 position = _mapping.to_canvas(Vector2(_x,float(_config.depth)))
func _draw() -> void:
 draw_set_transform(Vector2(0,12),0,Vector2(26,7))
 draw_circle(Vector2.ZERO,1,Color(1,0.686,0.294,0.22))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 draw_colored_polygon(PackedVector2Array([Vector2(-42,0),Vector2(42,0),Vector2(28,12),Vector2(-28,12)]),Color("4e301b"))
 draw_colored_polygon(PackedVector2Array([Vector2(-6,-2),Vector2(26,-68),Vector2(-28,-10)]),Color("ebe4d8"))
 draw_circle(Vector2(10,-6),4,Color("ffae42"))
