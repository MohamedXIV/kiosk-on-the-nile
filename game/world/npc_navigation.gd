class_name NpcNavigation
extends RefCounted
## Transient movement intent; domain owners decide what a failed route means.
var _navigation: KioskNavigation
var _settings: Dictionary={}
var _goal := Vector2.ZERO
var _has_goal: bool=false
var _revision: int=-1
var _path := PackedVector2Array()
var _dirty: bool=true
var _stall: float=0
var _cooldown: float=0
var _attempts: int=0
var _fallbacks: int=0
var _cursor: int=-1
var _best: float=INF
var _failed: bool=false
var _failure_pending: bool=false
func configure(navigation: KioskNavigation, settings: Dictionary) -> void:
 _navigation=navigation
 _settings=settings.duplicate(true)
func invalidate() -> void:
 _has_goal=false
func step(motor: ActorMotor, destination: Vector2, delta: float, paused: bool=false) -> void:
 if not _has_goal or _goal!=destination or _revision!=_navigation.revision:
  if not _has_goal or _revision!=_navigation.revision:_fallbacks=0
  _goal=destination;_has_goal=true;_revision=_navigation.revision
  _dirty=true;_stall=0;_cooldown=0;_attempts=0;_cursor=-1;_best=INF
  _failed=false;_failure_pending=false
  motor.reset_path()
 if paused:
  _stall=0
  motor.step_input(Vector2.ZERO,delta)
  return
 var radius := float(_settings.get("arrival_radius",0.12))
 if motor.pose.ground.distance_to(_goal)<=radius or _failed:
  motor.step_input(Vector2.ZERO,delta)
  return
 if _cooldown>0:
  _cooldown=maxf(0,_cooldown-delta)
  motor.step_input(Vector2.ZERO,delta)
  return
 if _dirty:
  var started := RuntimePerformance.begin()
  _path=_navigation.path(motor.pose.ground,_goal)
  RuntimePerformance.finish("npc_path",started)
  _dirty=false;_cursor=-1;_best=INF
  motor.reset_path()
  if _path.is_empty() or _path[_path.size()-1].distance_to(_goal)>radius:
   motor.step_input(Vector2.ZERO,delta)
   _retry()
   return
 motor.step_path(_path,delta,minf(0.08,radius*0.5))
 var cursor := motor.path_cursor()
 var distance := motor.waypoint_distance()
 if cursor!=_cursor:
  _cursor=cursor;_best=distance;_stall=0
 elif distance<float(_best)-float(_settings.get("progress_distance",0.04)):
  _best=distance;_stall=0
 else:_stall+=delta
 if _settings.get("enabled",false) and _stall>=float(_settings.stall_seconds):_retry()
func _retry() -> void:
 if not _settings.get("enabled",false):return
 if _attempts>=int(_settings.max_replans):
  _failed=true;_failure_pending=true
  RuntimePerformance.observe("npc_route_exhausted",0)
  return
 _attempts+=1;_stall=0;_dirty=true
 _cooldown=float(_settings.replan_cooldown_seconds)
func take_failure() -> bool:
 var pending := _failure_pending
 _failure_pending=false
 return pending
func claim_fallback() -> bool:
 if _fallbacks>=int(_settings.get("max_fallbacks",0)):return false
 _fallbacks+=1
 return true
func status() -> Dictionary:
 return {"fallbacks":_fallbacks,"failed":_failed,"attempts":_attempts,"revision":_revision,"stall_seconds":_stall}
