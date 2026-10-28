class_name HospitalityContentValidation
extends RefCounted
static func validate(bundle: Dictionary) -> ActionResult:
 var visitors: Dictionary=bundle.get("visitors",{})
 if not visitors.has("hospitality"):return ActionResult.success()
 var data: Variant=visitors.hospitality
 if not data is Dictionary or not data.get("enabled") is bool or not data.get("actors") is Dictionary or data.actors.size()>4:return ContentValidation.fail("visitors.hospitality")
 for id in data.actors:
  var record: Variant=data.actors[id]
  if not visitors.get("characters",{}).has(id) or not record is Dictionary or not ContentValidation.integer(record.get("minimum_visits")) or record.minimum_visits<1 or record.minimum_visits>100:return ContentValidation.fail("visitors.hospitality.actor")
 return ActionResult.success()
