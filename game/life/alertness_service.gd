class_name AlertnessService
extends RefCounted
## Consumption evidence belongs to ItemStore. Stimulation never restores rest.
var _session: GameSession
var _data: Dictionary
var _doses: Dictionary={}
var _exemption_used: float=0
var _last_world: float=0
var _cycle_start: float=0
func configure(session: GameSession) -> void:
 _session=session
 _data=session.config.section("action_policy").caffeine
 _last_world=session.clock.world_minutes
 _cycle_start=_last_world
func boost() -> float:
 if _exemption_used>=float(_data.maximum_exemption_minutes):return 0
 var total := 0.0
 for dose in _doses.values():
  if _session.clock.world_minutes<float(dose.expires):total+=float(dose.boost)
 return minf(total,float(_data.maximum_boost))
func effective_focus() -> float:
 return minf(100,_session.needs.rest+boost())
func _multiplier(at: float, doses: Dictionary) -> float:
 var count := 0
 for dose in doses.values():
  if at-float(dose.at)<float(_data.window_minutes):count+=1
 return float(_data.multipliers[mini(count,_data.multipliers.size()-1)])
func consume(food_id: StringName, source_id: String) -> ActionResult:
 if _doses.has(source_id):return ActionResult.success({"duplicate":true})
 if not _data.foods.has(str(food_id)):return ActionResult.success()
 var receipt: Dictionary=_session.items.snapshot().consumed.get(source_id,{})
 if receipt.is_empty() or receipt.item.attributes.get("food_id")!=str(food_id) or receipt.at!=_session.clock.world_minutes:return _fail()
 var spec: Dictionary=_data.foods[str(food_id)]
 var multiplier := _multiplier(_session.clock.world_minutes,_doses)
 _doses[source_id]={"source":source_id,"food":str(food_id),"at":_session.clock.world_minutes,"expires":_session.clock.world_minutes+float(spec.duration_minutes),"boost":float(spec.boost)*multiplier,"base_boost":float(spec.boost),"duration":float(spec.duration_minutes),"multiplier":multiplier}
 _account_to(_session.clock.world_minutes)
 return ActionResult.success({"focus_boost":float(spec.boost)*multiplier})
func _accounted(doses: Dictionary, now: float) -> float:
 var intervals: Array=[]
 for dose in doses.values():
  if float(dose.boost)<=0:continue
  var begin := maxf(_cycle_start,float(dose.at))
  var end := minf(now,float(dose.expires))
  if end>begin:intervals.append(Vector2(begin,end))
 intervals.sort_custom(func(a,b):return a.x<b.x)
 var cursor := _cycle_start
 var used := 0.0
 for interval in intervals:
  used+=maxf(0,float(interval.y)-maxf(cursor,float(interval.x)))
  cursor=maxf(cursor,float(interval.y))
 return minf(float(_data.maximum_exemption_minutes),used)
func _account_to(now: float) -> void:
 _exemption_used=_accounted(_doses,now)
 _last_world=now
func tick(_frame: Dictionary) -> void:
 _account_to(_session.clock.world_minutes)
func recover_sleep(hours: float) -> void:
 _account_to(_session.clock.world_minutes)
 if hours>=float(_data.reset_sleep_hours):
  _doses={}
  _exemption_used=0
  _cycle_start=_last_world
func snapshot() -> Dictionary:
 return {"doses":_doses.duplicate(true),"exemption_used":_exemption_used,"last_world":_last_world,"cycle_start":_cycle_start}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("doses") is Dictionary or not ContentValidation.bounded(data.get("exemption_used"),0,_data.maximum_exemption_minutes) or not ContentValidation.bounded(data.get("last_world"),0,_session.clock.world_minutes+0.001) or not ContentValidation.bounded(data.get("cycle_start"),0,data.last_world):return _fail()
 for id in data.doses:
  if not data.doses[id] is Dictionary or not ContentValidation.number(data.doses[id].get("at")):return _fail()
 var ordered: Array=data.doses.values()
 ordered.sort_custom(func(a,b):return float(a.get("at",-1))<float(b.get("at",-1)))
 var verified: Dictionary={}
 var consumed: Dictionary=_session.items.snapshot().consumed
 for dose in ordered:
  if not dose is Dictionary or not dose.get("source") is String or not data.doses.has(dose.source) or data.doses[dose.source]!=dose or not _data.foods.has(dose.get("food")) or not ContentValidation.bounded(dose.get("at"),data.cycle_start,data.last_world):return _fail()
  var receipt: Dictionary=consumed.get(dose.source,{})
  if receipt.is_empty() or receipt.at!=dose.at or receipt.item.attributes.get("food_id")!=dose.food:return _fail()
  var spec: Dictionary=_data.foods[dose.food]
  var multiplier := _multiplier(float(dose.at),verified)
  if dose.get("base_boost")!=spec.boost or dose.get("duration")!=spec.duration_minutes or dose.get("multiplier")!=multiplier or not ContentValidation.number(dose.get("boost")) or not ContentValidation.number(dose.get("expires")):return _fail()
  if absf(float(dose.boost)-float(spec.boost)*multiplier)>0.001 or absf(float(dose.expires)-float(dose.at)-float(spec.duration_minutes))>0.001:return _fail()
  verified[dose.source]=dose
 # Every consumed stimulant in this recovery cycle must have its dose receipt.
 for id in consumed:
  var receipt: Dictionary=consumed[id]
  if float(receipt.at)>_session.clock.world_minutes+0.001:return _fail()
  if float(receipt.at)>=float(data.cycle_start) and _data.foods.has(str(receipt.item.attributes.get("food_id",""))) and not verified.has(id):return _fail()
 _cycle_start=float(data.cycle_start)
 if absf(_accounted(verified,float(data.last_world))-float(data.exemption_used))>0.01:return _fail()
 _doses=verified.duplicate(true)
 _exemption_used=float(data.exemption_used)
 _last_world=float(data.last_world)
 # Validate the saved analytical state first, then catch up a clock gap left by
 # older dependency-blocked sessions. No doses or consumption receipts are invented.
 _account_to(_session.clock.world_minutes)
 return ActionResult.success()
func _fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_alertness")
