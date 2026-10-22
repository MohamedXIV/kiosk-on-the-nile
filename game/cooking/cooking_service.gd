class_name CookingService
extends RefCounted
signal changed(station_id: StringName)
signal held_changed
var _recipes: Dictionary = {}
var _stations: Dictionary = {}
var _jobs: Dictionary = {}
var _inventory: InventoryService
var _stock_keys: Array = []
var _quality_provider: Callable
var _rules := {"tea":TeaRules.new(),"kebda":KebdaRules.new()}
func configure(data: Dictionary, inventory: InventoryService) -> ActionResult:
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
 _inventory = inventory
 _stock_keys = data.initial_stock.keys()
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
 var result: ActionResult = _rules[str(recipe.rules_id)].act(current,stock_count(recipe.stock_key)>=recipe.portion_cost,_inventory.held_id().is_empty())
 if not result.ok: return result
 if starting: current.quality_penalty=penalty
 if result.details.has("stock_debit"):
  var debit := _inventory.debit_legacy(recipe.stock_key,int(result.details.stock_debit))
  if not debit.ok: return debit
 if result.details.get("completed",false):
  var item := PreparedItem.new()
  item.id = _inventory.next_food_id()
  item.recipe_id = recipe.id
  item.food_id = recipe.food_id
  item.sugar_id = current.sugar_id
  var technique_score := int(result.details.score)
  item.quality_score = maxi(1,technique_score-current.quality_penalty) if technique_score>0 else 0
  result.details["technique_score"] = technique_score
  result.details["mood_penalty"] = current.quality_penalty
  result.details["score"] = item.quality_score
  item.quality_key = StringName(recipe.data.quality_keys[item.quality_score])
  var received := _inventory.receive_prepared(item)
  if not received.ok: return received
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
 return _inventory.prepared_item(_inventory.held_id())
func take_held(expected_id: StringName, notify: bool = true) -> PreparedItem:
 var item := held_item()
 if item==null or item.id!=expected_id: return null
 var result := _inventory.consume_held(expected_id,notify)
 if not result.ok: return null
 if notify: held_changed.emit()
 return item
func stock_count(stock_id: StringName) -> int:
 return _inventory.stock_count(&"kiosk",stock_id)
func inventory_snapshot() -> Dictionary:
 var result: Dictionary = {}
 for id in _stock_keys: result[id] = stock_count(StringName(id))
 return result
func restock(tea: int, kebda: int) -> ActionResult:
 var result := _inventory.restock_legacy({"tea":tea,"kebda":kebda})
 if result.ok: changed.emit(&"")
 return result
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
 return {"jobs":jobs}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("jobs") is Dictionary or data.jobs.size()!=_jobs.size(): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_kitchen")
 var jobs: Dictionary = {}
 for id in _jobs:
  if not data.jobs.get(id) is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"missing_job")
  var candidate := CookingJob.new(StringName(id),_recipes[str(_stations[id].recipe_id)])
  var result := candidate.restore(data.jobs[id])
  if not result.ok: return result
  if candidate.stage == &"EMPTY":
   candidate.recipe = _recipes[str(candidate.recipe.id)]
  jobs[id] = candidate
 _jobs = jobs
 return ActionResult.success()

func station_ids() -> Array:
 return _jobs.keys()

func set_quality_provider(provider: Callable) -> void:
 _quality_provider = provider

func legacy_busy(id: StringName) -> bool:
 var current := job(id)
 return current!=null and current.stage!=&"EMPTY"
