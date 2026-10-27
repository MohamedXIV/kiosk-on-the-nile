class_name RiverView
extends Node2D
var _config: Dictionary
var _mapping: SpatialMapping
var _elapsed: float = 0.0
func configure(data: Dictionary, projection: SpatialMapping) -> void:
 _config = data
 _mapping = projection
func _process(delta: float) -> void:
 _elapsed += delta
 queue_redraw()
func _draw() -> void:
 if _mapping == null: return
 var inverse := get_global_transform_with_canvas().affine_inverse()
 var start: Vector2 = inverse*Vector2.ZERO
 var end: Vector2 = inverse*get_viewport_rect().size
 var horizon := _mapping.to_canvas(Vector2(0,float(_config.horizon))).y
 draw_polygon(PackedVector2Array([start,Vector2(end.x,start.y),Vector2(end.x,horizon+20),Vector2(start.x,horizon+20)]),PackedColorArray([Color(_config.top),Color(_config.top),Color(_config.bottom),Color(_config.bottom)]))
 for i in range(int(_config.shimmer_count)):
  var point := _mapping.to_canvas(Vector2(sin(_elapsed+i*1.7)*10,-12+i*0.3))
  if point.y < horizon-8:
   var width := 28+sin(_elapsed*3+i)*14
   draw_line(point-Vector2(width/2,0),point+Vector2(width/2,0),Color(1,0.776,0.45,0.16),2,true)
