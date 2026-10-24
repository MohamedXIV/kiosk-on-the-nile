class_name ResidentialRecord
extends RefCounted
var id: StringName
var character_id: StringName=&"abdul_karim"
var pose := ActorPose.new()
var phase: StringName=&"arriving"
var destination := Vector2.ZERO
var greeted: bool=false
var arrived_at: float=-1
func snapshot() -> Dictionary:
 return {"greeted":greeted,"id":str(id),"character_id":str(character_id),"pose":pose.snapshot(),"phase":str(phase),"destination":[destination.x,destination.y],"arrived_at":arrived_at}
