class_name MoodPolicy
extends RefCounted
## Pure, deterministic rules: a save/reload cannot reroll waking or food quality.
var _data: Dictionary
func _init(data: Dictionary) -> void:
 _data = data.duplicate(true)
func sleep_settings() -> Dictionary:
 return _data.sleep.duplicate(true)
func valid_duration(hours: Variant) -> bool:
 return ContentValidation.integer(hours) and float(hours)>=float(_data.sleep.minimum_hours) and float(hours)<=float(_data.sleep.maximum_hours) and (int(hours)-int(_data.sleep.minimum_hours))%int(_data.sleep.step_hours)==0
func oversleep_hours(mood: float, rest: float) -> int:
 for rule in _data.oversleep_rules:
  if mood<float(rule.mood_below) and rest<float(rule.rest_below): return int(rule.extra_hours)
 return 0
func quality_penalty(mood: float) -> int:
 for rule in _data.quality_rules:
  if mood<float(rule.mood_below): return int(rule.penalty)
 return 0
