class_name VisitorService
extends RefCounted
signal encounter_requested(kind: StringName, visit_ids: PackedStringArray, context: Dictionary)
signal departed(visit_id: StringName)
var visits: Dictionary = {}
var leisure := QuietLeisure.new()
var awareness := SpatialAwareness.new()
var meetings := VisitorMeetings.new()
var peers := PeerEncounters.new()
var peer_available: Callable
var peer_cancel: Callable
var peer_manual: Callable
var seating := VisitorSeating.new()
var seat_catalog: SeatCatalog
var seat_unavailable: Callable
var observed_actors: Callable
var sight_clear: Callable
var meeting_available: Callable
var route_reachable: Callable
var history := VisitorHistory.new()
var memory: Dictionary = {"amgad_visits":0,"last_served_quality":""}
var service_presence: Callable
var service_busy: Callable
var availability_provider: Callable
var purchase_blocked: Callable
var demand_provider: Callable
var food_selector: Callable
var tuning: TuningStore
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
 leisure.configure(data.get("leisure",{}))
 awareness.configure(data.get("awareness",{}))
 meetings.configure(data.get("meetings",{}))
 peers.configure(data.get("peer_encounters",{}))
 seating.configure(data.get("seating",{}),seat_catalog,data.characters)
 seating.item_busy=seat_unavailable
 seating.released.connect(_seat_released)
 _markers = markers.duplicate(true)
 _clock = clock
 _orders = orders
 _open = open
 if int(data.seed)==0:_rng.randomize()
 else:_rng.seed = int(data.seed)
 _cooldown = _delay("initial_delay")
func character(id: StringName) -> Dictionary:
 var result: Dictionary=_data.characters.get(str(id),{}).duplicate(true)
 if not result.is_empty() and tuning!=null:result.name=tuning.display_name(str(id),str(result.name))
 return result
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
 visit.maximum_wait=float(_data.max_wait_seconds)
 visit.pose.location_id = &"kiosk"
 var spawn_position: Array = _markers[_data.spawn_markers[_rng.randi_range(0,_data.spawn_markers.size()-1)]]
 visit.pose.ground = Vector2(spawn_position[0],spawn_position[1])
 var marker: Array = _markers[definition.leisure_marker]
 visit.destination = Vector2(marker[0],marker[1])
 visits[str(visit.id)] = visit
 return visit
func tick(delta: float, calendar_delta: float = -1) -> void:
 var elapsed := delta if calendar_delta<0 else calendar_delta
 awareness.step(delta,visits,observed_actors.call() if observed_actors.is_valid() else {},sight_clear)
 var peer_started := RuntimePerformance.begin()
 var event := peers.step(delta,visits,awareness,_peer_eligible,route_reachable,_position_available,peer_manual)
 RuntimePerformance.finish("peer_update",peer_started)
 if event.has("cancel") and not str(event.cancel).is_empty() and peer_cancel.is_valid():peer_cancel.call(event.cancel)
 var peer_initiator := peers.initiator()
 if peer_initiator!=&"" and not peers.paused(peer_initiator) and seating.reserved(peer_initiator):seating.release(peer_initiator)
 if event.has("encounter"):encounter_requested.emit(&"peer",event.participants,{"peer_id":event.id,"encounter_id":event.encounter})
 meetings.step(delta,visits,awareness,_can_meet,route_reachable,_position_available)
 seating.step(delta,visits,meetings,_seat_busy,_orders.pending_for,route_reachable,_position_available,sight_clear)
 for id in visits.keys():
  var visit: VisitState = visits[id]
  if (visit.phase==&"arriving" or visit.shopping_state==&"approaching") and visit.pose.ground.distance_to(visit.destination)<=float(_data.arrival_radius): _arrived(visit)
  elif visit.phase == &"staying":
   if not busy_in_conversation(visit.id):
    visit.elapsed += elapsed
    if not meetings.active(visit.id) and not peers.active(visit.id):
     _consider_purchase(visit,elapsed)
     _remarks(visit,delta)
    if not seating.reserved(visit.id) and not meetings.active(visit.id) and not peers.active(visit.id) and visit.shopping_state in [&"undecided",&"declined"] and _orders.pending_for(visit.id)==null and visit.pose.ground.distance_to(visit.destination)<=float(_data.arrival_radius):
     leisure.step(visit,elapsed,_markers,str(_data.characters[str(visit.character_id)].leisure_marker),_position_available,route_reachable)
   if (visit.elapsed >= visit.stay_seconds and (visit.served or visit.food_id==&"")) or visit.elapsed>=visit.maximum_wait:
    visit.phase = &"leaving"
    if peers.active(visit.id):finish_peer()
    meetings.finish(visit.id)
    seating.release(visit.id)
    var exit_position: Array = _markers[_data.exit_markers[_rng.randi_range(0,_data.exit_markers.size()-1)]]
    visit.destination = Vector2(exit_position[0],exit_position[1])
    _orders.cancel_visit(visit.id)
    visit.shopping_state=&"declined"
    departed.emit(visit.id)
  elif visit.phase == &"leaving" and visit.pose.ground.distance_to(visit.destination)<=float(_data.arrival_radius): visits.erase(id)
 leisure.prune(visits.keys())
 awareness.prune(visits)
 meetings.prune(visits)
 var cancelled_peer := peers.prune(visits)
 if not cancelled_peer.is_empty() and peer_cancel.is_valid():peer_cancel.call(cancelled_peer)
 seating.prune(visits)
 _cooldown=maxf(0,_cooldown-elapsed)
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
  if not _present() or (service_busy.is_valid() and service_busy.call()):
   visit.shopping_state=&"undecided"
   visit.food_id=&""
   _return_to_leisure(visit)
   return
  visit.needs_hospitality=history.request_hospitality(str(visit.character_id),visit.id,_data.get("hospitality",{}),visit_count(visit.character_id),_clock)
  visit.shopping_state=&"requesting"
  encounter_requested.emit(&"service_request",PackedStringArray([str(visit.id)]),{"character_id":str(visit.character_id)})
  return
 encounter_requested.emit(&"arrival",PackedStringArray([str(visit.id)]),{"character_id":str(visit.character_id)})
 # Peer conversation starts only after an observed, purposeful meeting.
func busy_in_conversation(visit_id: StringName) -> bool:
 return purchase_blocked.is_valid() and purchase_blocked.call(visit_id)
func _can_meet(visit: VisitState) -> bool:
 return not peers.active(visit.id) and visit.phase==&"staying" and visit.shopping_state in [&"undecided",&"declined"] and _orders.pending_for(visit.id)==null and not busy_in_conversation(visit.id) and meeting_available.is_valid() and bool(meeting_available.call(visit.id))
func _peer_eligible(visit: VisitState, own_conversation: String) -> bool:
 return visit.phase==&"staying" and (not own_conversation.is_empty() or peers.active(visit.id) or visit.pose.ground.distance_to(visit.destination)<=float(_data.arrival_radius)) and visit.shopping_state in [&"undecided",&"declined",&"served"] and _orders.pending_for(visit.id)==null and not meetings.active(visit.id) and peer_available.is_valid() and bool(peer_available.call(visit.id,own_conversation))
func _seat_busy(id: StringName) -> bool:
 return busy_in_conversation(id) or peers.active(id)
func effective_goal(visit: VisitState) -> Vector2:
 return peers.goal(visit,meetings.goal(visit))
func finish_peer() -> void:
 var cancelled := peers.finish()
 if not cancelled.is_empty() and peer_cancel.is_valid():peer_cancel.call(cancelled)
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
 if not _present() or (service_busy.is_valid() and service_busy.call()):return
 var definition := character(visit.character_id)
 var service_point := _service_point(visit)
 if not _position_available(service_point,visit.id):return
 if _rng.randf()>=float(definition.purchase_chance):visit.shopping_state=&"declined";return
 var food := StringName(str(food_selector.call(visit.character_id))) if food_selector.is_valid() else StringName(definition.food_id)
 if food.is_empty():visit.shopping_state=&"declined";return
 visit.food_id=food
 visit.shopping_state=&"approaching"
 visit.destination=service_point
func _service_point(visit: VisitState) -> Vector2:
 var slot := seating.slot_for(visit.id)
 if not slot.is_empty():return slot.access
 var marker: Array=_markers[character(visit.character_id).marker]
 return Vector2(marker[0],marker[1])
func _return_to_leisure(visit: VisitState) -> void:
 var slot := seating.slot_for(visit.id)
 if not slot.is_empty():visit.destination=slot.access;return
 var marker: Array=_markers[leisure.marker(visit.id,str(character(visit.character_id).leisure_marker))]
 visit.destination=Vector2(marker[0],marker[1])
func _seat_released(id: StringName) -> void:
 var visit: VisitState=visits.get(str(id))
 if visit==null or visit.phase==&"leaving" or _orders.pending_for(id)!=null:return
 if visit.shopping_state==&"approaching":visit.destination=_service_point(visit)
 elif visit.shopping_state in [&"undecided",&"declined",&"served"]:_return_to_leisure(visit)
func caption_ground(visit: VisitState) -> Vector2:
 return seating.slot_for(visit.id).anchor if seating.seated(visit.id) else visit.pose.ground
 # Keep staying phase: movement follows destination independently.
func is_available(visit_id: StringName) -> bool:
 return visits.has(str(visit_id)) and visits[str(visit_id)].phase == &"staying"
func commit_pose(visit_id: StringName, pose: ActorPose) -> void:
 if visits.has(str(visit_id)): visits[str(visit_id)].pose = pose
func record_service(_order_id: StringName, visit_id: StringName, item: PreparedItem, _payment: int) -> void:
 if not visits.has(str(visit_id)): return
 var visit: VisitState = visits[str(visit_id)]
 var order := _orders.order(_order_id)
 history.served(str(visit.character_id),_order_id,visit_id,item,order.settlement,order.payment)
 visit.served = true
 visit.shopping_state=&"served"
 visit.elapsed = 0
 visit.remark_remaining = _rng.randf_range(float(_data.ambient_remark_delay[0]),float(_data.ambient_remark_delay[1]))
 if visit.character_id == &"amgad": memory.last_served_quality = str(item.quality_key)
 encounter_requested.emit(&"served",PackedStringArray([str(visit_id)]),{"quality_score":item.quality_score,"character_id":str(visit.character_id)})
func record_settlement(order_id: StringName, visit_id: StringName, _item: PreparedItem, payment: int) -> void:
 history.record_settlement("",order_id,_orders.order(order_id).settlement,payment)
func clear_visits() -> void:
 var cancelled := peers.clear()
 if not cancelled.is_empty() and peer_cancel.is_valid():peer_cancel.call(cancelled)
 for visit in visits.values():
  _orders.cancel_visit(visit.id)
  departed.emit(visit.id)
 visits.clear()
 leisure.clear()
 awareness.clear()
 meetings.clear()
 seating.clear()
func begin_day() -> void:
 _flags.clear()
 # Do not reset the independent arrival clock at midnight.
func snapshot() -> Dictionary:
 var records: Dictionary = {}
 for id in visits: records[id] = visits[id].snapshot()
 return {"peers":peers.snapshot(),"seating":seating.snapshot(),"awareness":awareness.snapshot(),"meetings":meetings.snapshot(),"leisure":leisure.snapshot(),"history":history.snapshot(),"visits":records,"visit_counts":_other_visit_counts.duplicate(),"memory":memory.duplicate(true),"flags":_flags.duplicate(),"cooldown":_cooldown,"next_id":_next,"rng_state":str(_rng.state)}
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
  if not ContentValidation.bounded(record.get("maximum_wait"),0.01,86400):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visit_deadline")
  visit.maximum_wait=float(record.maximum_wait)
  visit.stay_seconds = float(record.stay_seconds)
  visit.destination = Vector2(record.destination[0],record.destination[1])
  visit.phase = StringName(record.phase)
  visit.elapsed = float(record.elapsed)
  visit.remark_remaining = float(record.remark_remaining)
  if not record.get("needs_hospitality") is bool:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_hospitality_state")
  visit.needs_hospitality=record.needs_hospitality
  visit.served = record.served
  if not record.get("shopping_state") in ["undecided","approaching","requesting","pending","declined","served"] or not ContentValidation.bounded(record.get("decision_remaining"),0,86400):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_purchase_decision")
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
 var leisure_candidate := QuietLeisure.new()
 leisure_candidate.configure(_data.get("leisure",{}))
 var leisure_result := leisure_candidate.restore(data.get("leisure",{}),candidate,_markers)
 if not leisure_result.ok:return leisure_result
 var awareness_candidate := SpatialAwareness.new()
 awareness_candidate.configure(_data.get("awareness",{}))
 var awareness_result := awareness_candidate.restore(data.get("awareness",{}),candidate,_data.characters)
 if not awareness_result.ok:return awareness_result
 var meetings_candidate := VisitorMeetings.new()
 meetings_candidate.configure(_data.get("meetings",{}))
 var meetings_result := meetings_candidate.restore(data.get("meetings",{"active":"","records":{}}),candidate)
 if not meetings_result.ok:return meetings_result
 var peer_candidate := PeerEncounters.new()
 peer_candidate.configure(_data.get("peer_encounters",{}))
 var peer_result := peer_candidate.restore(data.get("peers",PeerEncounters.empty_state()),candidate)
 if not peer_result.ok:return peer_result
 var seating_candidate := VisitorSeating.new()
 seating_candidate.configure(_data.get("seating",{}),seat_catalog,_data.characters)
 seating_candidate.item_busy=seat_unavailable
 var seating_result := seating_candidate.restore(data.get("seating",{}),candidate)
 if not seating_result.ok:return seating_result
 for id in candidate:
  if peer_candidate.active(StringName(id)) and meetings_candidate.active(StringName(id)):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"conflicting_visitor_intents")
  if peer_candidate.initiator()==StringName(id) and seating_candidate.reserved(StringName(id)):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"conflicting_visitor_intents")
  if meetings_candidate.active(StringName(id)) and seating_candidate.reserved(StringName(id)):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"conflicting_visitor_intents")
 seating_candidate.released.connect(_seat_released)
 if not meetings_candidate.snapshot().active.is_empty() and awareness_candidate.recalled(StringName(meetings_candidate.snapshot().active),"player").is_empty():return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"meeting_without_observation")
 peers=peer_candidate
 seating=seating_candidate
 awareness=awareness_candidate
 meetings=meetings_candidate
 leisure=leisure_candidate
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
  var slot := seating.slot_for(visit.id)
  if not slot.is_empty():visit.destination=slot.access;continue
  if _orders.pending_for(visit.id)!=null:continue
  var definition := character(visit.character_id)
  var key := str(definition.marker) if visit.shopping_state in [&"approaching",&"requesting",&"pending",&"served"] else leisure.marker(visit.id,str(definition.leisure_marker))
  var marker: Array = _markers[key]
  var target := Vector2(marker[0],marker[1])
  if visit.destination.distance_to(target)>0.01:
   visit.destination = target

func random_index(size: int) -> int:
 return _rng.randi_range(0,maxi(0,size-1))

func random_chance(probability: float) -> bool:
 return _rng.randf()<clampf(probability,0,1)

func _present() -> bool:
 return service_presence.is_valid() and bool(service_presence.call())
func accept_request(id: StringName, gift: bool=false) -> ActionResult:
 var visit: VisitState=visits.get(str(id))
 if visit==null or visit.phase!=&"staying" or not _present():return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"visitor_unavailable")
 var existing := _orders.pending_for(id)
 if existing!=null:return ActionResult.success({"order_id":str(existing.id),"duplicate":true})
 if visit.shopping_state!=&"requesting":return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"order_unavailable")
 if visit.needs_hospitality and not gift:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"hospitality_promised")
 var order := _orders.place_order(id,visit.food_id,gift)
 if order==null:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"order_unavailable")
 visit.order_id=order.id
 if visit.needs_hospitality:history.decide_hospitality(str(visit.character_id),visit.id,"accepted",order.id,_clock)
 visit.shopping_state=&"pending"
 return ActionResult.success({"order_id":str(order.id)})
func decline_request(id: StringName) -> ActionResult:
 var visit: VisitState=visits.get(str(id))
 if visit==null or visit.shopping_state!=&"requesting":return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"order_unavailable")
 if visit.needs_hospitality:history.decide_hospitality(str(visit.character_id),visit.id,"declined",&"",_clock)
 visit.needs_hospitality=false
 visit.food_id=&""
 visit.shopping_state=&"declined"
 _return_to_leisure(visit)
 return ActionResult.success()
func reset_request(id: StringName) -> void:
 var visit: VisitState=visits.get(str(id))
 if visit==null or visit.shopping_state!=&"requesting":return
 visit.food_id=&""
 visit.shopping_state=&"undecided"
 visit.decision_remaining=_delay("purchase_retry_delay")
 _return_to_leisure(visit)

func navigation_alternative(id: StringName) -> bool:
 var visit: VisitState=visits.get(str(id))
 if visit==null or not route_reachable.is_valid() or _orders.pending_for(id)!=null:return false
 if visit.phase!=&"leaving" and not (visit.phase==&"arriving" or visit.shopping_state in [&"undecided",&"declined",&"approaching"]):return false
 var names: Array=_data.exit_markers if visit.phase==&"leaving" else leisure.candidates(str(_data.characters[str(visit.character_id)].leisure_marker))
 for key in names:
  var point := Vector2(_markers[key][0],_markers[key][1])
  if point.distance_to(visit.destination)<=float(_data.arrival_radius) or not _position_available(point,id) or not route_reachable.call(visit.pose.ground,point):continue
  visit.destination=point
  if visit.phase!=&"leaving":
   leisure.remember(visit.id,str(key))
   if visit.shopping_state==&"approaching":visit.shopping_state=&"declined";visit.food_id=&""
  return true
 return false
