class_name ContentValidation
extends RefCounted
## Shared runtime/tool validation. Invalid edits never partially activate.
static func validate(bundle: Dictionary) -> ActionResult:
 if bundle.has("character_life"):
  var characters := CharacterLifeValidation.validate(bundle.character_life,ActorPresence.authored_profiles(bundle).keys(),bundle.get("foods",{}))
  if not characters.ok:return characters
 var semantic := SemanticNarrative.validate(bundle)
 if not semantic.ok:return semantic
 var save_feedback := SaveFeedbackValidation.validate(bundle)
 if not save_feedback.ok:return save_feedback
 var peer_result := PeerContentValidation.validate(bundle)
 if not peer_result.ok:return peer_result
 var hud_result := HudContentValidation.validate(bundle)
 if not hud_result.ok:return hud_result
 var notebook_result := NotebookView.validate_layout(bundle)
 if not notebook_result.ok:return notebook_result
 if bundle.has("locale_ar") or bundle.has("locale_en"):
  var localized := LocaleService.validate_bundle(bundle)
  if not localized.ok:return localized
 if bundle.has("suppliers"):
  var supplier_result := SupplierValidation.validate(bundle)
  if not supplier_result.ok:return supplier_result
 if bundle.has("accounts"):
  var account_result := AccountValidation.validate(bundle)
  if not account_result.ok:return account_result
 if bundle.has("tuning"):
  var tuning_result := TuningValidation.validate(bundle)
  if not tuning_result.ok:return tuning_result
 if bundle.has("narration"):
  var narration_result := NarrationValidation.validate(bundle)
  if not narration_result.ok:return narration_result
 if bundle.has("social_life"):
  var social_result := SocialLifeValidation.validate(bundle)
  if not social_result.ok:return social_result
 if bundle.has("items") or bundle.has("containers"):
  var items_result := ItemContentValidation.validate(bundle.get("items",{}),bundle.get("containers",{}))
  if not items_result.ok: return items_result
 if bundle.has("spaces") or bundle.has("initial_layout"):
  var spaces_result := SpaceContentValidation.validate(bundle)
  if not spaces_result.ok: return spaces_result
 if bundle.has("shops"):
  var commerce_result := CommerceContentValidation.validate(bundle)
  if not commerce_result.ok:return commerce_result
 if bundle.has("equipment"):
  var equipment_result := CookingWorkflowValidation.validate_equipment(bundle.equipment,bundle.get("items",{}))
  if not equipment_result.ok:return equipment_result
 if bundle.has("recipe_workflows"):
  var recipe_items := ItemStore.new()
  var recipe_store_result := recipe_items.configure(bundle.get("items",{}),bundle.get("containers",{}))
  if not recipe_store_result.ok:return recipe_store_result
  var workflow_result := CookingWorkflowValidation.validate_recipes(bundle.recipe_workflows,recipe_items)
  if not workflow_result.ok:return workflow_result
 if bundle.has("foods"):
  var foods_result := FoodRegistry.validate(bundle.foods)
  if not foods_result.ok:return foods_result
 if bundle.has("hygiene"):
  var hygiene_result := HygieneContentValidation.validate(bundle.hygiene,bundle.get("items",{}))
  if not hygiene_result.ok:return hygiene_result
 if bundle.has("customer_experience"):
  var experience_result := CustomerExperienceValidation.validate(bundle.customer_experience,bundle)
  if not experience_result.ok:return experience_result
 var time: Dictionary = bundle.get("time",{})
 if not number(time.get("minutes_per_second")) or float(time.minutes_per_second) <= 0: return fail("time.minutes_per_second")
 if bundle.has("visitors"):
  for field in ["start_day","start_minutes","fixed_step"]:
   if not number(time.get(field)): return fail("time."+field)
  if not integer(time.start_day) or time.start_day<1 or not bounded(time.start_minutes,0,1439.999999) or not bounded(time.fixed_step,0.001,0.1): return fail("time.initial")
  if not time.get("system_dependencies") is Dictionary: return fail("time.system_dependencies")
  var handlers: Dictionary = {}
  for id in ["needs","cooking","motion","visitors","narrative","scheduler"]: handlers[id]=func(_frame):return ActionResult.success()
  if bundle.has("accounts"):
   handlers["accounts"]=func(_frame):return ActionResult.success()
   handlers["deliveries"]=func(_frame):return ActionResult.success()
   handlers["residential"]=func(_frame):return ActionResult.success()
  if bundle.has("tuning"):handlers["body"]=func(_frame):return ActionResult.success()
  if bundle.has("travel"):handlers["travel"]=func(_frame):return ActionResult.success()
  if bundle.has("shops"):handlers["shops"]=func(_frame):return ActionResult.success()
  if bundle.has("hygiene"):handlers["hygiene"]=func(_frame):return ActionResult.success()
  if bundle.has("social_life"):handlers["social_life"]=func(_frame):return ActionResult.success()
  if bundle.has("customer_experience"):handlers["customer_experience"]=func(_frame):return ActionResult.success()
  var ordering := SimulationCoordinator.new().prepare(GameClock.new(time),handlers,time.system_dependencies)
  if not ordering.ok: return ordering
 if bundle.has("balance"):
  var balance: Dictionary = bundle.balance
  var fields := ["starting_money","daily_rent","snack_price","supply_price","supply_tea","supply_kebda","fan_price","tea_price","kebda_price"]
  for key in fields:
   if not integer(balance.get(key)) or float(balance[key]) < 0: return fail("balance."+key)
  if not balance.get("quality_tips") is Array or balance.quality_tips.size() != 4: return fail("balance.quality_tips")
  for tip in balance.quality_tips:
   if not integer(tip) or float(tip) < 0: return fail("balance.quality_tips")
  for key in balance:
   if not key in fields and key != "quality_tips": return fail("balance."+key)
 if bundle.has("needs"):
  var needs: Dictionary = bundle.needs
  for key in ["hunger_decay","work_rest_decay","rest_decay","low_rest","low_hunger","low_needs_mood_decay","river_mood","fan_on_mood","good_service_mood"]:
   if not bounded(needs.get(key),0,100): return fail("needs."+key)
  var groups := {"initial":["hunger","rest","mood","baseline"],"sleep":["fan_baseline","rest_per_hour","mood_per_hour","hunger_per_hour","fan_rest_multiplier","fan_mood_multiplier"],"snack":["hunger","mood"],"tea":["hunger","base_mood","quality_mood"],"kebda":["hunger","base_mood","quality_mood"]}
  for group in groups:
   if not needs.get(group) is Dictionary: return fail("needs."+group)
   for key in groups[group]:
    if not bounded(needs[group].get(key),0,100): return fail("needs."+group+"."+key)
 if bundle.has("social"):
  var social: Dictionary = bundle.social
  if not bounded(social.get("conversation_familiarity_threshold"),0,100) or not bounded(social.get("hearing_radius"),0.1,100): return fail("social.conversation")
  for field in ["facts","initial_facts","initial_notes"]:
   if not social.get(field) is Array: return fail("social."+field)
   for value in social[field]:
    if not value is String: return fail("social."+field)
  for fact in social.initial_facts:
   if not fact in social.facts: return fail("social.initial_facts")
  if not social.get("relationship_bounds") is Array or social.relationship_bounds.size() != 2: return fail("social.relationship_bounds")
  if not number(social.relationship_bounds[0]) or not number(social.relationship_bounds[1]) or float(social.relationship_bounds[0]) > float(social.relationship_bounds[1]): return fail("social.relationship_bounds")
  if not social.get("relationship_defaults") is Dictionary: return fail("social.relationship_defaults")
  for axis in ["familiarity","trust"]:
   if not bounded(social.relationship_defaults.get(axis),social.relationship_bounds[0],social.relationship_bounds[1]): return fail("social.relationship_defaults."+axis)
 if bundle.has("spatial"):
  var spatial: Dictionary = bundle.spatial
  for key in ["x_scale","depth_scale","height_scale","player_speed","npc_speed","foot_radius","camera_smoothing"]:
   if not number(spatial.get(key)) or float(spatial[key]) <= 0: return fail("spatial."+key)
  if not spatial.get("character") is Dictionary or not spatial.character.get("player_color") is String or not Color.html_is_valid(spatial.character.player_color): return fail("spatial.character.player_color")
  if not bounded(spatial.get("camera_vertical_anchor"),0,1): return fail("spatial.camera_vertical_anchor")
  if not spatial.get("initial_ground") is Array or spatial.initial_ground.size()!=2: return fail("spatial.initial_ground")
  for value in spatial.initial_ground:
   if not number(value): return fail("spatial.initial_ground")
 if bundle.has("locations"):
  if not bundle.locations is Dictionary: return fail("locations")
  for id in bundle.locations:
   var data: Variant = bundle.locations[id]
   if not data is Dictionary: return fail("locations."+id)
   for key in ["player_bounds","navigation_bounds"]:
    if not rectangle(data.get(key)): return fail("locations."+id+"."+key)
   for key in ["canvas_origin","spawn"]:
    if not vector(data.get(key),2): return fail("locations."+id+"."+key)
   if not data.get("solids") is Array or not data.get("props") is Array or not data.get("interactions") is Array or not data.get("markers") is Dictionary or not data.get("floor") is Dictionary: return fail("locations."+id)
   if not number(data.get("navigation_cell")) or float(data.navigation_cell)<=0 or not bounded(data.get("navigation_clearance"),0,2): return fail("locations."+id+".navigation")
   if not props(data.props): return fail("locations."+id+".props")
   for marker in data.markers.values():
    if not vector(marker,2): return fail("locations."+id+".markers")
   for solid in data.solids:
    if not solid is Dictionary: return fail("locations."+id+".solids")
    if solid.get("kind") == "rect":
     if not rectangle(solid.get("rect")): return fail("locations."+id+".solids")
    elif solid.get("kind") == "circle":
     if not vector(solid.get("center"),2) or not number(solid.get("radius")) or float(solid.radius)<=0: return fail("locations."+id+".solids")
    else: return fail("locations."+id+".solids.kind")
   for target in data.interactions:
    if not target is Dictionary or not target.get("id") is String or not target.get("primary") is String or not vector(target.get("ground"),2) or not number(target.get("radius")) or float(target.radius)<=0: return fail("locations."+id+".interactions")
 if bundle.has("recipes"):
  var recipe_result := validate_recipes(bundle.recipes)
  if not recipe_result.ok: return recipe_result
 var features := FeatureContentValidation.validate(bundle)
 if not features.ok:return features
 var motion := CharacterMotionValidation.validate(bundle)
 if not motion.ok:return motion
 var seating := SeatingContentValidation.validate(bundle)
 if not seating.ok:return seating
 var hospitality := HospitalityContentValidation.validate(bundle)
 if not hospitality.ok:return hospitality
 return AvoidanceContentValidation.validate(bundle)
static func vector(value: Variant, count: int) -> bool:
 if not value is Array or value.size()!=count: return false
 for component in value:
  if not number(component): return false
 return true
static func rectangle(value: Variant) -> bool:
 return vector(value,4) and value[0]<value[2] and value[1]<value[3]
static func props(values: Array) -> bool:
 for prop in values:
  if not prop is Dictionary or not prop.get("kind") in ["box","counter","stool","table","lamp","railing","kettle","grill","fan","sign"] or not vector(prop.get("ground"),2): return false
  if prop.kind in ["box","counter"]:
   if not vector(prop.get("size"),3): return false
   for dimension in prop.size:
    if float(dimension)<=0: return false
  if prop.has("children") and (not prop.children is Array or not props(prop.children)): return false
 return true
static func number(value: Variant) -> bool:
 return typeof(value) in [TYPE_FLOAT,TYPE_INT] and is_finite(float(value))
static func integer(value: Variant) -> bool:
 return number(value) and absf(float(value)) < 9007199254740991.0 and float(value) == floor(float(value))
static func bounded(value: Variant, minimum: float, maximum: float) -> bool:
 return number(value) and float(value) >= minimum and float(value) <= maximum
static func fail(path: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_content",{"path":path})

static func validate_recipe(data: Dictionary) -> ActionResult:
 for field in ["rules_id","food_id","stock_key","name"]:
  if not data.get(field) is String or str(data[field]).is_empty(): return fail("recipes."+field)
 if not data.rules_id in ["tea","kebda"] or not integer(data.get("portion_cost")) or int(data.portion_cost)<1: return fail("recipes.rules")
 if not data.get("timing") is Dictionary or not data.get("quality_keys") is Array or data.quality_keys.size()!=4 or not data.get("quality_names") is Dictionary: return fail("recipes.quality")
 for i in range(4):
  if not data.quality_keys[i] is String or not data.quality_names.get(str(i)) is String: return fail("recipes.quality")
 for field in ["status","compact"]:
  if not data.get(field) is Dictionary: return fail("recipes."+field)
  for value in data[field].values():
   if not value is String: return fail("recipes."+field)
 var fields: Array = ["boil_seconds","brew_seconds","good_until","okay_until","warning_after"] if data.rules_id=="tea" else ["minimum_flip","excellent_a_min","excellent_a_max","excellent_b_min","excellent_b_max","burnt_after","good_total_min","good_total_max","warning_after"]
 for field in fields:
  if not number(data.timing.get(field)) or float(data.timing[field])<=0: return fail("recipes.timing."+field)
 if data.rules_id=="tea":
  if float(data.timing.good_until)>float(data.timing.okay_until) or not data.get("sugars") is Array or data.sugars.is_empty(): return fail("recipes.tea")
  var known: Array = []
  for sugar in data.sugars:
   if not sugar is Dictionary or not sugar.get("id") is String or not sugar.get("label") is String or sugar.id in known: return fail("recipes.sugars")
   known.append(sugar.id)
  if not data.get("default_sugar") in known: return fail("recipes.default_sugar")
 else:
  for pair in [["excellent_a_min","excellent_a_max"],["excellent_b_min","excellent_b_max"],["good_total_min","good_total_max"]]:
   if float(data.timing[pair[0]])>float(data.timing[pair[1]]): return fail("recipes.timing")
 return ActionResult.success()
static func validate_recipes(data: Dictionary) -> ActionResult:
 for field in ["initial_stock","recipes","stations","stock_labels"]:
  if not data.get(field) is Dictionary: return fail("recipes."+field)
 if data.stations.is_empty(): return fail("recipes.stations")
 for id in data.initial_stock:
  if not integer(data.initial_stock[id]) or float(data.initial_stock[id])<0 or not data.stock_labels.get(id) is String: return fail("recipes.initial_stock")
 for id in data.recipes:
  if not data.recipes[id] is Dictionary: return fail("recipes.recipes")
  var result := validate_recipe(data.recipes[id])
  if not result.ok: return result
  if not data.initial_stock.has(data.recipes[id].stock_key): return fail("recipes.stock_key")
 for id in data.stations:
  if not data.stations[id] is Dictionary or not data.recipes.has(data.stations[id].get("recipe_id")): return fail("recipes.stations."+id)
 return ActionResult.success()
