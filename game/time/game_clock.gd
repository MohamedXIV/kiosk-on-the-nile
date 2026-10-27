class_name GameClock
extends RefCounted
signal day_changed(previous_day: int, current_day: int)
## One calendar clock; displayed minutes stay within a day and deadlines never reverse.
var day: int
var minutes: float
var world_minutes: float
var simulation_seconds: float = 0.0
var tick: int = 0
var last_world_delta: float=0
var _config: Dictionary
func _init(config: Dictionary = {}) -> void:
 _config = config.duplicate(true)
 var start := float(config.get("start_minutes",930))
 day = int(config.get("start_day",1))+floori(start/1440.0)
 minutes = fposmod(start,1440.0)
 world_minutes = (day-1)*1440.0+minutes
func advance(delta: float) -> void:
 if delta<0 or not is_finite(delta): return
 simulation_seconds += delta
 var elapsed := delta*float(_config.get("minutes_per_second",1.0))
 last_world_delta=elapsed
 var previous := day
 var total := minutes+elapsed
 day += floori(total/1440.0)
 minutes = fposmod(total,1440.0)
 world_minutes += elapsed
 tick += 1
 if day!=previous: day_changed.emit(previous,day)
func elapse_minutes(elapsed: float) -> Dictionary:
 var delta := elapsed/float(_config.get("minutes_per_second",2.5))
 advance(delta)
 return frame(delta)
func frame(delta: float) -> Dictionary:
 return {"delta":delta,"tick":tick,"day":day,"minutes":minutes,"world_minutes":world_minutes,"simulation_seconds":simulation_seconds,"world_delta":last_world_delta}
func snapshot() -> Dictionary:
 var value := frame(0)
 value.erase("delta")
 return value
func restore(data: Dictionary) -> ActionResult:
 for key in ["day","minutes","world_minutes","simulation_seconds","tick"]:
  if not ContentValidation.number(data.get(key)) or float(data[key])<0: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_clock")
 if not ContentValidation.integer(data.day) or not ContentValidation.integer(data.tick) or data.day<1 or data.minutes>=1440: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_day")
 if absf(float(data.world_minutes)-((float(data.day)-1)*1440+float(data.minutes)))>0.001: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"inconsistent_clock")
 day = int(data.day)
 minutes = float(data.minutes)
 world_minutes = float(data.world_minutes)
 simulation_seconds = float(data.simulation_seconds)
 tick = int(data.tick)
 return ActionResult.success()

func set_speed(minutes_per_second: float) -> ActionResult:
 if not ContentValidation.bounded(minutes_per_second,0.1,10):return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_clock_speed")
 _config["minutes_per_second"]=minutes_per_second
 return ActionResult.success()
