class_name HygieneView
extends Node2D
var target_id: StringName
var service: HygieneService
var width: float=32
var _value: Dictionary={}
func configure(id: StringName, hygiene: HygieneService, visual_width: float) -> void:
 target_id=id
 service=hygiene
 width=visual_width
func _process(_delta: float) -> void:
 _value=service.state(target_id)
 queue_redraw()
func _draw() -> void:
 if _value.is_empty() or not _value.get("visible_dirt",false):return
 var amount := 1.0-float(_value.cleanliness)/100.0
 for i in range(3):draw_circle(Vector2((float(i)-1.0)*width/4,-8-float(i%2)*5),2+3*amount,Color(0.18,0.12,0.06,amount*0.6))
