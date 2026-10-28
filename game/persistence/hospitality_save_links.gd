class_name HospitalitySaveLinks
extends RefCounted
static func validate(session: GameSession) -> ActionResult:
 var history := session.visitors.history.snapshot()
 for record in session.service.snapshot().orders.values():
  if not session.config.section("visitors").characters.has(record.character_id):return _fail()
  var owner: VisitState=session.visitors.visits.get(record.visit_id)
  if owner!=null and str(owner.character_id)!=record.character_id:return _fail()
  if record.status=="delivered" and not session.items.get_item(StringName(record.delivered_item_id)).is_empty():return _fail()
 var limit := int(session.visitors.snapshot().next_id)
 for actor in history.hospitality:
  var receipt: Dictionary=history.hospitality[actor]
  if not receipt.visit_id.begins_with("visit_") or not receipt.visit_id.trim_prefix("visit_").is_valid_int():return _fail()
  var identity := int(receipt.visit_id.trim_prefix("visit_"))
  if identity<1 or identity>=limit:return _fail()
  var visit: VisitState=session.visitors.visits.get(receipt.visit_id)
  if visit!=null and str(visit.character_id)!=actor:return _fail()
  if receipt.outcome=="accepted":
   var order := session.service.order(StringName(receipt.order_id))
   if order==null or str(order.visit_id)!=receipt.visit_id or str(order.character_id)!=actor or not order.gift_promised:return _fail()
 for visit: VisitState in session.visitors.visits.values():
  if not visit.needs_hospitality:continue
  var receipt := session.visitors.history.hospitality(str(visit.character_id))
  if receipt.is_empty() or receipt.visit_id!=str(visit.id) or not receipt.outcome in ["requested","accepted"]:return _fail()
  if visit.shopping_state in [&"pending",&"served"]:
   var order := session.service.order(visit.order_id)
   if order==null or not order.gift_promised or receipt.outcome!="accepted" or receipt.order_id!=str(order.id):return _fail()
 return ActionResult.success()
static func _fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_hospitality_receipt")
