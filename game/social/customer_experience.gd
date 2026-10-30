class_name CustomerExperience
extends RefCounted
signal changed(location_id: StringName)
var visit_provider: Callable
var profile_provider: Callable
var suggestion_available: Callable
var order_provider: Callable
var relationship_provider: Callable
var _tastes: Dictionary={}
var _palates: Dictionary={}
var _first_tastes: Dictionary={}
var _source_candidates: Dictionary={}
var _comment_sources: Dictionary={}
var _starter_placements: Dictionary={}
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
 _starter_placements=spaces.snapshot().placements.duplicate(true)
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
  var point := _spaces.ground(StringName(id))
  if actor_pose.ground.distance_to(point)>float(_data.observe_radius):continue
  if not _visible(actor_pose.ground,point,id,str(placed.host_id),solids):continue
  if _nav(actor_pose.location_id).path(actor_pose.ground,point).is_empty():continue
  if item.get("kind") in ["furniture","equipment"] and not _starter_placements.has(id):
   var appearance := int(item.attributes.get("appearance_revision",0))
   _remember_source("notice/"+str(record.character_id)+"/"+str(id)+"/"+str(appearance),"notice",record,str(id),str(item.definition_id),appearance,{"observer_ground":[actor_pose.ground.x,actor_pose.ground.y],"target_ground":[point.x,point.y]})
  if category.is_empty():continue
  var state := _hygiene.state(StringName(id))
  if not state.is_empty():record.observations[id]={"target_id":id,"category":category,"cleanliness":state.cleanliness,"at":_clock.world_minutes}
 for observation in record.observations.values():
  if is_equal_approx(float(observation.at),_clock.world_minutes) and float(observation.cleanliness)<float(_data.dirty_below):
   var evidence := "dirty/"+str(record.character_id)+"/"+str(observation.target_id)+"/"+str(floori(_clock.world_minutes/1440.0))+"/"+str(floori(float(observation.cleanliness)/20.0))
   _remember_source(evidence,"dirty",record,str(observation.target_id),"",0,{"observation":observation.duplicate(true)})
 var last: Dictionary=_customers.get(record.character_id,{}).get("last_visit",{})
 var environment := _environment(record.observations)
 if not last.is_empty() and last.components.has("environment") and environment>=float(last.components.environment)+float(_data.improvement_delta):
  _remember_source("improved/"+str(record.character_id)+"/"+str(last.visit_id),"improved",record,str(last.visit_id),"",0,{"previous":float(last.components.environment),"previous_summary":last.duplicate(true),"current":environment,"observations":record.observations.duplicate(true)})
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
 var tasted: Dictionary=_tastes.get("taste/"+str(record.order_id),{})
 if not tasted.is_empty():
  record.food["score"]=float(tasted.score)
  record.food["tasted_quality"]=int(tasted.quality)
  components["food"]=record.food.score
 var wait_end := float(record.food.served_at) if not record.food.is_empty() else ended_at
 if record.timing_known and record.order_id!="":components["wait"]=clampf(100.0*(1.0-maxf(0,wait_end-float(record.order_started_at))/float(record.patience)),0,100)
 var weights: Dictionary=_data.weights.duplicate(true)
 var sensitivity: Dictionary=_data.sensitivities.get(record.character_id,{})
 for key in weights:weights[key]=float(weights[key])*float(sensitivity.get(key,1.0))
 var summary := {"visit_id":str(visit_id),"character_id":record.character_id,"location_id":record.location_id,"ended_at":ended_at,"reason":str(reason),"components":components,"weights":weights,"observations":record.observations.duplicate(true),"wait":{"order_id":record.order_id,"created_at":record.order_started_at,"closed_at":wait_end,"patience":record.patience,"timing_known":record.timing_known},"food":record.food.duplicate(true) if not tasted.is_empty() else {},"score":_weighted(components,weights)}
 var history: Array=_recent.get(record.location_id,[])
 history.append(summary)
 _recent[record.location_id]=history.slice(maxi(0,history.size()-int(_data.window)))
 var previous: Dictionary=_customers.get(record.character_id,{})
 _customers[record.character_id]={"last_visit":summary.duplicate(true),"last_food":summary.duplicate(true) if not tasted.is_empty() else previous.get("last_food",{}).duplicate(true)}
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
 return {"visit_id":str(visit_id),"dirty_observed":dirty,"dirty_category":dirty_category,"improved_observed":improved,"food_memory":not food.is_empty(),"previous_visit_id":str(last.get("visit_id","")),"food_visit_id":str(food.get("visit_id","")),"previous_food_id":str(food.get("food",{}).get("food_id","")),"previous_food_quality":int(food.get("food",{}).get("tasted_quality",-1)),"environment":current}
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
 return {"active":_active.duplicate(true),"recent":_recent.duplicate(true),"customers":_customers.duplicate(true),"closed":_closed.duplicate(true),"tastes":_tastes.duplicate(true),"comment_sources":_comment_sources.duplicate(true)}
func restore(data: Dictionary) -> ActionResult:
 for field in ["active","recent","customers","closed","tastes","comment_sources"]:
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
 for id in data.comment_sources:
  var r: Variant=data.comment_sources[id]
  if not r is Dictionary or not CharacterLifeValidation.keys(r,["id","kind","actor","subject","definition_id","appearance_revision","at","location_id","visit_id","proof"]) or r.id!=id or not r.kind in ["notice","dirty","improved"] or not r.actor is String or not r.subject is String or not r.definition_id is String or not ContentValidation.integer(r.appearance_revision) or r.appearance_revision<0 or not ContentValidation.bounded(r.at,0,_clock.world_minutes) or not r.location_id is String or not r.visit_id is String or not r.proof is Dictionary:return _fail("invalid_comment_source")
 _comment_sources=data.comment_sources.duplicate(true);_source_candidates.clear()
 for source in _comment_sources.values():_index_comment_source(source)
 var sequence := {}
 for id in data.tastes:
  var r: Variant=data.tastes[id]
  if not r is Dictionary or not CharacterLifeValidation.keys(r,["id","sequence","order_id","item_id","actor","visit","food_id","variant_id","at","quality","present_quality","fit","value","score","payment","settlement","observations","environment"]):return _fail("invalid_taste")
  if r.id!=id or id!="taste/"+str(r.order_id) or not ContentValidation.integer(r.sequence) or not ContentValidation.bounded(r.sequence,1,data.tastes.size()) or sequence.has(int(r.sequence)):return _fail("invalid_taste_sequence")
  for key in ["order_id","item_id","actor","visit","food_id","variant_id"]:
   if not r[key] is String or r[key].is_empty():return _fail("invalid_taste_identity")
  if not ContentValidation.bounded(r.at,0,_clock.world_minutes) or not ContentValidation.integer(r.quality) or not ContentValidation.bounded(r.quality,0,3) or not ContentValidation.integer(r.payment) or not ContentValidation.bounded(r.payment,0,MenuService.LIMIT) or not r.settlement in ["paid","gift"] or not r.observations is Dictionary or not ContentValidation.bounded(r.environment,-1,100):return _fail("invalid_taste_value")
  for key in ["present_quality","fit","value","score"]:
   if not ContentValidation.bounded(r[key],0,100):return _fail("invalid_taste_score")
  for observation in r.observations.values():
   if not observation is Dictionary or not _data.environment_weights.has(str(observation.get("category",""))) or not ContentValidation.bounded(observation.get("cleanliness"),0,100) or not ContentValidation.bounded(observation.get("at"),0,float(r.at)):return _fail("invalid_taste_observation")
  if not is_equal_approx(_environment(r.observations),float(r.environment)):return _fail("invalid_taste_environment")
  sequence[int(r.sequence)]=r
 _tastes=data.tastes.duplicate(true);_palates.clear();_first_tastes.clear()
 for index in range(1,sequence.size()+1):_remember(sequence[index])
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

func confirm_taste(order: OrderState, life: CharacterLife, foods: FoodRegistry, menu: MenuService) -> ActionResult:
 if order==null or not order_provider.is_valid() or order_provider.call(order.id)!=order:return _fail("unknown_taste_order")
 var id := "taste/"+str(order.id)
 if _tastes.has(id):return ActionResult.success({"duplicate":true})
 var visit: VisitState=visit_provider.call(order.visit_id) if visit_provider.is_valid() else null
 var record: Dictionary=_active.get(str(order.visit_id),{})
 if order.status!=&"delivered" or order.settlement==&"pending" or order.quote.get("consumption_mode")!="here" or visit==null or visit.phase!=&"staying" or visit.character_id!=order.character_id or record.get("order_id")!=str(order.id) or record.get("food",{}).get("item_id")!=str(order.delivered_item_id):return ActionResult.success({"waiting":true})
 if _clock.world_minutes<order.served_at+float(_data.taste_delay_minutes):return ActionResult.success({"waiting":true})
 var age := FoodFreshness.view(order.served_item,_clock.world_minutes,foods._definitions)
 if not age.sellable:return ActionResult.success({"untasted":true})
 var scores := _taste_scores(order,float(age.present_quality),life,foods,menu)
 var taste := {"id":id,"sequence":_tastes.size()+1,"order_id":str(order.id),"item_id":str(order.delivered_item_id),"actor":str(order.character_id),"visit":str(order.visit_id),"food_id":str(order.food_id),"variant_id":str(order.quote.variant_id),"at":_clock.world_minutes,"quality":int(age.grade),"present_quality":float(age.present_quality),"fit":scores.fit,"value":scores.value,"score":scores.score,"payment":order.payment,"settlement":str(order.settlement),"observations":record.observations.duplicate(true),"environment":_environment(record.observations)}
 # Both owners publish synchronously before any observer notification; all
 # fallible checks precede satisfaction, and no event can see half a taste.
 var satisfied := life.satisfy(order.character_id,id,order.food_id,_clock.world_minutes)
 if not satisfied.ok:return satisfied
 _tastes[id]=taste;_remember(taste)
 changed.emit(StringName(record.location_id))
 return ActionResult.success({"tasted":true,"source":id})
func _taste_scores(order: OrderState, quality: float, life: CharacterLife, foods: FoodRegistry, menu: MenuService) -> Dictionary:
 var p := life.profile(order.character_id);var food := foods.definition(order.food_id)
 var maximum := 1.0
 for weight in p.food_weights.values():maximum=maxf(maximum,float(weight))
 var spice := float(food.spice)
 for id in order.quote.additions:spice+=float(menu._data.additions[id].spice)
 var middle := (float(p.spice_preference[0])+float(p.spice_preference[1]))*0.5
 var fit := clampf(float(p.food_weights.get(str(order.food_id),maximum*0.35))/maximum*100.0,0,100)
 fit*=clampf(float(p.temperature_weights[food.temperature]),0,1)*clampf(1.0-absf(clampf(spice,0,1)-middle)*0.65,0,1)
 var value := 50.0 if order.settlement==&"gift" else clampf(quality*float(food.price_minor)/maxf(1,float(order.payment)),0,100)
 return {"fit":fit,"value":value,"score":clampf(quality*0.65+fit*0.25+value*0.10,0,100)}
func _remember(taste: Dictionary) -> void:
 var own: Dictionary=_palates.get(taste.actor,{})
 var previous: Dictionary=own.get(taste.food_id,{})
 own[taste.food_id]={"score":float(taste.score) if previous.is_empty() else float(previous.score)*0.7+float(taste.score)*0.3,"count":int(previous.get("count",0))+1,"source":taste.id,"variant_id":taste.variant_id}
 _palates[taste.actor]=own
 var first: Dictionary=_first_tastes.get(taste.actor,{})
 var ids: Array=first.get(taste.food_id,[])
 if ids.size()<20:ids.append(taste.id)
 first[taste.food_id]=ids;_first_tastes[taste.actor]=first
func expected(actor: StringName) -> Dictionary:return _palates.get(str(actor),{}).duplicate(true)
func return_factor(actor: StringName) -> float:
 var best := 70.0
 for memory in _palates.get(str(actor),{}).values():best=maxf(best,float(memory.score))
 var relationship := clampf(float(relationship_provider.call(actor)),0,100) if relationship_provider.is_valid() else 0.0
 var environment := -1.0
 var last: Dictionary=_customers.get(str(actor),{}).get("last_visit",{})
 if not last.is_empty():environment=float(last.components.get("environment",-1))
 return 1.0+minf(0.15,(best-70.0)/250.0+maxf(0,environment-70.0)/1000.0+relationship*0.0003)
func taste_sources(actor: StringName) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for record in _tastes.values():
  if record.actor==str(actor):result.append(record.duplicate(true))
 result.sort_custom(func(a,b):return int(a.sequence)>int(b.sequence))
 return result
func validate_tastes(session: GameSession) -> ActionResult:
 var satisfied: Dictionary=session.character_life.snapshot().satisfied
 if satisfied.size()!=_tastes.size():return _fail("taste_satisfaction_count")
 var summaries: Array=[]
 for history in _recent.values():summaries.append_array(history)
 for customer in _customers.values():
  summaries.append(customer.last_visit);summaries.append(customer.last_food)
 for summary in summaries:
  if summary.is_empty() or summary.food.is_empty():continue
  var tasted: Dictionary=_tastes.get("taste/"+str(summary.food.get("order_id","")),{})
  if tasted.is_empty() or tasted.actor!=summary.character_id or tasted.visit!=summary.visit_id or tasted.item_id!=summary.food.get("item_id") or tasted.food_id!=summary.food.get("food_id") or not is_equal_approx(float(tasted.score),float(summary.food.get("score",-1))) or tasted.quality!=summary.food.get("tasted_quality"):return _fail("food_memory_taste_source")
 for id in _tastes:
  var r: Dictionary=_tastes[id];var order := session.service.order(StringName(r.order_id))
  if order==null or order.status!=&"delivered" or order.quote.consumption_mode!="here" or str(order.character_id)!=r.actor or str(order.visit_id)!=r.visit or str(order.food_id)!=r.food_id or str(order.delivered_item_id)!=r.item_id or order.quote.variant_id!=r.variant_id or str(order.settlement)!=r.settlement or order.payment!=r.payment or float(r.at)<maxf(order.served_at+float(_data.taste_delay_minutes),order.closed_at):return _fail("taste_order_source")
  var age := FoodFreshness.view(order.served_item,float(r.at),session.foods._definitions)
  if not age.sellable or int(age.grade)!=int(r.quality) or not is_equal_approx(float(age.present_quality),float(r.present_quality)):return _fail("taste_food_source")
  var scores := _taste_scores(order,float(r.present_quality),session.character_life,session.foods,session.menu)
  for key in ["fit","value","score"]:
   if not is_equal_approx(float(scores[key]),float(r[key])):return _fail("taste_score_source")
  var source: Dictionary=satisfied.get(id,{})
  if source.get("actor")!=r.actor or source.get("food_id")!=r.food_id or not ContentValidation.number(source.get("at")) or not is_equal_approx(float(source.at),float(r.at)):return _fail("taste_satisfaction_source")
 return ActionResult.success()

func _remember_source(id: String, kind: String, record: Dictionary, subject: String, definition: String, appearance: int, proof: Dictionary) -> void:
 if _comment_sources.has(id):return
 _comment_sources[id]={"id":id,"kind":kind,"actor":str(record.character_id),"subject":subject,"definition_id":definition,"appearance_revision":appearance,"at":_clock.world_minutes,"location_id":str(record.location_id),"visit_id":str(record.id),"proof":proof.duplicate(true)}
 _index_comment_source(_comment_sources[id])
func comment_sources(actor: String, kind: String, food: String="") -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 if kind=="suggestion":
  for suggestion in _data.comment_suggestions:
   var source := _suggestion(actor,str(suggestion))
   if not source.is_empty():result.append(source)
 elif kind=="taste":
  for memory in _palates.get(actor,{}).values():
   var taste: Dictionary=_tastes[memory.source]
   if food.is_empty() or taste.food_id==food:result.append({"id":taste.id,"kind":kind,"actor":actor,"at":taste.at,"food_id":taste.food_id,"quality":taste.quality,"score":taste.score})
 else:
  for id in _source_candidates.get(actor,{}).get(kind,{}).values():
   result.append(_comment_sources[str(id)].duplicate(true))
 result.sort_custom(func(a,b):return str(a.id)>str(b.id) if float(a.at)==float(b.at) else float(a.at)>float(b.at))
 return result
func comment_source(kind: String, id: String) -> Dictionary:
 if kind=="suggestion":
  var parts := id.split("/")
  return _suggestion(str(parts[1]),str(parts[2])) if parts.size()==3 and parts[0]=="suggestion" else {}
 if kind=="taste":
  var taste: Dictionary=_tastes.get(id,{})
  return {} if taste.is_empty() else {"id":id,"kind":kind,"actor":taste.actor,"at":taste.at,"food_id":taste.food_id,"quality":taste.quality,"score":taste.score}
 var source: Dictionary=_comment_sources.get(id,{})
 return source.duplicate(true) if source.get("kind")==kind else {}
func comment_qualified(actor: String, kind: String, id: String) -> bool:
 var source := comment_source(kind,id)
 if source.is_empty() or source.actor!=actor:return false
 if kind=="suggestion":return suggestion_available.is_valid() and bool(suggestion_available.call(str(_data.comment_suggestions[source.subject].food_id)))
 if kind=="dirty":return float(_hygiene.state(StringName(source.subject)).get("cleanliness",100))<float(_data.dirty_below)
 if kind=="notice":
  var item := _spaces.item_record(StringName(source.subject))
  return not item.is_empty() and int(item.attributes.get("appearance_revision",0))==int(source.appearance_revision)
 return true
func validate_comment_sources(session: GameSession) -> ActionResult:
 for id in _comment_sources:
  var r: Dictionary=_comment_sources[id]
  if not session.presence.profiles().has(r.actor) or not _spaces.definitions().locations.has(r.location_id) or not r.visit_id.begins_with("visit_") or not r.visit_id.trim_prefix("visit_").is_valid_int() or int(r.visit_id.trim_prefix("visit_"))>=int(session.visitors.snapshot().next_id):return _fail("comment_source_actor")
  if r.kind=="notice":
   var item := session.items.get_item(StringName(r.subject))
   if not ContentValidation.vector(r.proof.get("observer_ground"),2) or not ContentValidation.vector(r.proof.get("target_ground"),2) or Vector2(r.proof.observer_ground[0],r.proof.observer_ground[1]).distance_to(Vector2(r.proof.target_ground[0],r.proof.target_ground[1]))>float(_data.observe_radius)+0.001:return _fail("comment_notice_observation")
   if item.is_empty() or item.definition_id!=r.definition_id or not item.kind in ["furniture","equipment"] or _starter_placements.has(r.subject) or int(item.attributes.get("appearance_revision",0))<int(r.appearance_revision) or id!="notice/"+r.actor+"/"+r.subject+"/"+str(int(r.appearance_revision)):return _fail("comment_notice_source")
  elif r.kind=="dirty":
   var observation: Variant=r.proof.get("observation")
   if not observation is Dictionary or observation.get("target_id")!=r.subject or not ContentValidation.bounded(observation.get("cleanliness"),0,float(_data.dirty_below)) or not ContentValidation.number(observation.get("at")) or not is_equal_approx(float(observation.at),float(r.at)):return _fail("comment_dirty_source")
  elif not r.proof.get("previous_summary") is Dictionary or not _valid_summary(r.proof.previous_summary) or r.proof.previous_summary.get("character_id")!=r.actor or r.proof.previous_summary.get("visit_id")!=r.subject or not ContentValidation.bounded(r.proof.get("previous"),0,100) or not ContentValidation.bounded(r.proof.get("current"),0,100) or float(r.proof.current)<float(r.proof.previous)+float(_data.improvement_delta):return _fail("comment_improved_source")
  if r.kind=="improved":
   if not r.proof.get("observations") is Dictionary or not ContentValidation.number(r.proof.previous_summary.get("ended_at")) or float(r.proof.previous_summary.ended_at)>float(r.at) or not is_equal_approx(float(r.proof.previous_summary.components.get("environment",-1)),float(r.proof.previous)) or not is_equal_approx(_environment(r.proof.observations),float(r.proof.current)):return _fail("comment_improved_observation")
 return ActionResult.success()

func _suggestion(actor: String, id: String) -> Dictionary:
 var rule: Dictionary=_data.comment_suggestions.get(id,{})
 if rule.is_empty() or not profile_provider.is_valid():return {}
 var p: Dictionary=profile_provider.call(StringName(actor))
 if float(p.get("temperature_weights",{}).get(str(rule.temperature),0))<float(rule.minimum_weight):return {}
 var own: Dictionary=_palates.get(actor,{}).get(str(rule.required_food),{})
 if int(own.get("count",0))<int(rule.minimum_tastes):return {}
 var ids: Array=_first_tastes.get(actor,{}).get(str(rule.required_food),[])
 var tasted: Dictionary=_tastes.get(str(ids[int(rule.minimum_tastes)-1]),{}) if ids.size()>=int(rule.minimum_tastes) else {}
 if tasted.is_empty():return {}
 return {"id":"suggestion/"+actor+"/"+id,"kind":"suggestion","actor":actor,"subject":id,"at":tasted.at,"upstream":tasted.id}

func _index_comment_source(source: Dictionary) -> void:
 var own: Dictionary=_source_candidates.get(source.actor,{})
 var kinds: Dictionary=own.get(source.kind,{})
 var key := "environment" if source.kind=="improved" else str(source.subject)
 var previous: Dictionary=_comment_sources.get(str(kinds.get(key,"")),{})
 if previous.is_empty() or float(source.at)>float(previous.at) or float(source.at)==float(previous.at) and str(source.id)>=str(previous.id):kinds[key]=source.id
 own[source.kind]=kinds;_source_candidates[source.actor]=own
