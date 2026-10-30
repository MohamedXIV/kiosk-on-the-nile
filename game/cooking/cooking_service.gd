class_name CookingService
extends RefCounted
signal changed(station_id: StringName)
signal held_changed
var foods: FoodRegistry
var _legacy := LegacyCookingAdapter.new()
var _workflow: RecipeWorkflow
var _inventory: InventoryService
var _recipes: Dictionary
var _station_recipes: Dictionary={}
func configure(data: Dictionary, inventory: InventoryService) -> ActionResult:
 _inventory=inventory
 _recipes=data.recipes.duplicate(true)
 for id in data.stations:_station_recipes[id]=data.stations[id].recipe_id
 _legacy.changed.connect(func(id):changed.emit(id))
 _legacy.held_changed.connect(func():held_changed.emit())
 return _legacy.configure(data,inventory)
func set_workflow(workflow: RecipeWorkflow) -> void:
 _workflow=workflow
 _workflow.sugar_provider=func(id):
  var current := _legacy.job(id)
  return str(current.sugar_id) if current!=null else ""
 _workflow.changed.connect(func():changed.emit(&"");held_changed.emit())
func act(station_id: StringName) -> ActionResult:
 if legacy_busy(station_id):return _legacy.act(station_id)
 if _workflow==null:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"unknown_station")
 var active := _workflow.active_at(station_id)
 if not active.is_empty():return _workflow.act(StringName(active.id),StringName(active.definition.steps[int(active.step_index)].action))
 if not _station_recipes.has(str(station_id)):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"unknown_station")
 return _workflow.start(StringName(_station_recipes[str(station_id)]),StringName(_inventory.spaces.placement(station_id).get("location_id","")),PackedStringArray([str(station_id)]))
func cycle_sugar(station_id: StringName) -> ActionResult:
 if _workflow!=null and not _workflow.active_at(station_id).is_empty():return ActionResult.failure(ActionResult.Code.INVALID_STAGE,&"sugar_unavailable")
 return _legacy.cycle_sugar(station_id)
func tick(delta: float) -> void:
 _legacy.tick(delta)
func job(station_id: StringName) -> CookingJob:
 var current := _legacy.job(station_id)
 if current==null or current.stage!=&"EMPTY" or _workflow==null:return current
 var status := _workflow.station_status(station_id)
 if status.get("process",false):
  var view := CookingJob.new(station_id,current.recipe)
  view.stage=&"SIDE_A" if status.step.kind in ["passive_heat","batch_hold"] and status.heat!="off" else &"EMPTY"
  view.side_a_elapsed=float(status.elapsed)
  return view
 var active := _workflow.active_at(station_id)
 if active.is_empty() or not active.recipe_id in ["tea","kebda"]:return current
 var view := CookingJob.new(station_id,current.recipe)
 view.sugar_id=StringName(active.sugar_id)
 view.quality_penalty=int(active.quality_penalty)
 var elapsed := float(active.elapsed)/float(active.definition.presentation_minutes_per_second)
 if active.recipe_id=="tea":
  if active.step_index==0:
   view.stage=&"BOILED" if active.elapsed>=active.definition.steps[0].duration else &"HEATING"
   view.heat_elapsed=elapsed
  else:
   view.stage=&"READY" if active.elapsed>=active.definition.steps[1].duration else &"BREWING"
   view.heat_elapsed=float(active.step_results[0].elapsed)/float(active.definition.presentation_minutes_per_second)
   view.brew_elapsed=elapsed
 else:
  view.stage=&"SIDE_A" if active.step_index==0 else &"SIDE_B" if active.step_index==1 else &"SEASONED"
  view.side_a_elapsed=elapsed if active.step_index==0 else float(active.step_results[0].elapsed)/float(active.definition.presentation_minutes_per_second)
  view.side_b_elapsed=0 if active.step_index==0 else elapsed
  view.seasoned=active.step_index==2
 return view
func legacy_busy(id: StringName) -> bool:
 return _legacy.legacy_busy(id)
func held_item() -> PreparedItem:
 return _inventory.prepared_item(_inventory.held_id())
func take_held(expected_id: StringName, notify: bool = true) -> PreparedItem:
 var item := held_item()
 if item==null or item.id!=expected_id:return null
 var age := freshness(item)
 if not age.sellable:return null
 var result := _inventory.consume_held(expected_id,notify)
 if not result.ok:return null
 item.quality_score=int(age.grade)
 item.quality_key=StringName(foods.definition(item.food_id).quality_keys[item.quality_score])
 return item
func stock_count(id: StringName) -> int:
 return _legacy.stock_count(id)
func inventory_snapshot() -> Dictionary:
 return _legacy.inventory_snapshot()
func restock(tea: int, kebda: int) -> ActionResult:
 return _legacy.restock(tea,kebda)
func item_label(item: PreparedItem) -> String:
 return foods.label(item) if foods!=null else _legacy.item_label(item)
func quality_label(item: PreparedItem) -> String:
 if foods==null:return _legacy.quality_label(item)
 var food := foods.definition(item.food_id)
 var current := PreparedItem.from_dict(item.snapshot())
 current.quality_score=int(freshness(item).grade)
 return ItemText.source("food."+str(item.food_id)+".quality."+str(food.quality_keys[current.quality_score]),foods.quality_label(current)) if not food.is_empty() else ""
func station_ids() -> Array:
 return _legacy.station_ids()
func set_quality_provider(provider: Callable) -> void:
 _legacy.set_quality_provider(provider)
func snapshot() -> Dictionary:
 return _legacy.snapshot()
func restore(data: Dictionary) -> ActionResult:
 return _legacy.restore(data)

func set_hygiene_provider(provider: Callable, use_provider: Callable) -> void:
 _legacy.hygiene_provider=provider
 _legacy.use_provider=use_provider

func process_status(instance_id: StringName) -> Dictionary:
 return _workflow.station_status(instance_id) if _workflow!=null else {}

func freshness(item: PreparedItem) -> Dictionary:
 return FoodFreshness.view(item.snapshot(),_inventory.items.world_clock.world_minutes,_inventory.items.food_definitions)
