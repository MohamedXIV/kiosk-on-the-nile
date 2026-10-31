class_name ItemText
extends RefCounted
## Stable ID + exact source guard. Frozen/custom names remain their own text.
static func t(key: String, args: Dictionary = {}) -> String:return UiText.localized("items_ui."+key,args,key)
static func source(key: String, value: String, args: Dictionary = {}) -> String:return LocaleService.current.source_text(key,value,args) if LocaleService.current else value.format(args)
static func definition(session: GameSession, id: String) -> String:
 return source("item."+id,str(session.items.definition(StringName(id)).get("label",id)))
static func recipe(id: String, value: String) -> String:return source("recipe."+id,value)
static func step(recipe_id: String, value: Dictionary) -> String:return source("recipe."+recipe_id+".step."+str(value.id),str(value.label))
static func capability(id: String) -> String:return UiText.localized("capability."+id,{},id)
static func instance(session: GameSession, item: Dictionary) -> String:
 if item.is_empty():return t("hands_empty")
 if item.get("kind")=="prepared":
  var attributes: Dictionary=item.get("attributes",{})
  var id := str(attributes.get("food_id",""))
  var food := session.cooking.foods.definition(StringName(id))
  if not food.is_empty():
   var sugar_id := str(attributes.get("sugar_id",""))
   var sugar := source("food."+id+".sugar."+sugar_id,str(food.get("sugars",{}).get(sugar_id,"")))
   return source("food."+id+".label",str(food.label),{"sugar":sugar})
 return definition(session,str(item.definition_id))
static func search_names(session: GameSession, item: Dictionary) -> String:
 var id := str(item.definition_id)
 var original := str(session.items.definition(StringName(id)).get("label",id))
 var values := LocaleService.current.source_variants("item."+id,original)
 values.append(instance(session,item))
 if item.get("kind")=="prepared":
  var food_id := str(item.get("attributes",{}).get("food_id",""))
  var food := session.cooking.foods.definition(StringName(food_id))
  if not food.is_empty():values.append_array(LocaleService.current.source_variants("food."+food_id+".label",str(food.label)))
 return "\n".join(values).to_lower()
static func item_details(session: GameSession, item: Dictionary) -> String:
 var attributes: Dictionary=item.get("attributes",{})
 if item.kind=="ingredient" and attributes.has("lot"):
  var lot: Dictionary=attributes.lot
  var grade := UiText.localized("ingredient.grade."+str(lot.grade),{},str(lot.grade))
  var detail := t("material_lot",{"grade":grade,"day":floori(float(lot.acquired_at)/1440.0)+1})
  if lot.cost_known:detail+=" · "+t("material_cost",{"amount":"%.2f" % (float(lot.cost_minor)/float(lot.cost_units)/100.0)})
  return detail
 if item.kind=="batch":
  var line := UiText.localized("ui.recipe_portions",{"count":attributes.get("portions_remaining",0)},str(attributes.get("portions_remaining",0)))
  return line+" · "+freshness(session,attributes) if attributes.has("freshness") else line
 if item.kind=="prepared":
  var food_id := str(attributes.get("food_id",""))
  var food := session.cooking.foods.definition(StringName(food_id))
  var age := FoodFreshness.view(attributes,session.clock.world_minutes,session.items.food_definitions)
  var score := int(age.grade)
  if not food.is_empty() and score>=0 and score<food.quality_names.size():return t("quality",{"label":source("food."+food_id+".quality."+str(food.quality_keys[score]),str(food.quality_names[score]))})+" · "+freshness(session,attributes)
 return ""
static func requirements(session: GameSession, definition_data: Dictionary) -> String:
 var values := PackedStringArray()
 for input in definition_data.inputs:values.append(t("quantity",{"name":definition(session,str(input.definition_id)),"quantity":int(input.quantity)}))
 return t("ingredients",{"items":" · ".join(values)})
static func equipment(definition_data: Dictionary) -> String:
 var values := PackedStringArray();var seen: Dictionary={}
 for value in definition_data.steps:
  if seen.has(value.capability):continue
  seen[value.capability]=true;values.append(capability(str(value.capability)))
 return t("equipment",{"items":" · ".join(values)})
static func missing(session: GameSession, text: UiText, result: ActionResult) -> String:
 var reason := text.outcome(result)
 if result.details.has("definition_id") and result.details.has("missing"):return t("missing_item",{"reason":reason,"name":definition(session,str(result.details.definition_id)),"quantity":int(result.details.missing)})
 if result.details.has("capability"):return t("missing_capability",{"reason":reason,"name":capability(str(result.details.capability))})
 return reason
static func hygiene(data: Dictionary, state: Dictionary) -> String:
 if state.is_empty():return ""
 var key := "clean" if float(state.cleanliness)>=float(data.thresholds.wipe) else "wipe" if float(state.cleanliness)>=float(data.thresholds.dirty) else "dirty"
 return t("cleanliness",{"label":source("hygiene."+key,str(state.label))})

static func freshness(session: GameSession, attributes: Dictionary) -> String:
 var age := FoodFreshness.view(attributes,session.clock.world_minutes,session.items.food_definitions)
 return UiText.localized("freshness."+str(age.stage),{},str(age.stage))
