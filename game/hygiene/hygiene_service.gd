class_name HygieneService
extends RefCounted
signal changed(target_id: StringName)
var _definitions: Dictionary
var _items: ItemStore
var _spaces: SpaceService
var _clock: GameClock
var _player: Callable
var _busy: Callable
var _targets: Dictionary={}
var _applied: Dictionary={}
var _last_at: float
var _action: CleaningAction
func configure(definitions: Dictionary, items: ItemStore, spaces: SpaceService, clock: GameClock, player_pose: Callable, equipment_busy: Callable) -> ActionResult:
 _definitions=definitions.duplicate(true)
 _items=items
 _spaces=spaces
 _clock=clock
 _player=player_pose
 _busy=equipment_busy
 _last_at=clock.world_minutes
 _sync_targets()
 items.changed.connect(func(_revision):_sync_targets())
 return ActionResult.success()
func _sync_targets() -> void:
 for id in _spaces.definitions().locations:
  if not _targets.has("floor:"+id):_targets["floor:"+id]={"cleanliness":100.0,"cleaning":{}}
 for item in _items.snapshot().items.values():
  if _definitions.item_profiles.has(item.definition_id) and not _targets.has(item.id):_targets[item.id]={"cleanliness":100.0,"cleaning":{}}
func state(target_id: StringName) -> Dictionary:
 if not _targets.has(str(target_id)):return {}
 var value: Dictionary=_targets[str(target_id)].duplicate(true)
 value["id"]=str(target_id)
 value["location_id"]=_location(target_id)
 value["label"]=_definitions.labels.clean if value.cleanliness>=float(_definitions.thresholds.wipe) else _definitions.labels.wipe if value.cleanliness>=float(_definitions.thresholds.dirty) else _definitions.labels.dirty
 return value
func record_use(source_id: StringName, target_id: StringName, use_id: StringName) -> ActionResult:
 if _applied.has(str(source_id)):return ActionResult.success({"duplicate":true})
 if not _targets.has(str(target_id)):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"not_cleanable")
 var profile := _profile(target_id)
 var loss := float(profile.get("uses",{}).get(str(use_id),0))
 _soil(target_id,loss)
 _applied[str(source_id)]=true
 changed.emit(target_id)
 return ActionResult.success()
func _soil(id: StringName, amount: float) -> void:
 var target: Dictionary=_targets[str(id)]
 var before := float(target.cleanliness)
 target.cleanliness=clampf(before-amount,0,100)
 var loss := before-float(target.cleanliness)
 if loss>0 and not target.cleaning.is_empty():target.cleaning.required_minutes=float(target.cleaning.required_minutes)+loss/float(target.cleaning.rate)
func begin_clean(target_id: StringName) -> ActionResult:
 var value := state(target_id)
 if value.is_empty() or not _reachable(target_id):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"cleaning_out_of_reach")
 if _busy.is_valid() and _busy.call(target_id):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"equipment_busy")
 if float(value.cleanliness)>=100:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"already_clean")
 interrupt_clean()
 var target: Dictionary=_targets[str(target_id)]
 if target.cleaning.is_empty():
  var duration := float(_profile(target_id).clean_minutes)
  target.cleaning={"required_minutes":duration,"completed_minutes":0.0,"rate":(100.0-float(target.cleanliness))/duration}
 _action=CleaningAction.new()
 _action.target_id=target_id
 _action.location_id=StringName(_location(target_id))
 var pose: ActorPose=_player.call()
 _action.anchor=pose.ground
 _action.progress=target.cleaning
 _action.active=true
 changed.emit(target_id)
 return ActionResult.success()
func interrupt_clean() -> void:
 if _action!=null:_action.active=false
func is_cleaning(target_id: StringName) -> bool:
 return _action!=null and _action.active and _action.target_id==target_id
func active_action() -> Dictionary:
 if _action==null or not _action.active:return {}
 var result := _action.snapshot()
 result["required_minutes"]=_action.required_minutes
 result["completed_minutes"]=_action.completed_minutes
 return result
func tick(frame: Dictionary) -> void:
 _advance(float(frame.world_minutes),true)
func elapse(_world_minutes: float) -> void:
 _advance(_clock.world_minutes,false)
func _advance(now: float, allow_cleaning: bool) -> void:
 var elapsed := maxf(0,now-_last_at)
 _last_at=now
 for id in _targets:
  var profile := _profile(StringName(id))
  if not str(id).begins_with("floor:"):
   var placement := _spaces.placement(StringName(id))
   if placement.is_empty():continue
   if placement.location_id!="rooftop":continue
  _soil(StringName(id),elapsed*float(profile.get("dust_per_minute",0)))
 if not allow_cleaning or _action==null or not _action.active:return
 var id := _action.target_id
 if not _reachable(id) or (_busy.is_valid() and _busy.call(id)):
  interrupt_clean()
  return
 var pose: ActorPose=_player.call()
 if str(id).begins_with("floor:") and pose.ground.distance_to(_action.anchor)>0.35:interrupt_clean();return
 var target: Dictionary=_targets[str(id)]
 var used := minf(elapsed,maxf(0,_action.required_minutes-_action.completed_minutes))
 target.cleaning.completed_minutes=float(target.cleaning.completed_minutes)+used
 target.cleanliness=minf(100,float(target.cleanliness)+used*float(target.cleaning.rate))
 if _action.completed_minutes>=_action.required_minutes-0.00001:
  target.cleanliness=100.0
  target.cleaning={}
  _action.active=false
 changed.emit(id)
func food_contact_evidence(target_ids: PackedStringArray) -> Dictionary:
 var records: Array=[]
 var penalty := 0
 for id in target_ids:
  if not _targets.has(id) or not _profile(StringName(id)).get("food_contact",false):continue
  var value := float(_targets[id].cleanliness)
  var loss := int(_definitions.food.max_penalty) if value<float(_definitions.food.penalty_below) else 0
  penalty=maxi(penalty,loss)
  records.append({"target_id":id,"cleanliness":value,"penalty":loss})
 return {"targets":records,"penalty":penalty}
func sleep_rest_multiplier(bed_id: StringName) -> float:
 var bed := state(bed_id)
 return float(_definitions.sleep.rest_multiplier) if not bed.is_empty() and float(bed.cleanliness)<float(_definitions.sleep.dirty_below) else 1.0
func _reachable(id: StringName) -> bool:
 if not _player.is_valid():return false
 var pose: ActorPose=_player.call()
 if _location(id)!=str(pose.location_id):return false
 if str(id).begins_with("floor:"):return true
 return not _spaces.placement(id).is_empty() and _spaces.ground(id).distance_to(pose.ground)<=1.6
func _location(id: StringName) -> String:
 if str(id).begins_with("floor:"):return str(id).trim_prefix("floor:")
 return str(_spaces.placement(id).get("location_id",""))
func _profile(id: StringName) -> Dictionary:
 if str(id).begins_with("floor:"):return _definitions.profiles.floor
 var item := _items.get_item(id)
 return _definitions.profiles.get(_definitions.item_profiles.get(item.get("definition_id",""),""),{}).duplicate(true)
func snapshot() -> Dictionary:
 return {"targets":_targets.duplicate(true),"applied":_applied.duplicate(true),"last_at":_last_at,"action":_action.snapshot() if _action!=null else {}}
func restore(data: Dictionary) -> ActionResult:
 _sync_targets()
 if not data.get("targets") is Dictionary or not data.get("applied") is Dictionary or not ContentValidation.number(data.get("last_at")) or data.last_at>_clock.world_minutes+0.001 or data.last_at<0 or not data.get("action") is Dictionary:return _fail("invalid_hygiene")
 for id in data.targets:
  if not _targets.has(id):return _fail("unknown_hygiene_target")
  var value: Variant=data.targets[id]
  if not value is Dictionary or not ContentValidation.bounded(value.get("cleanliness"),0,100) or not value.get("cleaning") is Dictionary:return _fail("invalid_cleanliness")
  if not value.cleaning.is_empty():
   for field in ["required_minutes","completed_minutes","rate"]:
    if not ContentValidation.number(value.cleaning.get(field)) or value.cleaning[field]<0:return _fail("invalid_cleaning_progress")
   if value.cleaning.rate<=0 or value.cleaning.completed_minutes>value.cleaning.required_minutes:return _fail("invalid_cleaning_progress")
 for value in data.applied.values():
  if value!=true:return _fail("invalid_hygiene_history")
 if data.targets.size()!=_targets.size():return _fail("missing_hygiene_target")
 _targets=data.targets.duplicate(true)
 _applied=data.applied.duplicate(true)
 _last_at=float(data.last_at)
 _action=null
 if not data.action.is_empty():
  var record: Dictionary=data.action
  if not _targets.has(str(record.get("target_id",""))) or not record.get("active") is bool or not ContentValidation.vector(record.get("anchor"),2):return _fail("invalid_cleaning_action")
  _action=CleaningAction.new()
  _action.target_id=StringName(record.target_id)
  _action.location_id=StringName(str(record.get("location_id","")))
  _action.anchor=Vector2(record.anchor[0],record.anchor[1])
  _action.active=record.active
  _action.progress=_targets[record.target_id].cleaning
  if _action.active and (_action.progress.is_empty() or not _reachable(_action.target_id) or (_busy.is_valid() and _busy.call(_action.target_id))):return _fail("invalid_active_cleaning")
 return ActionResult.success()
func _fail(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,StringName(key))
