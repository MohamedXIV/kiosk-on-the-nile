class_name ResidentialVisits
extends RefCounted
var current: ResidentialRecord
var _session: GameSession
var _data: Dictionary
var _next: int=1
var _scheduled: float=-1
var _retry_at: float=0
var invitation: Dictionary={}
var last_social_day: int=0
func configure(session: GameSession) -> void:
 _session=session
 _data=session.config.section("residential_visits")
func clear() -> void:
 if _session.seat_use!=null:_session.seat_use.release_guest()
 if current!=null:
  if _session.personal!=null and _session.personal.holds_visit(current.id):_session.personal.leave()
  if _session.narrative!=null:
   for chapter: ConversationSession in _session.narrative.sessions.values():
    if str(current.id) in chapter.participants:_session.narrative.cancel(chapter.id)
 current=null
 _scheduled=-1
func tick(_frame: Dictionary) -> void:
 if not invitation.is_empty() and _session.clock.world_minutes>float(invitation.expires):invitation={}
 if _session.location_id!=&"rooftop":clear();return
 var now := _session.clock.world_minutes
 if current!=null:
  if current.phase==&"arriving" and current.pose.ground.distance_to(current.destination)<0.15:
   current.phase=&"staying";current.arrived_at=now
  if current.phase==&"staying" and not current.greeted and now-current.arrived_at>=float(_data.greet_delay_minutes) and _session.presence.near_actor(current.character_id) and not _session.personal.active() and _session.narrative.focused_session()==null and not (_session.social_life.participation_blocked.is_valid() and _session.social_life.participation_blocked.call()):_greet(current)
  if current.phase==&"staying" and not _session.narrative.speech_active(current.id) and (current.depart_requested or now-current.arrived_at>=float(_data.stay_minutes) or _session.clock.minutes>float(_data.window[1])):
   if _session.seat_use!=null:_session.seat_use.release_guest()
   current.phase=&"leaving";current.destination=Vector2(_data.entrance[0],_data.entrance[1])
  if current.phase==&"leaving" and current.pose.ground.distance_to(current.destination)<0.15:
   current=null;_retry_at=now+float(_data.return_minutes)
  return
 if not _session.commitments.agenda() and not invitation.is_empty() and now>=float(invitation.not_before):
  var actor := str(invitation.actor)
  if not _session.social_life.reserved(actor) and not _session.visitors._has_character(StringName(actor)) and _spawn(actor):
   invitation={};last_social_day=_session.clock.day
  return
 if not _session.commitments.agenda() or now<_retry_at or _session.clock.minutes<float(_data.window[0]) or _session.clock.minutes>=float(_data.window[1]):_scheduled=-1;return
 if _scheduled<0:
  var sample := float(("landlord:%d:%d" % [_session.clock.day,_next]).sha256_text().substr(0,8).hex_to_int())/4294967295.0
  _scheduled=now+lerpf(float(_data.arrival_delay_minutes[0]),float(_data.arrival_delay_minutes[1]),sample)
 if now<_scheduled:return
 var point := Vector2(_data.entrance[0],_data.entrance[1])
 var standing := Vector2(_data.standing[0],_data.standing[1])
 var solids := _session.spaces.solids(&"rooftop")
 if _session.player_ground.distance_to(point)<0.8 or FootprintGeometry.blocked(point,solids,0.18) or FootprintGeometry.blocked(standing,solids,0.18):return
 current=ResidentialRecord.new()
 current.id=StringName("residential_%d" % _next);_next+=1
 current.pose.location_id=&"rooftop";current.pose.ground=point;current.destination=standing
 _scheduled=-1
func snapshot() -> Dictionary:
 return {"current":current.snapshot() if current!=null else {},"next_id":_next,"scheduled":_scheduled,"retry_at":_retry_at,"invitation":invitation.duplicate(true),"last_social_day":last_social_day}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("invitation") is Dictionary or not ContentValidation.integer(data.get("last_social_day")) or data.last_social_day<0 or data.last_social_day>_session.clock.day:return _fail()
 if not data.invitation.is_empty():
  var invited: Dictionary=data.invitation
  if not invited.get("actor") in _data.get("social_guests",[]) or not ContentValidation.bounded(invited.get("offered_at"),0,_session.clock.world_minutes) or not ContentValidation.number(invited.get("not_before")) or not ContentValidation.number(invited.get("expires")) or invited.not_before!=(floorf(float(invited.offered_at)/1440.0)+1)*1440.0+float(_data.guest_window[0]) or invited.expires!=(floorf(float(invited.offered_at)/1440.0)+1)*1440.0+float(_data.guest_window[1]):return _fail()
 if not data.get("current") is Dictionary or not ContentValidation.integer(data.get("next_id")) or data.next_id<1 or not ContentValidation.bounded(data.get("scheduled"),-1,_session.clock.world_minutes+1440) or not ContentValidation.bounded(data.get("retry_at"),0,_session.clock.world_minutes+1440):return _fail()
 var candidate: ResidentialRecord
 if not data.current.is_empty():
  var record: Dictionary=data.current
  var suffix := str(record.get("id","")).trim_prefix("residential_")
  if not record.get("depart_requested") is bool or not record.get("greeted") is bool or _session.location_id!=&"rooftop" or not str(record.get("id","")).begins_with("residential_") or not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=int(data.next_id) or not record.get("character_id") in ["abdul_karim"]+_data.get("social_guests",[]) or not record.get("phase") in ["arriving","staying","leaving"] or not record.get("pose") is Dictionary or not ContentValidation.vector(record.get("destination"),2) or not ContentValidation.bounded(record.get("arrived_at"),-1,_session.clock.world_minutes):return _fail()
  candidate=ResidentialRecord.new()
  if not candidate.pose.restore(record.pose).ok or candidate.pose.location_id!=&"rooftop" or FootprintGeometry.blocked(candidate.pose.ground,_session.spaces.solids(&"rooftop"),0.05):return _fail()
  candidate.id=StringName(record.id);candidate.character_id=StringName(record.character_id);candidate.phase=StringName(record.phase);candidate.destination=Vector2(record.destination[0],record.destination[1]);candidate.arrived_at=float(record.arrived_at);candidate.greeted=bool(record.greeted);candidate.depart_requested=bool(record.depart_requested)
 if candidate!=null and candidate.character_id!=&"abdul_karim" and (_session.visitors._has_character(candidate.character_id) or _session.social_life.snapshot().activity.phase=="active"):return _fail()
 current=candidate;_next=int(data.next_id);_scheduled=float(data.scheduled);_retry_at=float(data.retry_at)
 invitation=data.invitation.duplicate(true);last_social_day=int(data.last_social_day)
 return ActionResult.success()
func _fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_residential_presence")

func _greet(record: ResidentialRecord) -> void:
 record.greeted=true
 var result := await _session.personal.open_for(record.id)
 if result.ok and _session.personal.holds_visit(record.id) and _session.personal.view().get("conversation")==null:result=await _session.personal.select_topic("landlord" if record.character_id==&"abdul_karim" else "home/visit")
 if not result.ok and current==record:record.greeted=false

func navigation_alternative(navigation: KioskNavigation) -> bool:
 if current==null:return false
 var key := "exit_alternatives" if current.phase==&"leaving" else "standing_alternatives"
 for point in _data.get(key,[]):
  var target := Vector2(point[0],point[1])
  if target.distance_to(current.destination)<=0.15 or not navigation.reachable(current.pose.ground,target,0.12):continue
  current.destination=target
  return true
 return false

func reserved(actor: String) -> bool:
 return current!=null and str(current.character_id)==actor
func can_invite(visit_id: StringName) -> bool:
 var visit: VisitState=_session.visitors.visits.get(str(visit_id))
 return visit!=null and _session.visitors.is_available(visit_id) and str(visit.character_id) in _data.get("social_guests",[]) and _session.social_life.acquainted(str(visit.character_id),"home") and invitation.is_empty() and last_social_day!=_session.clock.day and not reserved(str(visit.character_id))
func action(id: String, _source: String, speaker: String, participants: PackedStringArray) -> ActionResult:
 if participants.size()!=1:return _fail()
 var person: Variant=_session.presence.record(participants[0])
 if person==null or str(person.character_id)!=speaker:return _fail()
 if id=="invite":
  if not can_invite(person.id):return _fail()
  var now := _session.clock.world_minutes
  invitation={"actor":speaker,"offered_at":now,"not_before":(floorf(now/1440.0)+1)*1440.0+float(_data.guest_window[0]),"expires":(floorf(now/1440.0)+1)*1440.0+float(_data.guest_window[1])}
 elif id=="cancel":
  if invitation.get("actor","")!=speaker:return _fail()
  invitation={}
 elif id=="heard":
  if current==null or current.id!=person.id:return _fail()
  current.greeted=true
 elif id=="goodbye":
  if current==null or current.id!=person.id or current.character_id==&"abdul_karim":return _fail()
  current.depart_requested=true
 else:return _fail()
 return ActionResult.success()
func _spawn(actor: String) -> bool:
 var point := Vector2(_data.entrance[0],_data.entrance[1])
 var standing := Vector2(_data.standing[0],_data.standing[1])
 var solids := _session.spaces.solids(&"rooftop")
 if _session.player_ground.distance_to(point)<0.8 or FootprintGeometry.blocked(point,solids,0.18) or FootprintGeometry.blocked(standing,solids,0.18):return false
 current=ResidentialRecord.new();current.id=StringName("residential_%d" % _next);_next+=1
 current.character_id=StringName(actor);current.pose.location_id=&"rooftop";current.pose.ground=point;current.destination=standing
 return true

func validate_links() -> ActionResult:
 if not invitation.is_empty():
  var actor := str(invitation.actor)
  var introduction: Dictionary=_session.social_life.snapshot().receipts.get("meet_"+actor,{})
  var days := int(_session.config.section("social_life").pacing.home.days)
  if not _session.social_life.acquainted(actor,"home") or introduction.is_empty() or floori(float(invitation.offered_at)/1440.0)-floori(float(introduction.at)/1440.0)<days:return _fail()
 if current!=null and current.character_id!=&"abdul_karim":
  if not _session.social_life.acquainted(str(current.character_id),"home") or _session.visitors._has_character(current.character_id) or _session.social_life.snapshot().activity.phase=="active":return _fail()
 return ActionResult.success()
