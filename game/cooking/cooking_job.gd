class_name CookingJob
extends RefCounted
var station_id: StringName
var recipe: RecipeDefinition
var stage: StringName = &"EMPTY"
var heat_elapsed: float = 0.0
var brew_elapsed: float = 0.0
var side_a_elapsed: float = 0.0
var side_b_elapsed: float = 0.0
var seasoned: bool = false
var sugar_id: StringName
var quality_penalty: int = 0
func _init(station: StringName = &"", definition: RecipeDefinition = null) -> void:
 station_id = station
 recipe = definition
 if recipe: reset()
func reset() -> void:
 stage = &"EMPTY"
 heat_elapsed = 0
 brew_elapsed = 0
 side_a_elapsed = 0
 side_b_elapsed = 0
 seasoned = false
 quality_penalty = 0
 sugar_id = StringName(recipe.data.get("default_sugar",""))
func snapshot() -> Dictionary:
 return {"station_id":str(station_id),"recipe_id":str(recipe.id),"recipe":recipe.data.duplicate(true),"stage":str(stage),"heat_elapsed":heat_elapsed,"brew_elapsed":brew_elapsed,"side_a_elapsed":side_a_elapsed,"side_b_elapsed":side_b_elapsed,"seasoned":seasoned,"sugar_id":str(sugar_id),"quality_penalty":quality_penalty}
func restore(data: Dictionary) -> ActionResult:
 if data.get("station_id") != str(station_id) or data.get("recipe_id") != str(recipe.id) or not data.get("recipe") is Dictionary:
  return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_cooking_job")
 if not ContentValidation.integer(data.get("quality_penalty")) or not ContentValidation.bounded(data.quality_penalty,0,2) or (data.get("stage")=="EMPTY" and data.quality_penalty!=0): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_work_quality")
 var validation := ContentValidation.validate_recipe(data.recipe)
 if not validation.ok: return validation
 if data.recipe.rules_id != str(recipe.rules_id) or data.recipe.food_id != str(recipe.food_id): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"incompatible_recipe")
 var allowed: Array = ["EMPTY","HEATING","BOILED","BREWING","READY"] if recipe.rules_id == &"tea" else ["EMPTY","SIDE_A","SIDE_B","SEASONED"]
 if not data.get("stage") in allowed or not data.get("seasoned") is bool or not data.get("sugar_id") is String: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_cooking_stage")
 for field in ["heat_elapsed","brew_elapsed","side_a_elapsed","side_b_elapsed"]:
  if not ContentValidation.number(data.get(field)) or float(data[field]) < 0: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_cooking_timer")
 if recipe.rules_id == &"tea":
  var known := false
  for sugar in data.recipe.sugars:
   if sugar.id == data.get("sugar_id"): known = true
  if not known: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_sugar")
  if data.stage == "READY" and float(data.brew_elapsed)<float(data.recipe.timing.brew_seconds): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"early_tea")
 if data.stage == "EMPTY" and (data.heat_elapsed!=0 or data.brew_elapsed!=0 or data.side_a_elapsed!=0 or data.side_b_elapsed!=0 or data.seasoned): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"nonempty_job")
 if recipe.rules_id == &"tea":
  var timing: Dictionary = data.recipe.timing
  if data.stage in ["BOILED","BREWING","READY"] and float(data.heat_elapsed)<float(timing.boil_seconds): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"early_boiling")
  if data.stage == "HEATING" and float(data.heat_elapsed)>=float(timing.boil_seconds): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"late_heating")
  if data.stage == "BREWING" and float(data.brew_elapsed)>=float(timing.brew_seconds): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"late_brewing")
  if data.stage in ["HEATING","BOILED"] and data.brew_elapsed!=0: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"early_brew_timer")
  if data.side_a_elapsed!=0 or data.side_b_elapsed!=0 or data.seasoned: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_tea_state")
 else:
  if data.stage in ["SIDE_B","SEASONED"] and float(data.side_a_elapsed)<float(data.recipe.timing.minimum_flip): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"early_flip")
  if data.seasoned != (data.stage == "SEASONED"): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_seasoning")
  if data.stage=="SIDE_A" and data.side_b_elapsed!=0: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"early_second_side")
  if data.sugar_id!="": return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_grill_sugar")
  if data.heat_elapsed!=0 or data.brew_elapsed!=0: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_grill_state")
 recipe = RecipeDefinition.new(recipe.id,data.recipe)
 stage = StringName(data.stage)
 heat_elapsed = float(data.heat_elapsed)
 brew_elapsed = float(data.brew_elapsed)
 side_a_elapsed = float(data.side_a_elapsed)
 side_b_elapsed = float(data.side_b_elapsed)
 seasoned = data.seasoned
 sugar_id = StringName(data.sugar_id)
 quality_penalty = int(data.quality_penalty)
 return ActionResult.success()
