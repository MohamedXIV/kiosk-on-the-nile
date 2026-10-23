class_name VisitorService
extends RefCounted
signal encounter_requested(kind: StringName, visit_ids: PackedStringArray, context: Dictionary)
signal departed(visit_id: StringName)
var visits: Dictionary = {}
var history := VisitorHistory.new()
var memory: Dictionary = {"amgad_visits":0,"last_served_quality":""}
var availability_provider: Callable
var purchase_blocked: Callable
var demand_provider: Callable
var food_selector: Callable
var foods: FoodRegistry
var _data: Dictionary
var _markers: Dictionary
var _clock: GameClock
var _orders: ServiceSystem
var _open: Callable
var _rng := RandomNumberGenerator.new()
var _cooldown: float
var _next: int = 1
var _other_visit_counts: Dictionary = {}
var _flags: Dictionary = {}
func configure(data: Dictionary, markers: Dictionary, clock: GameClock, orders: ServiceSystem, open: Callable) -> void:
 if foods!=null:history.food_ids=foods.ids()
 _data = data.duplicate(true)
 _markers = markers.duplicate(true)
 _clock = clock
 _orders = orders
 _open = open
 if int(data.seed)==0:_rng.randomize()
 else:_rng.seed = int(data.seed)
 _cooldown = _delay("initial_delay")
func character(id: StringName) -> Dictionary:
 return _data.characters.get(str(id),{}).duplicate(true)
func spawn(character_id: StringName) -> VisitState:
 var definition := character(character_id)
 if definition.is_empty() or _has_character(character_id): return null
 history.reserve(str(character_id),_clock)
 var visit := VisitState.new()
 visit.id = StringName("visit_%d" % _next)
 _next += 1
 visit.character_id = character_id
 visit.decision_remaining=_delay("purchase_delay")
 visit.stay_seconds = float(definition.stay_seconds)*_delay("stay_multiplier")
 visit.pose.location_id = &"kiosk"
 var spawn_position: Array = _markers[_data.spawn_markers[_rng.randi_range(0,_data.spawn_markers.size()-1)]]
 visit.pose.ground = Vector2(spawn_position[0],spawn_position[1])
 var marker: Array = _markers[definition.leisure_marker]
 visit.destination = Vector2(marker[0],marker[1])
 visits[str(visit.id)] = visit
 return visit
func tick(delta: float) -> void:
 for id in visits.keys():
  var visit: VisitState = visits[id]
  if (visit.phase==&"arriving" or visit.shopping_state==&"approaching") and visit.pose.ground.distance_to(visit.destination)<=float(_data.arrival_radius): _arrived(visit)
  elif visit.phase == &"staying":
   if not busy_in_conversation(visit.id):
    visit.elapsed += delta
    _consider_purchase(visit,delta)
    _remarks(visit,delta)
   if (visit.elapsed >= visit.stay_seconds and (visit.served or visit.food_id==&"")) or visit.elapsed>=float(_data.max_wait_seconds):
    visit.phase = &"leaving"
    var exit_position: Array = _markers[_data.exit_markers[_rng.randi_range(0,_data.exit_markers.size()-1)]]
    visit.destination = Vector2(exit_position[0],exit_position[1])
    _orders.cancel_visit(visit.id)
    visit.shopping_state=&"declined"
    departed.emit(visit.id)
  elif visit.phase == &"leaving" and visit.pose.ground.distance_to(visit.destination)<=float(_data.arrival_radius): visits.erase(id)
 _cooldown=maxf(0,_cooldown-delta)
 if _cooldown<=0:
  _cooldown=_delay("arrival_delay")
  if visits.size()<int(_data.capacity):
   var pool: Array[String]=[]
   var weights: Array[float]=[]
   var total := 0.0
   for id in _data.characters:
    if not _eligible(id):continue
    var previous := history.last_visit(id)
    var freshness := 1.0 if previous<0 else clampf((_clock.world_minutes-previous)/1440.0,0.25,1.0)
    var weight := float(_data.characters[id].arrival_weight)*freshness
    pool.append(id);weights.append(weight);total+=weight
   if total>0:
    var roll := _rng.randf()*total
    for i in range(pool.size()):
     roll-=weights[i]
     if roll<=0:spawn(StringName(pool[i]));break
func _arrived(visit: VisitState) -> void:
 if visit.shopping_state==&"approaching" and busy_in_conversation(visit.id):return
 visit.phase = &"staying"
 visit.elapsed = 0
 visit.remark_remaining = float(_data.waiting_reminder_seconds)
 if not visit.arrival_counted:
  visit.arrival_counted=true
  if visit.character_id==&"amgad":memory.amgad_visits+=1
  else:_other_visit_counts[str(visit.character_id)]=visit_count(visit.character_id)+1
 if visit.shopping_state==&"approaching":
  if not _open.call():
   visit.shopping_state=&"declined"
   visit.food_id=&""
   _return_to_leisure(visit)
   return
  var order := _orders.place_order(visit.id,visit.food_id)
  if order:
   visit.order_id=order.id
   visit.shopping_state=&"pending"
   encounter_requested.emit(&"order",PackedStringArray([str(visit.id)]),{"character_id":str(visit.character_id)})
  else:
   visit.food_id=&""
   visit.shopping_state=&"declined"
   _return_to_leisure(visit)
  return
 encounter_requested.emit(&"arrival",PackedStringArray([str(visit.id)]),{"character_id":str(visit.character_id)})
 # A conversation may happen when friends happen to meet; no scheduled pair spawn.
 if visit.character_id in [&"samir",&"mahmoud"] and not _flags.get("football_started",false):
  var pair := PackedStringArray()
  for other in visits.values():
   if other.character_id in [&"mahmoud",&"samir"] and other.phase==&"staying":pair.append(str(other.id))
  if pair.size()==2 and not Array(pair).any(func(id):return busy_in_conversation(StringName(id))):
   _flags.football_started=true
   encounter_requested.emit(&"football",pair,{})
func busy_in_conversation(visit_id: StringName) -> bool:
 return purchase_blocked.is_valid() and purchase_blocked.call(visit_id)
func _position_available(point: Vector2, except_id: StringName = &"") -> bool:
 for other in visits.values():
  if other.id==except_id:continue
  if other.destination.distance_to(point)<float(_data.personal_space) or other.pose.ground.distance_to(point)<float(_data.personal_space):return false
 return true
func _delay(key: String) -> float:
 var interval: Array=_data[key]
 return _rng.randf_range(float(interval[0]),float(interval[1]))
func _consider_purchase(visit: VisitState, delta: float) -> void:
 if visit.shopping_state!=&"undecided" or busy_in_conversation(visit.id):return
 visit.decision_remaining=maxf(0,visit.decision_remaining-delta)
 if visit.decision_remaining>0:return
 visit.decision_remaining=_delay("purchase_retry_delay")
 if not _open.call():return
 var definition := character(visit.character_id)
 var service_marker: Array=_markers[definition.marker]
 if not _position_available(Vector2(service_marker[0],service_marker[1]),visit.id):return
 if _rng.randf()>=float(definition.purchase_chance):visit.shopping_state=&"declined";return
 var food := StringName(str(food_selector.call(visit.character_id))) if food_selector.is_valid() else StringName(definition.food_id)
 if food.is_empty():visit.shopping_state=&"declined";return
 visit.food_id=food
 visit.shopping_state=&"approaching"
 var marker: Array=_markers[definition.marker]
 visit.destination=Vector2(marker[0],marker[1])
func _return_to_leisure(visit: VisitState) -> void:
 var marker: Array=_markers[character(visit.character_id).leisure_marker]
 visit.destination=Vector2(marker[0],marker[1])
 # Keep staying phase: movement follows destination independently.
func is_available(visit_id: StringName) -> bool:
 return visits.has(str(visit_id)) and visits[str(visit_id)].phase == &"staying"
func commit_pose(visit_id: StringName, pose: ActorPose) -> void:
 if visits.has(str(visit_id)): visits[str(visit_id)].pose = pose
func record_service(_order_id: StringName, visit_id: StringName, item: PreparedItem, _payment: int) -> void:
 if not visits.has(str(visit_id)): return
 var visit: VisitState = visits[str(visit_id)]
 history.served(str(visit.character_id),_order_id,visit_id,item)
 visit.served = true
 visit.shopping_state=&"served"
 visit.elapsed = 0
 visit.remark_remaining = _rng.randf_range(float(_data.ambient_remark_delay[0]),float(_data.ambient_remark_delay[1]))
 if visit.character_id == &"amgad": memory.last_served_quality = str(item.quality_key)
 encounter_requested.emit(&"served",PackedStringArray([str(visit_id)]),{"quality_score":item.quality_score,"character_id":str(visit.character_id)})
func clear_visits() -> void:
 for visit in visits.values():
  _orders.cancel_visit(visit.id)
  departed.emit(visit.id)
 visits.clear()
func begin_day() -> void:
 _flags.clear()
 # Do not reset the independent arrival clock at midnight.
func snapshot() -> Dictionary:
 var records: Dictionary = {}
 for id in visits: records[id] = visits[id].snapshot()
 return {"history":history.snapshot(),"visits":records,"visit_counts":_other_visit_counts.duplicate(),"memory":memory.duplicate(true),"flags":_flags.duplicate(),"cooldown":_cooldown,"next_id":_next,"rng_state":str(_rng.state)}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("visit_counts") is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visit_counts")
 for id in data.visit_counts:
  if id=="amgad" or not _data.characters.has(id) or not ContentValidation.integer(data.visit_counts[id]) or data.visit_counts[id]<0: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visit_counts")
 if not data.get("visits") is Dictionary or not data.get("memory") is Dictionary or not data.get("flags") is Dictionary or not ContentValidation.number(data.get("cooldown")) or not ContentValidation.integer(data.get("next_id")) or data.next_id<1 or not data.get("rng_state") is String or not data.rng_state.is_valid_int(): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visitors")
 if not ContentValidation.integer(data.memory.get("amgad_visits")) or data.memory.amgad_visits<0 or not data.memory.get("last_served_quality") is String: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_memory")
 var restored_history := VisitorHistory.new()
 restored_history.food_ids=foods.ids() if foods!=null else history.food_ids.duplicate()
 if not data.get("history") is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visitor_history")
 var history_result := restored_history.restore(data.history,_data.characters,_clock)
 if not history_result.ok: return history_result
 var candidate: Dictionary = {}
 for id in data.visits:
  var record: Variant = data.visits[id]
  if not record is Dictionary or record.get("id")!=id or not _data.characters.has(record.get("character_id")) or not record.get("phase") in ["arriving","staying","leaving"] or not ContentValidation.vector(record.get("destination"),2) or not ContentValidation.number(record.get("elapsed")) or record.elapsed<0 or not record.get("served") is bool or not record.get("order_id") is String or not record.get("pose") is Dictionary or not ContentValidation.number(record.get("remark_remaining")): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visit")
  var suffix: String = str(id).trim_prefix("visit_")
  if not str(id).begins_with("visit_") or not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=int(data.next_id): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visit_identity")
  if (record.get("food_id")!="" and (foods==null or not foods.has_food(StringName(str(record.get("food_id","")))))) or not ContentValidation.number(record.get("stay_seconds")) or record.stay_seconds<=0: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visit_intention")
  var visit := VisitState.new()
  var result := visit.pose.restore(record.pose)
  if not result.ok or visit.pose.location_id!=&"kiosk": return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visit_pose")
  visit.id = StringName(id)
  visit.character_id = StringName(record.character_id)
  visit.food_id = StringName(record.food_id)
  visit.stay_seconds = float(record.stay_seconds)
  visit.destination = Vector2(record.destination[0],record.destination[1])
  visit.phase = StringName(record.phase)
  visit.elapsed = float(record.elapsed)
  visit.remark_remaining = float(record.remark_remaining)
  visit.served = record.served
  if not record.get("shopping_state") in ["undecided","approaching","pending","declined","served"] or not ContentValidation.bounded(record.get("decision_remaining"),0,86400):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_purchase_decision")
  if not ContentValidation.integer(record.get("recall_variant")) or record.recall_variant< -1 or record.recall_variant>2:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_recall_variant")
  if not record.get("arrival_counted") is bool:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_arrival_count")
  visit.arrival_counted=record.arrival_counted
  visit.recall_variant=int(record.recall_variant)
  visit.shopping_state=StringName(record.shopping_state)
  visit.decision_remaining=float(record.decision_remaining)
  visit.order_id = StringName(record.order_id)
  candidate[id] = visit
 for flag in data.flags:
  if not flag in ["amgad","football","football_started"] or not data.flags[flag] is bool: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_daily_flags")
 history = restored_history
 _other_visit_counts = data.visit_counts.duplicate()
 visits = candidate
 memory = data.memory.duplicate(true)
 _flags = data.flags.duplicate()
 _cooldown = float(data.cooldown)
 _next = int(data.next_id)
 _rng.state = int(data.rng_state)
 return ActionResult.success()

func _remarks(visit: VisitState, delta: float) -> void:
 var definition := character(visit.character_id)
 var waiting: bool = _orders.pending_for(visit.id)!=null
 if not waiting and not definition.ambient: return
 visit.remark_remaining -= delta
 if visit.remark_remaining>0: return
 visit.remark_remaining = float(_data.waiting_reminder_seconds) if waiting else _rng.randf_range(float(_data.ambient_remark_delay[0]),float(_data.ambient_remark_delay[1]))
 encounter_requested.emit(&"reminder" if waiting else &"ambient",PackedStringArray([str(visit.id)]),{"character_id":str(visit.character_id)})

func visit_count(character_id: StringName) -> int:
 return int(memory.amgad_visits) if character_id==&"amgad" else int(_other_visit_counts.get(str(character_id),0))

func _has_character(character_id: StringName) -> bool:
 for visit in visits.values():
  if visit.character_id==character_id: return true
 return false

func _eligible(id: String) -> bool:
 if availability_provider.is_valid() and not availability_provider.call(id):return false
 var definition: Dictionary = _data.characters[id]
 if _has_character(StringName(id)) or not history.eligible(id,definition.visit_policy,_clock): return false
 var window: Array = definition.visit_policy.time_window
 if _clock.minutes<float(window[0]) or _clock.minutes>=float(window[1]): return false
 var marker: Array=_markers[definition.leisure_marker]
 return _position_available(Vector2(marker[0],marker[1]))

func update_markers(markers: Dictionary) -> void:
 _markers = markers.duplicate(true)
 for visit in visits.values():
  if visit.phase==&"leaving": continue
  var definition := character(visit.character_id)
  var key := str(definition.marker) if visit.shopping_state in [&"approaching",&"pending",&"served"] else str(definition.leisure_marker)
  var marker: Array = _markers[key]
  var target := Vector2(marker[0],marker[1])
  if visit.destination.distance_to(target)>0.01:
   visit.destination = target

func random_index(size: int) -> int:
 return _rng.randi_range(0,maxi(0,size-1))

func random_chance(probability: float) -> bool:
 return _rng.randf()<clampf(probability,0,1)
