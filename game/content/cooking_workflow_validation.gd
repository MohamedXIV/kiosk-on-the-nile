class_name CookingWorkflowValidation
extends RefCounted
static func validate_equipment(data: Dictionary, items: Dictionary) -> ActionResult:
 for id in data:
  var value: Variant=data[id]
  if not items.has(id) or not value is Dictionary or not value.get("capabilities") is Array or not value.get("resource_group") is String or not ContentValidation.integer(value.get("capacity")) or value.capacity<1 or not value.get("enabled_by_default") is bool:return ContentValidation.fail("equipment."+id)
  for capability in value.capabilities:
   if not capability in ["heat_water","griddle","fry","bake","roast_rotisserie","cold_storage","prep_surface"]:return ContentValidation.fail("equipment.capability")
 return ActionResult.success()
