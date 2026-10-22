@tool
class_name BuildingContentValidation
extends RefCounted
static func validate(space: Dictionary) -> ActionResult:
 if not space.get("buildings") is Array:return ContentValidation.fail("spaces.buildings")
 var rooms: Dictionary={}
 for room in space.rooms:rooms[room.id]=room.cells
 var walls: Dictionary={}
 for wall in space.walls:walls[wall.id]=wall
 var ids: Dictionary={}
 var used: Dictionary={}
 for building in space.buildings:
  if not building is Dictionary or not building.get("id") is String or building.id=="" or ids.has(building.id) or not building.get("room_ids") is Array or building.room_ids.is_empty() or not building.get("roof") is Dictionary:return ContentValidation.fail("spaces.building")
  ids[building.id]=true
  if not ContentValidation.bounded(building.roof.get("height"),0.1,10) or not building.roof.get("color") is String or not Color.html_is_valid(building.roof.color):return ContentValidation.fail("spaces.roof")
  var occupied: Dictionary={}
  for id in building.room_ids:
   if not id is String or not rooms.has(id) or used.has(id):return ContentValidation.fail("spaces.building_rooms")
   used[id]=true
   for cell in rooms[id]:occupied[Vector2i(int(cell[0]),int(cell[1]))]=true
  if not building.get("service_windows",[]) is Array:return ContentValidation.fail("spaces.windows")
  var seen_windows: Dictionary={}
  for window in building.get("service_windows",[]):
   if not window is Dictionary or not walls.has(str(window.get("wall_id",""))) or seen_windows.has(window.wall_id) or not ContentValidation.bounded(window.get("sill_height"),0.1,float(building.roof.height)):return ContentValidation.fail("spaces.window")
   seen_windows[window.wall_id]=true
   var wall: Dictionary=walls[window.wall_id]
   for index in range(int(wall.length)):
    var cell := Vector2i(int(wall.cell[0]),int(wall.cell[1]))+(Vector2i(index,0) if wall.axis=="x" else Vector2i(0,index))
    var before := cell-(Vector2i(0,1) if wall.axis=="x" else Vector2i(1,0))
    if occupied.has(cell)==occupied.has(before):return ContentValidation.fail("spaces.window_not_boundary")
 return ActionResult.success()
