class_name EquipmentService
extends RefCounted
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
func is_usable(id: StringName, location_id: StringName, capability: StringName) -> bool:
 var item := _items.get_item(id)
 var placement := _spaces.placement(id)
 if item.is_empty() or placement.is_empty() or placement.location_id!=str(location_id):return false
 var definition: Dictionary=_definitions.get(item.definition_id,{})
 return not definition.is_empty() and item.attributes.get("enabled",definition.get("enabled_by_default",true)) and str(capability) in definition.capabilities
func set_enabled(id: StringName, enabled: bool) -> ActionResult:
 var item := _items.get_item(id)
 if item.is_empty() or not _definitions.has(item.definition_id) or _spaces.placement(id).is_empty():return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"item_not_placed")
 var change := _items.candidate()
 change.state.items[str(id)].attributes["enabled"]=enabled
 return _items.commit(change)
func enabled(id: StringName) -> bool:
 var item := _items.get_item(id)
 if item.is_empty() or not _definitions.has(item.definition_id):return false
 return item.attributes.get("enabled",_definitions[item.definition_id].get("enabled_by_default",true))
func snapshot() -> Dictionary:
 return {}
func restore(data: Dictionary) -> ActionResult:
 return ActionResult.success() if data.is_empty() else ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_equipment")
