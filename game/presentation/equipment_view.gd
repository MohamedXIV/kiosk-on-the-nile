class_name EquipmentView
extends Node2D
var instance_id: StringName
var session: GameSession
var _state: Dictionary={}
func configure(id: StringName, source: GameSession) -> void:
 instance_id=id
 session=source
func _process(_delta: float) -> void:
 if session==null:return
 _state=session.workflow.active_at(instance_id)
 queue_redraw()
func _draw() -> void:
 if _state.is_empty():return
 var step: Dictionary=_state.definition.steps[int(_state.step_index)]
 var ready := float(_state.elapsed)>=float(step.duration)
 var burnt := step.has("burnt_after") and float(_state.elapsed)>=float(step.burnt_after)
 var settings: Dictionary=session.config.section("atmosphere").equipment
 var color := Color(settings.burnt if burnt else settings.ready if ready else settings.working)
 draw_circle(Vector2.ZERO,6,color)
 draw_rect(Rect2(-18,10,36,4),Color(0.2,0.18,0.15))
 draw_rect(Rect2(-18,10,36*clampf(float(_state.elapsed)/maxf(float(step.duration),0.01),0,1),4),color)
