class_name ContentValidation
extends RefCounted
## Shared runtime/tool validation. Invalid edits never partially activate.
static func validate(bundle: Dictionary) -> ActionResult:
 var time: Dictionary = bundle.get("time",{})
 if not number(time.get("minutes_per_second")) or float(time.minutes_per_second) <= 0: return fail("time.minutes_per_second")
 if bundle.has("balance"):
  var balance: Dictionary = bundle.balance
  var fields := ["starting_money","daily_rent","snack_price","supply_price","supply_tea","supply_kebda","fan_price","tea_price","kebda_price"]
  for key in fields:
   if not integer(balance.get(key)) or float(balance[key]) < 0: return fail("balance."+key)
  if not balance.get("quality_tips") is Array or balance.quality_tips.size() != 4: return fail("balance.quality_tips")
  for tip in balance.quality_tips:
   if not integer(tip) or float(tip) < 0: return fail("balance.quality_tips")
  for key in balance:
   if not key in fields and key != "quality_tips": return fail("balance."+key)
 if bundle.has("needs"):
  var needs: Dictionary = bundle.needs
  for key in ["hunger_decay","work_rest_decay","rest_decay","low_rest","low_hunger","low_needs_mood_decay","river_mood","fan_on_mood","good_service_mood"]:
   if not bounded(needs.get(key),0,100): return fail("needs."+key)
  var groups := {"initial":["hunger","rest","mood","baseline"],"sleep":["fan_baseline","fan_rest","fan_mood_floor","normal_rest","normal_mood_floor","hunger_floor","hunger_cost"],"snack":["hunger","mood"],"tea":["hunger","base_mood","quality_mood"],"kebda":["hunger","base_mood","quality_mood"]}
  for group in groups:
   if not needs.get(group) is Dictionary: return fail("needs."+group)
   for key in groups[group]:
    if not bounded(needs[group].get(key),0,100): return fail("needs."+group+"."+key)
 if bundle.has("social"):
  var social: Dictionary = bundle.social
  for field in ["facts","initial_facts","initial_notes"]:
   if not social.get(field) is Array: return fail("social."+field)
   for value in social[field]:
    if not value is String: return fail("social."+field)
  for fact in social.initial_facts:
   if not fact in social.facts: return fail("social.initial_facts")
  if not social.get("relationship_bounds") is Array or social.relationship_bounds.size() != 2: return fail("social.relationship_bounds")
  if not number(social.relationship_bounds[0]) or not number(social.relationship_bounds[1]) or float(social.relationship_bounds[0]) > float(social.relationship_bounds[1]): return fail("social.relationship_bounds")
  if not social.get("relationship_defaults") is Dictionary: return fail("social.relationship_defaults")
  for axis in ["familiarity","trust"]:
   if not bounded(social.relationship_defaults.get(axis),social.relationship_bounds[0],social.relationship_bounds[1]): return fail("social.relationship_defaults."+axis)
 if bundle.has("spatial"):
  var spatial: Dictionary = bundle.spatial
  for key in ["x_scale","depth_scale","height_scale","player_speed","npc_speed","foot_radius","camera_smoothing"]:
   if not number(spatial.get(key)) or float(spatial[key]) <= 0: return fail("spatial."+key)
  if not bounded(spatial.get("camera_vertical_anchor"),0,1): return fail("spatial.camera_vertical_anchor")
  if not spatial.get("initial_ground") is Array or spatial.initial_ground.size()!=2: return fail("spatial.initial_ground")
  for value in spatial.initial_ground:
   if not number(value): return fail("spatial.initial_ground")
 return ActionResult.success()
static func number(value: Variant) -> bool:
 return typeof(value) in [TYPE_FLOAT,TYPE_INT] and is_finite(float(value))
static func integer(value: Variant) -> bool:
 return number(value) and absf(float(value)) < 9007199254740991.0 and float(value) == floor(float(value))
static func bounded(value: Variant, minimum: float, maximum: float) -> bool:
 return number(value) and float(value) >= minimum and float(value) <= maximum
static func fail(path: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_content",{"path":path})
