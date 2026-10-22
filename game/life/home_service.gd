class_name HomeService
extends RefCounted
var _items: ItemStore
var has_fan: bool:
 get: return not _items.instances(&"fan").is_empty()
var fan_on: bool:
 get:
  for fan in _items.instances(&"fan"):
   var container := _items.get_container(StringName(fan.container_id))
   if container.location_id=="rooftop" and container.kind=="placed" and fan.attributes.get("enabled",false): return true
  return false
func _init(items: ItemStore) -> void:
 _items = items
func toggle_fan() -> ActionResult:
 for fan in _items.instances(&"fan"):
  var container := _items.get_container(StringName(fan.container_id))
  if container.location_id!="rooftop" or container.kind!="placed": continue
  var change := _items.candidate()
  change.state.items[fan.id].attributes.enabled = not fan.attributes.get("enabled",false)
  var result := _items.commit(change)
  return ActionResult.success({"fan_on":fan_on}) if result.ok else result
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"no_fan")
func install_fan(container_id: StringName = &"rooftop_furniture", enabled: bool = false) -> ActionResult:
 if has_fan: return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"already_owned")
 var result := _items.prepare_grants([{"definition_id":"fan","quantity":1,"container_id":str(container_id),"attributes":{"enabled":enabled}}])
 return _items.commit(result.details.change) if result.ok else result
func snapshot() -> Dictionary:
 return {"has_fan":has_fan,"fan_on":fan_on}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("has_fan") is bool or not data.get("fan_on") is bool or (data.fan_on and not data.has_fan): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_home")
 # Compatibility projection for schemas 1–3; schema 4 restores ItemStore first.
 if data.has_fan and not has_fan: return install_fan(&"rooftop_world",data.fan_on)
 if data.has_fan!=has_fan or data.fan_on!=fan_on: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"inconsistent_home")
 return ActionResult.success()
