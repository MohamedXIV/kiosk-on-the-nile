class_name QuietLeisure
extends RefCounted
## Rare visit-owned leisure intent, independent of purchase/conversation RNG.
var _data: Dictionary={}
var _records: Dictionary={}
func configure(data: Dictionary) -> void:
 _data=data.duplicate(true)
func marker(id: StringName, fallback: String) -> String:
 return str(_records.get(str(id),{}).get("marker",fallback))
func remember(id: StringName, name: String) -> void:
 if not _records.has(str(id)):_records[str(id)]={"remaining":_interval(id,0),"moves":0,"checks":0,"marker":name}
 else:_records[str(id)].marker=name
func step(visit: VisitState, delta: float, markers: Dictionary, fallback: String, available: Callable, reachable: Callable) -> void:
 if not _data.get("enabled",false) or not reachable.is_valid():return
 remember(visit.id,marker(visit.id,fallback))
 var record: Dictionary=_records[str(visit.id)]
 if int(record.moves)>=int(_data.max_moves):return
 record.remaining=maxf(0,float(record.remaining)-delta)
 if record.remaining>0:return
 record.checks=int(record.checks)+1
 record.remaining=_interval(visit.id,int(record.checks))
 if _sample(visit.id,int(record.checks),"chance")>=float(_data.chance):return
 var names: Array=_data.markers
 var start := int(_sample(visit.id,int(record.checks),"marker")*names.size())%names.size()
 for i in range(names.size()):
  var name := str(names[(start+i)%names.size()])
  var point := Vector2(markers[name][0],markers[name][1])
  var distance := visit.pose.ground.distance_to(point)
  if distance<=0.2 or distance>float(_data.max_distance) or not available.call(point,visit.id) or not reachable.call(visit.pose.ground,point):continue
  record.moves=int(record.moves)+1;record.marker=name
  visit.destination=point
  return
func candidates(fallback: String) -> Array:
 var names: Array=[fallback]
 for name in _data.get("markers",[]):
  if name not in names:names.append(name)
 return names
func prune(ids: Array) -> void:
 for id in _records.keys():
  if not id in ids:_records.erase(id)
func clear() -> void:
 _records.clear()
func snapshot() -> Dictionary:
 return _records.duplicate(true)
func restore(data: Variant, visits: Dictionary, markers: Dictionary) -> ActionResult:
 if not data is Dictionary:return _fail()
 for id in data:
  var record: Variant=data[id]
  if not visits.has(id) or not record is Dictionary or not ContentValidation.bounded(record.get("remaining"),0,86400) or not ContentValidation.integer(record.get("moves")) or record.moves<0 or record.moves>100 or not ContentValidation.integer(record.get("checks")) or record.checks<0 or record.checks>100000 or not record.get("marker") is String or not markers.has(record.marker):return _fail()
 _records=data.duplicate(true)
 return ActionResult.success()
func _interval(id: StringName, check: int) -> float:
 var interval: Array=_data.get("interval_minutes",[30,65])
 return lerpf(float(interval[0]),float(interval[1]),_sample(id,check,"interval"))
static func _sample(id: StringName, check: int, salt: String) -> float:
 return float((str(id)+":"+str(check)+":"+salt).sha256_text().substr(0,8).hex_to_int())/4294967296.0
static func _fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visitors")
