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
  "stool": stool()
  "table": table()
  "lamp":
   var top := -float(definition.height)*mapping.height_scale
   ellipse(Vector2(0,2),Vector2(11,4),Color(0,0,0,0.2))
   draw_rect(Rect2(-4,top,8,-top),Color(definition.pole))
   draw_line(Vector2(-2,-3),Vector2(-2,top+5),Color("59605d"),1)
   draw_line(Vector2(0,top+2),Vector2(15,top+2),Color(definition.pole),5,true)
   draw_circle(Vector2(12,top+5),7,Color(definition.bulb))
   draw_colored_polygon(PackedVector2Array([Vector2(1,top+1),Vector2(6,top-6),Vector2(18,top-6),Vector2(23,top+1)]),Color("373d3c"))
   draw_rect(Rect2(-7,-10,14,10),Color("323937"))
  "railing":
   var top := -float(definition.height)*mapping.height_scale
   var half := float(definition.length)*mapping.x_scale/2
   draw_rect(Rect2(-half,top,half*2,7),Color(definition.color))
   draw_line(Vector2(-half,top+1),Vector2(half,top+1),Color("5d6966"),1)
   draw_line(Vector2(-half,top*0.38),Vector2(half,top*0.38),Color(definition.color),3)
   var x := -float(definition.length)/2+1
   while x < float(definition.length)/2:
    draw_rect(Rect2(x*mapping.x_scale-3,top,6,-top),Color(definition.color))
    draw_line(Vector2(x*mapping.x_scale-2,top+8),Vector2(x*mapping.x_scale-2,-4),Color("444b46"),1)
    x += float(definition.spacing)
 for detail in definition.get("details",[]):
  var offset: Array = detail.get("offset",[0,0,0])
  var anchor := mapping.to_canvas(Vector2(offset[0],offset[1]),float(offset[2]))
  if detail.kind == "rect":
   var rect: Array = detail.rect
   draw_rect(Rect2(anchor+Vector2(rect[0],rect[1]),Vector2(rect[2],rect[3])),Color(detail.color))
  elif detail.kind == "circle":
   draw_circle(anchor+Vector2(detail.center[0],detail.center[1]),float(detail.radius),Color(detail.color))
func stool() -> void:
 var top := -float(definition.height)*mapping.height_scale
 ellipse(Vector2(0,2),Vector2(14,6),Color(0,0,0,0.22))
 for x in [-9,9]:
  draw_line(Vector2(x,top+2),Vector2(x*1.25,0),Color(definition.pole),3,true)
 draw_line(Vector2(-10,top*0.35),Vector2(10,top*0.35),Color(definition.pole),2)
 ellipse(Vector2(0,top+3),Vector2(14,7),Color(definition.top).darkened(0.25))
 ellipse(Vector2(0,top),Vector2(14,7),Color(definition.top))
 draw_line(Vector2(-9,top-1),Vector2(9,top-1),Color(definition.top).lightened(0.18),1,true)
func table() -> void:
 var top := -float(definition.height)*mapping.height_scale
 var radius := Vector2(40,20)
 if definition.has("size"):
  radius=Vector2(minf(radius.x,float(definition.size[0])*mapping.x_scale/2),minf(radius.y,float(definition.size[1])*mapping.depth_scale/2))
 ellipse(Vector2(0,2),radius*Vector2(0.95,0.8),Color(0,0,0,0.23))
 for side in [-1,1]:
  var x := radius.x*0.58*float(side)
  draw_line(Vector2(x,top+2),Vector2(x+side*3,0),Color(definition.pole),4,true)
 draw_line(Vector2(-radius.x*0.6,top*0.4),Vector2(radius.x*0.6,top*0.4),Color(definition.pole),2)
 ellipse(Vector2(0,top+3),radius,Color(definition.top).darkened(0.3))
 ellipse(Vector2(0,top),radius,Color(definition.top))
 ellipse(Vector2(0,top),radius*0.88,Color(definition.top).lightened(0.04))
 # Modest pale paint scuffs stay on the surface; it is still an empty usable table.
 draw_line(Vector2(-radius.x*0.55,top+2),Vector2(-radius.x*0.3,top+3),Color(0.81,0.79,0.65,0.3),1,true)
func box() -> void:
 var size: Array = definition.size
 var width := float(size[0])*mapping.x_scale
 var depth := float(size[1])*mapping.depth_scale
 var height := float(size[2])*mapping.height_scale
 draw_rect(Rect2(-width/2+3,-depth/2+3,width,depth),Color(0,0,0,0.22))
 var front := Rect2(-width/2,depth/2-height,width,height)
 var front_color := Color(definition.front)
 draw_rect(front,front_color)
 draw_rect(front,front_color.darkened(0.35),false,1)
 if width>35 and height>16:
  draw_line(front.position+Vector2(2,3),front.position+Vector2(width-2,3),front_color.lightened(0.14),1)
  for x in range(int(-width/2)+20,int(width/2),26):
   draw_line(Vector2(x,front.position.y+5),Vector2(x,front.end.y-3),front_color.darkened(0.12),1)
 var top := Rect2(-width/2,-depth/2-height,width,depth)
 var top_color := Color(definition.top)
 draw_rect(top,top_color)
 draw_rect(top,top_color.darkened(0.35),false,1)
 if width>25 and depth>12:
  draw_line(top.position+Vector2(3,3),top.position+Vector2(width-3,3),top_color.lightened(0.16),1)
  draw_line(top.position+Vector2(5,depth-4),top.position+Vector2(width*0.3,depth-4),top_color.lightened(0.12),1)
func ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
 draw_set_transform(center,0,radius)
 draw_circle(Vector2.ZERO,1,color)
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
