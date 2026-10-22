class_name ItemContentValidation
extends RefCounted
static func validate(definitions: Dictionary, containers: Dictionary) -> ActionResult:
 if definitions.is_empty() or containers.is_empty(): return ContentValidation.fail("items.empty")
 for id in definitions:
  var value: Variant = definitions[id]
  if not value is Dictionary or not value.get("kind") in ["ingredient","prepared","furniture","equipment","batch"] or not value.get("label") is String: return ContentValidation.fail("items."+str(id))
 for id in containers:
  var value: Variant = containers[id]
  if not value is Dictionary or value.get("id")!=id or not value.get("location_id") is String or not value.get("kind") is String or not value.get("host_id") is String or not ContentValidation.integer(value.get("capacity")) or value.capacity<1 or not value.get("allowed_tags") is Array or value.allowed_tags.is_empty(): return ContentValidation.fail("containers."+str(id))
 return ActionResult.success()
