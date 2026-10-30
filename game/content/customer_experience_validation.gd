class_name CustomerExperienceValidation
extends RefCounted
static func validate(data: Dictionary, bundle: Dictionary) -> ActionResult:
 if not ContentValidation.bounded(data.get("comment_global_minutes"),30,1440) or not ContentValidation.bounded(data.get("comment_actor_minutes"),30,2880) or not data.get("comment_topics") is Array or not data.get("comment_encounters") is Array or not data.get("comment_suggestions") is Dictionary:return ContentValidation.fail("customer_experience.comments")
 for topic in data.comment_topics:
  if not topic is String or not bundle.get("narrative_policies",{}).get("topics",{}).has(topic):return ContentValidation.fail("customer_experience.comment_topic")
 for encounter in data.comment_encounters:
  if not encounter is String or not bundle.get("encounters",{}).get(encounter,{}).get("semantic_topic") in data.comment_topics:return ContentValidation.fail("customer_experience.comment_encounter")
 for rule in data.comment_suggestions.values():
  if not rule is Dictionary or not CharacterLifeValidation.keys(rule,["food_id","required_food","temperature","minimum_weight","minimum_tastes","label"]) or not rule.label is String or not rule.food_id is String or not bundle.get("foods",{}).has(rule.required_food) or not rule.temperature in ["hot","cold","ambient"] or not ContentValidation.bounded(rule.minimum_weight,0,3) or not ContentValidation.integer(rule.minimum_tastes) or not ContentValidation.bounded(rule.minimum_tastes,1,20):return ContentValidation.fail("customer_experience.suggestion")
 for key in ["weights","environment_weights","sensitivities","categories","labels"]:
  if not data.get(key) is Dictionary:return ContentValidation.fail("customer_experience."+key)
 if not ContentValidation.integer(data.get("window")) or data.window<1 or data.window>100:return ContentValidation.fail("customer_experience.window")
 if not ContentValidation.bounded(data.get("taste_delay_minutes"),1,30):return ContentValidation.fail("customer_experience.taste_delay")
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
