class_name SpaceService
extends RefCounted
signal changed(location_id: StringName, revision: int)
var revision: int = 0
var _definitions: Dictionary
var _layout: Dictionary
var _items: ItemStore
var _actors: Callable
var _busy: Callable
var _adapter: Callable
func configure(definitions: Dictionary, layout: Dictionary, items: ItemStore, actors: Callable, busy_provider: Callable) -> ActionResult:
 _definitions = definitions.duplicate(true)
 _layout = layout.duplicate(true)
 _items = items
 _actors = actors
 _busy = busy_provider
 return _validate_layout(_layout)
func set_adapter(adapter: Callable) -> void:
 _adapter = adapter
func definitions() -> Dictionary:
 return _definitions.duplicate(true)
func placement(id: StringName) -> Dictionary:
 return _layout.placements.get(str(id),{}).duplicate(true)
func snapshot() -> Dictionary:
 return _layout.duplicate(true)
func restore(data: Dictionary) -> ActionResult:
 var result := _validate_layout(data)
 if not result.ok: return result
 _layout = data.duplicate(true)
 revision += 1
 return ActionResult.success()
func can_place(request: PlacementRequest) -> ActionResult:
 if request==null: return _fail("invalid_placement")
 var item := _items.get_item(request.instance_id)
 if item.is_empty(): return _fail("structure_dev_only")
 var source := _items.get_container(StringName(item.container_id))
 if source.location_id!=str(request.location_id): return _fail("item_wrong_location")
 if _busy.is_valid() and _busy.call(request.instance_id): return _fail("equipment_busy")
 for id in _layout.placements:
  if _layout.placements[id].host_id==str(request.instance_id) and _busy.is_valid() and _busy.call(StringName(id)): return _fail("equipment_busy")
 for container in _items.snapshot().containers.values():
  if container.host_id==str(request.instance_id) and not _items.items_in(StringName(container.id)).is_empty(): return _fail("surface_not_empty")
 var current := _layout.duplicate(true)
 current["instances"] = _items.snapshot().items
 var catalog := {"items":_items_definitions(),"spaces":_definitions.locations,"base_solids":_definitions.base_solids}
 var actors: Array[Dictionary] = []
 if _actors.is_valid(): actors.assign(_actors.call())
 return GridPlacementRules.validate(current,request,catalog,actors)
func place(request: PlacementRequest) -> ActionResult:
 # Called synchronously from input/before the next physics motion step.
 var result := can_place(request)
 if not result.ok: return result
 var candidate := _layout.duplicate(true)
 candidate.placements = result.details.placements
 var change := _items.candidate()
 for id in candidate.placements:
  if candidate.placements[id].location_id!=str(request.location_id): continue
  change.state.items[id].container_id = str(request.location_id)+"_world"
 # No observers run while both source state and colliders are replaced.
 var committed := _items.commit(change,false)
 if not committed.ok: return committed
 _layout = candidate
 revision += 1
 if _adapter.is_valid(): _adapter.call(request.location_id)
 _items.changed.emit(_items.revision)
 changed.emit(request.location_id,revision)
 return ActionResult.success()
func store(instance_id: StringName) -> ActionResult:
 var record := placement(instance_id)
 if record.is_empty(): return _fail("item_not_placed")
 if _busy.is_valid() and _busy.call(instance_id): return _fail("equipment_busy")
 for child in _layout.placements.values():
  if child.host_id==str(instance_id): return _fail("surface_not_empty")
 for container in _items.snapshot().containers.values():
  if container.host_id==str(instance_id) and not _items.items_in(StringName(container.id)).is_empty(): return _fail("surface_not_empty")
 var item := _items.get_item(instance_id)
 var candidate := _items.prepare_moves([{"item_id":str(instance_id),"quantity":1,"from_container":item.container_id,"to_container":record.location_id+"_furniture"}])
 if not candidate.ok: return candidate
 var result := _items.commit(candidate.details.change,false)
 if not result.ok: return result
 _layout.placements.erase(str(instance_id))
 revision += 1
 if _adapter.is_valid(): _adapter.call(StringName(record.location_id))
 _items.changed.emit(_items.revision)
 changed.emit(StringName(record.location_id),revision)
 return ActionResult.success()
func set_door_open(door_id: StringName, opened: bool) -> ActionResult:
 for location_id in _definitions.locations:
  var space: Dictionary = _definitions.locations[location_id]
  for door in space.doors:
   if door.id!=str(door_id): continue
   if not door.get("usable",true): return _fail("door_locked")
   if not opened:
    var solids := GridPlacementRules.structure_solids(space,{str(door_id):false})
    if _actors.is_valid():
     for actor in _actors.call():
      if actor.location_id==location_id and FootprintGeometry.blocked(Vector2(actor.ground[0],actor.ground[1]),solids,0.18): return _fail("person_in_the_way")
   _layout.door_states[str(door_id)] = opened
   revision += 1
   if _adapter.is_valid(): _adapter.call(StringName(location_id))
   changed.emit(StringName(location_id),revision)
   return ActionResult.success()
 return _fail("unknown_door")
func solids(location_id: StringName, potential: bool = false) -> Array:
 var space: Dictionary = _definitions.locations.get(str(location_id),{})
 if space.is_empty(): return []
 var result: Array = _definitions.base_solids.get(str(location_id),[]).duplicate(true)
 result.append_array(GridPlacementRules.structure_solids(space,_layout.door_states,potential))
 for id in _layout.placements:
  var record: Dictionary = _layout.placements[id]
  if record.location_id!=str(location_id) or record.host_id!="": continue
  result.append(GridPlacementRules.solid(GridPlacementRules.footprint(record,_items.definition(StringName(_items.get_item(StringName(id)).definition_id)),space),id))
 return result
func ground(id: StringName) -> Vector2:
 var record := placement(id)
 if record.is_empty(): return Vector2.ZERO
 return GridPlacementRules.footprint(record,_items.definition(StringName(_items.get_item(id).definition_id)),_definitions.locations[record.location_id]).get_center()
func _items_definitions() -> Dictionary:
 var result: Dictionary = {}
 for item in _items.snapshot().items.values(): result[item.definition_id]=_items.definition(StringName(item.definition_id))
 return result
func _validate_layout(data: Dictionary) -> ActionResult:
 if not data.get("placements") is Dictionary or not data.get("door_states") is Dictionary: return _fail("invalid_layout")
 var known_doors: Array = []
 for space in _definitions.locations.values():
  for door in space.doors: known_doors.append(door.id)
 for id in data.door_states:
  if not id in known_doors or not data.door_states[id] is bool: return _fail("invalid_door")
 for id in data.placements:
  var p: Variant = data.placements[id]
  if not p is Dictionary or p.get("instance_id")!=id or not _definitions.locations.has(str(p.get("location_id",""))) or not p.get("cell") is Array or p.cell.size()!=2 or not ContentValidation.integer(p.cell[0]) or not ContentValidation.integer(p.cell[1]) or not ContentValidation.integer(p.get("rotation")) or p.rotation<0 or p.rotation>3 or not p.get("host_id") is String or not p.get("slot_id") is String: return _fail("invalid_placement")
  var item := _items.get_item(StringName(id))
  if item.is_empty() or item.container_id!=p.location_id+"_world": return _fail("invalid_placement_owner")
  var result := GridPlacementRules.validate({"placements":data.placements,"door_states":data.door_states,"instances":_items.snapshot().items},PlacementRequest.from_dict(p),{"items":_items_definitions(),"spaces":_definitions.locations,"base_solids":_definitions.base_solids},[])
  if not result.ok: return result
 return ActionResult.success()
func _fail(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,StringName(key))
