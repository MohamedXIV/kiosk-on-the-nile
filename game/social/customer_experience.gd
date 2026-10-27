class_name CustomerExperience
extends RefCounted
signal changed(location_id: StringName)
var visit_provider: Callable
var _data: Dictionary
var _hygiene: HygieneService
var _spaces: SpaceService
var _clock: GameClock
var _active: Dictionary={}
var _recent: Dictionary={}
var _customers: Dictionary={}
var _closed: Dictionary={}
var _navigation: Dictionary={}
func configure(data: Dictionary, hygiene: HygieneService, spaces: SpaceService, clock: GameClock) -> ActionResult:
 _data=data.duplicate(true)
 _hygiene=hygiene
 _spaces=spaces
 _clock=clock
 spaces.changed.connect(func(id,_revision):_navigation.erase(str(id)))
 return ActionResult.success()
func observe(visit_id: StringName, actor_pose: ActorPose) -> ActionResult:
 var visit: VisitState=visit_provider.call(visit_id) if visit_provider.is_valid() else null
 if visit==null or visit.pose!=actor_pose or _closed.has(str(visit_id)):return _fail("unknown_experience_visit")
 if not _active.has(str(visit_id)):
  _active[str(visit_id)]={"id":str(visit_id),"character_id":str(visit.character_id),"location_id":str(actor_pose.location_id),"observations":{},"last_observed_at":-1.0,"order_id":"","order_started_at":-1.0,"patience":0.0,"timing_known":false,"food":{}}
 var record: Dictionary=_active[str(visit_id)]
 if record.last_observed_at>=0 and _clock.world_minutes-float(record.last_observed_at)<float(_data.observe_interval):return ActionResult.success()
 record.last_observed_at=_clock.world_minutes
 var floor_id := "floor:"+str(actor_pose.location_id)
 var floor := _hygiene.state(StringName(floor_id))
 if not floor.is_empty():record.observations[floor_id]={"target_id":floor_id,"category":"floor","cleanliness":floor.cleanliness,"at":_clock.world_minutes}
 var solids := _spaces.solids(actor_pose.location_id)
 for id in _spaces.snapshot().placements:
  var placed := _spaces.placement(StringName(id))
  if placed.location_id!=str(actor_pose.location_id):continue
  var item: Dictionary=_spaces.item_record(StringName(id))
  var category := str(_data.categories.get(item.get("definition_id",""),""))
  if category.is_empty():continue
  var point := _spaces.ground(StringName(id))
  if actor_pose.ground.distance_to(point)>float(_data.observe_radius):continue
  if not _visible(actor_pose.ground,point,id,str(placed.host_id),solids):continue
  if _nav(actor_pose.location_id).path(actor_pose.ground,point).is_empty():continue
  var state := _hygiene.state(StringName(id))
  if not state.is_empty():record.observations[id]={"target_id":id,"category":category,"cleanliness":state.cleanliness,"at":_clock.world_minutes}
 return ActionResult.success()
func record_order(visit_id: StringName, order_id: StringName, created_at: float, patience: float) -> ActionResult:
 if not _active.has(str(visit_id)) or patience<=0:return _fail("unknown_experience_visit")
 var record: Dictionary=_active[str(visit_id)]
 if record.order_id!="" and record.order_id!=str(order_id):return _fail("experience_order_changed")
 record.order_id=str(order_id)
 record.order_started_at=created_at
 record.patience=patience
 record.timing_known=created_at>=0
 return ActionResult.success()
func record_service(visit_id: StringName, receipt: Dictionary) -> ActionResult:
 if not _active.has(str(visit_id)):return _fail("unknown_experience_visit")
 var record: Dictionary=_active[str(visit_id)]
 if record.order_id!=receipt.get("order_id") or not receipt.get("item_id") is String or not receipt.get("food_id") is String or not ContentValidation.integer(receipt.get("quality")) or receipt.quality<0 or receipt.quality>3 or not ContentValidation.number(receipt.get("served_at")):return _fail("invalid_experience_service")
 if not record.food.is_empty():return ActionResult.success({"duplicate":true}) if record.food.item_id==receipt.item_id else _fail("experience_second_service")
 record.food=receipt.duplicate(true)
 return ActionResult.success()
func close_visit(visit_id: StringName, reason: StringName, ended_at: float) -> ActionResult:
 if _closed.has(str(visit_id)):return ActionResult.success({"duplicate":true})
 if not _active.has(str(visit_id)):return _fail("unknown_experience_visit")
 var record: Dictionary=_active[str(visit_id)]
 var components: Dictionary={}
 var environment := _environment(record.observations)
 if environment>=0:components["environment"]=environment
 if not record.food.is_empty():
  record.food["score"]=float(_data.quality_scores[int(record.food.quality)])
  components["food"]=record.food.score
 var wait_end := float(record.food.served_at) if not record.food.is_empty() else ended_at
 if record.timing_known and record.order_id!="":components["wait"]=clampf(100.0*(1.0-maxf(0,wait_end-float(record.order_started_at))/float(record.patience)),0,100)
 var weights: Dictionary=_data.weights.duplicate(true)
 var sensitivity: Dictionary=_data.sensitivities.get(record.character_id,{})
 for key in weights:weights[key]=float(weights[key])*float(sensitivity.get(key,1.0))
 var summary := {"visit_id":str(visit_id),"character_id":record.character_id,"location_id":record.location_id,"ended_at":ended_at,"reason":str(reason),"components":components,"weights":weights,"observations":record.observations.duplicate(true),"wait":{"order_id":record.order_id,"created_at":record.order_started_at,"closed_at":wait_end,"patience":record.patience,"timing_known":record.timing_known},"food":record.food.duplicate(true),"score":_weighted(components,weights)}
 var history: Array=_recent.get(record.location_id,[])
 history.append(summary)
 _recent[record.location_id]=history.slice(maxi(0,history.size()-int(_data.window)))
 var previous: Dictionary=_customers.get(record.character_id,{})
 _customers[record.character_id]={"last_visit":summary.duplicate(true),"last_food":summary.duplicate(true) if not record.food.is_empty() else previous.get("last_food",{}).duplicate(true)}
 _closed[str(visit_id)]=true
 _active.erase(str(visit_id))
 _hygiene.record_use(StringName("visit:"+str(visit_id)),StringName("floor:"+record.location_id),&"visit")
 changed.emit(StringName(record.location_id))
 return ActionResult.success({"summary":summary.duplicate(true)})
func context(visit_id: StringName) -> Dictionary:
 var record: Dictionary=_active.get(str(visit_id),{})
 if record.is_empty():return {}
 var previous: Dictionary=_customers.get(record.character_id,{})
 var last: Dictionary=previous.get("last_visit",{})
 var food: Dictionary=previous.get("last_food",{})
 var current := _environment(record.observations)
 var dirty := false
 var dirty_category := ""
 var lowest := float(_data.dirty_below)
 for value in record.observations.values():
  if float(value.cleanliness)<lowest:dirty=true;dirty_category=str(value.category);lowest=float(value.cleanliness)
 var improved: bool=not last.is_empty() and current>=0 and last.components.has("environment") and current-float(last.components.environment)>=float(_data.improvement_delta)
 return {"visit_id":str(visit_id),"dirty_observed":dirty,"dirty_category":dirty_category,"improved_observed":improved,"food_memory":not food.is_empty(),"previous_visit_id":str(last.get("visit_id","")),"food_visit_id":str(food.get("visit_id","")),"previous_food_id":str(food.get("food",{}).get("food_id","")),"previous_food_quality":int(food.get("food",{}).get("quality",-1)),"environment":current}
func reputation(location_id: StringName) -> Dictionary:
 var history: Array=_recent.get(str(location_id),[])
 history=history.slice(maxi(0,history.size()-int(_data.window)))
 var scores: Array=[]
 for summary in history:
  if summary.score>=0:scores.append(float(summary.score))
 if scores.is_empty():return {"rated":false,"score":0.0,"count":0,"label":_data.labels.unrated}
 var total := 0.0
 for score in scores:total+=score
 var score := total/scores.size()
 return {"rated":true,"score":score,"count":scores.size(),"label":_data.labels.good if score>=float(_data.good_above) else _data.labels.poor if score<float(_data.poor_below) else _data.labels.okay}
func demand_factor(location_id: StringName) -> float:
 var value := reputation(location_id)
 return 1.0 if not value.rated else float(_data.recovery_floor)+(1.0-float(_data.recovery_floor))*float(value.score)/100.0
func _environment(observations: Dictionary) -> float:
 var totals: Dictionary={}
 var counts: Dictionary={}
 for value in observations.values():
  totals[value.category]=float(totals.get(value.category,0))+float(value.cleanliness)
  counts[value.category]=int(counts.get(value.category,0))+1
 for category in totals:totals[category]=float(totals[category])/int(counts[category])
 return _weighted(totals,_data.environment_weights)
func _weighted(components: Dictionary, weights: Dictionary) -> float:
 var total := 0.0
 var weight := 0.0
 for key in components:
  total+=float(components[key])*float(weights.get(key,0))
  weight+=float(weights.get(key,0))
 return total/weight if weight>0 else -1.0
func _visible(start: Vector2, end: Vector2, id: String, host: String, solids: Array) -> bool:
 var obstacles: Array=[]
 for solid in solids:
  if solid.get("id","")!=id and solid.get("id","")!=host:obstacles.append(solid)
 var steps := maxi(1,ceili(start.distance_to(end)/0.15))
 for i in range(1,steps):
  if FootprintGeometry.blocked(start.lerp(end,float(i)/steps),obstacles,0):return false
 return true
func _nav(location_id: StringName) -> KioskNavigation:
 if not _navigation.has(str(location_id)):
  var space: Dictionary=_spaces.definitions().locations[str(location_id)]
  var navigation := KioskNavigation.new()
  navigation.configure(LocationDefinition.new(location_id,{"navigation_bounds":space.navigation_bounds,"navigation_cell":space.cell_size,"navigation_clearance":0.15,"solids":_spaces.solids(location_id)}),SpatialMapping.new())
  _navigation[str(location_id)]=navigation
 return _navigation[str(location_id)]
func snapshot() -> Dictionary:
 return {"active":_active.duplicate(true),"recent":_recent.duplicate(true),"customers":_customers.duplicate(true),"closed":_closed.duplicate(true)}
func restore(data: Dictionary) -> ActionResult:
 for field in ["active","recent","customers","closed"]:
  if not data.get(field) is Dictionary:return _fail("invalid_customer_experience")
 for id in data.closed:
  if data.closed[id]!=true:return _fail("invalid_experience_closed")
 for id in data.active:
  var record: Variant=data.active[id]
  if not record is Dictionary or record.get("id")!=id or data.closed.has(id) or not record.get("observations") is Dictionary or not record.get("food") is Dictionary or not record.get("order_id") is String or not record.get("timing_known") is bool:return _fail("invalid_active_experience")
  if not record.get("character_id") is String or not _spaces.definitions().locations.has(str(record.get("location_id",""))):return _fail("invalid_experience_location")
  if not record.food.is_empty():
   if record.food.get("order_id")!=record.order_id or not record.food.get("item_id") is String or not record.food.get("food_id") is String or not ContentValidation.integer(record.food.get("quality")) or record.food.quality<0 or record.food.quality>3 or not ContentValidation.number(record.food.get("served_at")) or record.food.served_at<0 or record.food.served_at>_clock.world_minutes:return _fail("invalid_experience_food")
  for key in ["last_observed_at","order_started_at","patience"]:
   if not ContentValidation.number(record.get(key)):return _fail("invalid_experience_timing")
  if record.patience<0 or (record.timing_known and (record.order_started_at<0 or record.patience<=0)):return _fail("invalid_experience_timing")
  for observation in record.observations.values():
   if not observation is Dictionary or not _data.environment_weights.has(str(observation.get("category",""))) or not ContentValidation.bounded(observation.get("cleanliness"),0,100) or not ContentValidation.number(observation.get("at")) or observation.at>_clock.world_minutes:return _fail("invalid_observation")
 for location_id in data.recent:
  if not _spaces.definitions().locations.has(location_id) or not data.recent[location_id] is Array or data.recent[location_id].size()>100:return _fail("invalid_recent_experiences")
  var seen: Dictionary={}
  for summary in data.recent[location_id]:
   if not summary is Dictionary or not summary.get("visit_id") is String or seen.has(summary.visit_id) or not data.closed.has(summary.visit_id) or summary.get("location_id")!=location_id or not summary.get("components") is Dictionary or not ContentValidation.bounded(summary.get("score"),-1,100):return _fail("invalid_experience_summary")
   if not _valid_summary(summary):return _fail("invalid_experience_summary")
   seen[summary.visit_id]=true
 for customer in data.customers.values():
  if not customer is Dictionary or not customer.get("last_visit") is Dictionary or not customer.get("last_food") is Dictionary:return _fail("invalid_customer_memory")
  for key in ["last_visit","last_food"]:
   if not customer[key].is_empty() and (not _valid_summary(customer[key]) or not data.closed.has(str(customer[key].get("visit_id","")))):return _fail("invalid_customer_memory")
 _active=data.active.duplicate(true)
 _recent=data.recent.duplicate(true)
 _customers=data.customers.duplicate(true)
 _closed=data.closed.duplicate(true)
 return ActionResult.success()
func _fail(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,StringName(key))

func _valid_summary(summary: Dictionary) -> bool:
 if not summary.get("character_id") is String or not summary.get("food") is Dictionary or not summary.get("components") is Dictionary or not summary.get("weights") is Dictionary or not ContentValidation.number(summary.get("ended_at")) or summary.ended_at<0 or summary.ended_at>_clock.world_minutes or not _spaces.definitions().locations.has(str(summary.get("location_id",""))):return false
 for key in summary.components:
  if not _data.weights.has(key) or not ContentValidation.bounded(summary.components[key],0,100):return false
 for key in summary.weights:
  if not _data.weights.has(key) or not ContentValidation.bounded(summary.weights[key],0,5):return false
 if not ContentValidation.number(summary.get("score")) or absf(float(summary.score)-_weighted(summary.components,summary.weights))>0.001:return false
 if summary.components.has("food")==summary.food.is_empty():return false
 if not summary.food.is_empty():
  if summary.food.get("score")!=summary.components.food:return false
  if not ContentValidation.integer(summary.food.get("quality")) or summary.food.quality<0 or summary.food.quality>3 or not summary.food.get("food_id") is String or not summary.food.get("item_id") is String:return false
 return true
