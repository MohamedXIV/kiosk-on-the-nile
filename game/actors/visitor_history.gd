class_name VisitorHistory
extends RefCounted
## Visit reservations and actual service and hospitality memories, independent of presentation.
var food_ids: Array=[]
var _visits: Dictionary = {}
var _services: Dictionary = {}
var _hospitality: Dictionary={}
func eligible(id: String, policy: Dictionary, clock: GameClock) -> bool:
 var previous: Dictionary = _visits.get(id,{})
 if previous.is_empty(): return true
 return (int(previous.day)!=clock.day or int(previous.count)<int(policy.daily_limit)) and clock.world_minutes-float(previous.world_minutes)>=float(policy.return_after_minutes)
func last_visit(id: String) -> float:
 return float(_visits.get(id,{}).get("world_minutes",-1))
func reserve(id: String, clock: GameClock) -> void:
 var previous: Dictionary = _visits.get(id,{})
 _visits[id] = {"day":clock.day,"count":int(previous.get("count",0))+1 if int(previous.get("day",0))==clock.day else 1,"world_minutes":clock.world_minutes}
func served(character_id: String, order_id: StringName, visit_id: StringName, item: PreparedItem, settlement: StringName=&"pending", payment: int=-1) -> void:
 var records: Array = _services.get(character_id,[])
 for record in records:
  if record.order_id==str(order_id): return
 records.push_front({"order_id":str(order_id),"visit_id":str(visit_id),"food_id":str(item.food_id),"quality":item.quality_score,"settlement":str(settlement),"payment":payment})
 _services[character_id] = records.slice(0,2)
func record_settlement(character_id: String, order_id: StringName, mode: StringName, amount: int) -> void:
 for actor in _services:
  if not character_id.is_empty() and actor!=character_id:continue
  for record in _services[actor]:
   if record.order_id==str(order_id):record.settlement=str(mode);record.payment=amount;return
func hospitality(character_id: String) -> Dictionary:
 return _hospitality.get(character_id,{}).duplicate(true)
func request_hospitality(character_id: String, visit_id: StringName, policy: Dictionary, visits: int, clock: GameClock) -> bool:
 var entry: Dictionary=policy.get("actors",{}).get(character_id,{})
 if not policy.get("enabled",false) or entry.is_empty() or visits<int(entry.minimum_visits):return false
 var previous := hospitality(character_id)
 if previous.get("outcome","") in ["accepted","declined"]:return false
 _hospitality[character_id]={"character_id":character_id,"visit_id":str(visit_id),"order_id":"","outcome":"requested","at":clock.world_minutes}
 return true
func decide_hospitality(character_id: String, visit_id: StringName, outcome: String, order_id: StringName, clock: GameClock) -> void:
 _hospitality[character_id]={"character_id":character_id,"visit_id":str(visit_id),"order_id":str(order_id),"outcome":outcome,"at":clock.world_minutes}
func previous_service(character_id: String, current_visit: StringName) -> Dictionary:
 for record in _services.get(character_id,[]):
  if record.visit_id!=str(current_visit): return record.duplicate(true)
 return {}
func snapshot() -> Dictionary:
 return {"visits":_visits.duplicate(true),"services":_services.duplicate(true),"hospitality":_hospitality.duplicate(true)}
func restore(data: Dictionary, characters: Dictionary, clock: GameClock) -> ActionResult:
 if not data.get("hospitality") is Dictionary or not data.get("visits") is Dictionary or not data.get("services") is Dictionary: return _invalid()
 for id in data.visits:
  var record: Variant = data.visits[id]
  if not characters.has(id) or not record is Dictionary or not ContentValidation.integer(record.get("day")) or record.day<1 or record.day>clock.day or not ContentValidation.integer(record.get("count")) or record.count<1 or not ContentValidation.number(record.get("world_minutes")) or record.world_minutes<0 or record.world_minutes>clock.world_minutes: return _invalid()
 for id in data.services:
  var records: Variant = data.services[id]
  if not characters.has(id) or not records is Array or records.size()>2: return _invalid()
  var orders: Dictionary = {}
  for record in records:
   if not record is Dictionary or not record.get("order_id") is String or record.order_id.is_empty() or orders.has(record.order_id) or not record.get("visit_id") is String or record.visit_id.is_empty() or not record.get("food_id") in food_ids or not ContentValidation.integer(record.get("quality")) or record.quality<0 or record.quality>3: return _invalid()
   if not record.get("settlement") in ["pending","paid","gift"] or not ContentValidation.integer(record.get("payment")) or (record.settlement=="pending" and record.payment!=-1) or (record.settlement=="gift" and record.payment!=0) or (record.settlement=="paid" and record.payment<0):return _invalid()
   orders[record.order_id] = true
 for id in data.hospitality:
  var record: Variant=data.hospitality[id]
  if not characters.has(id) or not record is Dictionary or record.get("character_id")!=id or not record.get("visit_id") is String or record.visit_id.is_empty() or not record.get("order_id") is String or not record.get("outcome") in ["requested","accepted","declined"] or not ContentValidation.number(record.get("at")) or record.at<0 or record.at>clock.world_minutes:return _invalid()
  if (record.outcome=="accepted")!=(not record.order_id.is_empty()):return _invalid()
 _hospitality=data.hospitality.duplicate(true)
 _visits = data.visits.duplicate(true)
 _services = data.services.duplicate(true)
 return ActionResult.success()
func _invalid() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visitor_history")
