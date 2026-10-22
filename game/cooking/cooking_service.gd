class_name CookingService
extends RefCounted
signal changed(station_id: StringName)
signal held_changed
var _recipes: Dictionary = {}
var _stations: Dictionary = {}
var _jobs: Dictionary = {}
var _stock: Dictionary = {}
var _held: PreparedItem
var _next_item: int = 1
var _quality_provider: Callable
var _rules := {"tea":TeaRules.new(),"kebda":KebdaRules.new()}
func configure(data: Dictionary) -> ActionResult:
 var validation := ContentValidation.validate_recipes(data)
 if not validation.ok: return validation
 var recipes: Dictionary = {}
 var stations: Dictionary = {}
 var jobs: Dictionary = {}
 for id in data.recipes: recipes[id] = RecipeDefinition.new(StringName(id),data.recipes[id])
 for id in data.stations:
  stations[id] = StationDefinition.new(StringName(id),StringName(data.stations[id].recipe_id))
  jobs[id] = CookingJob.new(StringName(id),recipes[str(stations[id].recipe_id)])
 _recipes = recipes
 _stations = stations
 _jobs = jobs
 _stock = data.initial_stock.duplicate(true)
 _held = null
 _next_item = 1
 return ActionResult.success()
func act(station_id: StringName) -> ActionResult:
 var current := job(station_id)
 if current == null: return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"unknown_station")
 var recipe := current.recipe
 var starting := current.stage==&"EMPTY"
 var penalty := 0
 if starting and _quality_provider.is_valid():
  var projected: Variant = _quality_provider.call()
  if not ContentValidation.integer(projected) or not ContentValidation.bounded(projected,0,2): return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_work_quality")
  penalty = int(projected)
 var result: ActionResult = _rules[str(recipe.rules_id)].act(current,stock_count(recipe.stock_key)>=recipe.portion_cost,_held==null)
 if not result.ok: return result
 if starting: current.quality_penalty=penalty
 if result.details.has("stock_debit"): _stock[str(recipe.stock_key)] = stock_count(recipe.stock_key)-int(result.details.stock_debit)
 if result.details.get("completed",false):
  var item := PreparedItem.new()
  item.id = StringName("food_%d" % _next_item)
  _next_item += 1
  item.recipe_id = recipe.id
  item.food_id = recipe.food_id
  item.sugar_id = current.sugar_id
  var technique_score := int(result.details.score)
  item.quality_score = maxi(1,technique_score-current.quality_penalty) if technique_score>0 else 0
  result.details["technique_score"] = technique_score
  result.details["mood_penalty"] = current.quality_penalty
  result.details["score"] = item.quality_score
  item.quality_key = StringName(recipe.data.quality_keys[item.quality_score])
  _held = item
  result.details["item"] = item
  current.recipe = _recipes[str(recipe.id)]
  current.reset()
  held_changed.emit()
 changed.emit(station_id)
 return result
func cycle_sugar(station_id: StringName) -> ActionResult:
 var current := job(station_id)
 if current == null or current.stage != &"EMPTY" or current.recipe.rules_id != &"tea": return ActionResult.failure(ActionResult.Code.INVALID_STAGE,&"sugar_unavailable")
 var sugars: Array = current.recipe.data.sugars
 for i in range(sugars.size()):
  if sugars[i].id == str(current.sugar_id):
   current.sugar_id = StringName(sugars[(i+1)%sugars.size()].id)
   changed.emit(station_id)
   return ActionResult.success({"cue":"chime"})
 return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_sugar")
func tick(delta: float) -> void:
 if delta < 0 or not is_finite(delta): return
 for current in _jobs.values(): _rules[str(current.recipe.rules_id)].tick(current,delta)
func job(station_id: StringName) -> CookingJob:
 return _jobs.get(str(station_id))
func held_item() -> PreparedItem:
 return _held
func take_held(expected_id: StringName, notify: bool = true) -> PreparedItem:
 if _held == null or _held.id != expected_id: return null
 var item := _held
 _held = null
 if notify: held_changed.emit()
 return item
func stock_count(stock_id: StringName) -> int:
 return int(_stock.get(str(stock_id),0))
func inventory_snapshot() -> Dictionary:
 return _stock.duplicate(true)
func restock(tea: int, kebda: int) -> ActionResult:
 if tea < 0 or kebda < 0: return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_stock")
 _stock["tea"] = stock_count(&"tea")+tea
 _stock["kebda"] = stock_count(&"kebda")+kebda
 changed.emit(&"")
 return ActionResult.success()
func item_label(item: PreparedItem) -> String:
 var recipe: RecipeDefinition = _recipes.get(str(item.recipe_id))
 if recipe == null: return ""
 var sugar := ""
 for definition in recipe.data.get("sugars",[]):
  if definition.id == str(item.sugar_id): sugar = definition.label
 return str(recipe.data.name).format({"sugar":sugar})
func quality_label(item: PreparedItem) -> String:
 return str(_recipes[str(item.recipe_id)].data.quality_names[str(item.quality_score)])
func snapshot() -> Dictionary:
 var jobs: Dictionary = {}
 for id in _jobs: jobs[id] = _jobs[id].snapshot()
 return {"stock":_stock.duplicate(true),"jobs":jobs,"held":_held.snapshot() if _held else null,"next_item":_next_item}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("stock") is Dictionary or not data.get("jobs") is Dictionary or not ContentValidation.integer(data.get("next_item")) or int(data.next_item)<1:
  return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_kitchen")
 if data.stock.size()!=_stock.size() or data.jobs.size()!=_jobs.size(): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"incompatible_kitchen")
 for id in _stock:
  if not ContentValidation.integer(data.stock.get(id)) or float(data.stock[id])<0: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_stock")
 var jobs: Dictionary = {}
 for id in _jobs:
  if not data.jobs.get(id) is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"missing_job")
  var candidate := CookingJob.new(StringName(id),_recipes[str(_stations[id].recipe_id)])
  var result := candidate.restore(data.jobs[id])
  if not result.ok: return result
  if candidate.stage == &"EMPTY":
   candidate.recipe = _recipes[str(candidate.recipe.id)]
  jobs[id] = candidate
 var held: PreparedItem
 if data.get("held") != null:
  var item: Variant = data.held
  if not item is Dictionary or not item.get("id") is String or not _recipes.has(item.get("recipe_id")) or not ContentValidation.integer(item.get("quality_score")) or not float(item.quality_score) in [0,1,2,3] or not item.get("sugar_id") is String:
   return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_food")
  var recipe: RecipeDefinition = _recipes[item.recipe_id]
  if item.get("food_id")!=str(recipe.food_id) or item.get("quality_key")!=recipe.data.quality_keys[int(item.quality_score)]: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_food")
  var suffix: String = item.id.trim_prefix("food_")
  if not item.id.begins_with("food_") or not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=int(data.next_item): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_food_identity")
  if recipe.rules_id==&"tea":
   var known_sugar := false
   for option in recipe.data.sugars:
    if option.id==item.sugar_id: known_sugar=true
   if not known_sugar: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_food_sugar")
  elif item.sugar_id!="": return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_food_sugar")
  held = PreparedItem.from_dict(item)
 _jobs = jobs
 _stock = data.stock.duplicate(true)
 _held = held
 _next_item = int(data.next_item)
 return ActionResult.success()

func station_ids() -> Array:
 return _jobs.keys()

func set_quality_provider(provider: Callable) -> void:
 _quality_provider = provider
