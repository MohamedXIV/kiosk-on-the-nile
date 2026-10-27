class_name KettleView
extends Node2D
var _style: Dictionary = {}
var state: Dictionary = {}
func configure(data: Dictionary, _mapping: SpatialMapping) -> void:
 _style = data
 queue_redraw()
func present(value: Dictionary) -> void:
 state = value
 queue_redraw()
func _draw() -> void:
 draw_circle(Vector2(0,-10),13,Color(_style.get("body","#b87333")))
 draw_arc(Vector2(0,-10),13,0,TAU,32,Color("3d230d"),1.5,true)
 draw_circle(Vector2(0,-18),6,Color(_style.get("lid","#d99658")))
