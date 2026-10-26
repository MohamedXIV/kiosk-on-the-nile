class_name SpatialAwareness
extends RefCounted
## Stores observations only; never resolves an unseen actor's live position.
var _data: Dictionary={}
var _records: Dictionary={}
var _visible: Dictionary={}
var _remaining: float=0
var _cursor: int=0
func configure(data: Dictionary) -> void:
 _data=data.duplicate(true)
func enabled() -> bool:
 return bool(_data.get("enabled",false))
func step(delta: float, visits: Dictionary, actors: Dictionary, sight: Callable) -> void:
 for id in _records.keys():
  if not visits.has(id):_records.erase(id);continue
  for target in _records[id].keys():
   var record: Dictionary=_records[id][target]
   record.age=float(record.age)+delta
   if record.age>float(_data.get("memory_seconds",45)):_records[id].erase(target)
 _remaining=maxf(0,_remaining-delta)
 if not _data.get("enabled",false) or not sight.is_valid():_visible.clear();return
 if _remaining>0:return
 if visits.is_empty():_visible.clear();return
 # Stagger observers: one bounded scan per update rather than a crowd burst.
 _remaining=float(_data.sample_seconds)/float(visits.size())
 var ids: Array=visits.keys()
 _cursor=_cursor%ids.size()
 var id: String=ids[_cursor]
 _cursor=(_cursor+1)%ids.size()
 _visible[id]={}
 var observer: VisitState=visits[id]
 if observer.phase==&"leaving":return
 if not _records.has(id):_records[id]={}
 var perf := RuntimePerformance.begin()
 for target in actors:
  var pose: ActorPose=actors[target]
  if target==str(observer.character_id) or pose.location_id!=observer.pose.location_id:continue
  if observer.pose.ground.distance_to(pose.ground)>float(_data.sight_radius) or not sight.call(observer.pose.ground,pose.ground):continue
  _records[id][target]={"location":str(pose.location_id),"ground":[pose.ground.x,pose.ground.y],"age":0.0}
  _visible[id][target]=true
 RuntimePerformance.finish("spatial_observation",perf)
func recalled(id: StringName, target: String) -> Dictionary:
 return _records.get(str(id),{}).get(target,{}).duplicate(true)
func visible(id: StringName, target: String) -> bool:
 return bool(_visible.get(str(id),{}).get(target,false)) and float(_records.get(str(id),{}).get(target,{}).get("age",INF))<=float(_data.get("sample_seconds",0.5))*2
func clear() -> void:
 _records.clear();_visible.clear();_remaining=0;_cursor=0
func prune(visits: Dictionary) -> void:
 for id in _records.keys():
  if not visits.has(id):_records.erase(id);_visible.erase(id)
 for id in _visible.keys():
  if not visits.has(id):_visible.erase(id)
func snapshot() -> Dictionary:
 return _records.duplicate(true)
func restore(data: Variant, visits: Dictionary, characters: Dictionary) -> ActionResult:
 if not data is Dictionary or data.size()>4:return _fail()
 for id in data:
  if not visits.has(id) or not data[id] is Dictionary or data[id].size()>characters.size()+1:return _fail()
  for target in data[id]:
   var record: Variant=data[id][target]
   if (target!="player" and not characters.has(target)) or target==str(visits[id].character_id) or not record is Dictionary:return _fail()
   if record.get("location")!="kiosk" or not ContentValidation.vector(record.get("ground"),2) or not ContentValidation.bounded(record.get("age"),0,86400):return _fail()
 _records=data.duplicate(true);_visible.clear();_remaining=0;_cursor=0
 return ActionResult.success()
static func _fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_spatial_awareness")
