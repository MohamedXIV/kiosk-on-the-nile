class_name ServiceReceiptValidation
extends RefCounted
static func valid(record: Dictionary, foods: FoodRegistry, recipes: Dictionary, menu: MenuService) -> bool:
 if menu==null or not menu.valid_quote(record.get("quote")) or not record.get("source_item") is Dictionary or record.get("food_id")!=record.quote.food_id or record.get("base_price")!=record.quote.price_minor or not record.get("tips",[]).all(func(t):return ContentValidation.integer(t) and int(t)==0):return false
 if not ContentValidation.number(record.get("created_at")) or not is_equal_approx(float(record.quote.at),float(record.created_at)):return false
 if not record.get("character_id") is String or record.character_id.is_empty():return false
 if not record.get("gift_promised") is bool or not record.get("settlement") in ["pending","paid","gift"] or not ContentValidation.integer(record.get("payment")) or not record.get("served_item") is Dictionary:return false
 if record.status!="delivered":return record.source_item.is_empty() and record.settlement=="pending" and record.payment==-1 and record.served_item.is_empty() and record.get("served_at",-1)==-1 and record.get("served_quality",-1)==-1
 var item: Dictionary=record.served_item
 for field in ["id","recipe_id","food_id","sugar_id","quality_key"]:
  if not item.get(field) is String:return false
 if item.id!=record.delivered_item_id or item.food_id!=record.food_id or item.recipe_id.is_empty() or not ContentValidation.integer(item.get("quality_score")) or item.quality_score<0 or item.quality_score>3 or item.quality_score!=record.get("served_quality"):return false
 if not menu.matches(PreparedItem.from_dict(item),record.quote) or not RecipeProcesses.preparation_matches(item,record.source_item):return false
 var recipe: Dictionary=recipes.get(item.recipe_id,{})
 var food := foods.definition(StringName(item.food_id)) if foods!=null else {}
 if recipe.get("output",{}).get("food_id")!=item.food_id or food.is_empty() or item.quality_key!=str(food.quality_keys[int(item.quality_score)]):return false
 if not FoodFreshness.valid(item.get("freshness"),float(item.get("prepared_at",-1)),float(record.get("served_at",-1))):return false
 var at_service := FoodFreshness.view(item,float(record.served_at),foods._definitions)
 if not at_service.sellable or int(at_service.grade)!=int(item.quality_score):return false
 if food.has("sugars"):
  if not food.sugars.has(item.sugar_id):return false
 elif not item.sugar_id.is_empty():return false
 if record.gift_promised and record.settlement=="paid":return false
 if record.settlement=="pending":return record.payment==-1 and record.get("closed_at",-1)==-1
 if record.settlement=="gift":return record.payment==0
 return record.payment==int(record.base_price)+int(record.tips[item.quality_score])
