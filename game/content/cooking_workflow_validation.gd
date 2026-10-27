class_name CookingWorkflowValidation
extends RefCounted
static func validate_equipment(data: Dictionary, items: Dictionary) -> ActionResult:
 for id in data:
  var value: Variant=data[id]
  if not items.has(id) or not value is Dictionary or not value.get("capabilities") is Array or not value.get("resource_group") is String or not ContentValidation.integer(value.get("capacity")) or value.capacity<1 or not value.get("enabled_by_default") is bool:return ContentValidation.fail("equipment."+id)
  if not value.get("retired_capabilities",[]) is Array:return ContentValidation.fail("equipment.retired_capabilities")
  for capability in value.capabilities+value.get("retired_capabilities",[]):
   if not capability in ["heat_water","griddle","fry","bake","roast_rotisserie","cold_storage","prep_surface"]:return ContentValidation.fail("equipment.capability")
 return ActionResult.success()
static func validate_recipes(recipes: Dictionary, items: ItemStore) -> ActionResult:
 if recipes.is_empty():return ContentValidation.fail("recipe_workflows.empty")
 for id in recipes:
  var recipe: Variant=recipes[id]
  if not recipe is Dictionary or not ContentValidation.integer(recipe.get("version")) or recipe.version<1 or not recipe.get("label") is String or not recipe.get("inputs") is Array or not recipe.get("steps") is Array or recipe.steps.is_empty() or not recipe.get("quality_keys") is Array or recipe.quality_keys.size()!=4:return ContentValidation.fail("recipe_workflows."+id)
  if recipe.has("allowed_locations"):
   if not recipe.allowed_locations is Array:return ContentValidation.fail("recipe_workflows.allowed_locations")
   for location in recipe.allowed_locations:
    if not location is String or location.is_empty():return ContentValidation.fail("recipe_workflows.allowed_location")
  if recipe.has("vessel_definition"):
   if items.definition(StringName(str(recipe.vessel_definition))).get("kind")!="batch" or items.definition(StringName(str(recipe.get("filling_definition","")))).get("kind")!="ingredient" or not ContentValidation.integer(recipe.get("portions")) or recipe.portions<1 or not ContentValidation.bounded(recipe.get("slice_minutes"),0.01,1440):return ContentValidation.fail("recipe_workflows.batch")
  if not recipe.get("output") is Dictionary or not recipe.output.get("food_id") is String:return ContentValidation.fail("recipe_workflows.output")
  if recipe.get("quality",{}).get("kind")=="two_sides":
   for field in ["burnt_after","excellent_a_min","excellent_a_max","excellent_b_min","excellent_b_max","good_total_min","good_total_max"]:
    if not ContentValidation.number(recipe.quality.get(field)) or recipe.quality[field]<0:return ContentValidation.fail("recipe_workflows.quality")
  for input in recipe.inputs:
   if not input is Dictionary or items.definition(StringName(str(input.get("definition_id","")))).is_empty() or not ContentValidation.integer(input.get("quantity")) or input.quantity<1:return ContentValidation.fail("recipe_workflows.inputs")
  var known: Dictionary={}
  for step in recipe.steps:
   if not step is Dictionary or not step.get("id") is String or known.has(step.id) or not step.get("kind") in ["heat","brew","wait","prepare","assemble","pour","flip","season","cold_wait","batch_heat"] or not step.get("capability") is String or not step.get("action") is String or not step.get("label") is String or not ContentValidation.number(step.get("duration")) or step.duration<0 or not step.get("after",[]) is Array:return ContentValidation.fail("recipe_workflows.step")
   for dependency in step.get("after",[]):
    if not known.has(dependency):return ContentValidation.fail("recipe_workflows.dependency_cycle")
   known[step.id]=true
   for field in ["good_until","okay_until","burnt_after"]:
    if step.has(field) and (not ContentValidation.number(step[field]) or step[field]<step.duration):return ContentValidation.fail("recipe_workflows.window")
 return ActionResult.success()
