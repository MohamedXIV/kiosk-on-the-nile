class_name OrderState
extends RefCounted
var id: StringName
var visit_id: StringName
var food_id: StringName
var status: StringName = &"pending"
var delivered_item_id: StringName
var base_price: int
var tips: Array = []
func snapshot() -> Dictionary:
 return {"id":str(id),"visit_id":str(visit_id),"food_id":str(food_id),"status":str(status),"delivered_item_id":str(delivered_item_id),"base_price":base_price,"tips":tips.duplicate()}
