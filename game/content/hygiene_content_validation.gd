class_name HygieneContentValidation
extends RefCounted
static func validate(data: Dictionary, items: Dictionary) -> ActionResult:
 for field in ["profiles","item_profiles","thresholds","labels","food","sleep"]:
  if not data.get(field) is Dictionary:return ContentValidation.fail("hygiene."+field)
 if not data.profiles.has("floor"):return ContentValidation.fail("hygiene.floor")
 for profile in data.profiles.values():
  if not profile is Dictionary or not ContentValidation.bounded(profile.get("clean_minutes"),0.01,1440) or not ContentValidation.bounded(profile.get("dust_per_minute"),0,100) or not profile.get("uses") is Dictionary:return ContentValidation.fail("hygiene.profile")
  for value in profile.uses.values():
   if not ContentValidation.bounded(value,0,100):return ContentValidation.fail("hygiene.use")
 for id in data.item_profiles:
  if not items.has(id) or not data.profiles.has(data.item_profiles[id]):return ContentValidation.fail("hygiene.item")
 if not ContentValidation.bounded(data.thresholds.get("wipe"),0,100) or not ContentValidation.bounded(data.thresholds.get("dirty"),0,data.thresholds.wipe):return ContentValidation.fail("hygiene.threshold")
 if not ContentValidation.bounded(data.food.get("penalty_below"),0,100) or not ContentValidation.integer(data.food.get("max_penalty")) or data.food.max_penalty<0 or data.food.max_penalty>1:return ContentValidation.fail("hygiene.food")
 if not ContentValidation.bounded(data.sleep.get("dirty_below"),0,100) or not ContentValidation.bounded(data.sleep.get("rest_multiplier"),0,1):return ContentValidation.fail("hygiene.sleep")
 return ActionResult.success()
