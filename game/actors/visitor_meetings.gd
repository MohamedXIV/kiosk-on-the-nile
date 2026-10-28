class_name VisitorMeetings
extends RefCounted
## Optional social intent. Movement overlays the visit destination, never its order.
var _data: Dictionary={}
var _records: Dictionary={}
var _active: String=""
func configure(data: Dictionary) -> void:
 _data=data.duplicate(true)
func step(delta: float, visits: Dictionary, awareness: SpatialAwareness, eligible: Callable, reachable: Callable, available: Callable) -> void:
 for id in _records.keys():
  if not visits.has(id):_records.erase(id)
 if not _active.is_empty() and not visits.has(_active):_active=""
 if not _data.get("enabled",false) or not eligible.is_valid() or not reachable.is_valid():_active="";return
 for id in visits:
  var visit: VisitState=visits[id]
  if not str(visit.character_id) in _data.actors:
   finish(visit.id)
   continue
  if not _records.has(id):
   var delay: Array=_data.get("delay_overrides",{}).get(str(visit.character_id),_data.delay_seconds)
   _records[id]={"remaining":lerpf(float(delay[0]),float(delay[1]),_sample(visit.id,"meeting_delay")),"attempted":false,"elapsed":0.0,"waiting":0.0,"retarget":0.0,"goal":[],"observed":[]}
  var record: Dictionary=_records[id]
  if id==_active:
   if not eligible.call(visit):finish(visit.id);continue
   record.elapsed=float(record.elapsed)+delta
   record.retarget=maxf(0,float(record.retarget)-delta)
   var memory := awareness.recalled(visit.id,"player")
   if memory.is_empty() or float(record.elapsed)>=float(_data.max_seconds):finish(visit.id);continue
   var observed := Vector2(memory.ground[0],memory.ground[1])
   var previous := Vector2(record.observed[0],record.observed[1])
   if awareness.visible(visit.id,"player") and record.retarget<=0 and observed.distance_to(previous)>=float(_data.retarget_distance):
    record.retarget=float(_data.retarget_seconds)
    if not _set_goal(visit,record,observed,reachable,available):finish(visit.id);continue
   if visit.pose.ground.distance_to(goal(visit))<=0.15:
    if awareness.visible(visit.id,"player"):record.waiting=0.0
    else:record.waiting=float(record.waiting)+delta
    if float(record.waiting)>=float(_data.lost_wait_seconds):finish(visit.id)
   continue
  if record.attempted or not _active.is_empty() or not eligible.call(visit):continue
  record.remaining=maxf(0,float(record.remaining)-delta)
  if record.remaining>0:continue
  var memory := awareness.recalled(visit.id,"player")
  if memory.is_empty():continue
  record.attempted=true
  if _sample(visit.id,"meeting_chance")>=float(_data.chance):continue
  if _set_goal(visit,record,Vector2(memory.ground[0],memory.ground[1]),reachable,available):
   _active=id
   RuntimePerformance.observe("meeting_started",0)
func _set_goal(visit: VisitState, record: Dictionary, target: Vector2, reachable: Callable, available: Callable) -> bool:
 var perf := RuntimePerformance.begin()
 var direction := target.direction_to(visit.pose.ground)
 if direction.is_zero_approx():direction=Vector2.DOWN
 for i in range(8):
  var candidate := target+direction.rotated(float(i)*TAU/8)*float(_data.stop_distance)
  if available.is_valid() and not available.call(candidate,visit.id):continue
  if not reachable.call(visit.pose.ground,candidate):continue
  record.goal=[candidate.x,candidate.y];record.observed=[target.x,target.y];record.waiting=0.0
  RuntimePerformance.finish("meeting_goal",perf)
  return true
 RuntimePerformance.finish("meeting_goal",perf)
 return false
func active(id: StringName) -> bool:
 return _active==str(id)
func goal(visit: VisitState) -> Vector2:
 if not active(visit.id):return visit.destination
 var point: Array=_records[_active].goal
 return Vector2(point[0],point[1])
func finish(id: StringName) -> void:
 if not active(id):return
 _active=""
 RuntimePerformance.observe("meeting_finished",0)
func clear() -> void:
 _active="";_records.clear()
func prune(visits: Dictionary) -> void:
 for id in _records.keys():
  if not visits.has(id):_records.erase(id)
 if not _active.is_empty() and not visits.has(_active):_active=""
func snapshot() -> Dictionary:
 return {"active":_active,"records":_records.duplicate(true)}
func restore(data: Variant, visits: Dictionary) -> ActionResult:
 if not data is Dictionary or not data.get("active") is String or not data.get("records") is Dictionary or data.records.size()>4:return _fail()
 if data.active!="" and not data.records.has(data.active):return _fail()
 for id in data.records:
  var record: Variant=data.records[id]
  if not visits.has(id) or not record is Dictionary or not record.get("attempted") is bool:return _fail()
  for key in ["remaining","elapsed","waiting","retarget"]:
   if not ContentValidation.bounded(record.get(key),0,86400):return _fail()
  for key in ["goal","observed"]:
   if not record.get(key) is Array or (not record[key].is_empty() and not ContentValidation.vector(record[key],2)):return _fail()
  if id==data.active and (not record.attempted or record.goal.is_empty() or record.observed.is_empty() or visits[id].phase!=&"staying" or not visits[id].shopping_state in [&"undecided",&"declined"]):return _fail()
 _records=data.records.duplicate(true);_active=data.active
 # Policy edits must not strand an active overlay or invalidate the whole save.
 if not _active.is_empty() and (not _data.get("enabled",false) or not str(visits[_active].character_id) in _data.get("actors",[])):_active=""
 return ActionResult.success()
static func _sample(id: StringName, salt: String) -> float:
 return float((str(id)+":"+salt).sha256_text().substr(0,8).hex_to_int())/4294967296.0
static func _fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visitor_meetings")
