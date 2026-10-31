class_name CharacterLifeValidation
extends RefCounted
const NEEDS := ["hunger","thirst","tiredness","social"]
static func validate(data: Dictionary, actors: Array, foods: Dictionary) -> ActionResult:
 if not keys(data,["policy","profiles"]) or not data.policy is Dictionary or not data.profiles is Dictionary:return _fail("shape")
 var policy: Dictionary=data.policy
 if not keys(policy,["seed","reconsider_minutes","quiet_weight","elapsed_cap_minutes","rates","company_stay_multiplier","rest_stay_multiplier","company_invite_rate"]):return _fail("policy")
 if not ContentValidation.integer(policy.seed) or policy.seed<0 or not ContentValidation.bounded(policy.reconsider_minutes,5,180) or not ContentValidation.bounded(policy.quiet_weight,0.1,10) or not ContentValidation.bounded(policy.elapsed_cap_minutes,60,1440) or not policy.rates is Dictionary or not keys(policy.rates,NEEDS):return _fail("policy.values")
 if not ContentValidation.bounded(policy.company_stay_multiplier,1,1.25) or not ContentValidation.bounded(policy.rest_stay_multiplier,0.7,1) or not ContentValidation.bounded(policy.company_invite_rate,1,1.5):return _fail("policy.intent_bias")
 for need in NEEDS:
  if not ContentValidation.bounded(policy.rates[need],0,1):return _fail("policy.rates."+need)
 if data.profiles.size()!=actors.size():return _fail("profiles.actors")
 for actor in actors:
  var profile: Variant=data.profiles.get(actor)
  if not profile is Dictionary or not keys(profile,["buying_enabled","food_weights","category_weights","temperature_weights","spice_preference","spice_limit","preferred_window","thermal_affinity","price_sensitivity","spend_limit_minor","initial"]):return _fail("profiles."+str(actor))
  if not ContentValidation.integer(profile.spend_limit_minor) or not ContentValidation.bounded(profile.spend_limit_minor,0,MenuService.LIMIT):return _fail("profiles.spending")
  if not profile.buying_enabled is bool or not profile.food_weights is Dictionary or not profile.category_weights is Dictionary or not keys(profile.category_weights,["drink","meal","snack"]) or not profile.temperature_weights is Dictionary or not keys(profile.temperature_weights,["hot","cold","ambient"]):return _fail("profiles.weights")
  for food in profile.food_weights:
   if not foods.has(food) or not ContentValidation.bounded(profile.food_weights[food],0,20):return _fail("profiles.food_weights")
  for field in ["category_weights","temperature_weights"]:
   for weight in profile[field].values():
    if not ContentValidation.bounded(weight,0,3):return _fail("profiles."+field)
  if not ContentValidation.vector(profile.spice_preference,2) or not ContentValidation.bounded(profile.spice_preference[0],0,1) or not ContentValidation.bounded(profile.spice_preference[1],profile.spice_preference[0],1) or not ContentValidation.bounded(profile.spice_limit,profile.spice_preference[1],1):return _fail("profiles.spice")
  if not ContentValidation.vector(profile.preferred_window,2) or not ContentValidation.bounded(profile.preferred_window[0],0,1439) or not ContentValidation.bounded(profile.preferred_window[1],profile.preferred_window[0]+1,1440):return _fail("profiles.window")
  if not profile.thermal_affinity in ["neutral","warm","cool"] or not ContentValidation.bounded(profile.price_sensitivity,0,3) or not profile.initial is Dictionary or not keys(profile.initial,NEEDS):return _fail("profiles.traits")
  for need in NEEDS:
   var bounds: Variant=profile.initial[need]
   if not ContentValidation.vector(bounds,2) or not ContentValidation.bounded(bounds[0],0,1) or not ContentValidation.bounded(bounds[1],bounds[0],1):return _fail("profiles.initial."+need)
 for food in foods:
  var d: Dictionary=foods[food]
  if not d.get("category") in ["drink","meal","snack"] or not d.get("temperature") in ["hot","cold","ambient"] or not ContentValidation.bounded(d.get("spice"),0,1) or not ContentValidation.bounded(d.get("satiation"),0,1) or not ContentValidation.bounded(d.get("hydration"),0,1):return _fail("foods."+food)
 return ActionResult.success()
static func keys(data: Dictionary, expected: Array) -> bool:
 return data.size()==expected.size() and expected.all(func(key):return data.has(key))
static func _fail(path: String) -> ActionResult:
 return ContentValidation.fail("character_life."+path)
