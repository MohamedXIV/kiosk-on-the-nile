class_name PassageCoordinator
extends RefCounted
## Transient physical targets only. Domain destinations and saves stay with owners.
var _settings: Dictionary={}
var _clearance: float=0.6
var _contact_distance: float=0.48
var _pairs: Array[Dictionary]=[]
var _waits: Dictionary={}
var _cooldowns: Dictionary={}
var _holds: Dictionary={}
var _revision: int=-1
var _searches: int=0
var _acquisitions: int=0
func configure(settings: Dictionary, clearance: float, contact_distance: float) -> void:
 _settings=settings.duplicate(true);_clearance=clearance;_contact_distance=contact_distance
 clear();_searches=0;_acquisitions=0
func enabled() -> bool:
 return bool(_settings.get("enabled",false))
func clear() -> void:
 _pairs.clear();_waits.clear();_cooldowns.clear();_holds.clear();_revision=-1
func active(id: StringName) -> bool:
 return _holds.has(str(id)) or not _pair(str(id)).is_empty()
func retreating(id: StringName) -> bool:
 var pair := _pair(str(id))
 return not pair.is_empty() and pair.loser==str(id)
func target(id: StringName, original: Vector2) -> Vector2:
 var pair := _pair(str(id))
 return pair.target if not pair.is_empty() and pair.loser==str(id) else original
func route(id: StringName) -> PackedVector2Array:
 var pair := _pair(str(id))
 return pair.route if not pair.is_empty() and pair.loser==str(id) else PackedVector2Array()
func waiting(id: StringName) -> bool:
 var pair := _pair(str(id))
 return _holds.has(str(id)) or (not pair.is_empty() and pair.winner==str(id) and not pair.ready)
func _pair(id: String) -> Dictionary:
 for pair in _pairs:
  if pair.winner==id or pair.loser==id:return pair
 return {}
func forget(id: StringName) -> void:
 for pair in _pairs.duplicate():
  if pair.winner==str(id) or pair.loser==str(id):_release(pair)
 _waits.erase(str(id));_cooldowns.erase(str(id))
 for held in _holds.keys():
  if held==str(id) or _holds[held].peer==str(id):_holds.erase(held)
func _release(pair: Dictionary) -> void:
 for id in [pair.winner,pair.loser]:
  _cooldowns[id]=float(_settings.get("retry_seconds",3.0))
  _waits.erase(id)
 _pairs.erase(pair)
func step(actors: Dictionary, navigation: KioskNavigation, delta: float) -> void:
 if not enabled():return
 if _revision!=navigation.revision:clear();_revision=navigation.revision
 for id in _cooldowns.keys():
  _cooldowns[id]=maxf(0,float(_cooldowns[id])-delta)
  if not actors.has(id) or float(_cooldowns[id])<=0:_cooldowns.erase(id)
 for pair in _pairs.duplicate():
  pair.age=float(pair.age)+delta
  if not actors.has(pair.winner) or not actors.has(pair.loser):_release(pair);continue
  var winner: Dictionary=actors[pair.winner]
  var loser: Dictionary=actors[pair.loser]
  if loser.protected or winner.protected!=pair.protected or winner.goal!=pair.winner_goal or loser.goal!=pair.loser_goal or float(pair.age)>=float(_settings.max_seconds):_release(pair);continue
  # Revalidate the reserved endpoint against newly arrived people/layout changes.
  if not _point_free(pair.target,pair.loser,actors) or navigation.blocked(pair.target):_release(pair);continue
  pair.ready=loser.position.distance_to(pair.target)<=float(_settings.arrival_radius)
  if (winner.position-pair.origin).dot(pair.forward)>_clearance or (not pair.protected and winner.position.distance_to(winner.goal)<=float(_settings.arrival_radius)):_release(pair)
 for id in _holds.keys():
  var hold: Dictionary=_holds[id]
  if not actors.has(id) or not actors.has(hold.peer):_holds.erase(id);continue
  var actor: Dictionary=actors[id]
  if actor.protected or actor.goal!=hold.goal or _blocker(id,actors,navigation,actor.goal-actor.position)!=hold.peer:
   _holds.erase(id);_cooldowns.erase(id);_waits.erase(id)
 var ids := actors.keys();ids.sort()
 for id in ids:
  var actor: Dictionary=actors[id]
  if not _pair(id).is_empty() or actor.protected or not actor.goal.is_finite():_waits.erase(id);continue
  if _cooldowns.has(id):continue
  var remaining: Vector2=actor.goal-actor.position
  if remaining.length()<=float(_settings.arrival_radius):_waits.erase(id);continue
  var peer := _blocker(id,actors,navigation,remaining)
  if peer.is_empty():_waits.erase(id);continue
  var wait: Dictionary=_waits.get(id,{"peer":peer,"seconds":0.0,"distance":remaining.length()})
  if wait.peer!=peer or remaining.length()<float(wait.distance)-float(actor.speed)*float(_settings.delay_seconds)*float(_settings.progress_ratio):wait={"peer":peer,"seconds":0.0,"distance":remaining.length()}
  if _holds.has(id):wait.seconds=float(_settings.delay_seconds)
  wait.seconds=float(wait.seconds)+delta;_waits[id]=wait
  if float(wait.seconds)<float(_settings.delay_seconds):continue
  var other: Dictionary=actors[peer]
  var winner: String=id
  var loser: String=peer
  # Protected people keep their place; otherwise stationary people can step aside.
  if other.protected or (not other.stationary and peer<id):winner=peer;loser=id
  var direction: Vector2=(actors[winner].goal-actors[winner].position).normalized() if actors[winner].goal.is_finite() and not actors[winner].stationary else (actors[loser].position-actors[winner].position).normalized()
  var pocket := _pocket(loser,winner,direction,actors,navigation)
  if pocket.is_empty() and not other.protected and not actor.stationary and not other.stationary:
   var swap := winner;winner=loser;loser=swap
   direction=(actors[winner].goal-actors[winner].position).normalized()
   pocket=_pocket(loser,winner,direction,actors,navigation)
  if pocket.is_empty():
   # With no safe refuge, hold the cached route and retry only on the cooldown.
   # An impossible corridor may remain blocked; never push through its occupant.
   _holds[id]={"peer":peer,"goal":actor.goal}
   if not other.protected and not other.stationary:_holds[peer]={"peer":id,"goal":other.goal}
   _cooldowns[id]=float(_settings.retry_seconds);_cooldowns[peer]=float(_settings.retry_seconds)
   _waits.erase(id);_waits.erase(peer)
   continue
  _pairs.append({"winner":winner,"loser":loser,"origin":actors[loser].position,"forward":direction,"target":pocket.target,"route":pocket.route,"ready":false,"age":0.0,"protected":actors[winner].protected,"winner_goal":actors[winner].goal,"loser_goal":actors[loser].goal})
  _holds.erase(winner);_holds.erase(loser)
  _waits.erase(winner);_waits.erase(loser);_acquisitions+=1
  RuntimePerformance.observe("passage_acquired",0)
func _blocker(id: String, actors: Dictionary, navigation: KioskNavigation, remaining: Vector2) -> String:
 var actor: Dictionary=actors[id]
 var forward := remaining.normalized()
 var closest: float=float(_settings.detect_distance)
 var result := ""
 for peer in actors:
  if peer==id or not _pair(peer).is_empty():continue
  var other: Dictionary=actors[peer]
  var offset: Vector2=other.position-actor.position
  var along := offset.dot(forward)
  if along<=0 or along>remaining.length() or offset.length()>closest:continue
  if absf(offset.cross(forward))>=_clearance or not navigation.sight_clear(actor.position,other.position):continue
  closest=offset.length();result=peer
 return result
func _pocket(loser: String, winner: String, forward: Vector2, actors: Dictionary, navigation: KioskNavigation) -> Dictionary:
 var origin: Vector2=actors[loser].position
 var side := Vector2(-forward.y,forward.x)*(_clearance+float(_settings.pocket_margin))
 var reach := float(_settings.retreat_distance)
 var forward_reach := sqrt(maxf(0,reach*reach-side.length_squared()))
 var candidates: Array[Vector2]=[origin+side,origin-side]
 for scale in [0.5,1.0]:
  for sign_value in [1.0,-1.0]:
   var offset := forward*forward_reach*float(scale)*float(sign_value)
   candidates.append(origin+offset+side);candidates.append(origin+offset-side)
 for index in range(mini(candidates.size(),int(_settings.candidate_limit))):
  var point := candidates[index]
  if origin.distance_to(point)>reach or not _point_free(point,loser,actors) or navigation.blocked(point):continue
  var lane_end: Vector2=actors[winner].position+forward*(actors[winner].position.distance_to(origin)+_clearance)
  if Geometry2D.get_closest_point_to_segment(point,actors[winner].position,lane_end).distance_to(point)<_clearance:continue
  _searches+=1
  RuntimePerformance.observe("passage_path",0)
  var route := navigation.path(origin,point)
  if route.is_empty() or route[route.size()-1].distance_to(point)>float(_settings.arrival_radius):continue
  # The nearest grid center may lead back into a person. Skip it only through
  # a clear static/person segment, then retain this exact validated route.
  while route.size()>1 and navigation.walkable_segment(origin,route[1]) and _segment_free(origin,route[1],loser,actors):route.remove_at(0)
  var previous := origin
  var distance: float=0
  var safe := true
  for waypoint in route:
   distance+=previous.distance_to(waypoint)
   if distance>float(_settings.route_distance) or not navigation.walkable_segment(previous,waypoint) or not _segment_free(previous,waypoint,loser,actors):safe=false;break
   previous=waypoint
  if safe:return {"target":point,"route":route}
 return {}
func _point_free(point: Vector2, except_id: String, actors: Dictionary) -> bool:
 for id in actors:
  if id!=except_id and point.distance_to(actors[id].position)<_clearance:return false
 for pair in _pairs:
  if pair.loser!=except_id and point.distance_to(pair.target)<_clearance:return false
 return true
func _segment_free(start: Vector2, goal: Vector2, except_id: String, actors: Dictionary) -> bool:
 for id in actors:
  if id==except_id:continue
  var point: Vector2=actors[id].position
  # Existing near contacts may escape, never deepen overlap along the retreat.
  var limit := minf(_contact_distance,start.distance_to(point))
  if Geometry2D.get_closest_point_to_segment(point,start,goal).distance_to(point)<limit-0.001:return false
 return true
func status() -> Dictionary:
 return {"active":_pairs.size(),"holding":_holds.size(),"searches":_searches,"acquisitions":_acquisitions}
