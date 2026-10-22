class_name InventoryService
extends RefCounted
var items: ItemStore
var _aliases: Dictionary
func _init(store: ItemStore, aliases: Dictionary) -> void:
 items = store
 _aliases = aliases.duplicate(true)
func stock_count(location_id: StringName, ingredient_id: StringName) -> int:
 var total := 0
 var definition_id := str(_aliases.get(str(ingredient_id),str(ingredient_id)))
 for item in items.instances(StringName(definition_id)):
  var container := items.get_container(StringName(item.container_id))
  if container.get("location_id")==str(location_id) and container.get("kind") in ["dry","cold"]: total += int(item.quantity)
 return total
func held_id() -> StringName:
 var held := items.items_in(&"player_hand")
 return StringName(held[0].id) if not held.is_empty() else &""
func prepared_item(id: StringName) -> PreparedItem:
 var item := items.get_item(id)
 if item.get("kind")!="prepared": return null
 return PreparedItem.from_dict(item.attributes)
func consume_held(expected_id: StringName, notify: bool = true) -> ActionResult:
 if expected_id.is_empty() or held_id()!=expected_id: return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"empty_hands")
 var change := items.candidate()
 change.state.items.erase(str(expected_id))
 return items.commit(change,notify)
func debit_legacy(ingredient_id: StringName, quantity: int) -> ActionResult:
 var definition_id := str(_aliases.get(str(ingredient_id),str(ingredient_id)))
 var change := items.candidate()
 var remaining := quantity
 for item in items.instances(StringName(definition_id)):
  var container := items.get_container(StringName(item.container_id))
  if container.location_id!="kiosk" or not container.kind in ["dry","cold"]: continue
  var taken := mini(remaining,int(item.quantity))
  change.state.items[item.id].quantity -= taken
  remaining -= taken
  if change.state.items[item.id].quantity==0: change.state.items.erase(item.id)
  if remaining==0: break
 if remaining!=0 or quantity<0: return ActionResult.failure(ActionResult.Code.OUT_OF_STOCK,&"out_of_stock")
 return items.commit(change)
func restock_legacy(stock: Dictionary) -> ActionResult:
 var grants: Array[Dictionary] = []
 for id in stock:
  if not ContentValidation.integer(stock[id]) or stock[id]<0: return ContentValidation.fail("stock")
  if stock[id]>0: grants.append({"definition_id":str(_aliases.get(id,id)),"quantity":int(stock[id]),"container_id":"kiosk_dry","attributes":{}})
 if grants.is_empty(): return ActionResult.success()
 var result := items.prepare_grants(grants)
 return items.commit(result.details.change) if result.ok else result
func receive_prepared(item: PreparedItem) -> ActionResult:
 if not held_id().is_empty(): return ActionResult.failure(ActionResult.Code.HANDS_BUSY,&"hands_busy")
 var result := items.prepare_grants([{"id":str(item.id),"definition_id":"prepared_food","quantity":1,"container_id":"player_hand","attributes":item.snapshot()}])
 return items.commit(result.details.change) if result.ok else result
func next_food_id() -> StringName:
 return StringName("food_%d" % int(items.snapshot().next_id))
func restore_legacy(stock: Dictionary, held: PreparedItem, next_id: int) -> ActionResult:
 var change := items.candidate()
 for id in change.state.items.keys():
  var item: Dictionary = change.state.items[id]
  if item.kind=="prepared" or item.definition_id in _aliases.values(): change.state.items.erase(id)
 change.state.next_id = maxi(int(change.state.next_id),next_id)
 var result := items.commit(change,false)
 if not result.ok: return result
 result = restock_legacy(stock)
 if not result.ok: return result
 return receive_prepared(held) if held!=null else ActionResult.success()

var player_pose: ActorPose
var spaces: SpaceService
func put_down(surface_slot_id: StringName) -> ActionResult:
 var held := held_id()
 if held.is_empty(): return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"empty_hands")
 var available := _surface_available(surface_slot_id)
 if not available.ok: return available
 var result := items.prepare_moves([{"item_id":str(held),"quantity":1,"from_container":"player_hand","to_container":str(surface_slot_id)}])
 return items.commit(result.details.change) if result.ok else result
func pick_up(surface_slot_id: StringName) -> ActionResult:
 if not held_id().is_empty(): return ActionResult.failure(ActionResult.Code.HANDS_BUSY,&"hands_busy")
 var reach := _surface_reachable(surface_slot_id)
 if not reach.ok: return reach
 var food := items.items_in(surface_slot_id)
 if food.is_empty(): return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"empty_surface")
 var result := items.prepare_moves([{"item_id":food[0].id,"quantity":1,"from_container":str(surface_slot_id),"to_container":"player_hand"}])
 return items.commit(result.details.change) if result.ok else result
func _surface_available(id: StringName) -> ActionResult:
 var reach := _surface_reachable(id)
 if not reach.ok: return reach
 var container := items.get_container(id)
 if container.get("kind")!="surface" or spaces==null: return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"missing_surface")
 var host := spaces.placement(StringName(container.host_id))
 if host.is_empty(): return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"missing_surface")
 for record in spaces.snapshot().placements.values():
  if record.host_id==container.host_id: return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"surface_busy")
 return ActionResult.success()

func _surface_reachable(id: StringName) -> ActionResult:
 var container := items.get_container(id)
 if container.get("kind")!="surface" or spaces==null or player_pose==null: return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"missing_surface")
 var host := spaces.placement(StringName(container.host_id))
 if host.is_empty() or host.location_id!=str(player_pose.location_id) or spaces.ground(StringName(container.host_id)).distance_to(player_pose.ground)>1.6: return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"missing_surface")
 return ActionResult.success()
