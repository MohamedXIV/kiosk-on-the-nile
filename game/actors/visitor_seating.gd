class_name VisitorSeating
extends RefCounted
signal released(visit_id: StringName)
## Visit-owned exclusive reservations. Neither paths nor furniture own orders.
var catalog: SeatCatalog
var item_busy: Callable
var external_owner: Callable
var _data: Dictionary={}
var _characters: Dictionary={}
var _records: Dictionary={}
func configure(data: Dictionary, seats: SeatCatalog, characters: Dictionary) -> void:
 _data=data.duplicate(true);catalog=seats;_characters=characters.duplicate(true)
func step(delta: float, visits: Dictionary, meetings: VisitorMeetings, busy: Callable, pending: Callable, reachable: Callable, available: Callable, sight: Callable) -> void:
 prune(visits)
 if catalog==null:return
 for id in visits:
  var visit: VisitState=visits[id]
  if visit.phase==&"leaving":release(visit.id);continue
  if not _data.get("enabled",false):release(visit.id);continue
  if not _records.has(id):
   var interval: Array=_data.delay_seconds
   _records[id]={"seat":"","seated":false,"decided":false,"willing":false,"tries":0,"remaining":lerpf(float(interval[0]),float(interval[1]),_sample(visit.id,"delay"))}
  var record: Dictionary=_records[id]
  if meetings.active(visit.id):release(visit.id);continue
  if not str(record.seat).is_empty():
   var slot := catalog.lookup(str(record.seat))
   if slot.is_empty() or slot.location_id!=str(visit.pose.location_id):
    release(visit.id)
    continue
   if not record.seated and _being_cleaned(slot):release(visit.id);continue
   # Selected access follows moved empty furniture. Occupied furniture is busy.
   visit.destination=slot.access
   record.seated=visit.pose.ground.distance_to(slot.access)<=float(_data.arrival_radius)
   continue
  if busy.call(visit.id) or pending.call(visit.id)!=null or not visit.shopping_state in [&"undecided",&"declined",&"served"]:continue
  record.remaining=maxf(0,float(record.remaining)-delta)
  if record.remaining>0 or int(record.tries)>=int(_data.max_searches):continue
  if not record.decided:
   record.decided=true
   record.willing=_sample(visit.id,"chance")<float(_characters[str(visit.character_id)].get("seating_chance",0))
  if not record.willing:continue
  if not reachable.is_valid() or not sight.is_valid():continue
  record.tries=int(record.tries)+1
  record.remaining=float(_data.retry_seconds)
  var candidates := catalog.entries(visit.pose.location_id)
  candidates.sort_custom(func(a,b):
   var first: float=visit.pose.ground.distance_squared_to(a.access)
   var second: float=visit.pose.ground.distance_squared_to(b.access)
   return str(a.id)<str(b.id) if is_equal_approx(first,second) else first<second)
  var perf := RuntimePerformance.begin()
  for index in range(mini(candidates.size(),int(_data.max_candidates))):
   var slot: Dictionary=candidates[index]
   if visit.pose.ground.distance_to(slot.access)>float(_data.search_radius) or owner(str(slot.id))!=&"" or (external_owner.is_valid() and external_owner.call(str(slot.id))!=&""):continue
   if _being_cleaned(slot):continue
   if not available.call(slot.access,visit.id) or not sight.call(visit.pose.ground,slot.access) or not reachable.call(visit.pose.ground,slot.access):continue
   record.seat=str(slot.id);record.seated=false
   visit.destination=slot.access
   RuntimePerformance.observe("seat_reserved",0)
   break
  RuntimePerformance.finish("seat_search",perf)
func _being_cleaned(slot: Dictionary) -> bool:
 return item_busy.is_valid() and (item_busy.call(StringName(slot.item_id)) or (slot.table_id!="" and item_busy.call(StringName(slot.table_id))))
func slot_for(id: StringName) -> Dictionary:
 return catalog.lookup(str(_records.get(str(id),{}).get("seat",""))) if catalog!=null else {}
func reserved(id: StringName) -> bool:
 return not slot_for(id).is_empty()
func seated(id: StringName) -> bool:
 return bool(_records.get(str(id),{}).get("seated",false)) and reserved(id)
func owner(slot_id: String) -> StringName:
 for id in _records:
  if _records[id].seat==slot_id:return StringName(id)
 return &""
func busy_item(item_id: StringName) -> bool:
 for id in _records:
  if not seated(StringName(id)):continue
  var slot := slot_for(StringName(id))
  if slot.item_id==str(item_id) or slot.table_id==str(item_id):return true
 return false
func release(id: StringName) -> void:
 var record: Dictionary=_records.get(str(id),{})
 if record.is_empty() or str(record.seat).is_empty():return
 record.seat="";record.seated=false;record.remaining=float(_data.get("retry_seconds",8))
 RuntimePerformance.observe("seat_released",0)
 released.emit(id)
func prune(visits: Dictionary) -> void:
 for id in _records.keys():
  if not visits.has(id):_records.erase(id)
func clear() -> void:
 _records.clear()
func snapshot() -> Dictionary:
 return _records.duplicate(true)
func restore(data: Variant, visits: Dictionary) -> ActionResult:
 if not data is Dictionary or data.size()>4:return _fail()
 var used: Dictionary={}
 var candidate: Dictionary=data.duplicate(true)
 for id in candidate:
  var record: Variant=candidate[id]
  if not visits.has(id) or not record is Dictionary or not record.get("seat") is String:return _fail()
  for flag in ["seated","decided","willing"]:
   if not record.get(flag) is bool:return _fail()
  if not ContentValidation.integer(record.get("tries")) or record.tries<0 or record.tries>100 or not ContentValidation.bounded(record.get("remaining"),0,86400):return _fail()
  if record.willing and not record.decided:return _fail()
  if record.seated and record.seat.is_empty():return _fail()
  if record.seat.is_empty():continue
  if used.has(record.seat) or not record.decided or not record.willing or record.tries<1:return _fail()
  used[record.seat]=id
  var slot := catalog.lookup(record.seat) if catalog!=null else {}
  if slot.is_empty() or not _data.get("enabled",false):record.seat="";record.seated=false;continue
  var visit: VisitState=visits[id]
  if slot.location_id!=str(visit.pose.location_id) or visit.phase==&"leaving":return _fail()
  if record.seated and (visit.phase!=&"staying" or visit.pose.ground.distance_to(slot.access)>float(_data.arrival_radius)+0.001):return _fail()
 _records=candidate
 return ActionResult.success()
static func _sample(id: StringName, salt: String) -> float:
 return float((str(id)+":seat:"+salt).sha256_text().substr(0,8).hex_to_int())/4294967296.0
static func _fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visitor_seating")
