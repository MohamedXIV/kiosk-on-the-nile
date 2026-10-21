class_name HomeService
extends RefCounted
var has_fan: bool = false
var fan_on: bool = false
func toggle_fan() -> ActionResult:
 if not has_fan: return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"no_fan")
 fan_on = not fan_on
 return ActionResult.success({"fan_on":fan_on})
func install_fan() -> ActionResult:
 if has_fan: return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"already_owned")
 has_fan = true
 fan_on = true
 return ActionResult.success()
func snapshot() -> Dictionary:
 return {"has_fan":has_fan,"fan_on":fan_on}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("has_fan") is bool or not data.get("fan_on") is bool or (data.fan_on and not data.has_fan):
  return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_home")
 has_fan = data.has_fan
 fan_on = data.fan_on
 return ActionResult.success()
