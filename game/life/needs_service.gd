class_name NeedsService
extends RefCounted
var hunger: float
var rest: float
var mood: float
var baseline: float
var _config: Dictionary
func _init(config: Dictionary = {}) -> void:
 _config = config.duplicate(true)
 hunger = float(config.get("initial",{}).get("hunger",80))
 rest = float(config.get("initial",{}).get("rest",90))
 mood = float(config.get("initial",{}).get("mood",75))
 baseline = float(config.get("initial",{}).get("baseline",70))
func tick(delta: float, kiosk_open: bool) -> void:
 apply_delta(-delta * _config.hunger_decay,-delta * (_config.work_rest_decay if kiosk_open else _config.rest_decay),0)
 if rest < _config.low_rest or hunger < _config.low_hunger:
  apply_delta(0,0,-delta * _config.low_needs_mood_decay)
func apply_delta(hunger_delta: float, rest_delta: float, mood_delta: float) -> void:
 hunger = clampf(hunger + hunger_delta,0,100)
 rest = clampf(rest + rest_delta,0,100)
 mood = clampf(mood + mood_delta,0,100)
func after_sleep(fan_running: bool) -> void:
 var config: Dictionary = _config.sleep
 if fan_running:
  baseline = config.fan_baseline
  rest = config.fan_rest
  mood = maxf(mood,config.fan_mood_floor)
 else:
  rest = config.normal_rest
  mood = maxf(config.normal_mood_floor,(mood + baseline) / 2.0)
 hunger = maxf(config.hunger_floor,hunger - config.hunger_cost)
func snapshot() -> Dictionary:
 return {"hunger":hunger,"rest":rest,"mood":mood,"baseline":baseline}
func restore(data: Dictionary) -> ActionResult:
 for key in ["hunger","rest","mood","baseline"]:
  if not typeof(data.get(key)) in [TYPE_FLOAT,TYPE_INT] or not is_finite(float(data[key])) or float(data[key]) < 0 or float(data[key]) > 100:
   return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_needs")
 hunger = float(data.hunger)
 rest = float(data.rest)
 mood = float(data.mood)
 baseline = float(data.baseline)
 return ActionResult.success()
