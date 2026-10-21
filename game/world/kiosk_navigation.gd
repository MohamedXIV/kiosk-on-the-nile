class_name KioskNavigation
extends RefCounted
var _grid := AStarGrid2D.new()
var _definition: LocationDefinition
var _cell: float
var _clearance: float
func configure(definition: LocationDefinition, _mapping: SpatialMapping) -> void:
 _definition = definition
 _cell = float(definition.data.get("navigation_cell",0.25))
 _clearance = float(definition.data.get("navigation_clearance",0.2))
 var bounds: Array = definition.data.navigation_bounds
 var start := Vector2i(floori(float(bounds[0])/_cell),floori(float(bounds[1])/_cell))
 var end := Vector2i(ceili(float(bounds[2])/_cell),ceili(float(bounds[3])/_cell))
 _grid.region = Rect2i(start,end-start+Vector2i.ONE)
 _grid.cell_size = Vector2.ONE*_cell
 _grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
 _grid.update()
 for x in range(start.x,end.x+1):
  for y in range(start.y,end.y+1): _grid.set_point_solid(Vector2i(x,y),blocked(Vector2(x,y)*_cell))
func blocked(point: Vector2) -> bool:
 return FootprintGeometry.blocked(point,_definition.data.solids,_clearance)
func path(start: Vector2, goal: Vector2) -> PackedVector2Array:
 var first := _nearest_cell(start)
 var last := _nearest_cell(goal)
 if not _grid.region.has_point(first) or not _grid.region.has_point(last): return PackedVector2Array()
 return _grid.get_point_path(first,last)
func _nearest_cell(point: Vector2) -> Vector2i:
 var center := Vector2i(roundi(point.x/_cell),roundi(point.y/_cell))
 for radius in range(6):
  var best := Vector2i(-999999,-999999)
  var distance: float = INF
  for x in range(center.x-radius,center.x+radius+1):
   for y in range(center.y-radius,center.y+radius+1):
    var id := Vector2i(x,y)
    if _grid.region.has_point(id) and not _grid.is_point_solid(id):
     var value := (Vector2(id)*_cell).distance_squared_to(point)
     if value < distance: distance=value;best=id
  if distance < INF: return best
 return Vector2i(-999999,-999999)
