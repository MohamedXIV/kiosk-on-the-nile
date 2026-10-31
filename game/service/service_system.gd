class_name ServiceSystem
extends RefCounted
signal handed_over(order_id: StringName, visit_id: StringName, item: PreparedItem)
signal settled(order_id: StringName, visit_id: StringName, item: PreparedItem, payment: int)
var policy: ActionPolicy
var menu: MenuService
var quote_provider: Callable
var personal_item: Callable
var gift_allowed: Callable
var recipient_for: Callable
var receipt_recipes: Dictionary={}
var _foods: FoodRegistry
var _clock: GameClock
var _wallet: WalletService
var _cooking: CookingService
var _available: Callable
var _balance: Dictionary
var _orders: Dictionary = {}
var _next_id: int = 1
var _decision_order: StringName
func configure(wallet: WalletService, cooking: CookingService, available: Callable, balance: Dictionary = {}, foods: FoodRegistry = null, clock: GameClock = null) -> void:
 _foods=foods
 _clock=clock
 _wallet = wallet
 _cooking = cooking
 _available = available
 _balance = balance.duplicate(true)
func place_order(visit_id: StringName, food_id: StringName, gift_promised: bool=false) -> OrderState:
 if _foods==null or not _foods.has_food(food_id) or not _available.call(visit_id) or unsettled_for(visit_id)!=null:return null
 for existing in _orders.values():
  if existing.visit_id == visit_id and existing.status == &"pending": return existing
 if gift_promised and (not gift_allowed.is_valid() or not gift_allowed.call(visit_id)):return null
 if not recipient_for.is_valid() or str(recipient_for.call(visit_id)).is_empty():return null
 var quoted: ActionResult = quote_provider.call(visit_id,food_id) if quote_provider.is_valid() else menu.quote(StringName(menu.default_variant(str(food_id))))
 if not quoted.ok:return null
 var order := OrderState.new()
 order.id = StringName("order_%d" % _next_id)
 _next_id += 1
 order.visit_id = visit_id
 order.character_id=StringName(recipient_for.call(visit_id))
 order.food_id = food_id
 order.gift_promised=gift_promised
 var food := _foods.definition(food_id)
 order.quote=quoted.details.quote.duplicate(true)
 order.base_price=int(order.quote.price_minor)
 order.tips=[0,0,0,0]
 order.created_at=_clock.world_minutes if _clock!=null else -1.0
 order.timing_known=_clock!=null
 _orders[str(order.id)] = order
 return order
func order(id: StringName) -> OrderState:
 return _orders.get(str(id))
func pending_for(visit_id: StringName) -> OrderState:
 for value in _orders.values():
  if value.visit_id == visit_id and value.status == &"pending": return value
 return null
func begin_decision(order_id: StringName) -> void:
 var value := order(order_id)
 if value!=null and value.settlement==&"pending":_decision_order=order_id
func end_decision(order_id: StringName) -> void:
 if _decision_order==order_id:_decision_order=&""
func decision_visit() -> StringName:
 var value := order(_decision_order)
 return value.visit_id if value!=null and value.settlement==&"pending" else &""
func unsettled_for(visit_id: StringName) -> OrderState:
 for value in _orders.values():
  if value.visit_id==visit_id and value.status==&"delivered" and value.settlement==&"pending":return value
 return null
func _check_handover(value: OrderState) -> ActionResult:
 if value==null or value.status!=&"pending" or not _available.call(value.visit_id):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"order_unavailable")
 var item := _cooking.held_item()
 if item==null or item.food_id!=value.food_id:return ActionResult.failure(ActionResult.Code.WRONG_ORDER,&"wrong_order")
 if menu==null or not menu.matches(item,value.quote):return ActionResult.failure(ActionResult.Code.WRONG_ORDER,&"wrong_order")
 if not _cooking.freshness(item).sellable:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"food_unservable")
 if personal_item.is_valid() and personal_item.call(item.id):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"personal_food")
 if policy!=null and policy.business_allowed.is_valid() and not policy.business_allowed.call():return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"business_suspended")
 return ActionResult.success()
func _check_settlement(value: OrderState, mode: StringName) -> ActionResult:
 if value==null or not mode in [&"paid",&"gift"]:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"order_unavailable")
 if value.gift_promised and mode!=&"gift":return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"hospitality_promised")
 if value.settlement!=&"pending":
  return ActionResult.success({"duplicate":true}) if value.settlement==mode else ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"order_already_settled")
 if mode==&"gift" and not value.gift_promised and (not gift_allowed.is_valid() or not gift_allowed.call(value.visit_id)):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"hospitality_unavailable")
 return ActionResult.success()
func _handover(value: OrderState) -> PreparedItem:
 var held := _cooking.held_item()
 var original := _cooking.held_record()
 var item := _cooking.take_held(held.id,false)
 if item==null:return null
 value.source_item=original.attributes.duplicate(true)
 value.status=&"delivered";value.delivered_item_id=item.id
 value.served_at=_clock.world_minutes if _clock!=null else -1.0
 value.served_quality=item.quality_score;value.served_item=item.snapshot()
 return item
func _settle(value: OrderState, mode: StringName) -> void:
 value.payment=value.base_price+int(value.tips[value.served_quality]) if mode==&"paid" else 0
 value.settlement=mode
 value.closed_at=_clock.world_minutes if _clock!=null else -1.0
 if value.payment>0:_wallet.credit(value.payment)
func deliver(order_id: StringName) -> ActionResult:
 var value := order(order_id)
 var checked := _check_handover(value)
 if not checked.ok:return checked
 var item := _handover(value)
 if item==null:return ActionResult.failure(ActionResult.Code.WRONG_ORDER,&"wrong_order")
 _cooking.held_changed.emit()
 handed_over.emit(value.id,value.visit_id,item)
 return ActionResult.success({"handed_over":true,"order_id":str(value.id),"visit_id":str(value.visit_id)})
func settle(order_id: StringName, mode: StringName) -> ActionResult:
 var value := order(order_id)
 if value==null or value.status!=&"delivered":return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"order_unavailable")
 var checked := _check_settlement(value,mode)
 if not checked.ok or checked.details.get("duplicate",false):return checked
 _settle(value,mode)
 settled.emit(value.id,value.visit_id,PreparedItem.from_dict(value.served_item),value.payment)
 return ActionResult.success({"payment":value.payment,"settlement":str(mode),"visit_id":str(value.visit_id),"cue":"coin" if mode==&"paid" else ""})
func complete(order_id: StringName, mode: StringName) -> ActionResult:
 # Production chooses disposition before handover; validate both, then commit
 # both owners before any callback can observe or save a partial transaction.
 var value := order(order_id)
 if value==null or not value.status in [&"pending",&"delivered"]:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"order_unavailable")
 var checked := _check_settlement(value,mode)
 if not checked.ok or checked.details.get("duplicate",false):return checked
 var item: PreparedItem
 var handover := value.status==&"pending"
 if handover:
  checked=_check_handover(value)
  if not checked.ok:return checked
  item=_handover(value)
  if item==null:return ActionResult.failure(ActionResult.Code.WRONG_ORDER,&"wrong_order")
 else:item=PreparedItem.from_dict(value.served_item)
 _settle(value,mode)
 if handover:
  _cooking.held_changed.emit()
  handed_over.emit(value.id,value.visit_id,item)
 settled.emit(value.id,value.visit_id,item,value.payment)
 return ActionResult.success({"payment":value.payment,"settlement":str(mode),"visit_id":str(value.visit_id),"cue":"coin" if mode==&"paid" else ""})
func cancel_visit(visit_id: StringName) -> void:
 var value := pending_for(visit_id)
 if value:
  value.status = &"cancelled"
  value.closed_at=_clock.world_minutes if _clock!=null else -1.0
func snapshot() -> Dictionary:
 var records: Dictionary = {}
 for id in _orders: records[id] = _orders[id].snapshot()
 return {"orders":records,"next_id":_next_id}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("orders") is Dictionary or not ContentValidation.integer(data.get("next_id")) or data.next_id<1: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_orders")
 var candidate: Dictionary = {}
 var visits: Dictionary = {}
 var delivered_ids: Dictionary={}
 for id in data.orders:
  var record: Variant = data.orders[id]
  if not record is Dictionary or record.get("id")!=id or not record.get("visit_id") is String or (_foods==null or not _foods.has_food(StringName(str(record.get("food_id",""))))) or not record.get("status") in ["pending","delivered","cancelled"] or not record.get("delivered_item_id") is String: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_order")
  if not ContentValidation.integer(record.get("base_price")) or record.base_price<0 or not record.get("tips") is Array or record.tips.size()!=4: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_quote")
  for tip in record.tips:
   if not ContentValidation.integer(tip) or tip<0: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_quote")
  var suffix: String = str(id).trim_prefix("order_")
  if not str(id).begins_with("order_") or not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=int(data.next_id): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_order_identity")
  if not ServiceReceiptValidation.valid(record,_foods,receipt_recipes,menu):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_service_receipt")
  if record.status=="pending" or (record.status=="delivered" and record.settlement=="pending"):
   if visits.has(record.visit_id): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"duplicate_order")
   visits[record.visit_id] = true
  if (record.status == "delivered") != (not record.delivered_item_id.is_empty()): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_delivery")
  if record.status=="delivered":
   if delivered_ids.has(record.delivered_item_id):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"duplicate_delivered_item")
   delivered_ids[record.delivered_item_id]=true
  var value := OrderState.new()
  value.id = StringName(id)
  value.visit_id = StringName(record.visit_id)
  value.character_id=StringName(record.character_id)
  value.food_id = StringName(record.food_id)
  value.status = StringName(record.status)
  value.delivered_item_id = StringName(record.delivered_item_id)
  value.quote=record.quote.duplicate(true);value.source_item=record.source_item.duplicate(true)
  value.gift_promised=record.gift_promised;value.settlement=StringName(record.settlement);value.payment=int(record.payment);value.served_item=record.served_item.duplicate(true)
  if record.has("timing_known") and not record.timing_known is bool:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_order_timing")
  if not ContentValidation.integer(record.get("served_quality",-1)) or int(record.get("served_quality",-1))< -1 or int(record.get("served_quality",-1))>3:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_order_quality")
  value.timing_known=record.get("timing_known",false)
  for field in ["created_at","served_at","closed_at"]:
   var timestamp: Variant=record.get(field,-1.0)
   if not ContentValidation.number(timestamp) or timestamp< -1:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_order_timing")
   value.set(field,float(timestamp))
  value.served_quality=int(record.get("served_quality",-1))
  if value.timing_known:
   if value.created_at<0 or (_clock!=null and value.created_at>_clock.world_minutes):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_order_timing")
   if (value.status==&"cancelled" or value.settlement!=&"pending") and value.closed_at<value.created_at:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_order_timing")
   if value.status==&"delivered" and (value.served_at<value.created_at or value.served_quality<0 or (value.settlement!=&"pending" and value.closed_at<value.served_at)):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_order_timing")
  value.base_price = int(record.base_price)
  value.tips = record.tips.duplicate()
  candidate[id] = value
 _decision_order=&""
 _orders = candidate
 _next_id = int(data.next_id)
 return ActionResult.success()
