class_name FoodRegistry
extends RefCounted
var _definitions: Dictionary={}
func configure(definitions: Dictionary) -> ActionResult:
 var result := validate(definitions)
 if not result.ok:return result
 _definitions=definitions.duplicate(true)
 return ActionResult.success()
static func validate(definitions: Dictionary) -> ActionResult:
 for id in definitions:
  var d: Variant=definitions[id]
  if not d is Dictionary or not d.get("label") is String or not ContentValidation.integer(d.get("price_minor")) or d.price_minor<0 or not d.get("nourishment") is Dictionary:return ContentValidation.fail("foods."+id)
  if not d.get("menu_label") is String or d.menu_label.is_empty() or not d.get("order_icon") in ["cup","sandwich","plate"]:return ContentValidation.fail("foods.order_presentation")
  for field in ["hunger","base_mood","quality_mood"]:
   if not ContentValidation.bounded(d.nourishment.get(field),0,100):return ContentValidation.fail("foods.nourishment")
  for field in ["quality_keys","quality_names","tips"]:
   if not d.get(field) is Array or d[field].size()!=4:return ContentValidation.fail("foods."+field)
  for amount in d.tips:
   if not ContentValidation.integer(amount) or amount<0:return ContentValidation.fail("foods.tip")
 return ActionResult.success()
func definition(id: StringName) -> Dictionary:
 return _definitions.get(str(id),{}).duplicate(true)
func has_food(id: StringName) -> bool:
 return _definitions.has(str(id))
func label(item: PreparedItem) -> String:
 var food := definition(item.food_id)
 if food.is_empty():return ""
 return str(food.label).format({"sugar":food.get("sugars",{}).get(str(item.sugar_id),"")})
func quality_label(item: PreparedItem) -> String:
 var food := definition(item.food_id)
 return str(food.quality_names[item.quality_score]) if not food.is_empty() else ""

func ids() -> Array:
 return _definitions.keys()
