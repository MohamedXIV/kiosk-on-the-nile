class_name ResidentialRecord
extends RefCounted
var id: StringName
var character_id: StringName=&"abdul_karim"
var pose := ActorPose.new()
var phase: StringName=&"arriving"
var destination := Vector2.ZERO
var greeted: bool=false
var depart_requested: bool=false
var arrived_at: float=-1
var semantic_source: String=""
func snapshot() -> Dictionary:
 var result: Dictionary={"greeted":greeted,"depart_requested":depart_requested,"id":str(id),"character_id":str(character_id),"pose":pose.snapshot(),"phase":str(phase),"destination":[destination.x,destination.y],"arrived_at":arrived_at}
 if not semantic_source.is_empty():result["semantic_source"]=semantic_source
 return result
