class_name ServiceSystem
extends RefCounted
signal settled(order_id: StringName, visit_id: StringName, item: PreparedItem, payment: int)
var _foods: FoodRegistry
var _clock: GameClock
var _wallet: WalletService
var _cooking: CookingService
var _available: Callable
var _balance: Dictionary
var _orders: Dictionary = {}
var _next_id: int = 1
func configure(wallet: WalletService, cooking: CookingService, available: Callable, balance: Dictionary = {}, foods: FoodRegistry = null, clock: GameClock = null) -> void:
 _foods=foods
 _clock=clock
 _wallet = wallet
 _cooking = cooking
 _available = available
 _balance = balance.duplicate(true)
func place_order(visit_id: StringName, food_id: StringName) -> OrderState:
 if _foods==null or not _foods.has_food(food_id) or not _available.call(visit_id):return null
 for existing in _orders.values():
  if existing.visit_id == visit_id and existing.status == &"pending": return existing
 var order := OrderState.new()
 order.id = StringName("order_%d" % _next_id)
 _next_id += 1
 order.visit_id = visit_id
 order.food_id = food_id
 var food := _foods.definition(food_id)
 order.base_price=int(food.price_minor)
 order.tips=food.tips.duplicate()
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
func deliver(order_id: StringName) -> ActionResult:
 var value := order(order_id)
 if value == null or value.status != &"pending" or not _available.call(value.visit_id): return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"order_unavailable")
 var item := _cooking.held_item()
 if item == null or item.food_id != value.food_id: return ActionResult.failure(ActionResult.Code.WRONG_ORDER,&"wrong_order")
 var payment := value.base_price+int(value.tips[item.quality_score])
 # Commit all owners before notifying observers.
 _cooking.take_held(item.id,false)
 _wallet.credit(payment)
 value.status = &"delivered"
 value.delivered_item_id = item.id
 value.served_at=_clock.world_minutes if _clock!=null else -1.0
 value.closed_at=value.served_at
 value.served_quality=item.quality_score
 _cooking.held_changed.emit()
 settled.emit(order_id,value.visit_id,item,payment)
 return ActionResult.success({"payment":payment,"cue":"coin","visit_id":str(value.visit_id)})
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
 for id in data.orders:
  var record: Variant = data.orders[id]
  if not record is Dictionary or record.get("id")!=id or not record.get("visit_id") is String or (_foods==null or not _foods.has_food(StringName(str(record.get("food_id",""))))) or not record.get("status") in ["pending","delivered","cancelled"] or not record.get("delivered_item_id") is String: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_order")
  if not ContentValidation.integer(record.get("base_price")) or record.base_price<0 or not record.get("tips") is Array or record.tips.size()!=4: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_quote")
  for tip in record.tips:
   if not ContentValidation.integer(tip) or tip<0: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_quote")
  var suffix: String = str(id).trim_prefix("order_")
  if not str(id).begins_with("order_") or not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=int(data.next_id): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_order_identity")
  if record.status == "pending":
   if visits.has(record.visit_id): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"duplicate_order")
   visits[record.visit_id] = true
  if (record.status == "delivered") != (not record.delivered_item_id.is_empty()): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_delivery")
  var value := OrderState.new()
  value.id = StringName(id)
  value.visit_id = StringName(record.visit_id)
  value.food_id = StringName(record.food_id)
  value.status = StringName(record.status)
  value.delivered_item_id = StringName(record.delivered_item_id)
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
   if value.status!=&"pending" and value.closed_at<value.created_at:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_order_timing")
   if value.status==&"delivered" and (value.served_at!=value.closed_at or value.served_quality<0):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_order_timing")
  value.base_price = int(record.base_price)
  value.tips = record.tips.duplicate()
  candidate[id] = value
 _orders = candidate
 _next_id = int(data.next_id)
 return ActionResult.success()
