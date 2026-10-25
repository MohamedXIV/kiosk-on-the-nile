class_name ActorPresence
extends RefCounted
## Adapter over distinct visit owners; household actors never enter kiosk rules.
var _session: GameSession
var _profiles: Dictionary={}
func configure(session: GameSession) -> void:
 _session=session
 _profiles=session.config.section("visitors").characters
 _profiles.merge(session.config.section("residential_visits").profiles)
 _profiles.merge(session.config.section("suppliers").profiles)
func actor_ids() -> Array:
 return _profiles.keys()
func profiles() -> Dictionary:
 return _profiles.duplicate(true)
func profile(id: StringName) -> Dictionary:
 var data: Dictionary=_profiles.get(str(id),{}).duplicate(true)
 if not data.is_empty() and _session.tuning!=null:data.name=_session.tuning.display_name(str(id),str(data.name))
 return data
func record(id: Variant) -> Variant:
 if _session.contact!=null and _session.contact.current!=null and str(_session.contact.current.id)==str(id):return _session.contact.current
 if _session.visitors!=null and _session.visitors.visits.has(str(id)):return _session.visitors.visits[str(id)]
 if _session.residential!=null and _session.residential.current!=null and _session.residential.current.id==id:return _session.residential.current
 return null
func is_available(id: StringName) -> bool:
 if _session.contact!=null and _session.contact.current!=null and _session.contact.current.id==id:return _session.contact.available()
 if _session.visitors!=null and _session.visitors.visits.has(str(id)):return _session.visitors.is_available(id)
 var visit: Variant=record(id)
 return visit!=null and visit.phase==&"staying"
func resolve(id: StringName) -> Dictionary:
 var visit: Variant=record(id)
 if visit==null:return {}
 return {"actor_id":str(visit.character_id),"location_id":str(visit.pose.location_id),"ground":[visit.pose.ground.x,visit.pose.ground.y],"available":is_available(id)}
func at(location: StringName) -> Array:
 var result: Array=[]
 if _session.visitors!=null:
  for visit in _session.visitors.visits.values():
   if visit.pose.location_id==location:result.append(visit)
 if _session.residential!=null and _session.residential.current!=null and _session.residential.current.pose.location_id==location:result.append(_session.residential.current)
 return result
func near_actor(id: StringName) -> bool:
 for visit in at(_session.location_id):
  if visit.character_id==id and is_available(visit.id) and visit.pose.ground.distance_to(_session.player_ground)<=float(_session.config.section("spatial").hearing_radius):return true
 return false
func food_id(id: StringName) -> String:
 var visit: VisitState=_session.visitors.visits.get(str(id))
 return str(visit.food_id) if visit!=null else ""

func has(id: Variant) -> bool:
 return record(id)!=null
