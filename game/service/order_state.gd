class_name OrderState
extends RefCounted
var id: StringName
var visit_id: StringName
var character_id: StringName
var food_id: StringName
var status: StringName = &"pending"
var delivered_item_id: StringName
var created_at: float=-1.0
var served_at: float=-1.0
var closed_at: float=-1.0
var served_quality: int=-1
var timing_known: bool=false
var base_price: int
var tips: Array = []
var gift_promised: bool=false
var settlement: StringName=&"pending"
var payment: int=-1
var served_item: Dictionary={}
func snapshot() -> Dictionary:
 return {"character_id":str(character_id),"gift_promised":gift_promised,"settlement":str(settlement),"payment":payment,"served_item":served_item.duplicate(true),"id":str(id),"visit_id":str(visit_id),"food_id":str(food_id),"status":str(status),"delivered_item_id":str(delivered_item_id),"base_price":base_price,"tips":tips.duplicate(),"created_at":created_at,"served_at":served_at,"closed_at":closed_at,"served_quality":served_quality,"timing_known":timing_known}
