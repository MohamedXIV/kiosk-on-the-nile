class_name AlertnessService
extends RefCounted
## Stimulation never restores true rest. Exemption has a finite sleep-reset budget.
var _session: GameSession
var _data: Dictionary
var _doses: Dictionary={}
var _exemption_used: float=0
var _last_world: float=0
func configure(session: GameSession) -> void:
 _session=session
 _data=session.config.section("action_policy").caffeine
 _last_world=session.clock.world_minutes
func boost() -> float:
 if _exemption_used>=float(_data.maximum_exemption_minutes):return 0
 var total := 0.0
 for dose in _doses.values():
  if _session.clock.world_minutes<float(dose.expires):total+=float(dose.boost)
 return minf(total,float(_data.maximum_boost))
func effective_focus() -> float:
 return minf(100,_session.needs.rest+boost())
func consume(food_id: StringName, source_id: String) -> ActionResult:
 if _doses.has(source_id):return ActionResult.success({"duplicate":true})
 if not _data.foods.has(str(food_id)):return ActionResult.success()
 var count := 0
 for dose in _doses.values():
  if _session.clock.world_minutes-float(dose.at)<float(_data.window_minutes):count+=1
 var spec: Dictionary=_data.foods[str(food_id)]
 var multiplier := float(_data.multipliers[mini(count,_data.multipliers.size()-1)])
 _doses[source_id]={"source":source_id,"food":str(food_id),"at":_session.clock.world_minutes,"expires":_session.clock.world_minutes+float(spec.duration_minutes),"boost":float(spec.boost)*multiplier,"base_boost":float(spec.boost),"duration":float(spec.duration_minutes),"multiplier":multiplier}
 return ActionResult.success({"focus_boost":float(spec.boost)*multiplier})
func tick(_frame: Dictionary) -> void:
 var now := _session.clock.world_minutes
 var intervals: Array=[]
 for dose in _doses.values():
  if float(dose.boost)<=0:continue
  var begin := maxf(_last_world,float(dose.at))
  var end := minf(now,float(dose.expires))
  if end>begin:intervals.append(Vector2(begin,end))
 intervals.sort_custom(func(a,b):return a.x<b.x)
 var cursor := _last_world
 var used := 0.0
 for interval in intervals:
  used+=maxf(0,float(interval.y)-maxf(cursor,float(interval.x)))
  cursor=maxf(cursor,float(interval.y))
 _exemption_used=minf(float(_data.maximum_exemption_minutes),_exemption_used+used)
 _last_world=now
func recover_sleep(hours: float) -> void:
 _last_world=_session.clock.world_minutes
 if hours>=float(_data.reset_sleep_hours):
  _doses={}
  _exemption_used=0
func snapshot() -> Dictionary:
 return {"doses":_doses.duplicate(true),"exemption_used":_exemption_used,"last_world":_last_world}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("doses") is Dictionary or not ContentValidation.bounded(data.get("exemption_used"),0,_data.maximum_exemption_minutes) or not ContentValidation.bounded(data.get("last_world"),0,_session.clock.world_minutes+0.001):return _fail()
 for id in data.doses:
  var dose: Variant=data.doses[id]
  if not id is String or id.is_empty() or not dose is Dictionary or dose.get("source")!=id or not _data.foods.has(dose.get("food")) or not ContentValidation.bounded(dose.get("at"),0,data.last_world) or not ContentValidation.number(dose.get("expires")) or dose.expires<=dose.at or not ContentValidation.bounded(dose.get("boost"),0,100):return _fail()
  if not ContentValidation.bounded(dose.get("base_boost"),0,100) or not ContentValidation.bounded(dose.get("duration"),0.01,1440) or not ContentValidation.bounded(dose.get("multiplier"),0,1) or absf(float(dose.boost)-float(dose.base_boost)*float(dose.multiplier))>0.001 or absf(float(dose.expires)-float(dose.at)-float(dose.duration))>0.001:return _fail()
  var suffix := str(id).trim_prefix("food_")
  if not str(id).begins_with("food_") or not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=int(_session.items.snapshot().next_id):return _fail()
 _doses=data.doses.duplicate(true)
 _exemption_used=float(data.exemption_used)
 _last_world=float(data.last_world)
 return ActionResult.success()
func _fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_alertness")
