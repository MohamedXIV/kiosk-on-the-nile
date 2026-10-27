class_name CharacterIdle
extends RefCounted
## Cosmetic time/randomness only; never writes simulation pose or game RNG.
var breathing: float=0
var gaze := Vector2.ZERO
var blinking: bool=false
var _data: Dictionary={}
var _rng := RandomNumberGenerator.new()
var _phase: float=0
var _period: float=3
var _blink_in: float=0
var _blink_left: float=0
var _look_in: float=0
var _looking: bool=false
var _target := Vector2.ZERO
func configure(data: Dictionary) -> void:
 _data=data.duplicate(true)
 _rng.randomize()
 _phase=_rng.randf_range(0,TAU)
 if not _data.get("enabled",false):return
 _period=_sample("breath_period_seconds")
 _blink_in=_sample("blink_interval_seconds")
 _look_in=_sample("look_interval_seconds")
func advance(delta: float, moving: bool, player: bool) -> void:
 if not _data.get("enabled",false):return
 _phase=fposmod(_phase+delta*TAU/_period,TAU)
 breathing=0.0 if moving else sin(_phase)*float(_data.breath_pixels)
 _blink_left=maxf(0,_blink_left-delta)
 _blink_in-=delta
 if _blink_in<=0:
  _blink_left=_sample("blink_duration_seconds")
  _blink_in=_sample("blink_interval_seconds")
  RuntimePerformance.observe("character_blink",0)
 blinking=_blink_left>0
 if moving or player:
  _target=Vector2.ZERO
 else:
  _look_in-=delta
  if _look_in<=0:
   _looking=not _looking
   _target=Vector2(_rng.randf_range(-1,1),_rng.randf_range(-0.3,0.3))*float(_data.look_pixels) if _looking else Vector2.ZERO
   _look_in=_sample("look_hold_seconds" if _looking else "look_interval_seconds")
 gaze=gaze.lerp(_target,1-exp(-delta*float(_data.look_smoothing)))
func _sample(key: String) -> float:
 return _rng.randf_range(float(_data[key][0]),float(_data[key][1]))
