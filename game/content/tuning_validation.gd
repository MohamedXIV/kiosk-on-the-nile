class_name TuningValidation
extends RefCounted
const KEYS := ["clock_speed","hunger_decay","rest_decay","low_needs_mood_decay","fatigue_warning","focus_denial","absolute_floor","hunger_denial","mood_threshold","refusal_probability","refusal_cooldown","refusal_daily_cap","blur_warning_min","blur_warning_max","blur_severe_min","blur_severe_max","blur_duration","blur_strength"]
static func validate(bundle: Dictionary) -> ActionResult:
 var spec: Dictionary=bundle.get("tuning",{})
 if not spec.get("dev_panel_enabled") is bool or not spec.get("fields") is Dictionary or spec.fields.size()!=KEYS.size():return _fail()
 for key in KEYS:
  var field: Variant=spec.fields.get(key)
  if not field is Dictionary or not ContentValidation.number(field.get("minimum")) or not ContentValidation.number(field.get("maximum")) or not ContentValidation.bounded(field.get("default"),field.minimum,field.maximum) or not field.get("unit") is String:return _fail()
 var policy: Dictionary=bundle.get("action_policy",{})
 var classes := ["personal_focus","practical_talk","cooking_for_self","commercial_preparation","ordinary_effort","eating","supply_access","return_home","sleep","payment","help"]
 if not policy.get("classes") is Dictionary or policy.classes.size()!=classes.size() or not policy.get("effort") is Dictionary:return _fail()
 for key in classes:
  var rule: Variant=policy.classes.get(key)
  if not rule is Dictionary:return _fail()
  for flag in ["focus","hunger","refusal"]:
   if not rule.get(flag) is bool:return _fail()
  if key in ["practical_talk","cooking_for_self","eating","supply_access","return_home","sleep","payment","help"] and (rule.focus or rule.hunger or rule.refusal):return _fail()
 if policy.classes.personal_focus.hunger:return _fail()
 for kind in ["preparation","cleaning","arranging"]:
  if not policy.effort.get(kind) is Dictionary:return _fail()
  for key in ["rest","mood"]:
   if not ContentValidation.bounded(policy.effort[kind].get(key),0,10):return _fail()
 var c: Variant=policy.get("caffeine")
 if not c is Dictionary or not c.get("foods") is Dictionary or not c.get("multipliers") is Array or c.multipliers.is_empty():return _fail()
 var previous := 1.0
 for multiplier in c.multipliers:
  if not ContentValidation.bounded(multiplier,0,previous):return _fail()
  previous=float(multiplier)
 for key in ["window_minutes","reset_sleep_hours","maximum_boost","maximum_exemption_minutes"]:
  if not ContentValidation.bounded(c.get(key),0.01,1440):return _fail()
 for food in c.foods:
  if not bundle.get("foods",{}).has(food) or not c.foods[food] is Dictionary:return _fail()
  for key in ["boost","duration_minutes"]:
   if not ContentValidation.bounded(c.foods[food].get(key),0.01,1440):return _fail()
 return ActionResult.success()
static func values_valid(values: Dictionary) -> bool:
 return values.absolute_floor<values.focus_denial and values.focus_denial<values.fatigue_warning and values.blur_warning_min<=values.blur_warning_max and values.blur_severe_min<=values.blur_severe_max and values.blur_duration<values.blur_severe_min and ContentValidation.integer(values.refusal_daily_cap) and ContentValidation.bounded(values.clock_speed,0.1,10) and ContentValidation.bounded(values.blur_strength,0,1) and values.blur_warning_max<=30 and values.blur_severe_max<=15 and values.blur_duration<=1.5
static func _fail() -> ActionResult:
 return ContentValidation.fail("tuning_or_action_policy")
