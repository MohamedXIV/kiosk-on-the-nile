@tool
class_name PlacementRequest
extends RefCounted
var instance_id: StringName
var location_id: StringName
var cell := Vector2i.ZERO
var rotation: int = 0
var host_id: StringName
var slot_id: StringName
func snapshot() -> Dictionary:
 return {"instance_id":str(instance_id),"location_id":str(location_id),"cell":[cell.x,cell.y],"rotation":rotation,"host_id":str(host_id),"slot_id":str(slot_id)}
static func from_dict(data: Dictionary) -> PlacementRequest:
 var value := PlacementRequest.new()
 value.instance_id = StringName(data.get("instance_id",""))
 value.location_id = StringName(data.get("location_id",""))
 var point: Array = data.get("cell",[0,0])
 value.cell = Vector2i(int(point[0]),int(point[1]))
 value.rotation = int(data.get("rotation",0))
 value.host_id = StringName(data.get("host_id",""))
 value.slot_id = StringName(data.get("slot_id",""))
 return value
