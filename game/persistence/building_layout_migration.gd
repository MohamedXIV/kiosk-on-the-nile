class_name BuildingLayoutMigration
extends RefCounted
## Revision 4 -> 5. Work on a private candidate; identities and job clocks never change.
static func upgrade(source: Dictionary, config: SessionConfig) -> ActionResult:
 var state := source.duplicate(true)
 if not state.get("spaces") is Dictionary or not state.spaces.get("placements") is Dictionary or not state.get("items") is Dictionary or not state.items.get("items") is Dictionary or not state.items.get("containers") is Dictionary:return _fail("building_components")
 for component in ["workflow","equipment","cooking","hygiene","travel"]:
  if not state.get(component) is Dictionary:return _fail("building_"+component)
 for component in ["workflow","cooking"]:
  if not state[component].get("jobs") is Dictionary:return _fail("building_jobs")
  for job in state[component].jobs.values():
   if not job is Dictionary:return _fail("building_job")
   if component=="workflow" and not job.get("devices") is Dictionary:return _fail("building_devices")
 if not state.equipment.get("reservations") is Dictionary:return _fail("building_reservations")
 for lines in state.equipment.reservations.values():
  if not lines is Array:return _fail("building_reservation_lines")
  for line in lines:
   if not line is Dictionary:return _fail("building_reservation_line")
 var store := ItemStore.new()
 var result := store.configure(config.section("items"),config.section("containers"))
 if not result.ok:return result
 result=store.restore(state.items)
 if not result.ok:return result
 var definitions := config.section("spaces")
 for space in definitions.locations.values():space["_building_cells"]=BuildingGeometry.cell_map(space)
 var catalog := {"items":config.section("items"),"spaces":definitions.locations,"base_solids":definitions.base_solids}
 var old: Dictionary=state.spaces.placements
 var doors: Dictionary={}
 for space in definitions.locations.values():
  for door in space.doors:doors[door.id]=door.get("open",true)
 var layout := {"placements":{},"door_states":doors,"starter_granted":true,"instances":state.items.items}
 var roots: Array[String]=[]
 for id in old:
  var p: Variant=old[id]
  if not p is Dictionary or p.get("instance_id")!=id or not definitions.locations.has(str(p.get("location_id",""))) or not ContentValidation.vector(p.get("cell"),2) or not ContentValidation.integer(p.cell[0]) or not ContentValidation.integer(p.cell[1]) or not ContentValidation.integer(p.get("rotation")) or p.rotation<0 or p.rotation>3 or not p.get("host_id") is String or not p.get("slot_id") is String or not state.items.items.has(id):return _fail("building_placement")
  if state.items.items[id].container_id!=p.location_id+"_world":return _fail("building_owner")
  if p.host_id=="":roots.append(id)
  elif not old.get(p.host_id) is Dictionary or old[p.host_id].get("host_id")!="":return _fail("building_host")
 roots.sort()
 var protected := _protected(state)
 var pending: Array[String]=[]
 var report := {"moved":[],"stored":[],"actors":0}
 # Keep valid custom arrangements before finding homes for displaced units.
 for id in roots:
  var attempt := _place(layout,old,id,old[id],catalog)
  if attempt.ok:layout.placements=attempt.details.placements
  else:pending.append(id)
 pending.sort_custom(func(a,b):return a<b if protected.has(a)==protected.has(b) else protected.has(a))
 for id in pending:
  var found := false
  var original: Dictionary=old[id]
  var space: Dictionary=definitions.locations[original.location_id]
  var points: Array[Vector2i]=[]
  var bounds: Array=space.build_bounds
  var scale := float(space.cell_size)
  for x in range(ceili((bounds[0]-space.origin[0])/scale),floori((bounds[2]-space.origin[0])/scale)+1):
   for y in range(ceili((bounds[1]-space.origin[1])/scale),floori((bounds[3]-space.origin[1])/scale)+1):points.append(Vector2i(x,y))
  var origin := Vector2i(original.cell[0],original.cell[1])
  points.sort_custom(func(a,b):
   var da: int=a.distance_squared_to(origin)
   var db: int=b.distance_squared_to(origin)
   return da<db if da!=db else a.x<b.x if a.x!=b.x else a.y<b.y)
  for point in points:
   for turn in range(4):
    var p := original.duplicate(true)
    p.cell=[point.x,point.y]
    p.rotation=posmod(int(original.rotation)+turn,4)
    var attempt := _place(layout,old,id,p,catalog)
    if not attempt.ok:continue
    layout.placements=attempt.details.placements
    for member in _members(old,id):report.moved.append(member)
    found=true
    break
   if found:break
  if found:continue
  if protected.has(id):return _fail("building_no_room_for_active_unit:"+id)
  for member in _members(old,id):
   var storage := str(original.location_id)+"_furniture"
   if not state.items.containers.has(storage):return _fail("building_no_storage:"+member)
   state.items.items[member].container_id=storage
   report.stored.append(member)
 if state.hygiene.get("action") is Dictionary and not state.hygiene.action.is_empty():
  var target := str(state.hygiene.action.get("target_id",""))
  if target in report.moved or target in report.stored:state.hygiene.action["active"]=false
 state.spaces={"placements":layout.placements,"door_states":doors,"starter_granted":true}
 result=store.restore(state.items)
 if not result.ok:return result
 state.home=HomeService.new(store).snapshot()
 var spaces := SpaceService.new()
 result=spaces.configure(definitions,state.spaces,store,Callable(),Callable())
 if not result.ok:return _fail("building_final_layout:"+str(result.message_key))
 if not state.get("player_pose") is Dictionary or not state.get("visitors") is Dictionary or not state.visitors.get("visits") is Dictionary:return _fail("building_actors")
 var previous: Dictionary=state.player_pose.duplicate(true)
 result=_repair(state.player_pose,config,spaces,true)
 if not result.ok:return result
 if previous!=state.player_pose:
  report.actors+=1
  if state.get("hygiene") is Dictionary and state.hygiene.get("action") is Dictionary and not state.hygiene.action.is_empty():state.hygiene.action["active"]=false
 for visit in state.visitors.visits.values():
  if not visit is Dictionary or not visit.get("pose") is Dictionary or not ContentValidation.vector(visit.get("destination"),2):return _fail("building_visitor")
  previous=visit.pose.duplicate(true)
  result=_repair(visit.pose,config,spaces,false)
  if not result.ok:return result
  if previous!=visit.pose:report.actors+=1
  var destination: Dictionary=visit.pose.duplicate(true)
  destination.ground=visit.destination.duplicate()
  result=_repair(destination,config,spaces,false)
  if not result.ok:return result
  visit.destination=destination.ground
 if state.get("travel") is Dictionary and state.travel.get("journey") is Dictionary and not state.travel.journey.is_empty():
  if not state.travel.journey.get("origin_pose") is Dictionary:return _fail("building_journey")
  result=_repair(state.travel.journey.origin_pose,config,spaces,true)
  if not result.ok:return result
 return ActionResult.success({"state":state,"report":report})
static func _members(placements: Dictionary, root: String) -> Array[String]:
 var result: Array[String]=[root]
 for id in placements:
  if placements[id].host_id==root:result.append(id)
 result.sort()
 return result
static func _protected(state: Dictionary) -> Dictionary:
 var ids: Dictionary={}
 for job in state.get("workflow",{}).get("jobs",{}).values():
  if job is Dictionary and job.get("status")=="active":
   for id in job.get("devices",{}).values():ids[str(id)]=true
 for lines in state.get("equipment",{}).get("reservations",{}).values():
  if lines is Array:
   for line in lines:
    if line is Dictionary:ids[str(line.get("instance_id",""))]=true
 for id in state.get("cooking",{}).get("jobs",{}):
  if state.cooking.jobs[id].get("stage","EMPTY")!="EMPTY":ids[str(id)]=true
 for container in state.items.containers.values():
  if container.kind!="surface":continue
  for item in state.items.items.values():
   if item.container_id==container.id:ids[str(container.host_id)]=true
 var roots: Dictionary={}
 for id in ids:
  if state.spaces.placements.has(id):
   var p: Dictionary=state.spaces.placements[id]
   roots[p.host_id if p.host_id!="" else id]=true
 return roots
static func _place(layout: Dictionary, old: Dictionary, id: String, target: Dictionary, catalog: Dictionary) -> ActionResult:
 var candidate := layout.duplicate(true)
 for member in _members(old,id):candidate.placements[member]=old[member].duplicate(true)
 var request := PlacementRequest.from_dict(target)
 var cheap := GridPlacementRules.validate(candidate,request,catalog,[],false,false)
 if not cheap.ok:return cheap
 return GridPlacementRules.validate(candidate,request,catalog,[])
static func _repair(pose: Dictionary, config: SessionConfig, spaces: SpaceService, player: bool) -> ActionResult:
 var actor := ActorPose.new()
 var result := actor.restore(pose)
 if not result.ok:return result
 if not config.section("locations").has(str(actor.location_id)):
  if player and actor.location_id==&"transit":return ActionResult.success()
  for route in config.section("travel").routes.values():
   if player and route.kind=="shop" and str(actor.location_id)==str(route.destination):return ActionResult.success()
  return _fail("building_pose_location")
 var location: Dictionary=config.section("locations")[str(actor.location_id)]
 var bounds: Array=location.player_bounds if player else location.navigation_bounds
 var area := Rect2(Vector2(bounds[0],bounds[1]),Vector2(bounds[2]-bounds[0],bounds[3]-bounds[1]))
 var solids := spaces.solids(actor.location_id)
 var outside := func(point: Vector2):return player or spaces.building_at(actor.location_id,point)==&""
 if area.has_point(actor.ground) and not FootprintGeometry.blocked(actor.ground,solids,0.18) and outside.call(actor.ground):return ActionResult.success()
 var choices: Array[Vector2]=[]
 for x in range(ceili(bounds[0]/0.25),floori(bounds[2]/0.25)+1):
  for y in range(ceili(bounds[1]/0.25),floori(bounds[3]/0.25)+1):
   var point := Vector2(x,y)*0.25
   if not FootprintGeometry.blocked(point,solids,0.18) and outside.call(point):choices.append(point)
 var origin := actor.ground
 choices.sort_custom(func(a,b):
  var da: float=a.distance_squared_to(origin)
  var db: float=b.distance_squared_to(origin)
  return da<db if not is_equal_approx(da,db) else a.x<b.x if a.x!=b.x else a.y<b.y)
 var adjusted := location.duplicate(true)
 adjusted.solids=spaces.solids(actor.location_id,true)
 var navigation := KioskNavigation.new()
 navigation.configure(LocationDefinition.new(actor.location_id,adjusted),SpatialMapping.new(config.section("spatial")))
 var space: Dictionary=spaces.definitions().locations[str(actor.location_id)]
 var exit: Array=space.exits[0]
 for point in choices:
  if not navigation.path(point,Vector2(exit[0],exit[1])).is_empty():
   pose.ground=[point.x,point.y]
   return ActionResult.success()
 return _fail("building_no_actor_position")
static func _fail(reason: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"incompatible_save",{"reason":reason})
