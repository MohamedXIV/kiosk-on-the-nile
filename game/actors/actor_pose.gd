class_name ActorPose
extends RefCounted
var location_id: StringName = &"rooftop"
var ground := Vector2.ZERO
var facing := Vector2.DOWN
var walk_phase: float = 0.0
func snapshot() -> Dictionary:
 return {"location_id":str(location_id),"ground":[ground.x,ground.y],"facing":[facing.x,facing.y],"walk_phase":walk_phase}
func restore(data: Dictionary) -> ActionResult:
 for key in ["ground","facing"]:
  if not data.get(key) is Array or data[key].size()!=2: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_pose")
  for value in data[key]:
   if not ContentValidation.number(value): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_pose")
 if not data.get("location_id") is String or not ContentValidation.number(data.get("walk_phase")): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_pose")
 location_id = StringName(data.location_id)
 ground = Vector2(data.ground[0],data.ground[1])
 facing = Vector2(data.facing[0],data.facing[1])
 walk_phase = float(data.walk_phase)
 return ActionResult.success()
