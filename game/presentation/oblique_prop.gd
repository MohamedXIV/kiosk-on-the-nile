class_name ObliqueProp
extends Node2D
var definition: Dictionary
var mapping: SpatialMapping
func configure(data: Dictionary, projection: SpatialMapping) -> void:
 definition = data.duplicate(true)
 mapping = projection
 queue_redraw()
func _draw() -> void:
 if definition.is_empty(): return
 var kind: String = definition.kind
 match kind:
  "box", "counter": box()
  "stool":
   var top := -float(definition.height)*mapping.height_scale
   draw_rect(Rect2(-4,top,8,-top),Color(definition.pole))
   ellipse(Vector2(0,top),Vector2(14,8),Color(definition.top))
  "table":
   var top := -float(definition.height)*mapping.height_scale
   ellipse(Vector2.ZERO,Vector2(38,18),Color(0,0,0,0.3))
   draw_rect(Rect2(-24,top,5,-top),Color(definition.pole))
   draw_rect(Rect2(19,top,5,-top),Color(definition.pole))
   ellipse(Vector2(0,top),Vector2(40,20),Color(definition.top))
  "lamp":
   var top := -float(definition.height)*mapping.height_scale
   draw_rect(Rect2(-4,top,8,-top),Color(definition.pole))
   draw_circle(Vector2(8,top),9,Color(definition.bulb))
  "railing":
   var top := -float(definition.height)*mapping.height_scale
   var half := float(definition.length)*mapping.x_scale/2
   draw_rect(Rect2(-half,top,half*2,7),Color(definition.color))
   var x := -float(definition.length)/2+1
   while x < float(definition.length)/2:
    draw_rect(Rect2(x*mapping.x_scale-3,top,6,-top),Color(definition.color))
    x += float(definition.spacing)
 for detail in definition.get("details",[]):
  var offset: Array = detail.get("offset",[0,0,0])
  var anchor := mapping.to_canvas(Vector2(offset[0],offset[1]),float(offset[2]))
  if detail.kind == "rect":
   var rect: Array = detail.rect
   draw_rect(Rect2(anchor+Vector2(rect[0],rect[1]),Vector2(rect[2],rect[3])),Color(detail.color))
  elif detail.kind == "circle":
   draw_circle(anchor+Vector2(detail.center[0],detail.center[1]),float(detail.radius),Color(detail.color))
func box() -> void:
 var size: Array = definition.size
 var width := float(size[0])*mapping.x_scale
 var depth := float(size[1])*mapping.depth_scale
 var height := float(size[2])*mapping.height_scale
 draw_rect(Rect2(-width/2+6,-depth/2+4,width,depth),Color(0,0,0,0.28))
 var front := Rect2(-width/2,depth/2-height,width,height)
 draw_rect(front,Color(definition.front))
 draw_rect(front,Color(0,0,0,0.35),false,1.5)
 var top := Rect2(-width/2,-depth/2-height,width,depth)
 draw_rect(top,Color(definition.top))
 draw_rect(top,Color(0,0,0,0.35),false,1.5)
func ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
 draw_set_transform(center,0,radius)
 draw_circle(Vector2.ZERO,1,color)
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
