class_name LocalPassingPolicy
extends RefCounted
## Local preferences only; never changes a route, actor pose or domain goal.
var _settings: Dictionary={}
var _contacts: Dictionary={}
var _revision: int=-1
func configure(settings: Dictionary) -> void:
 _settings=settings.duplicate(true)
 _contacts.clear();_revision=-1
func conflict(id: StringName, desired: Vector2, actors: Dictionary, navigation: KioskNavigation) -> StringName:
 var actor: Dictionary=actors[str(id)]
 if _revision!=navigation.revision:_contacts.clear();_revision=navigation.revision
 var contact: Dictionary=_contacts.get(str(id),{})
 if not contact.is_empty():
  var peer: String=contact.peer
  if actors.has(peer):
   var offset: Vector2=actor.position-actors[peer].position
   if offset.length()<=float(_settings.neighbor_distance) and offset.dot(contact.forward)<float(_settings.radius)*2.0+float(_settings.passing_margin) and desired.normalized().dot(contact.forward)>-0.25 and navigation.sight_clear(actor.position,actors[peer].position):return StringName(peer)
  _contacts.erase(str(id))
 var closest: float=INF
 var result := &""
 for other_id in actors:
  if other_id==str(id):continue
  var other: Dictionary=actors[other_id]
  var offset: Vector2=other.position-actor.position
  var distance := offset.length()
  if distance>float(_settings.neighbor_distance) or distance>=closest:continue
  var relative: Vector2=desired-other.actual
  var horizon: float=0
  var lookahead := float(_settings.conflict_lookahead)
  var goal: Vector2=actor.get("motion_goal",actor.goal)
  if goal.is_finite():lookahead=minf(lookahead,actor.position.distance_to(goal)/maxf(desired.length(),0.001))
  if relative.length_squared()>0.00001:horizon=clampf(offset.dot(relative)/relative.length_squared(),0,lookahead)
  var separation := (offset-relative*horizon).length()
  if separation>float(_settings.radius)*2.0+float(_settings.passing_margin):continue
  if not navigation.sight_clear(actor.position,other.position):continue
  closest=distance;result=StringName(other_id)
 return result
func preferred(id: StringName, desired: Vector2, peer: StringName, actors: Dictionary, navigation: KioskNavigation) -> Vector2:
 var actor: Dictionary=actors[str(id)]
 var other: Dictionary=actors[str(peer)]
 if not _contacts.has(str(id)):
  var direction := desired.normalized()
  var side := Vector2(-direction.y,direction.x)
  if actor.position.distance_to(other.position)<0.01 and str(id)>str(peer):side=-side
  _contacts[str(id)]={"peer":str(peer),"forward":direction,"side":side}
 var contact: Dictionary=_contacts[str(id)]
 var clearance := float(_settings.radius)*2.0+float(_settings.passing_margin)
 var target: Vector2=other.position+contact.side*clearance+contact.forward*(clearance+float(_settings.passing_margin))
 var preferred: Vector2=actor.position.direction_to(target)*desired.length()
 if navigation.walkable_segment(actor.position,actor.position+preferred.normalized()*0.4):return preferred
 return desired
func forget(id: StringName) -> void:
 _contacts.erase(str(id))
 for other in _contacts.keys():
  if _contacts[other].peer==str(id):_contacts.erase(other)
func stop(id: StringName) -> void:
 _contacts.erase(str(id))
