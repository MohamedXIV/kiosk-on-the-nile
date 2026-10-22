class_name JourneyState
extends RefCounted
var data: Dictionary={}
func snapshot() -> Dictionary:
 return data.duplicate(true)
