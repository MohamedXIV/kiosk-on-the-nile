class_name RiverView
extends Node2D
var _config: Dictionary
var _mapping: SpatialMapping
var _elapsed: float = 0.0
func configure(data: Dictionary, projection: SpatialMapping) -> void:
 _config = data
 _mapping = projection
func _process(delta: float) -> void:
 if not is_visible_in_tree():return
 _elapsed += delta
 queue_redraw()
func _draw() -> void:
 if _mapping == null: return
 var inverse := get_global_transform_with_canvas().affine_inverse()
 var start: Vector2 = inverse*Vector2.ZERO
 var end: Vector2 = inverse*get_viewport_rect().size
 var horizon := _mapping.to_canvas(Vector2(0,float(_config.horizon))).y
 draw_polygon(PackedVector2Array([start,Vector2(end.x,start.y),Vector2(end.x,horizon+20),Vector2(start.x,horizon+20)]),PackedColorArray([Color(_config.top),Color(_config.top),Color(_config.bottom),Color(_config.bottom)]))
 # A narrow hazy far bank stays distant. No animated windows, traffic or crowds.
 var bank_y := minf(start.y+32,horizon-160)
 draw_rect(Rect2(start.x,start.y,end.x-start.x,maxf(bank_y-start.y,0)),Color("17272d"))
 draw_line(Vector2(start.x,bank_y),Vector2(end.x,bank_y),Color("344349"),3)
 for i in range(20):
  var x := start.x+i*(end.x-start.x)/19
  var height := 4+fmod(float(i*17),13)
  draw_rect(Rect2(x,bank_y-height,26+fmod(float(i*13),30),height),Color("26373b"))
 for i in range(int(_config.shimmer_count)):
  var fraction := float(i)/maxf(float(_config.shimmer_count),1)
  var y := lerpf(bank_y+14,horizon-12,fraction)
  if y<=bank_y or y>=horizon-8:continue
  var x := lerpf(start.x,end.x,(sin(i*17.13)+1)*0.5)+sin(_elapsed*0.16+i)*9
  var width := 12+fraction*32+sin(_elapsed*0.4+i)*4
  draw_line(Vector2(x-width/2,y),Vector2(x+width/2,y),Color(0.61,0.68,0.67,0.05+fraction*0.035),1,true)
 draw_line(Vector2(start.x,horizon+2),Vector2(end.x,horizon+2),Color("262f30"),4)
