class_name RecipeDefinition
extends RefCounted
var id: StringName
var rules_id: StringName
var food_id: StringName
var stock_key: StringName
var portion_cost: int
var data: Dictionary
func _init(identity: StringName = &"", definition: Dictionary = {}) -> void:
 id = identity
 data = definition.duplicate(true)
 rules_id = StringName(data.get("rules_id",""))
 food_id = StringName(data.get("food_id",""))
 stock_key = StringName(data.get("stock_key",""))
 portion_cost = int(data.get("portion_cost",1))
