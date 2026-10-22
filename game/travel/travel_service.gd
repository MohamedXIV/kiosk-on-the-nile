class_name TravelService
extends RefCounted
signal changed
signal departed
signal returned(journey_id: StringName, bag_id: StringName, location_id: StringName)
var journey := JourneyState.new()
var _config: Dictionary
var _clock: GameClock
var _pose: ActorPose
var _inventory: InventoryService
var _locations: LocationRegistry
var _next_id: int=1
func configure(routes: Dictionary, clock: GameClock, pose: ActorPose, inventory: InventoryService, locations: LocationRegistry) -> ActionResult:
 if not routes.get("routes") is Dictionary or not ContentValidation.integer(routes.get("bag_capacity")) or routes.bag_capacity<1:return ContentValidation.fail("travel")
 for id in routes.routes:
  var route: Variant=routes.routes[id]
  if not route is Dictionary or not route.get("kind") in ["physical","shop"] or not route.get("from_locations") is Array or route.from_locations.is_empty() or not locations.kind(StringName(str(route.get("destination","")))) in [&"physical",&"shop"]:return ContentValidation.fail("travel.route")
  for value in ["outbound_minutes","return_minutes"]:
   if not ContentValidation.bounded(route.get(value),0.01,1440):return ContentValidation.fail("travel.duration")
  if route.has("arrival_ground"):
   if route.kind!="physical" or not ContentValidation.vector(route.arrival_ground,2):return ContentValidation.fail("travel.arrival")
   var bounds: Array=routes.physical_spawns[str(route.destination)].player_bounds
   if not Rect2(Vector2(bounds[0],bounds[1]),Vector2(bounds[2]-bounds[0],bounds[3]-bounds[1])).has_point(Vector2(route.arrival_ground[0],route.arrival_ground[1])):return ContentValidation.fail("travel.arrival_bounds")
 _config=routes.duplicate(true)
 _clock=clock
 _pose=pose
 _inventory=inventory
 _locations=locations
 return ActionResult.success()
func depart(route_id: StringName) -> ActionResult:
 if active() or not _locations.is_physical(_pose.location_id) or not _config.routes.has(str(route_id)):return _fail("journey_busy")
 var route: Dictionary=_config.routes[str(route_id)]
 if not str(_pose.location_id) in route.from_locations:return _fail("invalid_destination")
 var id := "journey_%d" % _next_id
 var bag_id := id+":bag" if route.kind=="shop" else ""
 if route.kind=="shop":
  var change := _inventory.items.candidate()
  change.state.containers[bag_id]={"id":bag_id,"location_id":str(_pose.location_id),"kind":"purchase_bag","capacity":int(_config.bag_capacity),"allowed_tags":["ingredient","equipment","furniture"],"host_id":""}
  var result := _inventory.items.commit(change)
  if not result.ok:return result
 _next_id+=1
 journey.data={"id":id,"route_id":str(route_id),"phase":"outbound","origin_pose":_pose.snapshot(),"return_location":str(_pose.location_id),"started_at":_clock.world_minutes,"due_at":_clock.world_minutes+float(route.outbound_minutes),"purchase_container_id":bag_id}
 departed.emit()
 _pose.location_id=&"transit"
 changed.emit()
 return ActionResult.success()
func begin_return() -> ActionResult:
 if journey.data.get("phase")!="browsing":return _fail("journey_busy")
 var route: Dictionary=_config.routes[journey.data.route_id]
 journey.data.phase="returning"
 journey.data.started_at=_clock.world_minutes
 journey.data.due_at=_clock.world_minutes+float(route.return_minutes)
 _pose.location_id=&"transit"
 changed.emit()
 return ActionResult.success()
func tick(_frame: Dictionary) -> void:
 if not journey.data.get("phase") in ["outbound","returning"] or _clock.world_minutes<float(journey.data.due_at):return
 var route: Dictionary=_config.routes[journey.data.route_id]
 if journey.data.phase=="outbound" and route.kind=="shop":
  journey.data.phase="browsing"
  _pose.location_id=StringName(route.destination)
 elif journey.data.phase=="returning":
  _pose.restore(journey.data.origin_pose)
  journey.data.phase="completed"
  _safe_return_pose()
  returned.emit(StringName(journey.data.id),StringName(journey.data.purchase_container_id),_pose.location_id)
 else:
  _pose.location_id=StringName(route.destination)
  var definition: Dictionary=_config.physical_spawns[str(_pose.location_id)]
  var arrival: Array=route.get("arrival_ground",definition.spawn)
  _pose.ground=Vector2(arrival[0],arrival[1])
  journey.data.phase="completed"
  _safe_return_pose()
 changed.emit()
func _safe_return_pose() -> void:
 if _inventory.spaces==null:return
 var solids := _inventory.spaces.solids(_pose.location_id)
 if not FootprintGeometry.blocked(_pose.ground,solids,0.18):return
 var candidates: Array[Vector2]=[]
 var bounds: Array=_config.physical_spawns[str(_pose.location_id)].player_bounds
 for x in range(ceili(bounds[0]/0.25),floori(bounds[2]/0.25)+1):
  for y in range(ceili(bounds[1]/0.25),floori(bounds[3]/0.25)+1):
   var point := Vector2(x,y)*0.25
   if not FootprintGeometry.blocked(point,solids,0.18):candidates.append(point)
 var origin := _pose.ground
 candidates.sort_custom(func(a,b):return a.distance_squared_to(origin)<b.distance_squared_to(origin))
 if not candidates.is_empty():_pose.ground=candidates[0]
func can_shop(shop_id: StringName) -> bool:
 if journey.data.get("phase")!="browsing":return false
 var route: Dictionary=_config.routes[journey.data.route_id]
 return str(route.get("shop_id",""))==str(shop_id) and _pose.location_id==StringName(route.destination)
func active() -> bool:
 return journey.data.get("phase","") in ["outbound","browsing","returning"]
func route() -> Dictionary:
 return _config.routes.get(journey.data.get("route_id",""),{}).duplicate(true)
func snapshot() -> Dictionary:
 return {"journey":journey.snapshot(),"next_id":_next_id}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("journey") is Dictionary or not ContentValidation.integer(data.get("next_id")) or data.next_id<1:return _fail("invalid_journey")
 var record: Dictionary=data.journey
 if not record.is_empty():
  if not record.get("id") is String or not _config.routes.has(str(record.get("route_id",""))) or not record.get("phase") in ["outbound","browsing","returning","completed"] or not record.get("origin_pose") is Dictionary or not _locations.is_physical(StringName(str(record.get("return_location","")))) or not record.get("purchase_container_id") is String:return _fail("invalid_journey")
  for key in ["started_at","due_at"]:
   if not ContentValidation.number(record.get(key)) or record[key]<0:return _fail("invalid_journey")
  if record.due_at<record.started_at or record.origin_pose.get("location_id")!=record.return_location:return _fail("invalid_journey")
  var suffix := str(record.id).trim_prefix("journey_")
  if not str(record.id).begins_with("journey_") or not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=int(data.next_id):return _fail("invalid_journey_counter")
  var origin := ActorPose.new()
  if not origin.restore(record.origin_pose).ok:return _fail("invalid_journey")
  var selected_route: Dictionary=_config.routes[record.route_id]
  if selected_route.kind=="shop" and _inventory.items.get_container(StringName(record.purchase_container_id)).get("kind")!="purchase_bag":return _fail("missing_purchase_bag")
 journey.data=record.duplicate(true)
 _next_id=int(data.next_id)
 return ActionResult.success()
func _fail(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,StringName(key))
