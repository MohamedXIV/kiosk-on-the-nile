class_name MenuService
extends RefCounted
## Authored serving rules, player prices and immutable accepted quote values.
signal changed
const LIMIT := 1000000000
var _data: Dictionary
var _foods: FoodRegistry
var _inventory: InventoryService
var _clock: GameClock
var _prices: Dictionary={}
var _extras: Dictionary={}
var revision: int=1
func configure(data: Dictionary, foods: FoodRegistry, inventory: InventoryService, clock: GameClock) -> ActionResult:
 var checked := validate_catalog(data,foods._definitions,inventory.items._definitions)
 if not checked.ok:return checked
 _data=data.duplicate(true);_foods=foods;_inventory=inventory;_clock=clock
 _prices={};_extras={};revision=1
 for food in data.foods:
  for format in data.foods[food].formats:
   for mode in ["here","takeaway"]:_prices[variant_id(food,format,mode)]=int(foods.definition(StringName(food)).price_minor)
 for id in data.additions:_extras[id]=int(data.additions[id].price_minor)
 inventory.items.serving_catalog=data.duplicate(true)
 return ActionResult.success()
static func variant_id(food: String, format: String, mode: String) -> String:return food+"/"+format+"/"+mode
func variants(food: String) -> PackedStringArray:
 var ids := PackedStringArray()
 for id in _prices:
  if str(id).get_slice("/",0)==food:ids.append(str(id))
 return ids
func default_variant(food: String) -> String:
 return variant_id(food,str(_data.foods[food].formats[0]),"here") if _data.foods.has(food) else ""
func set_price(variant: StringName, amount_minor: int) -> ActionResult:
 if not _prices.has(str(variant)) or amount_minor<0 or amount_minor>LIMIT:return _fail("invalid_menu_price")
 if int(_prices[str(variant)])==amount_minor:return ActionResult.success({"duplicate":true})
 _prices[str(variant)]=amount_minor;revision+=1;changed.emit()
 return ActionResult.success()
func set_addition_price(id: StringName, amount_minor: int) -> ActionResult:
 if not _extras.has(str(id)) or amount_minor<0 or amount_minor>LIMIT:return _fail("invalid_menu_price")
 if int(_extras[str(id)])==amount_minor:return ActionResult.success({"duplicate":true})
 _extras[str(id)]=amount_minor;revision+=1;changed.emit()
 return ActionResult.success()
func plan(food: StringName, options: Dictionary={}) -> ActionResult:
 var variant := str(options.get("variant_id",default_variant(str(food))))
 var additions: Variant=options.get("additions",[])
 if not additions is Array:return _fail("incompatible_serving")
 return make_plan(_data,str(food),variant,additions)
static func make_plan(data: Dictionary, food: String, variant: String, additions: Array) -> ActionResult:
 var parts := variant.split("/")
 if parts.size()!=3 or parts[0]!=food or not data.get("foods",{}).has(food) or not parts[1] in data.foods[food].formats or not parts[2] in ["here","takeaway"]:return _fail("incompatible_serving")
 var selected: Array=[];var inputs: Array=[]
 for input in data.formats[parts[1]]:inputs.append(input.duplicate(true))
 if parts[2]=="takeaway":
  for input in data.packaging[parts[1]]:inputs.append(input.duplicate(true))
 for id in additions:
  if not id is String or id in selected or not id in data.foods[food].additions:return _fail("incompatible_serving")
  selected.append(id)
 selected.sort()
 for id in selected:
  for input in data.additions[id].inputs:inputs.append(input.duplicate(true))
 return ActionResult.success({"plan":{"version":1,"food_id":food,"variant_id":variant,"serving_format":str(parts[1]),"consumption_mode":str(parts[2]),"additions":selected,"inputs":inputs}})
static func validate_plan(plan: Variant, data: Dictionary) -> bool:
 if not plan is Dictionary or not plan.get("food_id") is String or not plan.get("variant_id") is String or not plan.get("additions") is Array:return false
 var expected := make_plan(data,plan.food_id,plan.variant_id,plan.additions)
 return expected.ok and StableJson.stringify(plan)==StableJson.stringify(expected.details.plan)
static func consume_inputs(inventory: InventoryService, change: ItemChangeSet, location: StringName, plan: Dictionary) -> ActionResult:
 var inputs: Array[Dictionary]=[];inputs.assign(plan.inputs)
 var available := inventory.available(location,inputs)
 if not available.ok:return available
 var evidence: Array=[]
 for source in available.details.sources:
  var record: Dictionary=change.state.items[str(source.item_id)].duplicate(true)
  record["consumed_quantity"]=int(source.quantity);record["requirement_index"]=int(source.requirement_index);evidence.append(record)
  change.state.items[str(source.item_id)].quantity-=int(source.quantity)
  if change.state.items[str(source.item_id)].quantity==0:change.state.items.erase(str(source.item_id))
 return ActionResult.success({"evidence":evidence})
func quote(variant: StringName, additions: PackedStringArray=[]) -> ActionResult:
 if not _prices.has(str(variant)):return _fail("incompatible_serving")
 var made := make_plan(_data,str(variant).get_slice("/",0),str(variant),Array(additions))
 if not made.ok:return made
 var plan: Dictionary=made.details.plan
 var amount := int(_prices[str(variant)])
 var lines: Dictionary={}
 for id in plan.additions:
  lines[id]=int(_extras[id]);amount+=int(_extras[id])
 if amount>LIMIT:return _fail("invalid_menu_price")
 return ActionResult.success({"quote":{"variant_id":str(variant),"food_id":plan.food_id,"serving_format":plan.serving_format,"consumption_mode":plan.consumption_mode,"additions":plan.additions.duplicate(),"base_minor":int(_prices[str(variant)]),"extra_prices":lines,"price_minor":amount,"revision":revision,"at":_clock.world_minutes}})
func valid_quote(quote: Variant) -> bool:
 if not quote is Dictionary or not CharacterLifeValidation.keys(quote,["variant_id","food_id","serving_format","consumption_mode","additions","base_minor","extra_prices","price_minor","revision","at"]) or not quote.get("variant_id") is String or not quote.get("food_id") is String or not quote.get("additions") is Array or not quote.get("extra_prices") is Dictionary:return false
 var made := make_plan(_data,quote.food_id,quote.variant_id,quote.additions)
 if not made.ok or quote.serving_format!=made.details.plan.serving_format or quote.consumption_mode!=made.details.plan.consumption_mode or quote.additions!=made.details.plan.additions:return false
 if not ContentValidation.integer(quote.base_minor) or not ContentValidation.bounded(quote.base_minor,0,LIMIT) or not ContentValidation.integer(quote.price_minor) or not ContentValidation.bounded(quote.price_minor,0,LIMIT) or not ContentValidation.integer(quote.revision) or not ContentValidation.bounded(quote.revision,1,revision) or not ContentValidation.bounded(quote.at,0,_clock.world_minutes) or quote.extra_prices.size()!=quote.additions.size():return false
 var total := int(quote.base_minor)
 for id in quote.additions:
  if not ContentValidation.integer(quote.extra_prices.get(id)) or not ContentValidation.bounded(quote.extra_prices[id],0,LIMIT):return false
  total+=int(quote.extra_prices[id])
 return total==int(quote.price_minor)
func matches(item: PreparedItem, quote: Dictionary) -> bool:
 return str(item.food_id)==str(quote.food_id) and str(item.variant_id)==str(quote.variant_id) and str(item.serving_format)==str(quote.serving_format) and str(item.consumption_mode)==str(quote.consumption_mode) and Array(item.additions)==quote.additions
func offers(available: PackedStringArray, preparable: PackedStringArray=[]) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for food in available:
  if not _data.foods.has(food):continue
  var combinations: Array=[[]]
  for id in _data.foods[food].additions:
   var existing := combinations.duplicate(true)
   for list in existing:
    var added: Array=list.duplicate();added.append(id);combinations.append(added)
  for variant in variants(food):
   for additions in combinations:
    var quoted := quote(StringName(variant),PackedStringArray(additions))
    if not quoted.ok:continue
    var q: Dictionary=quoted.details.quote
    var feasible := false
    for item in _inventory.items.instances(&"prepared_food"):
     if item.attributes.get("personal_use",false):continue
     var container := _inventory.items.get_container(StringName(item.container_id))
     var local: bool=container.get("location_id")=="kiosk" or container.get("id")=="player_hand" and _inventory.player_pose.location_id==&"kiosk"
     if local and matches(PreparedItem.from_dict(item.attributes),q) and FoodFreshness.view(item.attributes,_clock.world_minutes,_inventory.items.food_definitions).sellable:feasible=true;break
    if not feasible and food in preparable:
     var made := plan(StringName(food),{"variant_id":variant,"additions":additions})
     var inputs: Array[Dictionary]=[];inputs.assign(made.details.plan.inputs)
     feasible=_inventory.available(&"kiosk",inputs,true).ok
    if not feasible:continue
    var spice := float(_foods.definition(StringName(food)).spice)
    for id in q.additions:spice+=float(_data.additions[id].spice)
    result.append({"food_id":food,"variant_id":variant,"additions":q.additions.duplicate(),"price_minor":int(q.price_minor),"spice":clampf(spice,0,1)})
 return result
func snapshot() -> Dictionary:return {"prices":_prices.duplicate(true),"addition_prices":_extras.duplicate(true),"revision":revision}
func restore(data: Dictionary) -> ActionResult:
 if not CharacterLifeValidation.keys(data,["prices","addition_prices","revision"]) or not data.prices is Dictionary or not data.addition_prices is Dictionary or not ContentValidation.integer(data.revision) or data.revision<1 or data.prices.size()!=_prices.size() or data.addition_prices.size()!=_extras.size():return _fail("invalid_menu")
 for pair in [[data.prices,_prices],[data.addition_prices,_extras]]:
  for id in pair[0]:
   if not pair[1].has(id) or not ContentValidation.integer(pair[0][id]) or not ContentValidation.bounded(pair[0][id],0,LIMIT):return _fail("invalid_menu_price")
 _prices=data.prices.duplicate(true);_extras=data.addition_prices.duplicate(true);revision=int(data.revision)
 return ActionResult.success()
static func validate_catalog(data: Dictionary, foods: Dictionary, items: Dictionary) -> ActionResult:
 if not CharacterLifeValidation.keys(data,["version","foods","formats","packaging","additions"]) or data.version!=1 or not data.foods is Dictionary or not data.formats is Dictionary or not data.packaging is Dictionary or not data.additions is Dictionary:return _fail("invalid_menu_catalog")
 for food in data.foods:
  var d: Variant=data.foods[food]
  if not foods.has(food) or not d is Dictionary or not CharacterLifeValidation.keys(d,["formats","additions"]) or not d.formats is Array or d.formats.is_empty() or not d.additions is Array or d.additions.size()>3:return _fail("invalid_menu_food")
  for format in d.formats:
   if not format in ["cup","sandwich","plate"] or not data.formats.has(format) or not data.packaging.has(format):return _fail("invalid_menu_format")
  for id in d.additions:
   if not data.additions.has(id):return _fail("invalid_menu_addition")
 for id in data.additions:
  var d: Variant=data.additions[id]
  if not d is Dictionary or not CharacterLifeValidation.keys(d,["inputs","price_minor","spice"]) or not ContentValidation.integer(d.price_minor) or not ContentValidation.bounded(d.price_minor,0,LIMIT) or not ContentValidation.bounded(d.spice,0,1):return _fail("invalid_menu_addition")
 var requirements: Array=[]
 for collection in [data.formats,data.packaging]:
  for inputs in collection.values():requirements.append(inputs)
 for addition in data.additions.values():requirements.append(addition.inputs)
 for inputs in requirements:
  if not inputs is Array:return _fail("invalid_serving_inputs")
  for input in inputs:
   if not input is Dictionary or not CharacterLifeValidation.keys(input,["definition_id","quantity","required_storage"]) or not input.definition_id is String or items.get(input.definition_id,{}).get("kind")!="ingredient" or not ContentValidation.integer(input.quantity) or not ContentValidation.bounded(input.quantity,1,12) or not input.required_storage in ["dry","cold"]:return _fail("invalid_serving_inputs")
 return ActionResult.success()
static func _fail(key: String) -> ActionResult:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,StringName(key))
