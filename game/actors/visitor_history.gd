class_name VisitorHistory
extends RefCounted
## Visit reservations and actual paid service memories, independent of presentation.
var food_ids: Array=[]
var _visits: Dictionary = {}
var _services: Dictionary = {}
func eligible(id: String, policy: Dictionary, clock: GameClock) -> bool:
 var previous: Dictionary = _visits.get(id,{})
 if previous.is_empty(): return true
 return (int(previous.day)!=clock.day or int(previous.count)<int(policy.daily_limit)) and clock.world_minutes-float(previous.world_minutes)>=float(policy.return_after_minutes)
func last_visit(id: String) -> float:
 return float(_visits.get(id,{}).get("world_minutes",-1))
func reserve(id: String, clock: GameClock) -> void:
 var previous: Dictionary = _visits.get(id,{})
 _visits[id] = {"day":clock.day,"count":int(previous.get("count",0))+1 if int(previous.get("day",0))==clock.day else 1,"world_minutes":clock.world_minutes}
func served(character_id: String, order_id: StringName, visit_id: StringName, item: PreparedItem) -> void:
 var records: Array = _services.get(character_id,[])
 for record in records:
  if record.order_id==str(order_id): return
 records.push_front({"order_id":str(order_id),"visit_id":str(visit_id),"food_id":str(item.food_id),"quality":item.quality_score})
 _services[character_id] = records.slice(0,2)
func previous_service(character_id: String, current_visit: StringName) -> Dictionary:
 for record in _services.get(character_id,[]):
  if record.visit_id!=str(current_visit): return record.duplicate(true)
 return {}
func snapshot() -> Dictionary:
 return {"visits":_visits.duplicate(true),"services":_services.duplicate(true)}
func restore(data: Dictionary, characters: Dictionary, clock: GameClock) -> ActionResult:
 if not data.get("visits") is Dictionary or not data.get("services") is Dictionary: return _invalid()
 for id in data.visits:
  var record: Variant = data.visits[id]
  if not characters.has(id) or not record is Dictionary or not ContentValidation.integer(record.get("day")) or record.day<1 or record.day>clock.day or not ContentValidation.integer(record.get("count")) or record.count<1 or not ContentValidation.number(record.get("world_minutes")) or record.world_minutes<0 or record.world_minutes>clock.world_minutes: return _invalid()
 for id in data.services:
  var records: Variant = data.services[id]
  if not characters.has(id) or not records is Array or records.size()>2: return _invalid()
  var orders: Dictionary = {}
  for record in records:
   if not record is Dictionary or not record.get("order_id") is String or record.order_id.is_empty() or orders.has(record.order_id) or not record.get("visit_id") is String or record.visit_id.is_empty() or not record.get("food_id") in food_ids or not ContentValidation.integer(record.get("quality")) or record.quality<0 or record.quality>3: return _invalid()
   orders[record.order_id] = true
 _visits = data.visits.duplicate(true)
 _services = data.services.duplicate(true)
 return ActionResult.success()
func _invalid() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visitor_history")
