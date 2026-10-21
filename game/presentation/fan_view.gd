class_name FanView
extends Node2D
var _config: Dictionary
var _mapping: SpatialMapping
var _elapsed: float = 0.0
var _angle: float = 0.0
var _running: bool = false
func configure(data: Dictionary, projection: SpatialMapping) -> void:
 _config = data
 _mapping = projection
func present(state: Dictionary) -> void:
 _running = state.get("fan_on",false)
 visible = state.get("has_fan",false)
func _process(delta: float) -> void:
 _elapsed += delta
 if _running: _angle += delta*float(_config.get("rotation_speed",21))
 queue_redraw()
func _draw() -> void:
 if _mapping == null: return
 var height := -float(_config.get("height",1.15))*_mapping.height_scale
 draw_set_transform(Vector2.ZERO,0,Vector2(16,9))
 draw_circle(Vector2.ZERO,1,Color("2b3a42"))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 draw_rect(Rect2(-3,height,6,-height),Color("d0d5d9"))
 var head := Vector2(sin(_elapsed*2.2)*7 if _running else 0.0,height)
 draw_set_transform(head,_angle,Vector2.ONE)
 draw_rect(Rect2(-16,-4,32,8),Color("88b4cc"))
 draw_rect(Rect2(-4,-16,8,32),Color("88b4cc"))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 draw_arc(head,18,0,TAU,48,Color("3d5a6c"),2,true)
 if _running:
  var y := 18+fmod(_elapsed*60,28)
  draw_line(head+Vector2(-14,y),head+Vector2(14,y+10),Color(0.63,0.86,1,0.28),1.5,true)
