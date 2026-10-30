class_name ItemContentValidation
extends RefCounted
static func validate(definitions: Dictionary, containers: Dictionary) -> ActionResult:
 if definitions.is_empty() or containers.is_empty(): return ContentValidation.fail("items.empty")
 for id in definitions:
  var value: Variant = definitions[id]
  if not value is Dictionary or not value.get("kind") in ["ingredient","prepared","furniture","equipment","batch"] or not value.get("label") is String: return ContentValidation.fail("items."+str(id))
  if value.kind in ["furniture","equipment"]:
   var policy: Variant=value.get("placement")
   if not policy is Dictionary or not policy.get("environment") in ["interior","exterior","either"] or not policy.get("allowed_locations") is Array:return ContentValidation.fail("items.placement")
   for location in policy.allowed_locations:
    if not location is String or location=="":return ContentValidation.fail("items.placement_location")
  if value.has("container"):
   var spec: Variant=value.container
   if not spec is Dictionary or not spec.get("kind") in ["cold","dry"] or not ContentValidation.integer(spec.get("capacity")) or spec.capacity<1 or not spec.get("allowed_tags") is Array:return ContentValidation.fail("items.container")
 var lots := IngredientLots.validate_definitions(definitions)
 if not lots.ok:return lots
 for id in containers:
  var value: Variant = containers[id]
  if not value is Dictionary or value.get("id")!=id or not value.get("location_id") is String or not value.get("kind") is String or not value.get("host_id") is String or not ContentValidation.integer(value.get("capacity")) or value.capacity<1 or not value.get("allowed_tags") is Array or value.allowed_tags.is_empty(): return ContentValidation.fail("containers."+str(id))
 return ActionResult.success()
