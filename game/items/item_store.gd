class_name ItemStore
extends RefCounted
signal changed(revision: int)
var _definitions: Dictionary = {}
var _state: Dictionary = {"items":{},"containers":{},"reservations":{},"consumed":{},"discarded":{},"next_id":1}
var revision: int = 0
var world_clock: GameClock
var food_definitions: Dictionary={}
var cold_active: Callable
func configure(definitions: Dictionary, containers: Dictionary) -> ActionResult:
 var result := ItemContentValidation.validate(definitions,containers)
 if not result.ok: return result
 _definitions = definitions.duplicate(true)
 _state = {"items":{},"containers":containers.duplicate(true),"reservations":{},"consumed":{},"discarded":{},"next_id":1}
 revision = 0
 return ActionResult.success()
func definition(id: StringName) -> Dictionary:
 return _definitions.get(str(id),{}).duplicate(true)
func get_item(id: StringName) -> Dictionary:
 return _state.items.get(str(id),{}).duplicate(true)
func get_container(id: StringName) -> Dictionary:
 return _state.containers.get(str(id),{}).duplicate(true)
func items_in(container_id: StringName) -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 for id in _state.items:
  if _state.items[id].container_id==str(container_id): result.append(_state.items[id].duplicate(true))
 result.sort_custom(func(a,b):return a.id<b.id)
 return result
func instances(definition_id: StringName) -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 for item in _state.items.values():
  if item.definition_id==str(definition_id): result.append(item.duplicate(true))
 return result
func reserved_quantities() -> Dictionary:
 var result := {}
 for lines in _state.reservations.values():
  for line in lines:result[str(line.item_id)]=int(result.get(str(line.item_id),0))+int(line.quantity)
 return result
func ingredient_family(id: String) -> String:
 return str(_definitions.get(id,{}).get("material",{}).get("family",id))
func ingredient_matches(actual: String, required: String) -> bool:
 return IngredientLots.matches(_definitions,actual,required)
func material_instances(required: StringName) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for item in _state.items.values():
  if ingredient_matches(str(item.definition_id),str(required)):result.append(item.duplicate(true))
 result.sort_custom(func(a,b):
  var first: Dictionary=a.attributes.get("lot",{})
  var second: Dictionary=b.attributes.get("lot",{})
  if float(first.get("acquired_at",0))!=float(second.get("acquired_at",0)):return float(first.get("acquired_at",0))<float(second.get("acquired_at",0))
  return str(a.id)<str(b.id))
 return result
func snapshot() -> Dictionary:
 return _state.duplicate(true)
func storage_view() -> Dictionary:
 # Current storage only; UI has no use for the unbounded consumption history.
 return {"items":_state.items.duplicate(true),"containers":_state.containers.duplicate(true),"reservations":_state.reservations.duplicate(true)}
func candidate() -> ItemChangeSet:
 return ItemChangeSet.new(revision,_state)
func prepare_moves(moves: Array[Dictionary]) -> ActionResult:
 var change := candidate()
 for move in moves:
  var id := str(move.get("item_id",""))
  if not change.state.items.has(id): return _fail("missing_item")
  var item: Dictionary = change.state.items[id]
  if item.container_id!=str(move.get("from_container","")) or not ContentValidation.integer(move.get("quantity")) or int(move.quantity)!=int(item.quantity): return _fail("invalid_item_move")
  var destination := str(move.get("to_container",""))
  if item.attributes.has("freshness"):
   var container: Dictionary=change.state.containers.get(destination,{})
   var context := "cold" if container.get("kind")=="cold" and cold_active.is_valid() and cold_active.call(StringName(str(container.host_id))) else "ambient"
   item.attributes.freshness=FoodFreshness.transition(item.attributes.freshness,context,world_clock.world_minutes)
  item.container_id = destination
 return _prepared(change)
func prepare_grants(grants: Array[Dictionary]) -> ActionResult:
 var change := candidate()
 for grant in grants:
  var definition_id := str(grant.get("definition_id",""))
  if not _definitions.has(definition_id): return _fail("unknown_item")
  var id := str(grant.get("id","item_%d" % int(change.state.next_id)))
  if change.state.items.has(id): return _fail("duplicate_item")
  change.state.next_id = int(change.state.next_id)+1
  change.state.items[id] = {"id":id,"definition_id":definition_id,"kind":_definitions[definition_id].kind,"quantity":grant.get("quantity",0),"container_id":str(grant.get("container_id","")),"attributes":grant.get("attributes",{}).duplicate(true)}
  if _definitions[definition_id].has("material"):
   var attributes: Dictionary=change.state.items[id].attributes
   if attributes.has("lot"):return _fail("ingredient_lot_already_stamped")
   var acquisition: Variant=attributes.get("acquisition",{})
   if not acquisition is Dictionary:return _fail("invalid_ingredient_acquisition")
   if acquisition.has("cost_minor") and not ContentValidation.integer(acquisition.cost_minor):return _fail("invalid_ingredient_cost")
   var lot := IngredientLots.stamp(_definitions[definition_id],id,world_clock.world_minutes if world_clock!=null else 0,int(acquisition.get("cost_minor",0)))
   for key in ["cost_units","cost_known","source_kind","source_ref"]:
    if acquisition.has(key):lot[key]=acquisition[key]
   attributes.erase("acquisition")
   attributes["lot"]=lot
  if _definitions[definition_id].get("surface",false):
   var owner: Dictionary=change.state.containers.get(str(grant.get("container_id","")),{})
   var slot_id := id+":top"
   change.state.containers[slot_id]={"id":slot_id,"location_id":owner.get("location_id",""),"kind":"surface","capacity":1,"allowed_tags":["prepared","batch","ingredient"],"host_id":id}
  var container_spec: Dictionary=_definitions[definition_id].get("container",{})
  if not container_spec.is_empty():
   var owner: Dictionary=change.state.containers.get(str(grant.get("container_id","")),{})
   var container_id := id+":"+str(container_spec.kind)
   change.state.containers[container_id]={"id":container_id,"location_id":owner.get("location_id",""),"kind":container_spec.kind,"capacity":container_spec.capacity,"allowed_tags":container_spec.allowed_tags.duplicate(),"host_id":id}
 return _prepared(change)
func validate_change(change: ItemChangeSet) -> ActionResult:
 if change==null or change.revision!=revision:return _fail("stale_item_change")
 var valid := _validate_state(change.state)
 if not valid.ok:return valid
 for id in change.state.items:
  if _state.items.has(id) and _state.items[id].attributes.has("lot"):
   if not IngredientLots._same_lot(_state.items[id].attributes.lot,change.state.items[id].attributes.get("lot",{})):return _fail("immutable_ingredient_lot")
  if _state.items.has(id) and _state.items[id].attributes.has("freshness"):
   var before: Dictionary=_state.items[id].attributes
   var after: Dictionary=change.state.items[id].attributes
   if not after.has("freshness") or after.get("prepared_at")!=before.get("prepared_at") or after.get("initial_quality")!=before.get("initial_quality"):return _fail("immutable_food_origin")
   if not is_equal_approx(FoodFreshness.exposure(before.freshness,world_clock.world_minutes),FoodFreshness.exposure(after.freshness,world_clock.world_minutes)):return _fail("food_rejuvenation")
 return ActionResult.success()
func commit(change: ItemChangeSet, notify: bool = true) -> ActionResult:
 if change==null or change.revision!=revision: return _fail("stale_item_change")
 var result := validate_change(change)
 if not result.ok: return result
 _state = change.state.duplicate(true)
 revision += 1
 if notify: changed.emit(revision)
 return ActionResult.success()
func restore(data: Dictionary) -> ActionResult:
 var result := _validate_state(data)
 if not result.ok: return result
 _state = data.duplicate(true)
 if not _state.has("consumed"):_state["consumed"]={}
 if not _state.has("discarded"):_state["discarded"]={}
 revision += 1
 return ActionResult.success()
func _prepared(change: ItemChangeSet) -> ActionResult:
 var result := validate_change(change)
 return ActionResult.success({"change":change}) if result.ok else result
func _validate_state(data: Dictionary) -> ActionResult:
 if not data.get("items") is Dictionary or not data.get("containers") is Dictionary or not data.get("reservations") is Dictionary or not ContentValidation.integer(data.get("next_id")) or data.next_id<1: return _fail("invalid_items")
 var result := ItemContentValidation.validate(_definitions,data.containers)
 if not result.ok: return result
 var used: Dictionary = {}
 for id in data.items:
  var item: Variant = data.items[id]
  if not item is Dictionary or item.get("id")!=id or not _definitions.has(str(item.get("definition_id",""))) or not ContentValidation.integer(item.get("quantity")) or item.quantity<1 or not item.get("attributes") is Dictionary: return _fail("invalid_item")
  if str(id).begins_with("food_") or str(id).begins_with("item_"):
   var suffix := str(id).substr(str(id).find("_")+1)
   if not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=int(data.next_id):return _fail("invalid_item_counter")
  if item.attributes.has("material_quality") and not ContentValidation.bounded(item.attributes.material_quality,0,1):return _fail("invalid_material_quality")
  if item.attributes.has("freshness") and (not ContentValidation.bounded(item.attributes.get("initial_quality"),0,100) or not ContentValidation.number(item.attributes.get("prepared_at"))):return _fail("invalid_food_origin")
  if item.attributes.has("freshness") and not FoodFreshness.valid(item.attributes.freshness,float(item.attributes.get("prepared_at",-1)),world_clock.world_minutes if world_clock!=null else INF):return _fail("invalid_food_freshness")
  if item.get("kind")=="prepared" and not item.attributes.has("freshness"):return _fail("missing_food_freshness")
  var lot_result := IngredientLots.validate(item,_definitions,world_clock.world_minutes if world_clock!=null else INF)
  if not lot_result.ok:return lot_result
  var definition: Dictionary = _definitions[item.definition_id]
  if item.get("kind")!=definition.kind or (definition.kind!="ingredient" and int(item.quantity)!=1) or not data.containers.has(str(item.get("container_id",""))): return _fail("invalid_item_owner")
  var container: Dictionary = data.containers[item.container_id]
  if not str(item.kind) in container.allowed_tags: return _fail("incompatible_container")
  used[item.container_id] = int(used.get(item.container_id,0))+int(item.quantity)
  if int(used[item.container_id])>int(container.capacity): return _fail("container_full")
 var reserved: Dictionary = {}
 if not data.get("discarded") is Dictionary:return _fail("invalid_discard_history")
 for id in data.discarded:
  var receipt: Variant=data.discarded[id]
  if not receipt is Dictionary or not receipt.get("item") is Dictionary or not receipt.get("item",{}).get("attributes") is Dictionary or receipt.item.get("id")!=id or data.items.has(id) or data.get("consumed",{}).has(id) or receipt.item.get("container_id")!="player_hand" or not receipt.item.get("kind") in ["prepared","ingredient"] or receipt.item.get("quantity")!=1 or not ContentValidation.bounded(receipt.get("at"),0,world_clock.world_minutes):return _fail("invalid_discard")
  if not _definitions.has(str(receipt.item.get("definition_id",""))) or _definitions[str(receipt.item.definition_id)].kind!=receipt.item.kind:return _fail("invalid_removed_definition")
  var raw: Dictionary=receipt.item.attributes
  if not ContentValidation.bounded(raw.get("initial_quality"),0,100) or not ContentValidation.number(raw.get("prepared_at")) or not FoodFreshness.valid(raw.get("freshness"),float(raw.prepared_at),float(receipt.at)):return _fail("invalid_discard_freshness")
 if not data.get("consumed",{}) is Dictionary:return _fail("invalid_consumption_history")
 for id in data.get("consumed",{}):
  var receipt: Variant=data.consumed[id]
  if not receipt is Dictionary or not receipt.get("item") is Dictionary or receipt.item.get("id")!=id or data.items.has(id) or receipt.item.get("container_id")!="player_hand" or receipt.item.get("kind")!="prepared" or receipt.item.get("quantity")!=1 or not receipt.item.get("attributes") is Dictionary or not ContentValidation.number(receipt.get("at")) or receipt.at<0:return _fail("invalid_consumption_receipt")
  if not _definitions.has(str(receipt.item.get("definition_id",""))) or _definitions[str(receipt.item.definition_id)].kind!=receipt.item.kind:return _fail("invalid_removed_definition")
  var raw: Dictionary=receipt.item.attributes
  if not ContentValidation.bounded(raw.get("initial_quality"),0,100) or not ContentValidation.number(raw.get("prepared_at")) or not FoodFreshness.valid(raw.get("freshness"),float(raw.prepared_at),float(receipt.at)):return _fail("invalid_consumed_freshness")
  var suffix := str(id).trim_prefix("food_")
  if not str(id).begins_with("food_") or not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=int(data.next_id):return _fail("invalid_consumption_id")
 for job_id in data.reservations:
  if not data.reservations[job_id] is Array: return _fail("invalid_reservation")
  for line in data.reservations[job_id]:
   if not line is Dictionary or not data.items.has(str(line.get("item_id",""))) or not ContentValidation.integer(line.get("quantity")) or line.quantity<1: return _fail("invalid_reservation")
   var id := str(line.item_id)
   var actual := str(data.items[id].definition_id)
   if line.get("definition_id")!=actual or not IngredientLots.matches(_definitions,actual,str(line.get("requirement_id",actual))):return _fail("invalid_reservation_material")
   reserved[id] = int(reserved.get(id,0))+int(line.quantity)
   if reserved[id]>data.items[id].quantity: return _fail("over_reserved_item")
 return ActionResult.success()
func _fail(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,StringName(key))
