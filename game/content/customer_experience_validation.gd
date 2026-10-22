class_name CustomerExperienceValidation
extends RefCounted
static func validate(data: Dictionary, bundle: Dictionary) -> ActionResult:
 for key in ["weights","environment_weights","sensitivities","categories","labels"]:
  if not data.get(key) is Dictionary:return ContentValidation.fail("customer_experience."+key)
 if not ContentValidation.integer(data.get("window")) or data.window<1 or data.window>100:return ContentValidation.fail("customer_experience.window")
 for key in ["observe_interval","observe_radius","improvement_delta"]:
  if not ContentValidation.bounded(data.get(key),0.01,1000):return ContentValidation.fail("customer_experience."+key)
 if not ContentValidation.bounded(data.get("recovery_floor"),0.01,1) or not data.get("quality_scores") is Array or data.quality_scores.size()!=4:return ContentValidation.fail("customer_experience.scoring")
 for value in data.quality_scores:
  if not ContentValidation.bounded(value,0,100):return ContentValidation.fail("customer_experience.quality")
 for mapping in [data.weights,data.environment_weights]:
  var total := 0.0
  for value in mapping.values():
   if not ContentValidation.bounded(value,0,1):return ContentValidation.fail("customer_experience.weight")
   total+=float(value)
  if total<=0:return ContentValidation.fail("customer_experience.weights")
 for id in data.categories:
  if not bundle.get("items",{}).has(id) or not data.environment_weights.has(data.categories[id]):return ContentValidation.fail("customer_experience.category")
 for id in data.sensitivities:
  if not bundle.visitors.characters.has(id) or not data.sensitivities[id] is Dictionary:return ContentValidation.fail("customer_experience.person")
  for key in data.sensitivities[id]:
   if not data.weights.has(key) or not ContentValidation.bounded(data.sensitivities[id][key],0.01,5):return ContentValidation.fail("customer_experience.sensitivity")
 return ActionResult.success()
