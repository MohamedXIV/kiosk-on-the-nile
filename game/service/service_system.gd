class_name ServiceSystem
extends RefCounted
signal settled(order_id: StringName, visit_id: StringName, item: PreparedItem, payment: int)
var _wallet: WalletService
var _cooking: CookingService
var _available: Callable
var _balance: Dictionary
var _orders: Dictionary = {}
var _next_id: int = 1
func configure(wallet: WalletService, cooking: CookingService, available: Callable, balance: Dictionary = {}) -> void:
 _wallet = wallet
 _cooking = cooking
 _available = available
 _balance = balance.duplicate(true)
func place_order(visit_id: StringName, food_id: StringName) -> OrderState:
 if not _balance.has(str(food_id)+"_price") or not _available.call(visit_id): return null
 for existing in _orders.values():
  if existing.visit_id == visit_id and existing.status == &"pending": return existing
 var order := OrderState.new()
 order.id = StringName("order_%d" % _next_id)
 _next_id += 1
 order.visit_id = visit_id
 order.food_id = food_id
 order.base_price = int(_balance[str(food_id)+"_price"])
 order.tips = _balance.quality_tips.duplicate()
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
 _cooking.held_changed.emit()
 settled.emit(order_id,value.visit_id,item,payment)
 return ActionResult.success({"payment":payment,"cue":"coin","visit_id":str(value.visit_id)})
func cancel_visit(visit_id: StringName) -> void:
 var value := pending_for(visit_id)
 if value: value.status = &"cancelled"
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
  if not record is Dictionary or record.get("id")!=id or not record.get("visit_id") is String or not record.get("food_id") in ["tea","kebda"] or not record.get("status") in ["pending","delivered","cancelled"] or not record.get("delivered_item_id") is String: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_order")
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
  value.base_price = int(record.base_price)
  value.tips = record.tips.duplicate()
  candidate[id] = value
 _orders = candidate
 _next_id = int(data.next_id)
 return ActionResult.success()
