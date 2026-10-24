class_name ResidentialVisits
extends RefCounted
var current: ResidentialRecord
var _session: GameSession
var _data: Dictionary
var _next: int=1
var _scheduled: float=-1
var _retry_at: float=0
func configure(session: GameSession) -> void:
 _session=session
 _data=session.config.section("residential_visits")
func clear() -> void:
 if current!=null:
  if _session.personal!=null and _session.personal.holds_visit(current.id):_session.personal.leave()
  if _session.narrative!=null:
   for chapter: ConversationSession in _session.narrative.sessions.values():
    if str(current.id) in chapter.participants:_session.narrative.cancel(chapter.id)
 current=null
 _scheduled=-1
func tick(_frame: Dictionary) -> void:
 if _session.location_id!=&"rooftop":clear();return
 var now := _session.clock.world_minutes
 if current!=null:
  if current.phase==&"arriving" and current.pose.ground.distance_to(current.destination)<0.15:
   current.phase=&"staying";current.arrived_at=now
  if current.phase==&"staying" and not current.greeted and now-current.arrived_at>=float(_data.greet_delay_minutes) and _session.presence.near_actor(&"abdul_karim") and not _session.personal.active() and _session.narrative.focused_session()==null and not (_session.social_life.participation_blocked.is_valid() and _session.social_life.participation_blocked.call()):_greet(current)
  if current.phase==&"staying" and not _session.narrative.speech_active(current.id) and (now-current.arrived_at>=float(_data.stay_minutes) or _session.clock.minutes>float(_data.window[1])):
   current.phase=&"leaving";current.destination=Vector2(_data.entrance[0],_data.entrance[1])
  if current.phase==&"leaving" and current.pose.ground.distance_to(current.destination)<0.15:
   current=null;_retry_at=now+float(_data.return_minutes)
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
 return {"current":current.snapshot() if current!=null else {},"next_id":_next,"scheduled":_scheduled,"retry_at":_retry_at}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("current") is Dictionary or not ContentValidation.integer(data.get("next_id")) or data.next_id<1 or not ContentValidation.bounded(data.get("scheduled"),-1,_session.clock.world_minutes+1440) or not ContentValidation.bounded(data.get("retry_at"),0,_session.clock.world_minutes+1440):return _fail()
 var candidate: ResidentialRecord
 if not data.current.is_empty():
  var record: Dictionary=data.current
  var suffix := str(record.get("id","")).trim_prefix("residential_")
  if not record.get("greeted") is bool or _session.location_id!=&"rooftop" or not str(record.get("id","")).begins_with("residential_") or not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=int(data.next_id) or record.get("character_id")!="abdul_karim" or not record.get("phase") in ["arriving","staying","leaving"] or not record.get("pose") is Dictionary or not ContentValidation.vector(record.get("destination"),2) or not ContentValidation.bounded(record.get("arrived_at"),-1,_session.clock.world_minutes):return _fail()
  candidate=ResidentialRecord.new()
  if not candidate.pose.restore(record.pose).ok or candidate.pose.location_id!=&"rooftop" or FootprintGeometry.blocked(candidate.pose.ground,_session.spaces.solids(&"rooftop"),0.05):return _fail()
  candidate.id=StringName(record.id);candidate.phase=StringName(record.phase);candidate.destination=Vector2(record.destination[0],record.destination[1]);candidate.arrived_at=float(record.arrived_at);candidate.greeted=bool(record.greeted)
 current=candidate;_next=int(data.next_id);_scheduled=float(data.scheduled);_retry_at=float(data.retry_at)
 return ActionResult.success()
func _fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_residential_presence")

func _greet(record: ResidentialRecord) -> void:
 record.greeted=true
 var result := await _session.personal.open_for(record.id)
 if result.ok and _session.personal.holds_visit(record.id) and _session.personal.view().get("conversation")==null:result=await _session.personal.select_topic("landlord")
 if not result.ok and current==record:record.greeted=false
