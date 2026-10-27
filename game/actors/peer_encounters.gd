class_name PeerEncounters
extends RefCounted
## Intent/reservations only. Domain visits and Ink remain separately owned.
var _data: Dictionary={}
var _records: Dictionary={}
var _active: Dictionary={}
var _next: int=1
var _cooldown: float=0
func configure(data: Dictionary) -> void:
 _data=data.duplicate(true)
func active(id: StringName) -> bool:
 return not _active.is_empty() and str(id) in [_active.initiator,_active.target]
func initiator() -> StringName:
 return StringName(_active.get("initiator",""))
func prune(visits: Dictionary) -> String:
 for id in _records.keys():
  if not visits.has(id):_records.erase(id)
 if not _active.is_empty() and (not visits.has(_active.initiator) or not visits.has(_active.target)):return finish()
 return ""
func paused(id: StringName) -> bool:
 return active(id) and (str(id)==_active.target or _active.phase!="approaching")
func goal(visit: VisitState, fallback: Vector2) -> Vector2:
 if not active(visit.id):return fallback
 var point: Array=_active.goal if str(visit.id)==_active.initiator else _active.target_point
 return Vector2(point[0],point[1])
func pending(id: String, participants: PackedStringArray) -> bool:
 return not _active.is_empty() and _active.id==id and _active.phase=="greeting" and participants==PackedStringArray([_active.initiator,_active.target])
func link(id: String, conversation: String) -> bool:
 if _active.is_empty() or _active.id!=id or _active.phase!="greeting":return false
 _active.phase="conversing";_active.conversation=conversation
 return true
func conversation_ended(id: String) -> void:
 if not _active.is_empty() and _active.conversation==id:finish()
func finish() -> String:
 if _active.is_empty():return ""
 var conversation: String=_active.conversation
 _active={};_cooldown=float(_data.get("cooldown_seconds",15))
 RuntimePerformance.observe("peer_finished",0)
 return conversation
func clear() -> String:
 var cancelled := finish()
 _records.clear();_cooldown=0
 return cancelled
func step(delta: float, visits: Dictionary, awareness: SpatialAwareness, eligible: Callable, reachable: Callable, available: Callable, manual: Callable=Callable()) -> Dictionary:
 for id in _records.keys():
  if not visits.has(id):_records.erase(id)
 _cooldown=maxf(0,_cooldown-delta)
 if not _data.get("enabled",false):return {"cancel":finish()} if not _active.is_empty() else {}
 if not _active.is_empty():
  if not visits.has(_active.initiator) or not visits.has(_active.target):return {"cancel":finish()}
  var a: VisitState=visits[_active.initiator]
  var b: VisitState=visits[_active.target]
  if a.pose.location_id!=b.pose.location_id or not eligible.call(a,str(_active.conversation)) or not eligible.call(b,str(_active.conversation)):return {"cancel":finish()}
  if not (manual.is_valid() and not str(_active.conversation).is_empty() and manual.call(str(_active.conversation))):_active.elapsed=float(_active.elapsed)+delta
  if float(_active.elapsed)>=float(_data.max_seconds):return {"cancel":finish()}
  if _active.phase=="conversing":return {}
  var memory := awareness.recalled(a.id,str(b.character_id))
  if memory.is_empty() or memory.location!=str(a.pose.location_id):return {"cancel":finish()}
  var observed := Vector2(memory.ground[0],memory.ground[1])
  var last := Vector2(_active.observed[0],_active.observed[1])
  # A moving target is no longer waiting at the reserved meeting point.
  if observed.distance_to(last)>float(_data.target_tolerance):return {"cancel":finish()}
  if _active.phase=="approaching" and a.pose.ground.distance_to(goal(a,a.destination))<=float(_data.arrival_radius):
   if not awareness.visible(a.id,str(b.character_id)) or a.pose.ground.distance_to(b.pose.ground)>float(_data.stop_distance)+float(_data.arrival_radius)+float(_data.target_tolerance):return {"cancel":finish()}
   _active.phase="greeting"
   return {"id":_active.id,"encounter":_active.encounter,"participants":PackedStringArray([a.id,b.id])}
  return {}
 if _cooldown>0 or not eligible.is_valid() or not reachable.is_valid():return {}
 for id in visits:
  var a: VisitState=visits[id]
  var pair: Dictionary={}
  for definition: Dictionary in _data.pairs.values():
   if definition.initiator==str(a.character_id):pair=definition;break
  if pair.is_empty():continue
  if not _records.has(id):
   var interval: Array=_data.delay_seconds
   _records[id]={"attempted":false,"remaining":lerpf(float(interval[0]),float(interval[1]),_sample(a.id,"delay"))}
  var record: Dictionary=_records[id]
  if record.attempted or not eligible.call(a,""):continue
  record.remaining=maxf(0,float(record.remaining)-delta)
  if record.remaining>0:continue
  var b: VisitState=null
  for other: VisitState in visits.values():
   if str(other.character_id)==pair.target:b=other;break
  if b==null or not eligible.call(b,"") or a.pose.location_id!=b.pose.location_id or not awareness.visible(a.id,str(b.character_id)):continue
  var memory := awareness.recalled(a.id,str(b.character_id))
  if memory.is_empty():continue
  var observed := Vector2(memory.ground[0],memory.ground[1])
  if observed.distance_to(b.pose.ground)>float(_data.target_tolerance):continue
  record.attempted=true
  if _sample(a.id,"chance")>=float(_data.chance):continue
  var direction := observed.direction_to(a.pose.ground)
  if direction.is_zero_approx():direction=Vector2.DOWN
  var search_started := RuntimePerformance.begin()
  var chosen := Vector2(INF,INF)
  for index in range(8):
   var candidate := observed+direction.rotated(float(index)*TAU/8)*float(_data.stop_distance)
   if available.is_valid() and not available.call(candidate,a.id):continue
   if reachable.call(a.pose.ground,candidate):chosen=candidate;break
  RuntimePerformance.finish("peer_search",search_started)
  if not chosen.is_finite():continue
  _active={"id":"peer_%d" % _next,"initiator":str(a.id),"target":str(b.id),"encounter":pair.encounter,"phase":"approaching","elapsed":0.0,"goal":[chosen.x,chosen.y],"observed":[observed.x,observed.y],"target_point":[b.pose.ground.x,b.pose.ground.y],"conversation":""}
  _next+=1
  RuntimePerformance.observe("peer_started",0)
  break
 return {}
func snapshot() -> Dictionary:
 return {"active":_active.duplicate(true),"records":_records.duplicate(true),"next_id":_next,"cooldown":_cooldown}
func restore(data: Variant, visits: Dictionary) -> ActionResult:
 if not data is Dictionary or not data.get("active") is Dictionary or not data.get("records") is Dictionary or data.records.size()>4 or not ContentValidation.integer(data.get("next_id")) or data.next_id<1 or not ContentValidation.bounded(data.get("cooldown"),0,86400):return _fail()
 for id in data.records:
  var record: Variant=data.records[id]
  if not visits.has(id) or not record is Dictionary or not record.get("attempted") is bool or not ContentValidation.bounded(record.get("remaining"),0,86400):return _fail()
 var a: Dictionary=data.active
 if not a.is_empty():
  for key in ["id","initiator","target","encounter","phase","conversation"]:
   if not a.get(key) is String:return _fail()
  if not a.id.begins_with("peer_") or not a.id.trim_prefix("peer_").is_valid_int() or int(a.id.trim_prefix("peer_"))<1 or int(a.id.trim_prefix("peer_"))>=data.next_id or a.id.trim_prefix("peer_")!=str(int(a.id.trim_prefix("peer_"))):return _fail()
  if a.initiator==a.target or not visits.has(a.initiator) or not visits.has(a.target) or not data.records.has(a.initiator) or not data.records[a.initiator].attempted:return _fail()
  if not a.phase in ["approaching","greeting","conversing"] or not ContentValidation.bounded(a.get("elapsed"),0,86400) or (a.phase=="conversing")!=not a.conversation.is_empty():return _fail()
  for key in ["goal","observed","target_point"]:
   if not ContentValidation.vector(a.get(key),2):return _fail()
  for id in [a.initiator,a.target]:
   if visits[id].phase!=&"staying" or not visits[id].shopping_state in [&"undecided",&"declined",&"served"]:return _fail()
  if visits[a.initiator].pose.location_id!=visits[a.target].pose.location_id:return _fail()
 _active=a.duplicate(true);_records=data.records.duplicate(true);_next=int(data.next_id);_cooldown=float(data.cooldown)
 if not _data.get("enabled",false):_active={}
 elif not _active.is_empty():
  var match_pair := false
  for pair: Dictionary in _data.pairs.values():
   if pair.initiator==str(visits[a.initiator].character_id) and pair.target==str(visits[a.target].character_id) and pair.encounter==a.encounter:match_pair=true
  if not match_pair:_active={}
  elif _active.phase=="greeting":_active.phase="approaching"
 return ActionResult.success()
static func empty_state() -> Dictionary:
 return {"active":{},"records":{},"next_id":1,"cooldown":0.0}
static func _sample(id: StringName, salt: String) -> float:
 return float((str(id)+":peer:"+salt).sha256_text().substr(0,8).hex_to_int())/4294967296.0
static func _fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_peer_encounters")
