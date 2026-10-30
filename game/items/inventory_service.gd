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
 for item in material_instances(StringName(definition_id)):
  var container := items.get_container(StringName(item.container_id))
  if container.get("location_id")==str(location_id) and container.get("kind") in ["dry","cold"]: total += int(item.quantity)
 for lines in items.snapshot().reservations.values():
  for line in lines:
   var item := items.get_item(StringName(line.item_id))
   var container := items.get_container(StringName(item.container_id))
   if _matches(str(item.definition_id),definition_id) and container.location_id==str(location_id):total-=int(line.quantity)
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
 for item in material_instances(StringName(definition_id)):
  var container := items.get_container(StringName(item.container_id))
  if container.location_id!="kiosk" or not container.kind in ["dry","cold"]: continue
  var taken := mini(remaining,int(item.quantity))
  change.state.items[item.id].quantity -= taken
  remaining -= taken
  if change.state.items[item.id].quantity==0: change.state.items.erase(item.id)
  if remaining==0: break
 if remaining!=0 or quantity<0: return ActionResult.failure(ActionResult.Code.OUT_OF_STOCK,&"out_of_stock")
 return items.commit(change)
func restock_legacy(stock: Dictionary, source: String="grant") -> ActionResult:
 var grants: Array[Dictionary] = []
 for id in stock:
  if not ContentValidation.integer(stock[id]) or stock[id]<0: return ContentValidation.fail("stock")
  if stock[id]>0: grants.append({"definition_id":str(_aliases.get(id,id)),"quantity":int(stock[id]),"container_id":"kiosk_dry","attributes":{"acquisition":{"source_kind":source,"cost_known":source=="starter"}}})
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
 if equipment!=null and equipment.is_busy(StringName(container.host_id)):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"equipment_busy")
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

var equipment: EquipmentService
func available(location_id: StringName, requirements: Array[Dictionary]) -> ActionResult:
 var remaining: Dictionary={}
 var sources: Array[Dictionary]=[]
 var state := items.snapshot()
 var reserved: Dictionary={}
 for lines in state.reservations.values():
  for line in lines:reserved[line.item_id]=int(reserved.get(line.item_id,0))+int(line.quantity)
 for requirement in requirements:
  var definition_id := str(requirement.get("definition_id",""))
  if not ContentValidation.integer(requirement.get("quantity")) or requirement.quantity<1 or items.definition(StringName(definition_id)).is_empty():return ContentValidation.fail("inventory.requirement")
  var needed := int(requirement.quantity)
  for item in material_instances(StringName(definition_id)):
   if requirement.has("item_id") and requirement.item_id!=item.id:continue
   var container := items.get_container(StringName(item.container_id))
   if not _usable_storage(container,location_id,str(requirement.get("required_storage",items.definition(StringName(definition_id)).get("required_storage","dry")))):continue
   var used := int(reserved.get(item.id,0))+int(remaining.get(item.id,0))
   var quantity := mini(needed,maxi(0,int(item.quantity)-used))
   if quantity<=0:continue
   sources.append({"item_id":item.id,"definition_id":item.definition_id,"requirement_id":definition_id,"quantity":quantity})
   remaining[item.id]=int(remaining.get(item.id,0))+quantity
   needed-=quantity
   if needed==0:break
  if needed>0:return ActionResult.failure(ActionResult.Code.OUT_OF_STOCK,&"out_of_stock",{"definition_id":definition_id,"missing":needed,"location_id":str(location_id)})
 return ActionResult.success({"sources":sources})
func reserve(job_id: StringName, location_id: StringName, requirements: Array[Dictionary]) -> ActionResult:
 if items.snapshot().reservations.has(str(job_id)):return ContentValidation.fail("inventory.duplicate_reservation")
 var result := available(location_id,requirements)
 if not result.ok:return result
 var change := items.candidate()
 change.state.reservations[str(job_id)]=result.details.sources
 return items.commit(change)
func consume_reservation(job_id: StringName, amounts: Array[Dictionary]) -> ActionResult:
 var change := items.candidate()
 if not change.state.reservations.has(str(job_id)):return ContentValidation.fail("inventory.missing_reservation")
 var lines: Array=change.state.reservations[str(job_id)]
 for amount in amounts:
  if not ContentValidation.integer(amount.get("quantity")) or amount.quantity<1:return ContentValidation.fail("inventory.consume")
  var needed := int(amount.quantity)
  for line in lines:
   if str(line.get("requirement_id",line.definition_id))!=str(amount.get("definition_id","")):continue
   var taken := mini(needed,int(line.quantity))
   line.quantity-=taken
   change.state.items[line.item_id].quantity-=taken
   if change.state.items[line.item_id].quantity==0:change.state.items.erase(line.item_id)
   needed-=taken
   if needed==0:break
  if needed>0:return ContentValidation.fail("inventory.consume_over_reservation")
 var remaining: Array=[]
 for line in lines:
  if line.quantity>0:remaining.append(line)
 change.state.reservations[str(job_id)]=remaining
 return items.commit(change)
func release_reservation(job_id: StringName) -> ActionResult:
 var change := items.candidate()
 change.state.reservations.erase(str(job_id))
 return items.commit(change)
func unpack_purchase_bag(bag_id: StringName, location_id: StringName) -> ActionResult:
 if player_pose==null or player_pose.location_id!=location_id:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"invalid_destination")
 var bag := items.get_container(bag_id)
 if bag.get("kind")!="purchase_bag":return ContentValidation.fail("inventory.not_bag")
 var change := items.candidate()
 var moved: Array=[]
 var remaining: Array=[]
 var containers: Array=change.state.containers.keys()
 containers.sort()
 for item in items.items_in(bag_id):
  var quantity := int(item.quantity)
  if item.kind in ["furniture","equipment"]:
   var destination := str(location_id)+"_furniture"
   if not change.state.containers.has(destination):return ContentValidation.fail("inventory.furniture_storage")
   change.state.items[item.id].container_id=destination
   for hosted in change.state.containers.values():
    if hosted.host_id==item.id:hosted.location_id=str(location_id)
   moved.append({"definition_id":item.definition_id,"quantity":1})
   continue
  var storage := str(items.definition(StringName(item.definition_id)).get("required_storage","dry"))
  for id in containers:
   var container: Dictionary=change.state.containers[id]
   if not _usable_storage(container,location_id,storage):continue
   var used := 0
   for owned in change.state.items.values():
    if owned.container_id==id:used+=int(owned.quantity)
   var fitted := mini(quantity,maxi(0,int(container.capacity)-used))
   if fitted==0:continue
   if fitted==quantity and quantity==int(item.quantity):change.state.items[item.id].container_id=id
   else:
    var copy: Dictionary=item.duplicate(true)
    if copy.attributes.has("supply_occurrence") and not copy.attributes.has("supply_grant_id"):copy.attributes["supply_grant_id"]=str(item.id)
    var new_id := "item_%d" % int(change.state.next_id)
    change.state.next_id=int(change.state.next_id)+1
    copy.id=new_id
    copy.quantity=fitted
    copy.container_id=id
    change.state.items[new_id]=copy
    change.state.items[item.id].quantity-=fitted
    if change.state.items[item.id].quantity==0:change.state.items.erase(item.id)
   quantity-=fitted
   moved.append({"definition_id":item.definition_id,"quantity":fitted})
   if quantity==0:break
  if quantity>0:remaining.append({"definition_id":item.definition_id,"quantity":quantity})
 var result := items.commit(change)
 return ActionResult.success({"moved":moved,"remaining":remaining}) if result.ok else result
func pack(item_id: StringName) -> ActionResult:
 var item := items.get_item(item_id)
 if item.is_empty() or player_pose==null:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"missing_item")
 var container := items.get_container(StringName(item.container_id))
 if container.location_id!=str(player_pose.location_id) or not container.kind in ["dry","cold","storage"]:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"item_wrong_location")
 for lines in items.snapshot().reservations.values():
  for line in lines:
   if line.item_id==str(item_id):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"ingredient_reserved")
 if item.kind in ["furniture","equipment"]:
  if spaces==null or not spaces.placement(item_id).is_empty() or (equipment!=null and equipment.is_busy(item_id)):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"equipment_busy")
  var change := items.candidate()
  for hosted in change.state.containers.values():
   if hosted.host_id==str(item_id) and not items.items_in(StringName(hosted.id)).is_empty():return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"surface_not_empty")
  if not change.state.containers.has("player_furniture_bag"):
   change.state.containers["player_furniture_bag"]={"id":"player_furniture_bag","location_id":"player","kind":"purchase_bag","capacity":1,"allowed_tags":["furniture","equipment"],"host_id":""}
  change.state.items[str(item_id)].container_id="player_furniture_bag"
  return items.commit(change)
 var result := items.prepare_moves([{"item_id":str(item_id),"quantity":int(item.quantity),"from_container":item.container_id,"to_container":"player_bag"}])
 return items.commit(result.details.change) if result.ok else result
func _usable_storage(container: Dictionary, location_id: StringName, storage: String) -> bool:
 if storage=="hand":return container.get("id")=="player_hand" and player_pose!=null and player_pose.location_id==location_id
 if container.get("location_id")!=str(location_id) or container.get("kind")!=storage:return false
 if storage=="cold":return equipment!=null and equipment.is_usable(StringName(container.host_id),location_id,&"cold_storage")
 return storage=="dry"

func store_held(container_id: StringName) -> ActionResult:
 var id := held_id()
 var item := items.get_item(id)
 var container := items.get_container(container_id)
 if item.get("kind")!="batch" or player_pose==null or not _usable_storage(container,player_pose.location_id,"cold") or spaces.ground(StringName(container.host_id)).distance_to(player_pose.ground)>1.6:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"storage_out_of_reach")
 var result := items.prepare_moves([{"item_id":str(id),"quantity":1,"from_container":"player_hand","to_container":str(container_id)}])
 return items.commit(result.details.change) if result.ok else result
func pick_up_storage(item_id: StringName) -> ActionResult:
 if not held_id().is_empty():return ActionResult.failure(ActionResult.Code.HANDS_BUSY,&"hands_busy")
 var item := items.get_item(item_id)
 if item.get("kind")!="batch" or player_pose==null:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"missing_item")
 var container := items.get_container(StringName(item.container_id))
 if not _usable_storage(container,player_pose.location_id,"cold") or spaces.ground(StringName(container.host_id)).distance_to(player_pose.ground)>1.6:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"storage_out_of_reach")
 var result := items.prepare_moves([{"item_id":str(item_id),"quantity":1,"from_container":item.container_id,"to_container":"player_hand"}])
 return items.commit(result.details.change) if result.ok else result

func consume_for_player(expected_id: StringName, at: float) -> ActionResult:
 if expected_id.is_empty() or held_id()!=expected_id:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"empty_hands")
 var change := items.candidate()
 var item: Dictionary=change.state.items[str(expected_id)]
 if item.kind!="prepared":return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"unknown_food")
 change.state.consumed[str(expected_id)]={"item":item.duplicate(true),"at":at}
 change.state.items.erase(str(expected_id))
 return items.commit(change,false)

func _matches(actual: String, required: String) -> bool:
 return items.ingredient_matches(actual,required)
func material_instances(required: StringName) -> Array[Dictionary]:
 return items.material_instances(required)
