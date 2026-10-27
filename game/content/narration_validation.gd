class_name NarrationValidation
extends RefCounted
static func validate(bundle: Dictionary) -> ActionResult:
 var data: Variant=bundle.get("narration")
 if not data is Dictionary or not data.get("thoughts") is Array:return ContentValidation.fail("narration")
 for field in ["thought_delay_minutes","thought_retry_minutes"]:
  if not ContentValidation.bounded(data.get(field),1,14400):return ContentValidation.fail("narration."+field)
 var ids: Dictionary={}
 for rule in data.thoughts:
  if not rule is Dictionary or not rule.get("id") is String or ids.has(rule.id) or not rule.get("once") is bool or not ContentValidation.bounded(rule.get("cooldown_minutes"),1,14400) or not rule.get("need") in ["","hunger","rest","mood"] or not ContentValidation.bounded(rule.get("below"),0,100) or not rule.get("requires") is Dictionary:return ContentValidation.fail("narration.thought")
  ids[rule.id]=true
 for definition in bundle.get("encounters",{}).values():
  if not definition.get("advancement","automatic") in ["automatic","manual"]:return ContentValidation.fail("encounters.advancement")
 return ActionResult.success()
