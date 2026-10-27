class_name FootprintGeometry
extends RefCounted
## Shared authored footprints for physics construction and native navigation occupancy.
static func blocked(point: Vector2, solids: Array, clearance: float = 0.0) -> bool:
 for solid in solids:
  if solid.kind == "rect":
   var box: Array = solid.rect
   if point.x >= box[0]-clearance and point.x <= box[2]+clearance and point.y >= box[1]-clearance and point.y <= box[3]+clearance: return true
  elif solid.kind == "circle":
   if point.distance_to(Vector2(solid.center[0],solid.center[1])) <= float(solid.radius)+clearance: return true
 return false
static func shape(solid: Dictionary, mapping: SpatialMapping) -> Shape2D:
 var polygon := ConvexPolygonShape2D.new()
 var points := PackedVector2Array()
 if solid.kind == "rect":
  var box: Array = solid.rect
  for point in [Vector2(box[0],box[1]),Vector2(box[2],box[1]),Vector2(box[2],box[3]),Vector2(box[0],box[3])]: points.append(mapping.to_canvas(point))
 else:
  for i in range(24):
   var angle := TAU*i/24.0
   points.append(mapping.to_canvas(Vector2(solid.center[0],solid.center[1])+Vector2(cos(angle),sin(angle))*float(solid.radius)))
 polygon.points = points
 return polygon
