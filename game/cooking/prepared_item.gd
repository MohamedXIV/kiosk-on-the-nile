class_name PreparedItem
extends RefCounted
var id: StringName
var recipe_id: StringName
var food_id: StringName
var sugar_id: StringName
var quality_score: int = 0
var quality_key: StringName
func snapshot() -> Dictionary:
 return {"id":str(id),"recipe_id":str(recipe_id),"food_id":str(food_id),"sugar_id":str(sugar_id),"quality_score":quality_score,"quality_key":str(quality_key)}
static func from_dict(data: Dictionary) -> PreparedItem:
 var item := PreparedItem.new()
 item.id = StringName(data.id)
 item.recipe_id = StringName(data.recipe_id)
 item.food_id = StringName(data.food_id)
 item.sugar_id = StringName(data.get("sugar_id",""))
 item.quality_score = int(data.quality_score)
 item.quality_key = StringName(data.quality_key)
 return item
