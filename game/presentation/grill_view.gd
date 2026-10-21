class_name GrillView
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
 draw_rect(Rect2(-28,-16,56,24),Color(_style.get("body","#1f2024")))
 draw_rect(Rect2(-28,-16,56,24),Color("555555"),false,1)
 var stage: String = state.get("stage","EMPTY")
 if stage != "EMPTY":
  var fill := Color(_style.get("raw","#8b322c")) if stage == "SIDE_A" else Color(_style.get("cooked","#4f2412"))
  draw_rect(Rect2(-18,-11,36,14),fill)
  if stage == "SEASONED":
   draw_rect(Rect2(-10,-7,5,4),Color("7bb354"))
   draw_rect(Rect2(4,-5,5,4),Color("7bb354"))
