@tool
class_name GridPlacementRules
extends RefCounted
## Pure geometry used by both editor authoring and live placement.
static func footprint(record: Dictionary, definition: Dictionary, space: Dictionary) -> Rect2:
 var size: Array = definition.footprint
 var dimensions := Vector2(float(size[0]),float(size[1]))
 if int(record.rotation)%2==1: dimensions=Vector2(dimensions.y,dimensions.x)
 var origin: Array = space.origin
 var scale := float(space.cell_size)
 return Rect2(Vector2(origin[0],origin[1])+Vector2(record.cell[0],record.cell[1])*scale,dimensions*scale)
static func solid(rect: Rect2, id: String = "") -> Dictionary:
 return {"id":id,"kind":"rect","rect":[rect.position.x,rect.position.y,rect.end.x,rect.end.y]}
static func structure_solids(space: Dictionary, door_states: Dictionary, potential: bool = false) -> Array:
 var result: Array = []
 var scale := float(space.cell_size)
 var origin := Vector2(space.origin[0],space.origin[1])
 for wall in space.get("walls",[]):
  var start := origin+Vector2(wall.cell[0],wall.cell[1])*scale
  var size := Vector2(float(wall.length)*scale,0.08) if wall.axis=="x" else Vector2(0.08,float(wall.length)*scale)
  result.append(solid(Rect2(start-Vector2(0.04,0.04),size),str(wall.id)))
 for door in space.get("doors",[]):
  if door_states.get(door.id,door.get("open",true)) or (potential and door.get("usable",true)): continue
  var start := origin+Vector2(door.cell[0],door.cell[1])*scale
  var size := Vector2(float(door.length)*scale,0.08) if door.axis=="x" else Vector2(0.08,float(door.length)*scale)
  result.append(solid(Rect2(start-Vector2(0.04,0.04),size),str(door.id)))
 return result
static func validate(layout: Dictionary, request: PlacementRequest, catalog: Dictionary, actors: Array[Dictionary], structural_authoring: bool = false) -> ActionResult:
 if request==null or not catalog.spaces.has(str(request.location_id)): return _fail("invalid_destination")
 var instances: Dictionary = layout.get("instances",{})
 if not instances.has(str(request.instance_id)): return _fail("unknown_item")
 var definition_id := str(instances[str(request.instance_id)].definition_id)
 if not catalog.items.has(definition_id): return _fail("unknown_item")
 var definition: Dictionary = catalog.items[definition_id]
 if not structural_authoring and not definition.get("movable",false): return _fail("structure_dev_only")
 if request.rotation<0 or request.rotation>3: return _fail("invalid_rotation")
 var placements: Dictionary = layout.placements.duplicate(true)
 var previous: Dictionary = placements.get(str(request.instance_id),{})
 placements[str(request.instance_id)] = request.snapshot()
 # Idle mounted pieces move with their counter as one placement transaction.
 if not previous.is_empty():
  var turn := posmod(request.rotation-int(previous.rotation),4)
  var host_size: Array = definition.footprint
  var old_size := Vector2(host_size[0],host_size[1])
  if int(previous.rotation)%2==1: old_size=Vector2(old_size.y,old_size.x)
  var new_size := Vector2(old_size.y,old_size.x) if turn%2==1 else old_size
  var old_center := Vector2(previous.cell[0],previous.cell[1])+old_size/2
  var new_center := Vector2(request.cell)+new_size/2
  for id in placements:
   if placements[id].host_id!=str(request.instance_id): continue
   var child: Dictionary = placements[id]
   var child_definition: Dictionary = catalog.items[instances[id].definition_id]
   var child_size := Vector2(child_definition.footprint[0],child_definition.footprint[1])
   if int(child.rotation)%2==1: child_size=Vector2(child_size.y,child_size.x)
   var offset := Vector2(child.cell[0],child.cell[1])+child_size/2-old_center
   for i in range(turn): offset=Vector2(-offset.y,offset.x)
   if turn%2==1: child_size=Vector2(child_size.y,child_size.x)
   var new_cell := new_center+offset-child_size/2
   child.cell = [roundi(new_cell.x),roundi(new_cell.y)]
   child.rotation = posmod(int(child.rotation)+turn,4)
   child.location_id = str(request.location_id)
 var space: Dictionary = catalog.spaces[str(request.location_id)]
 var solids: Array = catalog.get("base_solids",{}).get(str(request.location_id),[]).duplicate(true)
 var potential_solids := solids.duplicate(true)
 solids.append_array(structure_solids(space,layout.get("door_states",{})))
 potential_solids.append_array(structure_solids(space,layout.get("door_states",{}),true))
 var footprints: Dictionary = {}
 var slots: Dictionary = {}
 for id in placements:
  var record: Dictionary = placements[id]
  if record.location_id!=str(request.location_id): continue
  if not instances.has(id): return _fail("invalid_placement")
  var item_definition: Dictionary = catalog.items[instances[id].definition_id]
  var box := footprint(record,item_definition,space)
  var bounds: Array = space.build_bounds
  if not Rect2(Vector2(bounds[0],bounds[1]),Vector2(bounds[2]-bounds[0],bounds[3]-bounds[1])).encloses(box): return _fail("outside_build_area")
  var environment := BuildingGeometry.validate_placement(space,item_definition,box,StringName(record.location_id))
  if not environment.ok:return environment
  if record.host_id!="":
   if not placements.has(record.host_id) or record.host_id==id: return _fail("missing_surface")
   var host: Dictionary = placements[record.host_id]
   var host_definition: Dictionary = catalog.items[instances[record.host_id].definition_id]
   if not host_definition.get("surface",false) or not item_definition.get("mountable",false) or host.location_id!=record.location_id or not footprint(host,host_definition,space).encloses(box): return _fail("incompatible_surface")
   var key: String = record.host_id+":"+record.slot_id
   if record.slot_id!="top" or slots.has(key): return _fail("surface_busy")
   slots[key]=id
   continue
  if item_definition.get("mountable",false): return _fail("requires_counter")
  for other in footprints.values():
   if box.intersects(other): return _fail("overlapping_item")
  for obstacle in solids:
   if obstacle.kind=="rect":
    var r: Array = obstacle.rect
    if box.intersects(Rect2(Vector2(r[0],r[1]),Vector2(r[2]-r[0],r[3]-r[1]))): return _fail("overlapping_structure")
   elif obstacle.kind=="circle":
    if box.grow(float(obstacle.radius)).has_point(Vector2(obstacle.center[0],obstacle.center[1])): return _fail("overlapping_structure")
  footprints[id]=box
  solids.append(solid(box,id))
  potential_solids.append(solid(box,id))
 for actor in actors:
  if actor.location_id!=str(request.location_id): continue
  var point := Vector2(actor.ground[0],actor.ground[1])
  # Only prevent collisions introduced by this request, including its children.
  for id in footprints:
   if (id==str(request.instance_id) or placements[id].host_id==str(request.instance_id)) and footprints[id].grow(0.18).has_point(point): return _fail("person_in_the_way")
 var connectivity := _reachable(space,potential_solids,actors,placements,catalog,instances,str(request.location_id))
 if not connectivity.ok: return connectivity
 return ActionResult.success({"placements":placements})
static func _reachable(space: Dictionary, solids: Array, actors: Array[Dictionary], placements: Dictionary, catalog: Dictionary, instances: Dictionary, location_id: String) -> ActionResult:
 var bounds: Array = space.navigation_bounds
 var scale := float(space.cell_size)
 var grid := AStarGrid2D.new()
 var start := Vector2i(floori(bounds[0]/scale),floori(bounds[1]/scale))
 var end := Vector2i(ceili(bounds[2]/scale),ceili(bounds[3]/scale))
 grid.region = Rect2i(start,end-start+Vector2i.ONE)
 grid.cell_size = Vector2.ONE*scale
 grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
 grid.update()
 for x in range(start.x,end.x+1):
  for y in range(start.y,end.y+1): grid.set_point_solid(Vector2i(x,y),FootprintGeometry.blocked(Vector2(x,y)*scale,solids,0.15))
 var exits: Array = space.exits
 var exit_point := _nearest(grid,Vector2(exits[0][0],exits[0][1]),scale)
 if not grid.region.has_point(exit_point): return _fail("blocked_exit")
 for target in exits:
  var target_point := Vector2i(roundi(target[0]/scale),roundi(target[1]/scale))
  if not grid.region.has_point(target_point) or grid.is_point_solid(target_point) or grid.get_id_path(exit_point,target_point).is_empty(): return _fail("blocked_exit")
 for actor in actors:
  if actor.location_id!=location_id: continue
  var point := _nearest(grid,Vector2(actor.ground[0],actor.ground[1]),scale)
  if not grid.region.has_point(point) or grid.get_id_path(point,exit_point).is_empty(): return _fail("trapped_person")
 for id in placements:
  if placements[id].location_id!=location_id: continue
  var definition: Dictionary = catalog.items[instances[id].definition_id]
  if not definition.get("surface",false) and definition.get("mountable",false): continue
  var box := footprint(placements[id],definition,space)
  var accessible := false
  for point in [Vector2(box.get_center().x,box.end.y+0.3),Vector2(box.get_center().x,box.position.y-0.3),Vector2(box.position.x-0.3,box.get_center().y),Vector2(box.end.x+0.3,box.get_center().y)]:
   var cell := Vector2i(roundi(point.x/scale),roundi(point.y/scale))
   if grid.region.has_point(cell) and not grid.is_point_solid(cell) and not grid.get_id_path(cell,exit_point).is_empty(): accessible=true;break
  if not accessible: return _fail("blocked_interaction")
 return ActionResult.success()
static func _nearest(grid: AStarGrid2D, point: Vector2, scale: float) -> Vector2i:
 var cell := Vector2i(roundi(point.x/scale),roundi(point.y/scale))
 for radius in range(4):
  for x in range(cell.x-radius,cell.x+radius+1):
   for y in range(cell.y-radius,cell.y+radius+1):
    var candidate := Vector2i(x,y)
    if grid.region.has_point(candidate) and not grid.is_point_solid(candidate): return candidate
 return Vector2i(-99999,-99999)
static func _fail(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,StringName(key))
