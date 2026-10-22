class_name ItemStore
extends RefCounted
signal changed(revision: int)
var _definitions: Dictionary = {}
var _state: Dictionary = {"items":{},"containers":{},"reservations":{},"next_id":1}
var revision: int = 0
func configure(definitions: Dictionary, containers: Dictionary) -> ActionResult:
 var result := ItemContentValidation.validate(definitions,containers)
 if not result.ok: return result
 _definitions = definitions.duplicate(true)
 _state = {"items":{},"containers":containers.duplicate(true),"reservations":{},"next_id":1}
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
func snapshot() -> Dictionary:
 return _state.duplicate(true)
func candidate() -> ItemChangeSet:
 return ItemChangeSet.new(revision,_state)
func prepare_moves(moves: Array[Dictionary]) -> ActionResult:
 var change := candidate()
 for move in moves:
  var id := str(move.get("item_id",""))
  if not change.state.items.has(id): return _fail("missing_item")
  var item: Dictionary = change.state.items[id]
  if item.container_id!=str(move.get("from_container","")) or not ContentValidation.integer(move.get("quantity")) or int(move.quantity)!=int(item.quantity): return _fail("invalid_item_move")
  item.container_id = str(move.get("to_container",""))
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
 return _validate_state(change.state)
func commit(change: ItemChangeSet, notify: bool = true) -> ActionResult:
 if change==null or change.revision!=revision: return _fail("stale_item_change")
 var result := _validate_state(change.state)
 if not result.ok: return result
 _state = change.state.duplicate(true)
 revision += 1
 if notify: changed.emit(revision)
 return ActionResult.success()
func restore(data: Dictionary) -> ActionResult:
 var result := _validate_state(data)
 if not result.ok: return result
 _state = data.duplicate(true)
 revision += 1
 return ActionResult.success()
func _prepared(change: ItemChangeSet) -> ActionResult:
 var result := _validate_state(change.state)
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
  var definition: Dictionary = _definitions[item.definition_id]
  if item.get("kind")!=definition.kind or (definition.kind!="ingredient" and int(item.quantity)!=1) or not data.containers.has(str(item.get("container_id",""))): return _fail("invalid_item_owner")
  var container: Dictionary = data.containers[item.container_id]
  if not str(item.kind) in container.allowed_tags: return _fail("incompatible_container")
  used[item.container_id] = int(used.get(item.container_id,0))+int(item.quantity)
  if int(used[item.container_id])>int(container.capacity): return _fail("container_full")
 var reserved: Dictionary = {}
 for job_id in data.reservations:
  if not data.reservations[job_id] is Array: return _fail("invalid_reservation")
  for line in data.reservations[job_id]:
   if not line is Dictionary or not data.items.has(str(line.get("item_id",""))) or not ContentValidation.integer(line.get("quantity")) or line.quantity<1: return _fail("invalid_reservation")
   var id := str(line.item_id)
   reserved[id] = int(reserved.get(id,0))+int(line.quantity)
   if reserved[id]>data.items[id].quantity: return _fail("over_reserved_item")
 return ActionResult.success()
func _fail(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,StringName(key))
