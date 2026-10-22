class_name ShopService
extends RefCounted
signal changed
var eligibility_provider: Callable
var _data: Dictionary
var _wallet: WalletService
var _items: ItemStore
var _travel: TravelService
var _clock: GameClock
var _stock: Dictionary={}
var _receipts: Dictionary={}
var _delivered: Dictionary={}
var _revision: int=1
var _next_quote: int=1
var _next_receipt: int=1
var _next_restock_at: float
func configure(data: Dictionary, wallet: WalletService, items: ItemStore, travel: TravelService, clock: GameClock) -> ActionResult:
 _data=data.duplicate(true)
 _wallet=wallet
 _items=items
 _travel=travel
 _clock=clock
 for shop_id in _data.shops:_stock[shop_id]=_data.shops[shop_id].stock.duplicate(true)
 _next_restock_at=float(clock.day)*1440+float(data.restock_minutes)
 travel.returned.connect(_return_purchases)
 return ActionResult.success()
func offers(shop_id: StringName) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 if not _data.shops.has(str(shop_id)):return result
 for id in _data.shops[str(shop_id)].offers:
  var offer: Dictionary=_data.shops[str(shop_id)].offers[id].duplicate(true)
  if not _eligible(offer):continue
  offer["id"]=id
  offer["available"]=_available(str(shop_id),offer)
  result.append(offer)
 return result
func quote(shop_id: StringName, lines: Array[Dictionary]) -> ActionResult:
 if not _travel.can_shop(shop_id) or lines.is_empty() or not _data.shops.has(str(shop_id)):return _fail("shop_unavailable")
 var quote := ShopQuote.new()
 quote.id="quote_%d" % _next_quote
 quote.shop_id=str(shop_id)
 quote.offer_revision=_revision
 var demand: Dictionary={}
 var seen: Dictionary={}
 for line in lines:
  var id := str(line.get("offer_id",""))
  if seen.has(id) or not _data.shops[str(shop_id)].offers.has(id) or not ContentValidation.integer(line.get("quantity")) or line.quantity<1:return _fail("invalid_shop_quantity")
  seen[id]=true
  var offer: Dictionary=_data.shops[str(shop_id)].offers[id]
  if not _eligible(offer):return _fail("shop_unavailable")
  for part in offer.contents:demand[part.definition_id]=int(demand.get(part.definition_id,0))+int(part.quantity)*int(line.quantity)
  quote.lines.append({"offer_id":id,"definition_id":offer.contents[0].definition_id,"quantity":int(line.quantity),"unit_price_minor":int(offer.price_minor)})
  quote.total_minor+=int(offer.price_minor)*int(line.quantity)
 for id in demand:
  if int(_stock[str(shop_id)][id])<int(demand[id]):return ActionResult.failure(ActionResult.Code.OUT_OF_STOCK,&"out_of_stock")
 _next_quote+=1
 return ActionResult.success({"quote":quote})
func purchase(quote: ShopQuote, request_id: StringName) -> ActionResult:
 if quote==null or request_id.is_empty():return _fail("invalid_shop_quote")
 if _receipts.has(str(request_id)):
  var receipt: Dictionary=_receipts[str(request_id)]
  if receipt.quote!=quote.snapshot():return _fail("reused_purchase_id")
  return ActionResult.success({"receipt":receipt.duplicate(true),"duplicate":true})
 if quote.offer_revision!=_revision or not _travel.can_shop(StringName(quote.shop_id)):return _fail("stale_shop_quote")
 var lines: Array[Dictionary]=[]
 for line in quote.lines:lines.append({"offer_id":line.offer_id,"quantity":line.quantity})
 var validation := self.quote(StringName(quote.shop_id),lines)
 if not validation.ok:return validation
 var current: ShopQuote=validation.details.quote
 if current.total_minor!=quote.total_minor or current.lines!=quote.lines:return _fail("stale_shop_quote")
 if _wallet.balance<quote.total_minor:return ActionResult.failure(ActionResult.Code.INSUFFICIENT_FUNDS,&"insufficient_funds")
 var grants: Array[Dictionary]=[]
 var stock := _stock.duplicate(true)
 var journey: Dictionary=_travel.snapshot().journey
 for line in quote.lines:
  var offer: Dictionary=_data.shops[quote.shop_id].offers[line.offer_id]
  for part in offer.contents:
   var quantity := int(part.quantity)*int(line.quantity)
   stock[quote.shop_id][part.definition_id]-=quantity
   var definition := _items.definition(StringName(part.definition_id))
   if definition.kind=="ingredient":grants.append({"definition_id":part.definition_id,"quantity":quantity,"container_id":journey.purchase_container_id,"attributes":{}})
   else:
    for i in range(quantity):grants.append({"definition_id":part.definition_id,"quantity":1,"container_id":journey.purchase_container_id,"attributes":{"enabled":false} if part.definition_id in ["fan","radio"] else {}})
 var prepared := _items.prepare_grants(grants)
 if not prepared.ok:return prepared
 var granted: Array=[]
 for id in prepared.details.change.state.items:
  if not _items.get_item(StringName(id)).is_empty():continue
  var item: Dictionary=prepared.details.change.state.items[id]
  granted.append({"item_id":id,"definition_id":item.definition_id,"quantity":item.quantity})
 var receipt := {"grants_known":true,"granted":granted,"id":"receipt_%d" % _next_receipt,"request_id":str(request_id),"journey_id":journey.id,"bag_id":journey.purchase_container_id,"quote":quote.snapshot(),"total_minor":quote.total_minor,"at":_clock.world_minutes}
 var committed := _items.commit(prepared.details.change,false)
 if not committed.ok:return committed
 # No await or observer between commit and debit; all preconditions checked above.
 _wallet.try_spend(quote.total_minor)
 _stock=stock
 _receipts[str(request_id)]=receipt
 _next_receipt+=1
 _revision+=1
 _items.changed.emit(_items.revision)
 changed.emit()
 return ActionResult.success({"receipt":receipt.duplicate(true),"cue":"coin"})
func tick(_frame: Dictionary) -> void:
 elapse(0)
func elapse(_world_minutes: float) -> void:
 if _clock.world_minutes<_next_restock_at:return
 for shop_id in _data.shops:
  var unique: Array=[]
  for offer in _data.shops[shop_id].offers.values():
   if offer.has("unique_owned_definition"):
    for part in offer.contents:unique.append(part.definition_id)
  for id in _data.shops[shop_id].stock:
   if not id in unique:_stock[shop_id][id]=_data.shops[shop_id].stock[id]
 _next_restock_at=floorf(_clock.world_minutes/1440)*1440+float(_data.restock_minutes)
 if _next_restock_at<=_clock.world_minutes:_next_restock_at+=1440
 _revision+=1
 changed.emit()
func _eligible(offer: Dictionary) -> bool:
 if offer.has("unique_owned_definition") and not _items.instances(StringName(offer.unique_owned_definition)).is_empty():return false
 if offer.has("required_fact") and (not eligibility_provider.is_valid() or not eligibility_provider.call(StringName(offer.required_fact))):return false
 return true
func _available(shop_id: String, offer: Dictionary) -> int:
 var value := 2147483647
 for part in offer.contents:value=mini(value,int(_stock[shop_id][part.definition_id])/int(part.quantity))
 return value
func _return_purchases(journey_id: StringName, bag_id: StringName, location_id: StringName) -> void:
 if _delivered.has(str(journey_id)):return
 var change := _items.candidate()
 var store_id := str(location_id)+"_furniture"
 for item in _items.items_in(bag_id):
  if item.kind in ["equipment","furniture"]:change.state.items[item.id].container_id=store_id
 var result := _items.commit(change,false)
 if not result.ok:return
 _delivered[str(journey_id)]=true
 _items.changed.emit(_items.revision)
 changed.emit()
func snapshot() -> Dictionary:
 return {"stock":_stock.duplicate(true),"receipts":_receipts.duplicate(true),"delivered":_delivered.duplicate(true),"revision":_revision,"next_quote":_next_quote,"next_receipt":_next_receipt,"next_restock_at":_next_restock_at}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("stock") is Dictionary or not data.get("receipts") is Dictionary or not data.get("delivered") is Dictionary or not ContentValidation.number(data.get("next_restock_at")):return _fail("invalid_shop_save")
 for key in ["revision","next_quote","next_receipt"]:
  if not ContentValidation.integer(data.get(key)) or data[key]<1:return _fail("invalid_shop_save")
 if data.stock.size()!=_data.shops.size():return _fail("invalid_shop_stock")
 for shop_id in _data.shops:
  if not data.stock.get(shop_id) is Dictionary or data.stock[shop_id].size()!=_data.shops[shop_id].stock.size():return _fail("invalid_shop_stock")
  for id in _data.shops[shop_id].stock:
   if not ContentValidation.integer(data.stock[shop_id].get(id)) or data.stock[shop_id][id]<0 or data.stock[shop_id][id]>1000000000:return _fail("invalid_shop_stock")
 for id in data.receipts:
  var receipt: Variant=data.receipts[id]
  if not receipt is Dictionary or receipt.get("request_id")!=id or not receipt.get("quote") is Dictionary or not receipt.get("journey_id") is String or not receipt.get("bag_id") is String or not ContentValidation.integer(receipt.get("total_minor")) or receipt.total_minor<1:return _fail("invalid_shop_receipt")
  if not receipt.get("grants_known") is bool or not receipt.get("granted") is Array:return _fail("invalid_shop_grants")
  if receipt.grants_known and receipt.granted.is_empty():return _fail("missing_shop_grants")
  var total := 0
  if not receipt.quote.get("lines") is Array:return _fail("invalid_shop_quote")
  for line in receipt.quote.lines:
   if not line is Dictionary or not ContentValidation.integer(line.get("quantity")) or line.quantity<1 or not ContentValidation.integer(line.get("unit_price_minor")) or line.unit_price_minor<1:return _fail("invalid_shop_quote")
   total+=int(line.quantity)*int(line.unit_price_minor)
  if total!=receipt.total_minor:return _fail("invalid_shop_receipt_total")
  var suffix := str(receipt.get("id","")).trim_prefix("receipt_")
  if not str(receipt.get("id","")).begins_with("receipt_") or not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=int(data.next_receipt):return _fail("invalid_receipt_counter")
 for value in data.delivered.values():
  if value!=true:return _fail("invalid_shop_delivery")
 _stock=data.stock.duplicate(true)
 _receipts=data.receipts.duplicate(true)
 _delivered=data.delivered.duplicate(true)
 _revision=int(data.revision)
 _next_quote=int(data.next_quote)
 _next_receipt=int(data.next_receipt)
 _next_restock_at=float(data.next_restock_at)
 return ActionResult.success()
func _fail(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,StringName(key))
