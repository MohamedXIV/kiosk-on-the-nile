class_name NpcAvoidanceWorld
extends Node
## Native RVO-only map in ground units. Grid paths/physics stay with their owners.
var _settings: Dictionary={}
var _navigation: KioskNavigation
var _map := RID()
var _actors: Dictionary={}
var _passing := LocalPassingPolicy.new()
var _delta: float=0.0166666667
var _updates: int=0
func configure(navigation: KioskNavigation, settings: Dictionary) -> void:
 _clear()
 _navigation=navigation;_settings=settings.duplicate(true);_passing.configure(settings)
 if not enabled():return
 _map=NavigationServer2D.map_create()
 NavigationServer2D.map_set_active(_map,true)
func enabled() -> bool:
 return bool(_settings.get("enabled",false))
func begin_step(delta: float) -> void:
 _delta=maxf(delta,0.000001)
 for actor: Dictionary in _actors.values():actor.age=float(actor.age)+delta
func sync(id: StringName, point: Vector2, stationary: bool, speed: float, external: bool=false, goal: Vector2=Vector2(INF,INF)) -> void:
 if not enabled():return
 var key := str(id)
 if not _actors.has(key):
  var rid := NavigationServer2D.agent_create()
  _actors[key]={"rid":rid,"position":point,"actual":Vector2.ZERO,"desired":Vector2.ZERO,"safe":Vector2.ZERO,"sample_input":Vector2.ZERO,"age":INF,"stationary":stationary,"external":external,"speed":speed,"goal":goal}
  NavigationServer2D.agent_set_map(rid,_map)
  NavigationServer2D.agent_set_radius(rid,float(_settings.radius))
  NavigationServer2D.agent_set_neighbor_distance(rid,float(_settings.neighbor_distance))
  NavigationServer2D.agent_set_max_neighbors(rid,int(_settings.max_neighbors))
  NavigationServer2D.agent_set_time_horizon_agents(rid,float(_settings.time_horizon_agents))
  NavigationServer2D.agent_set_time_horizon_obstacles(rid,0.5)
  NavigationServer2D.agent_set_avoidance_enabled(rid,true)
  if not external:NavigationServer2D.agent_set_avoidance_callback(rid,_computed.bind(id))
 var actor: Dictionary=_actors[key]
 var motion: Vector2=(point-actor.position)/_delta
 if point.distance_to(actor.position)>speed*_delta*4.0+float(_settings.radius)*2.0:
  motion=Vector2.ZERO;actor.age=INF;actor.safe=Vector2.ZERO;actor.sample_input=Vector2.ZERO
  _passing.forget(id)
  NavigationServer2D.agent_set_velocity_forced(actor.rid,Vector2.ZERO)
 if stationary and not actor.stationary:NavigationServer2D.agent_set_velocity_forced(actor.rid,Vector2.ZERO)
 actor.position=point;actor.actual=Vector2.ZERO if stationary else motion.limit_length(speed);actor.stationary=stationary;actor.speed=speed
 actor.goal=goal
 NavigationServer2D.agent_set_position(actor.rid,point)
 NavigationServer2D.agent_set_max_speed(actor.rid,0.0 if stationary and not external else speed)
 NavigationServer2D.agent_set_avoidance_priority(actor.rid,1.0 if stationary or external else 0.5)
 if stationary or external:
  actor.desired=actor.actual if external else Vector2.ZERO
  NavigationServer2D.agent_set_velocity(actor.rid,actor.desired)
  if external:NavigationServer2D.agent_set_velocity_forced(actor.rid,actor.actual)
func tune_motor(motor: ActorMotor, id: StringName) -> void:
 if not enabled():return
 motor.motion_filter=steer.bind(id)
 motor.detour_skip_distance=float(_settings.path_skip_distance)
 motor.dynamic_wait_limit=float(_settings.max_wait_seconds)
func steer(desired: Vector2, delta: float, id: StringName) -> Vector2:
 var started := RuntimePerformance.begin()
 var result := _steer(desired,delta,id)
 RuntimePerformance.finish("avoidance_steer",started)
 return result
func _steer(desired: Vector2, delta: float, id: StringName) -> Vector2:
 if not enabled():return desired
 if not _actors.has(str(id)):return Vector2.ZERO
 var actor: Dictionary=_actors[str(id)]
 if actor.stationary or desired.is_zero_approx():
  _passing.stop(id)
  actor.desired=Vector2.ZERO
  actor.stationary=true
  NavigationServer2D.agent_set_max_speed(actor.rid,0.0)
  NavigationServer2D.agent_set_avoidance_priority(actor.rid,1.0)
  NavigationServer2D.agent_set_velocity(actor.rid,Vector2.ZERO)
  return Vector2.ZERO
 var peer := _passing.conflict(id,desired,_actors,_navigation)
 var preferred := desired if peer==&"" else _passing.preferred(id,desired,peer,_actors,_navigation)
 actor.desired=preferred
 NavigationServer2D.agent_set_velocity(actor.rid,preferred)
 # No nearby predicted conflict needs no solver delay or static-path distortion.
 if peer==&"":return desired
 if float(actor.age)>float(_settings.sample_age_seconds) or actor.sample_input.is_zero_approx():return Vector2.ZERO
 if actor.sample_input.normalized().dot(preferred.normalized())<0.25:return Vector2.ZERO
 var safe: Vector2=actor.safe.limit_length(desired.length())
 if not _navigation.walkable_segment(actor.position,actor.position+safe*delta):return Vector2.ZERO
 return safe
func _computed(velocity: Vector2, id: StringName) -> void:
 if not _actors.has(str(id)):return
 var actor: Dictionary=_actors[str(id)]
 actor.safe=velocity;actor.sample_input=actor.desired;actor.age=0.0
 _updates+=1
 RuntimePerformance.observe("avoidance_sample",0)
func remove_actor(id: StringName) -> void:
 var key := str(id)
 if not _actors.has(key):return
 var actor: Dictionary=_actors[key]
 NavigationServer2D.agent_set_avoidance_callback(actor.rid,Callable())
 NavigationServer2D.free_rid(actor.rid)
 _actors.erase(key)
 _passing.forget(id)
func status() -> Dictionary:
 return {"enabled":enabled(),"agents":_actors.size(),"map_valid":_map.is_valid(),"samples":_updates}
func _clear() -> void:
 for id in _actors.keys():remove_actor(StringName(id))
 if _map.is_valid():NavigationServer2D.free_rid(_map);_map=RID()
func _exit_tree() -> void:
 _clear()
func _notification(what: int) -> void:
 if what==NOTIFICATION_PREDELETE:_clear()
