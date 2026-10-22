class_name CleaningAction
extends RefCounted
var target_id: StringName
var location_id: StringName
var anchor := Vector2.ZERO
var active: bool=false
var progress: Dictionary
var required_minutes: float:
 get:return float(progress.get("required_minutes",0))
var completed_minutes: float:
 get:return float(progress.get("completed_minutes",0))
func snapshot() -> Dictionary:
 return {"target_id":str(target_id),"location_id":str(location_id),"anchor":[anchor.x,anchor.y],"active":active}
