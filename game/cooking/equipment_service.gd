class_name EquipmentService
extends RefCounted
var external_busy: Callable
var _reservations: Dictionary={}
var _revision: int=0
var _frozen_capabilities: Dictionary={}
var _definitions: Dictionary
var _items: ItemStore
var _spaces: SpaceService
func configure(definitions: Dictionary, items: ItemStore, spaces: SpaceService) -> ActionResult:
 for id in definitions:
  var value: Variant=definitions[id]
  if not value is Dictionary or not value.get("capabilities") is Array or not value.get("resource_group") is String or not ContentValidation.integer(value.get("capacity")) or value.capacity<1:return ContentValidation.fail("equipment."+id)
 _definitions=definitions.duplicate(true)
 _items=items
 _spaces=spaces
 return ActionResult.success()
func is_usable(id: StringName, location_id: StringName, capability: StringName, job_id: StringName = &"") -> bool:
 var item := _items.get_item(id)
 var placement := _spaces.placement(id)
 if item.is_empty() or placement.is_empty() or placement.location_id!=str(location_id):return false
 if capability==&"prep_surface":
  for p in _spaces.snapshot().placements.values():
   if p.host_id==str(id):return false
  if not _items.items_in(StringName(str(id)+":top")).is_empty():return false
 var definition: Dictionary=_definitions.get(item.definition_id,{})
 return not definition.is_empty() and item.attributes.get("enabled",definition.get("enabled_by_default",true)) and (str(capability) in definition.capabilities or (str(capability) in definition.get("retired_capabilities",[]) and str(capability) in _frozen_capabilities.get(str(job_id),{}).get(str(id),[])))
func set_enabled(id: StringName, enabled: bool) -> ActionResult:
 var item := _items.get_item(id)
 if item.is_empty() or not _definitions.has(item.definition_id) or _spaces.placement(id).is_empty():return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"item_not_placed")
 if is_busy(id):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"equipment_busy")
 var change := _items.candidate()
 change.state.items[str(id)].attributes["enabled"]=enabled
 return _items.commit(change)
func enabled(id: StringName) -> bool:
 var item := _items.get_item(id)
 if item.is_empty() or not _definitions.has(item.definition_id):return false
 return item.attributes.get("enabled",_definitions[item.definition_id].get("enabled_by_default",true))
func candidates(location_id: StringName, capability: StringName) -> PackedStringArray:
 var result := PackedStringArray()
 for id in _spaces.snapshot().placements:
  if is_usable(StringName(id),location_id,capability):result.append(id)
 result.sort()
 return result
func reserve(job_id: StringName, instance_id: StringName, requirements: Dictionary) -> ActionResult:
 var result := prepare_reservations(job_id,[{"instance_id":str(instance_id),"capability":str(requirements.get("capability","")),"units":requirements.get("units",1)}])
 return commit_reservations(result.details.state) if result.ok else result
func prepare_reservations(job_id: StringName, requirements: Array[Dictionary], replace_existing: bool = false) -> ActionResult:
 var candidate := _reservations.duplicate(true)
 if replace_existing:candidate.erase(str(job_id))
 var lines: Array=candidate.get(str(job_id),[])
 for requirement in requirements:
  var id := StringName(str(requirement.get("instance_id","")))
  var placement := _spaces.placement(id)
  if placement.is_empty() or not ContentValidation.integer(requirement.get("units",1)) or requirement.get("units",1)<1:return _fail("equipment_unavailable")
  var capability := StringName(str(requirement.get("capability","")))
  if not is_usable(id,StringName(placement.location_id),capability,job_id) or (external_busy.is_valid() and external_busy.call(id)):return _fail("equipment_busy")
  var item := _items.get_item(id)
  var definition: Dictionary=_definitions[item.definition_id]
  var group := str(definition.resource_group)
  var units := int(requirement.get("units",1))
  var used := 0
  for job_lines in candidate.values():
   for line in job_lines:
    if line.instance_id==str(id) and line.resource_group==group:used+=int(line.units)
  if used+units>int(definition.capacity):return _fail("equipment_busy")
  lines.append({"instance_id":str(id),"resource_group":group,"capability":str(capability),"units":units})
  candidate[str(job_id)]=lines
 return ActionResult.success({"state":{"reservations":candidate,"revision":_revision}})
func can_commit_reservations(state: Dictionary) -> bool:
 return state.get("revision")==_revision and state.get("reservations") is Dictionary
func commit_reservations(state: Dictionary) -> ActionResult:
 if state.get("revision")!=_revision or not state.get("reservations") is Dictionary:return _fail("stale_equipment_change")
 _reservations=state.reservations.duplicate(true)
 _revision+=1
 return ActionResult.success()
func release(job_id: StringName) -> ActionResult:
 _reservations.erase(str(job_id))
 _revision+=1
 return ActionResult.success()
func is_busy(instance_id: StringName) -> bool:
 for lines in _reservations.values():
  for line in lines:
   if line.instance_id==str(instance_id):return true
 return false
func snapshot() -> Dictionary:
 return {"reservations":_reservations.duplicate(true),"revision":_revision}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("reservations") is Dictionary or not ContentValidation.integer(data.get("revision")) or data.revision<0:return _fail("invalid_equipment")
 var occupied: Dictionary={}
 for job_id in data.reservations:
  if not data.reservations[job_id] is Array:return _fail("invalid_equipment")
  for line in data.reservations[job_id]:
   if not line is Dictionary or not line.get("instance_id") is String or not line.get("capability") is String or not ContentValidation.integer(line.get("units")) or line.units<1:return _fail("invalid_equipment")
   var id := StringName(line.instance_id)
   var item := _items.get_item(id)
   var placement := _spaces.placement(id)
   if item.is_empty() or placement.is_empty() or not _definitions.has(item.definition_id) or not is_usable(id,StringName(placement.location_id),StringName(line.capability),StringName(job_id)):return _fail("orphan_equipment")
   var definition: Dictionary=_definitions[item.definition_id]
   if line.get("resource_group")!=definition.resource_group:return _fail("invalid_resource_group")
   var key := str(id)+":"+str(line.resource_group)
   occupied[key]=int(occupied.get(key,0))+int(line.units)
   if occupied[key]>int(definition.capacity):return _fail("equipment_over_capacity")
 _reservations=data.reservations.duplicate(true)
 _revision=int(data.revision)
 return ActionResult.success()
func _fail(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,StringName(key))

func restore_frozen_contracts(jobs: Dictionary) -> void:
 # Only pre-location-policy jobs may finish with a retired capability.
 # This grant is job-scoped, derived from its frozen definition, never a new-start candidate.
 _frozen_capabilities.clear()
 for id in jobs:
  var job: Variant=jobs[id]
  if not job is Dictionary or job.get("status")!="active" or not job.get("definition") is Dictionary or job.definition.has("allowed_locations") or not job.definition.get("steps") is Array or not job.get("devices") is Dictionary:continue
  var validation := CookingWorkflowValidation.validate_recipes({str(job.get("recipe_id","")):job.definition},_items)
  if not validation.ok:continue
  var grants: Dictionary={}
  for step in job.definition.steps:
   var device := str(job.devices.get(step.capability,""))
   if not grants.has(device):grants[device]=[]
   grants[device].append(step.capability)
  _frozen_capabilities[str(id)]=grants
