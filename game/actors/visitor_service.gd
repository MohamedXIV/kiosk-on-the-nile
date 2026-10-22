class_name VisitorService
extends RefCounted
signal encounter_requested(kind: StringName, visit_ids: PackedStringArray, context: Dictionary)
signal departed(visit_id: StringName)
var visits: Dictionary = {}
var history := VisitorHistory.new()
var memory: Dictionary = {"amgad_visits":0,"last_served_quality":""}
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
 _data = data.duplicate(true)
 _markers = markers.duplicate(true)
 _clock = clock
 _orders = orders
 _open = open
 _rng.seed = int(data.seed)
 _cooldown = float(data.initial_cooldown)
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
 visit.food_id = StringName(definition.food_id)
 visit.stay_seconds = float(definition.stay_seconds)
 visit.pose.location_id = &"kiosk"
 var spawn_position: Array = _markers[_data.spawn_markers[_rng.randi_range(0,_data.spawn_markers.size()-1)]]
 visit.pose.ground = Vector2(spawn_position[0],spawn_position[1])
 var marker: Array = _markers[definition.marker]
 visit.destination = Vector2(marker[0],marker[1])
 visits[str(visit.id)] = visit
 return visit
func tick(delta: float) -> void:
 for id in visits.keys():
  var visit: VisitState = visits[id]
  if visit.phase == &"arriving" and visit.pose.ground.distance_to(visit.destination)<=float(_data.arrival_radius): _arrived(visit)
  elif visit.phase == &"staying":
   visit.elapsed += delta
   _remarks(visit,delta)
   if (visit.elapsed >= visit.stay_seconds and (visit.served or visit.food_id==&"")) or visit.elapsed>=float(_data.max_wait_seconds):
    visit.phase = &"leaving"
    var exit_position: Array = _markers[_data.exit_markers[_rng.randi_range(0,_data.exit_markers.size()-1)]]
    visit.destination = Vector2(exit_position[0],exit_position[1])
    _orders.cancel_visit(visit.id)
    departed.emit(visit.id)
  elif visit.phase == &"leaving" and visit.pose.ground.distance_to(visit.destination)<=float(_data.arrival_radius): visits.erase(id)
 if not _open.call(): return
 if not _flags.get("amgad",false) and visits.size()<int(_data.regular_capacity) and _eligible("amgad"):
  _flags.amgad = true
  spawn(&"amgad")
  return
 if not _flags.get("football",false) and _clock.minutes>=float(_data.football_minutes) and visits.size()<=int(_data.football_capacity_before_pair) and _eligible("mahmoud") and _eligible("samir"):
  _flags.football = true
  spawn(&"mahmoud")
  spawn(&"samir")
  return
 var quiet: Dictionary = _data.quiet
 if _clock.day==int(quiet.day) and _clock.minutes>=float(quiet.start) and _clock.minutes<=float(quiet.end): return
 _cooldown -= delta
 if _cooldown<=0 and visits.size()<int(_data.ambient_capacity):
  _cooldown = _rng.randf_range(float(_data.ambient_delay[0]),float(_data.ambient_delay[1]))
  var pool: Array = []
  for id in _data.characters:
   if _data.characters[id].ambient and _eligible(id): pool.append(id)
  if not pool.is_empty():
   var oldest := INF
   for id in pool: oldest=minf(oldest,history.last_visit(id))
   var candidates: Array = pool.filter(func(id):return history.last_visit(id)==oldest)
   spawn(StringName(candidates[_rng.randi_range(0,candidates.size()-1)]))
func _arrived(visit: VisitState) -> void:
 visit.phase = &"staying"
 visit.elapsed = 0
 visit.remark_remaining = float(_data.waiting_reminder_seconds)
 var definition := character(visit.character_id)
 if not visit.food_id.is_empty():
  var order := _orders.place_order(visit.id,visit.food_id)
  if order: visit.order_id = order.id
 if visit.character_id == &"amgad": memory.amgad_visits += 1
 else: _other_visit_counts[str(visit.character_id)] = visit_count(visit.character_id)+1
 if visit.character_id in [&"samir",&"mahmoud"] and not _flags.get("football_started",false):
  var pair := PackedStringArray()
  for other in visits.values():
   if other.character_id in [&"mahmoud",&"samir"] and other.phase == &"staying": pair.append(str(other.id))
  if pair.size()==2:
   _flags.football_started = true
   encounter_requested.emit(&"football",pair,{})
 else: encounter_requested.emit(&"arrival",PackedStringArray([str(visit.id)]),{"character_id":str(visit.character_id)})
func is_available(visit_id: StringName) -> bool:
 return visits.has(str(visit_id)) and visits[str(visit_id)].phase == &"staying"
func commit_pose(visit_id: StringName, pose: ActorPose) -> void:
 if visits.has(str(visit_id)): visits[str(visit_id)].pose = pose
func record_service(_order_id: StringName, visit_id: StringName, item: PreparedItem, _payment: int) -> void:
 if not visits.has(str(visit_id)): return
 var visit: VisitState = visits[str(visit_id)]
 history.served(str(visit.character_id),_order_id,visit_id,item)
 visit.served = true
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
 _cooldown = float(_data.initial_cooldown)
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
 if not data.get("history") is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visitor_history")
 var history_result := restored_history.restore(data.history,_data.characters,_clock)
 if not history_result.ok: return history_result
 var candidate: Dictionary = {}
 for id in data.visits:
  var record: Variant = data.visits[id]
  if not record is Dictionary or record.get("id")!=id or not _data.characters.has(record.get("character_id")) or not record.get("phase") in ["arriving","staying","leaving"] or not ContentValidation.vector(record.get("destination"),2) or not ContentValidation.number(record.get("elapsed")) or record.elapsed<0 or not record.get("served") is bool or not record.get("order_id") is String or not record.get("pose") is Dictionary or not ContentValidation.number(record.get("remark_remaining")): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visit")
  var suffix: String = str(id).trim_prefix("visit_")
  if not str(id).begins_with("visit_") or not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=int(data.next_id): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visit_identity")
  if not record.get("food_id") in ["tea","kebda",""] or not ContentValidation.number(record.get("stay_seconds")) or record.stay_seconds<=0: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visit_intention")
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
 var waiting: bool = not visit.served and not visit.food_id.is_empty()
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
 var definition: Dictionary = _data.characters[id]
 if _has_character(StringName(id)) or not history.eligible(id,definition.visit_policy,_clock): return false
 var window: Array = definition.visit_policy.time_window
 if _clock.minutes<float(window[0]) or _clock.minutes>=float(window[1]): return false
 for visit: VisitState in visits.values():
  if character(visit.character_id).marker==definition.marker: return false
 return true

func update_markers(markers: Dictionary) -> void:
 _markers = markers.duplicate(true)
 for visit in visits.values():
  if visit.phase==&"leaving": continue
  var definition := character(visit.character_id)
  var marker: Array = _markers[definition.marker]
  var target := Vector2(marker[0],marker[1])
  if visit.destination.distance_to(target)>0.01:
   visit.destination = target
