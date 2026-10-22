class_name BuildController
extends RefCounted
signal changed
var active: bool = false
var location_id: StringName
var request: PlacementRequest
var last_result := ActionResult.success()
var _spaces: SpaceService
var _items: ItemStore
var _pose: ActorPose
func _init(spaces: SpaceService, items: ItemStore, pose: ActorPose) -> void:
 _spaces = spaces
 _items = items
 _pose = pose
func begin(location: StringName) -> ActionResult:
 if location!=_pose.location_id or not _spaces.definitions().locations.has(str(location)): return _failure("invalid_destination")
 active=true
 location_id=location
 request=null
 changed.emit()
 return ActionResult.success()
func choices() -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 for item in _items.snapshot().items.values():
  var definition := _items.definition(StringName(item.definition_id))
  var container := _items.get_container(StringName(item.container_id))
  if definition.get("movable",false) and container.location_id==str(location_id):
   var entry: Dictionary = item.duplicate(true)
   entry["label"]=definition.label
   entry["placed"]=not _spaces.placement(StringName(item.id)).is_empty()
   result.append(entry)
 result.sort_custom(func(a,b):return a.id<b.id)
 return result
func select(instance_id: StringName) -> ActionResult:
 if not active or _pose.location_id!=location_id: return _failure("invalid_destination")
 var found := false
 for item in choices():
  if item.id==str(instance_id): found=true;break
 if not found: return _failure("structure_dev_only")
 var placed := _spaces.placement(instance_id)
 request = PlacementRequest.from_dict(placed) if not placed.is_empty() else PlacementRequest.new()
 request.instance_id=instance_id
 request.location_id=location_id
 if placed.is_empty(): request.cell=Vector2i(roundi(_pose.ground.x/0.25),roundi(_pose.ground.y/0.25))
 return preview(request.cell,request.rotation,request.host_id,request.slot_id)
func preview(cell: Vector2i, rotation: int, host_id: StringName = &"", slot_id: StringName = &"") -> ActionResult:
 if not active or request==null or _pose.location_id!=location_id: return _failure("invalid_destination")
 request.cell=cell
 request.rotation=rotation
 request.host_id=host_id
 request.slot_id=slot_id
 last_result=_spaces.can_place(request)
 changed.emit()
 return last_result
func confirm() -> ActionResult:
 if not active or request==null or _pose.location_id!=location_id: return _failure("invalid_destination")
 last_result=_spaces.place(request)
 changed.emit()
 return last_result
func store_selected() -> ActionResult:
 if not active or request==null or _pose.location_id!=location_id: return _failure("invalid_destination")
 last_result=_spaces.store(request.instance_id)
 changed.emit()
 return last_result
func cancel() -> void:
 active=false
 request=null
 changed.emit()
func _failure(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,StringName(key))
func definition(id: StringName) -> Dictionary:
 return _items.definition(id)
