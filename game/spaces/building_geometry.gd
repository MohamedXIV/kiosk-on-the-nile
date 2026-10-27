@tool
class_name BuildingGeometry
extends RefCounted
## Derived cell membership shared by placement, rendering and authoring.
static func cell_map(space: Dictionary) -> Dictionary:
 if space.get("_building_cells") is Dictionary:return space._building_cells
 var owners: Dictionary={}
 var rooms: Dictionary={}
 for room in space.get("rooms",[]):rooms[room.id]=room.cells
 for building in space.get("buildings",[]):
  for room_id in building.room_ids:
   for cell in rooms.get(room_id,[]):owners[Vector2i(int(cell[0]),int(cell[1]))]=str(building.id)
 return owners
static func building_at(space: Dictionary, ground: Vector2) -> StringName:
 var origin := Vector2(space.origin[0],space.origin[1])
 var local := (ground-origin)/float(space.cell_size)
 return StringName(cell_map(space).get(Vector2i(floori(local.x),floori(local.y)),""))
static func environment_for(space: Dictionary, footprint: Rect2) -> StringName:
 var owners := cell_map(space)
 var scale := float(space.cell_size)
 var origin := Vector2(space.origin[0],space.origin[1])
 var start := (footprint.position-origin)/scale
 var end := (footprint.end-origin)/scale
 var first := "?"
 for x in range(floori(start.x+0.00001),ceili(end.x-0.00001)):
  for y in range(floori(start.y+0.00001),ceili(end.y-0.00001)):
   var owner := str(owners.get(Vector2i(x,y),""))
   if first=="?":first=owner
   elif first!=owner:return &"mixed"
 return &"exterior" if first=="" else &"interior"
static func validate_placement(space: Dictionary, item: Dictionary, footprint: Rect2, location_id: StringName) -> ActionResult:
 var policy: Dictionary=item.get("placement",{})
 var allowed: Array=policy.get("allowed_locations",[])
 if not allowed.is_empty() and not str(location_id) in allowed:return _fail("item_wrong_location")
 var environment := environment_for(space,footprint)
 if environment==&"mixed":return _fail("placement_crosses_building")
 var required := str(policy.get("environment","either"))
 if required!="either" and required!=str(environment):return _fail("placement_inside_only" if required=="interior" else "placement_outside_only")
 return ActionResult.success()
static func edge_height(space: Dictionary, edge: Dictionary) -> float:
 var scale := float(space.cell_size)
 var point := Vector2(space.origin[0],space.origin[1])+Vector2(edge.cell[0],edge.cell[1])*scale
 point+=(Vector2(float(edge.length)/2,0) if edge.axis=="x" else Vector2(0,float(edge.length)/2))*scale
 var normal := Vector2(0,scale/2) if edge.axis=="x" else Vector2(scale/2,0)
 var owner := building_at(space,point-normal)
 if owner.is_empty():owner=building_at(space,point+normal)
 for building in space.buildings:
  if str(building.id)==str(owner):return float(building.roof.height)
 return 1.7
static func _fail(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,StringName(key))
