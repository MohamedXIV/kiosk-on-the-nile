class_name VisitState
extends RefCounted
var id: StringName
var character_id: StringName
var pose := ActorPose.new()
var destination := Vector2.ZERO
var phase: StringName = &"arriving"
var elapsed: float = 0
var food_id: StringName
var stay_seconds: float = 0
var maximum_wait: float = 160
var served: bool = false
var needs_hospitality: bool=false
var remark_remaining: float = 0
var order_id: StringName
var shopping_state: StringName = &"undecided"
var decision_remaining: float = 0
var recall_variant: int = -1
var arrival_counted: bool = false
func snapshot() -> Dictionary:
 return {"needs_hospitality":needs_hospitality,"maximum_wait":maximum_wait,"arrival_counted":arrival_counted,"recall_variant":recall_variant,"shopping_state":str(shopping_state),"decision_remaining":decision_remaining,"id":str(id),"character_id":str(character_id),"pose":pose.snapshot(),"destination":[destination.x,destination.y],"phase":str(phase),"elapsed":elapsed,"food_id":str(food_id),"stay_seconds":stay_seconds,"remark_remaining":remark_remaining,"served":served,"order_id":str(order_id)}
