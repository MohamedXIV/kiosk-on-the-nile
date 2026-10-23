class_name BuildController
extends RefCounted
signal changed
var policy: ActionPolicy
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
func instance_at(point: Vector2, height_ratio: float = 0.0) -> StringName:
 var selected := &""
 var height := -1.0
 var space: Dictionary=_spaces.definitions().locations[str(location_id)]
 for record in _spaces.snapshot().placements.values():
  if record.location_id!=str(location_id):continue
  var item := _items.get_item(StringName(record.instance_id))
  var definition := _items.definition(StringName(item.definition_id))
  var box := GridPlacementRules.footprint(record,definition,space)
  var mount_height := 0.0
  if record.host_id!="":mount_height=float(_items.definition(StringName(_items.get_item(StringName(record.host_id)).definition_id)).get("height",0.96))
  var item_height := float(definition.get("height",0))
  var visual_box := Rect2(box.position-Vector2(0,(mount_height+item_height)*height_ratio),box.size+Vector2(0,item_height*height_ratio))
  if not definition.get("movable",false) or not visual_box.has_point(point):continue
  var rank := float(definition.get("height",0))+ (10.0 if record.host_id!="" else 0.0)
  if rank>height:selected=StringName(record.instance_id);height=rank
 return selected
func select_at(ground: Vector2) -> ActionResult:
 var id := instance_at(ground)
 if id.is_empty():return _failure("arrange_select_piece")
 return select(id)
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
 var valid := _spaces.can_place(request)
 if not valid.ok:return valid
 if policy!=null:
  var permitted := policy.attempt(&"ordinary_effort",policy.opportunity(&"ordinary_effort","build:"+str(_spaces.revision)))
  if not permitted.ok:return permitted
 last_result=_spaces.place(request)
 if last_result.ok and policy!=null:policy.record_effort("build:%d:%d" % [_spaces.revision,_items.revision],&"arranging")
 changed.emit()
 return last_result
func store_selected() -> ActionResult:
 if not active or request==null or _pose.location_id!=location_id: return _failure("invalid_destination")
 if policy!=null:
  var permitted := policy.attempt(&"ordinary_effort",policy.opportunity(&"ordinary_effort","store:"+str(_spaces.revision)))
  if not permitted.ok:return permitted
 last_result=_spaces.store(request.instance_id)
 if last_result.ok and policy!=null:policy.record_effort("store:%d:%d" % [_spaces.revision,_items.revision],&"arranging")
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

func host_placement(id: StringName) -> Dictionary:
 return _spaces.placement(id)
