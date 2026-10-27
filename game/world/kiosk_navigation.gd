class_name KioskNavigation
extends RefCounted
var _grid := AStarGrid2D.new()
var _definition: LocationDefinition
var _cell: float
var _clearance: float
var revision: int=0
var _walk_solids: Array=[]
func configure(definition: LocationDefinition, _mapping: SpatialMapping) -> void:
 revision+=1
 _definition = definition
 _cell = float(definition.data.get("navigation_cell",0.25))
 _clearance = float(definition.data.get("navigation_clearance",0.2))
 _walk_solids.clear()
 for solid: Dictionary in definition.data.solids:
  if solid.kind=="rect":
   var box: Array=solid.rect
   _walk_solids.append({"kind":"rect","rect":[float(box[0])-_clearance,float(box[1])-_clearance,float(box[2])+_clearance,float(box[3])+_clearance],"raw":box})
  elif solid.kind=="circle":_walk_solids.append({"kind":"circle","center":Vector2(solid.center[0],solid.center[1]),"radius":float(solid.radius)+_clearance,"raw_radius":float(solid.radius)})
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
func sight_clear(start: Vector2, goal: Vector2) -> bool:
 # Finite ground-space segment; no physics query or path search per observation.
 for solid: Dictionary in _definition.data.solids:
  if solid.kind=="rect":
   if _segment_crosses_box(start,goal,solid.rect):return false
  elif solid.kind=="circle":
   var center := Vector2(solid.center[0],solid.center[1])
   if Geometry2D.get_closest_point_to_segment(center,start,goal).distance_to(center)<=float(solid.radius):return false
 return true
func walkable_segment(start: Vector2, goal: Vector2) -> bool:
 var bounds: Array=_definition.data.navigation_bounds
 if goal.x<bounds[0] or goal.y<bounds[1] or goal.x>bounds[2] or goal.y>bounds[3]:return false
 for solid: Dictionary in _walk_solids:
  if solid.kind=="rect":
   if _segment_crosses_box(start,goal,solid.rect):
    # A legal physical pose may already hug a wall closer than the grid margin.
    # Let it leave/slide along that margin, never enter the actual solid.
    var initial := _box_distance_squared(start,solid.raw)
    if initial>0 and initial<=_clearance*_clearance and _box_distance_squared(goal,solid.raw)+0.0000001>=initial and not _segment_crosses_box(start,goal,solid.raw):continue
    return false
  elif solid.kind=="circle":
   var nearest := Geometry2D.get_closest_point_to_segment(solid.center,start,goal).distance_to(solid.center)
   if nearest<=float(solid.radius):
    var initial := start.distance_to(solid.center)
    if initial>float(solid.raw_radius) and initial<=float(solid.radius) and goal.distance_to(solid.center)+0.0000001>=initial and nearest>float(solid.raw_radius):continue
    return false
 return true
static func _box_distance_squared(point: Vector2, box: Array) -> float:
 return point.distance_squared_to(Vector2(clampf(point.x,box[0],box[2]),clampf(point.y,box[1],box[3])))
static func _segment_crosses_box(start: Vector2, goal: Vector2, box: Array) -> bool:
 # Clip a finite segment against the two slabs, without allocating edge arrays.
 var direction := goal-start
 var enter: float=0
 var leave: float=1
 for axis in range(2):
  if direction[axis]==0:
   if start[axis]<float(box[axis]) or start[axis]>float(box[axis+2]):return false
   continue
  var first := (float(box[axis])-start[axis])/direction[axis]
  var last := (float(box[axis+2])-start[axis])/direction[axis]
  enter=maxf(enter,minf(first,last))
  leave=minf(leave,maxf(first,last))
  if enter>leave:return false
 return true
func path(start: Vector2, goal: Vector2) -> PackedVector2Array:
 var first := _nearest_cell(start)
 var last := _nearest_cell(goal)
 if not _grid.region.has_point(first) or not _grid.region.has_point(last): return PackedVector2Array()
 var points := _grid.get_point_path(first,last)
 if not points.is_empty() and not blocked(goal) and points[points.size()-1].distance_to(goal)>0.001: points.append(goal)
 return points
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

func reachable(start: Vector2, goal: Vector2, radius: float = 0.12) -> bool:
 if blocked(goal):return false
 var cell := Vector2i(roundi(goal.x/_cell),roundi(goal.y/_cell))
 if not _grid.region.has_point(cell):return false
 var route := path(start,goal)
 return not route.is_empty() and route[route.size()-1].distance_to(goal)<=radius
