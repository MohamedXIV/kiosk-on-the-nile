class_name DeliveryService
extends RefCounted
var _session: GameSession
var state: Dictionary={}
static func initial_state() -> Dictionary:return {"occurrences":{},"stock_days":{}}
func configure(session: GameSession) -> void:_session=session;state=initial_state()
func tick(frame: Dictionary) -> ActionResult:
 var now := _session.clock.world_minutes
 var due: Array[Dictionary]=[]
 for v in _session.contracts.state.versions.values():
  var at := float(v.first_at)
  var count := 0
  while at<=now+0.000001 and (float(v.closed_at)<0 or at<=float(v.closed_at)):
   count+=1
   if count>100000:return _fail("supplier_calendar_too_large")
   var id := identity(str(v.id),at)
   if not state.occurrences.has(id):state.occurrences[id]={"id":id,"version_id":str(v.id),"scheduled_at":at,"status":"scheduled","reason":"","evaluated_at":-1.0,"receipt":"","grants":[],"emergency":false,"cash_waiting":false}
   if state.occurrences[id].status=="scheduled":due.append(state.occurrences[id])
   if v.once:break
   at=SupplierContracts.next_time(v,at)
 due.sort_custom(func(a,b):return float(a.scheduled_at)<float(b.scheduled_at) or (a.scheduled_at==b.scheduled_at and str(a.id)<str(b.id)))
 for occurrence in due:
  var result := _session.supply_transactions.deliver(str(occurrence.id),false,bool(frame.get("sleeping",false)))
  if not result.ok:return result
 return ActionResult.success()
static func identity(version: String, at: float) -> String:return version+"@"+str(roundi(at*1000000.0))
func occurrences(_filters: Dictionary = {}) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for v in state.occurrences.values():result.append(v.duplicate(true))
 result.sort_custom(func(a,b):return float(a.scheduled_at)<float(b.scheduled_at))
 return result
func cash_waiting() -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for row in occurrences():
  if row.status=="scheduled" and row.cash_waiting:result.append(row)
 return result
func snapshot() -> Dictionary:return state.duplicate(true)
func restore(data: Dictionary) -> ActionResult:
 var result := validate_state(data)
 if result.ok:state=data.duplicate(true)
 return result
func validate_state(data: Dictionary) -> ActionResult:
 if not data.get("occurrences") is Dictionary or not data.get("stock_days") is Dictionary:return _fail("invalid_deliveries")
 for id in data.occurrences:
  var o: Variant=data.occurrences[id]
  if not o is Dictionary or o.get("id")!=id or not o.get("status") in ["scheduled","delivered","skipped"] or not ContentValidation.bounded(o.get("scheduled_at"),0,_session.clock.world_minutes+0.001) or not ContentValidation.bounded(o.get("evaluated_at"),-1,_session.clock.world_minutes+0.001) or not o.get("grants") is Array or not o.get("reason") is String or not o.get("receipt") is String or not o.get("emergency") is bool or not o.get("cash_waiting") is bool:return _fail("invalid_delivery")
  if o.emergency:
   if not str(id).begins_with("emergency:") or o.get("version_id")!="":return _fail("invalid_emergency_delivery")
  else:
   var v: Dictionary=_session.contracts.state.versions.get(o.get("version_id"),{})
   if v.is_empty() or id!=identity(v.id,float(o.scheduled_at)) or o.scheduled_at<float(v.first_at)-0.001 or (v.closed_at>=0 and o.scheduled_at>v.closed_at+0.001):return _fail("invalid_delivery_schedule")
   if v.once:
    if absf(float(o.scheduled_at)-float(v.first_at))>0.001:return _fail("invalid_delivery_schedule")
   elif absf(float(o.scheduled_at)-SupplierContracts.next_time(v,float(o.scheduled_at)-0.01))>0.001:return _fail("invalid_delivery_schedule")
  if o.status=="scheduled" and (o.evaluated_at!=-1 or o.receipt!="" or not o.grants.is_empty()):return _fail("unfulfilled_delivery_receipt")
  if o.status!="scheduled" and o.evaluated_at<o.scheduled_at-0.001:return _fail("early_delivery")
  if o.status=="skipped" and (o.reason=="" or o.receipt!="" or not o.grants.is_empty()):return _fail("charged_skipped_delivery")
  if o.status=="delivered" and (o.receipt=="" or o.grants.is_empty() or o.reason!=""):return _fail("missing_delivery_receipt")
 for day in data.stock_days:
  var stock: Variant=data.stock_days[day]
  if not str(day).is_valid_int() or int(day)<0 or not stock is Dictionary:return _fail("invalid_supplier_stock")
  for id in stock:
   var line: Variant=stock[id]
   if not line is Dictionary or not ContentValidation.integer(line.get("capacity")) or not ContentValidation.integer(line.get("used")) or line.used<0 or line.used>line.capacity:return _fail("invalid_supplier_stock")
 return ActionResult.success()
func _fail(key: String) -> ActionResult:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,StringName(key))
