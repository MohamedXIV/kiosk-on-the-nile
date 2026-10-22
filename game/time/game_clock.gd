class_name GameClock
extends RefCounted
## Day/minutes preserve the prototype's work-day labels; world_minutes never reverses.
var day: int
var minutes: float
var world_minutes: float
var simulation_seconds: float = 0.0
var tick: int = 0
var _config: Dictionary
func _init(config: Dictionary = {}) -> void:
 _config = config.duplicate(true)
 day = int(config.get("start_day",1))
 minutes = float(config.get("start_minutes",930))
 world_minutes = (day - 1) * 1440.0 + minutes
func advance(delta: float) -> void:
 if delta < 0 or not is_finite(delta): return
 simulation_seconds += delta
 var elapsed := delta * float(_config.get("minutes_per_second",2.5))
 minutes += elapsed
 world_minutes += elapsed
 tick += 1
func next_day() -> void:
 var wake := float(_config.get("wake_minutes",900))
 var sleep_duration := fposmod(wake - fposmod(minutes,1440.0),1440.0)
 if sleep_duration <= 0: sleep_duration = 1440.0
 world_minutes += sleep_duration
 day += 1
 minutes = wake
func frame(delta: float) -> Dictionary:
 return {"delta":delta,"tick":tick,"day":day,"minutes":minutes,"world_minutes":world_minutes,"simulation_seconds":simulation_seconds}
func snapshot() -> Dictionary:
 var value := frame(0)
 value.erase("delta")
 return value
func restore(data: Dictionary) -> ActionResult:
 for key in ["day","minutes","world_minutes","simulation_seconds","tick"]:
  if not typeof(data.get(key)) in [TYPE_FLOAT,TYPE_INT] or not is_finite(float(data[key])) or float(data[key]) < 0:
   return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_clock")
 if not ContentValidation.integer(data.day) or not ContentValidation.integer(data.tick) or int(data.day) < 1: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_day")
 day = int(data.day)
 minutes = float(data.minutes)
 world_minutes = float(data.world_minutes)
 simulation_seconds = float(data.simulation_seconds)
 tick = int(data.tick)
 return ActionResult.success()
