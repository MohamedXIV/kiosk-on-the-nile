class_name SocialLife
extends RefCounted
## Owns consented social actions and one authored offscreen activity.
## Transactions validate private knowledge/relationship candidates before publication.
var _session: GameSession
var _data: Dictionary
var _state: Dictionary
var participation_blocked: Callable
func configure(session: GameSession) -> void:
 _session=session
 _data=session.config.section("social_life")
 _state=empty_state()
static func empty_state() -> Dictionary:
 return {"receipts":{},"topic_history":{},"moments":{},"daily":{},"people":{},"invitations":{},"activity":{"phase":"idle","not_before":-1.0,"start_at":-1.0,"end_at":-1.0,"clear_since":-1.0,"outcome":""}}
func done(id: String) -> bool:
 return _state.receipts.has(id)
func available(id: String) -> bool:
 return _available(id,_state)
func _available(id: String, state: Dictionary) -> bool:
 var action: Dictionary=_data.actions.get(id,{})
 if action.is_empty() or state.receipts.has(id):return false
 for required in action.needs:
  if not state.receipts.has(required):return false
 for fact in action.facts:
  if not _session.knowledge.has(StringName(fact)):return false
 return action.phases.is_empty() or state.activity.phase in action.phases
func topic_available(id: String) -> bool:
 var topic: Dictionary=_data.topics.get(id,{})
 if topic.is_empty() or (not topic.phases.is_empty() and not _state.activity.phase in topic.phases):return false
 return available(str(topic.action)) if topic.get("action","")!="" else int(_state.topic_history.get(id,0))!=_session.clock.day and done("consent_farid") and done("consent_youssef") and _state.activity.phase=="coordinating"
func apply(id: String, source: String, speaker: String = "", internal: bool = false) -> ActionResult:
 if not _data.actions.has(id) or (id=="trial_complete" and not internal):return _fail("unknown_social_action")
 if done(id):return ActionResult.success({"duplicate":true})
 var action: Dictionary=_data.actions[id]
 if not _available(id,_state) or (not internal and speaker!=action.actor):return _fail("social_action_unavailable")
 var candidate := _state.duplicate(true)
 var knowledge := KnowledgeBook.new(_session.config.section("social"))
 var result := knowledge.restore(_session.knowledge.snapshot())
 if not result.ok:return result
 var actors: Array=_session.config.section("visitors").characters.keys()+["player"]
 var relationships := RelationshipStore.new(_session.config.section("social"),actors)
 result=relationships.restore(_session.relationships.snapshot())
 if not result.ok:return result
 var now := _session.clock.world_minutes
 candidate.receipts[id]={"at":now,"source":source,"actor":action.actor}
 if not str(action.actor).is_empty():candidate.people[action.actor]=true
 if not str(action.learn).is_empty() and not knowledge.has(StringName(action.learn)):
  knowledge.learn_from(StringName(action.learn),str(action.note),source,str(action.actor),now)
 _moment(candidate,relationships,str(action.moment),str(action.actor),float(action.familiarity),float(action.trust))
 if candidate.receipts.has("consent_farid") and candidate.receipts.has("consent_youssef") and candidate.activity.phase=="idle":candidate.activity.phase="coordinating"
 if id=="trial_complete":
  candidate.activity.phase="completed"
  candidate.activity.outcome="week_trial" if candidate.receipts.has("days_farid") and candidate.receipts.has("days_youssef") else "days_pending"
  for actor in _data.trial.actors:
   for axis in _data.trial.peer_gains[actor]:
    var other: String="youssef" if actor=="farid" else "farid"
    result=relationships.adjust(StringName(actor),StringName(other),StringName(axis),float(_data.trial.peer_gains[actor][axis]))
    if not result.ok:return result
 if candidate.activity.phase=="completed" and candidate.receipts.has("days_farid") and candidate.receipts.has("days_youssef"):candidate.activity.outcome="week_trial"
 result=_validate(candidate)
 if not result.ok:return result
 # These restores have already validated these exact candidates, without signals.
 _session.knowledge.restore(knowledge.snapshot())
 _session.relationships.restore(relationships.snapshot())
 _state=candidate
 return ActionResult.success()
func _moment(state: Dictionary, store: RelationshipStore, key: String, actor: String, familiarity: float, trust: float) -> void:
 if key.is_empty() or actor.is_empty() or state.moments.has(key):return
 state.moments[key]=true
 var day := str(_session.clock.day)
 if not state.daily.has(day):state.daily[day]={}
 var used := float(state.daily[day].get(actor,0))
 var remaining := maxf(0,float(_data.relationships.daily_cap)-used)
 var gain := minf(familiarity,remaining)
 store.adjust(StringName(actor),&"player",&"familiarity",gain)
 store.adjust(StringName(actor),&"player",&"trust",minf(trust,remaining-gain))
 state.daily[day][actor]=used+gain+minf(trust,remaining-gain)
func reserved(actor: String) -> bool:
 return actor in _data.trial.actors and _state.activity.phase in ["scheduled","waiting","active"] and _session.clock.world_minutes>=float(_state.activity.not_before)-float(_data.trial.reservation_lead_minutes)
func _participants_absent() -> bool:
 for visit in _session.visitors.visits.values():
  if str(visit.character_id) in _data.trial.actors:return false
 return true
func tick(_frame: Dictionary) -> ActionResult:
 for id in _state.invitations.keys():
  if not _session.visitors.visits.has(id):_state.invitations.erase(id)
 var activity: Dictionary=_state.activity
 var now := _session.clock.world_minutes
 var absent := _participants_absent()
 if absent:
  if activity.clear_since<0:activity.clear_since=now
 else:activity.clear_since=-1.0
 if activity.phase=="coordinating" and absent:
  activity.not_before=(floorf(now/1440.0)+1)*1440.0+float(_data.trial.appointment_minute)
  activity.phase="scheduled"
 if activity.phase in ["scheduled","waiting"] and now>=float(activity.not_before):
  activity.phase="waiting"
  if absent:
   activity.start_at=maxf(float(activity.not_before),float(activity.clear_since))
   activity.end_at=float(activity.start_at)+float(_data.trial.duration_minutes)
   activity.phase="active"
 if activity.phase=="active" and now>=float(activity.end_at):return apply("trial_complete","workshop/trial", "",true)
 return ActionResult.success()
func before_time_jump() -> void:
 # Called after sleep clears physical visits, before GameClock jumps.
 if _participants_absent() and float(_state.activity.clear_since)<0:_state.activity.clear_since=_session.clock.world_minutes
 tick(_session.clock.frame(0))
func people() -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for actor in _state.people:
  var score := _session.relationships.value(StringName(actor),&"player",&"familiarity")
  var label := ""
  var stage_ref := ""
  for stage in _data.relationships.stages:
   if score>=float(stage.at):label=stage.label;stage_ref=str(stage.get("text_ref",""))
  var connection := ""
  if actor in _data.trial.actors and (_session.knowledge.has(&"WORK_TRIAL_APPOINTMENT") or _session.knowledge.has(&"WORK_TRIAL_RESULT")):connection=("جرّب الشغل مع يوسف" if actor=="farid" else "جرّب الشغل مع فريد") if _session.knowledge.has(&"WORK_TRIAL_RESULT") else ("تواصل مع يوسف لترتيب تجربة" if actor=="farid" else "تواصل مع فريد لترتيب تجربة")
  result.append({"actor_id":str(actor),"name":_session.visitors.character(StringName(actor)).name,"score":score,"stage":label,"stage_ref":stage_ref,"connection":connection})
 return result
func heard(actor: String) -> void:
 if _session.config.section("visitors").characters.has(actor):_state.people[actor]=true
func snapshot() -> Dictionary:
 return _state.duplicate(true)
func restore(data: Dictionary) -> ActionResult:
 var result := _validate(data)
 if not result.ok:return result
 _state=data.duplicate(true)
 return ActionResult.success()
func _validate(data: Dictionary) -> ActionResult:
 for key in ["topic_history","receipts","moments","daily","people","invitations","activity"]:
  if not data.get(key) is Dictionary:return _fail("invalid_social_state")
 var now := _session.clock.world_minutes
 for id in data.receipts:
  var receipt: Variant=data.receipts[id]
  if not _data.actions.has(id) or not receipt is Dictionary or not ContentValidation.bounded(receipt.get("at"),0,now+0.001) or not receipt.get("source") is String or receipt.get("actor")!=_data.actions[id].actor:return _fail("invalid_social_receipt")
 for id in data.receipts:
  for required in _data.actions[id].needs:
   if not data.receipts.has(required) or data.receipts[required].at>data.receipts[id].at:return _fail("invalid_social_dependency")
 var valid_moments: Array=[]
 for action in _data.actions.values():valid_moments.append(action.moment)
 for key in data.moments:
  if not key in valid_moments or data.moments[key]!=true:return _fail("invalid_social_moment")
  var grounded := false
  for id in data.receipts:
   if _data.actions[id].moment==key:grounded=true
  if not grounded:return _fail("ungrounded_social_moment")
 for topic in data.topic_history:
  if not _data.topics.has(topic) or not ContentValidation.integer(data.topic_history[topic]) or data.topic_history[topic]<1 or data.topic_history[topic]>_session.clock.day:return _fail("invalid_social_topic_history")
 for actor in data.people:
  if not _session.config.section("visitors").characters.has(actor) or data.people[actor]!=true:return _fail("invalid_social_person")
 for day in data.daily:
  if not str(day).is_valid_int() or int(day)<1 or int(day)>_session.clock.day or not data.daily[day] is Dictionary:return _fail("invalid_social_cap")
  for actor in data.daily[day]:
   if not actor in data.people or not ContentValidation.bounded(data.daily[day][actor],0,_data.relationships.daily_cap):return _fail("invalid_social_cap")
 var activity: Dictionary=data.activity
 if not activity.get("phase") in ["idle","coordinating","scheduled","waiting","active","completed"] or not activity.get("outcome") in ["","days_pending","week_trial"]:return _fail("invalid_activity")
 for key in ["not_before","start_at","end_at","clear_since"]:
  if not ContentValidation.number(activity.get(key)) or activity[key]<-1:return _fail("invalid_activity_time")
 if activity.clear_since>now+0.001:return _fail("future_clearance")
 var consent: bool=data.receipts.has("consent_farid") and data.receipts.has("consent_youssef")
 if consent!=(activity.phase!="idle"):return _fail("invalid_activity_consent")
 if activity.phase in ["scheduled","waiting","active","completed"]:
  if activity.not_before<0 or activity.not_before<maxf(float(data.receipts.consent_farid.at),float(data.receipts.consent_youssef.at)):return _fail("invalid_appointment")
 else:
  if activity.not_before!=-1:return _fail("premature_appointment")
 if activity.phase in ["active","completed"]:
  if activity.start_at<activity.not_before or activity.start_at>now+0.001 or absf(float(activity.end_at)-float(activity.start_at)-float(_data.trial.duration_minutes))>0.001:return _fail("invalid_trial_interval")
 else:
  if activity.start_at!=-1 or activity.end_at!=-1:return _fail("premature_trial")
 if (activity.phase=="completed")!=data.receipts.has("trial_complete"):return _fail("invalid_trial_receipt")
 if activity.phase=="completed":
  if float(data.receipts.trial_complete.at)<float(activity.end_at) or activity.end_at>now+0.001 or activity.outcome!=("week_trial" if data.receipts.has("days_farid") and data.receipts.has("days_youssef") else "days_pending"):return _fail("invalid_trial_outcome")
 elif activity.outcome!="":return _fail("premature_outcome")
 for id in data.receipts:
  if not _data.actions[id].phases.is_empty() and not activity.phase in _data.actions[id].phases:return _fail("premature_social_receipt")
 for id in data.invitations:
  var invitation: Variant=data.invitations[id]
  if not _session.visitors.visits.has(id) or not invitation is Dictionary or not ContentValidation.bounded(invitation.get("wait"),0,120) or not ContentValidation.bounded(invitation.get("elapsed"),0,120) or not invitation.get("offered") is bool or invitation.elapsed>invitation.wait:return _fail("invalid_invitation")
 return ActionResult.success()
func cross_validate() -> ActionResult:
 if _state.activity.phase=="active" and not _participants_absent():return _fail("participant_in_two_places")
 for id in _state.receipts:
  var action: Dictionary=_data.actions[id]
  if action.learn!="" and not _session.knowledge.has(StringName(action.learn)):return _fail("missing_social_knowledge")
 var facts: Dictionary=_session.knowledge.snapshot().facts
 for fact in ["WORKSHOP_OPPORTUNITY","YOUSSEF_WORK_STUDY","WORK_TRIAL_APPOINTMENT","WORK_TRIAL_RESULT","WORK_TRIAL_WEEK"]:
  if not facts.has(fact):continue
  var grounded := false
  var record: Dictionary=facts[fact]
  for id in _state.receipts:
   var receipt: Dictionary=_state.receipts[id]
   if _data.actions[id].learn==fact and record.get("source")==receipt.source and record.get("speaker")==receipt.actor and ContentValidation.number(record.get("at")) and absf(float(record.at)-float(receipt.at))<0.001:grounded=true
  if not grounded:return _fail("ungrounded_social_knowledge")
 return ActionResult.success()
func _fail(reason: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,StringName(reason))

func topics_for(visit_id: StringName) -> Array[Dictionary]:
 var topics: Array[Dictionary]=[]
 var visit: VisitState=_session.visitors.visits.get(str(visit_id))
 if visit==null:return topics
 for id in _data.topics:
  var topic: Dictionary=_data.topics[id]
  if topic.actor==str(visit.character_id) and topic_available(id):topics.append({"id":id,"label":topic.label,"encounter":topic.encounter})
 return topics
func start_topic(visit_id: StringName, id: String) -> ActionResult:
 if _session.narrative.speech_active(visit_id):return _fail("conversation_in_progress")
 var visit: VisitState=_session.visitors.visits.get(str(visit_id))
 if visit==null or not topic_available(id) or _data.topics[id].actor!=str(visit.character_id):return _fail("nothing_new_to_say")
 return await _session.narrative.start(StringName(_data.topics[id].encounter),PackedStringArray([str(visit_id)]))
func step_companionship(delta: float) -> void:
 if _session.narrative==null or (_session.personal!=null and _session.personal.active()):return
 var config: Dictionary=_data.companionship
 var blocked := participation_blocked.is_valid() and bool(participation_blocked.call())
 for visit: VisitState in _session.visitors.visits.values():
  if not str(visit.character_id) in config.actors:continue
  var id := str(visit.id)
  if not _state.invitations.has(id):
   var sample := float(_session.visitors.random_index(1001))/1000.0
   _state.invitations[id]={"wait":lerpf(float(config.wait_seconds[0]),float(config.wait_seconds[1]),sample),"elapsed":0.0,"offered":false}
  var invitation: Dictionary=_state.invitations[id]
  var near := visit.phase==&"staying" and _session.location_id==visit.pose.location_id and _session.player_ground.distance_to(visit.pose.ground)<=float(config.radius)
  if _session.visitors.awareness.enabled():near=near and _session.visitors.awareness.visible(visit.id,"player")
  if not near:invitation.elapsed=0.0;continue
  if invitation.offered or blocked or not _session.narrative.sessions.is_empty():continue
  var topics := topics_for(visit.id).filter(func(topic):return bool(_data.topics[topic.id].automatic))
  if topics.is_empty():continue
  invitation.elapsed=minf(float(invitation.wait),float(invitation.elapsed)+delta)
  if invitation.elapsed<float(invitation.wait):continue
  invitation.offered=true
  _session.narrative.start(&"social_invitation",PackedStringArray([id]),{"topic_id":topics[0].id,"invitation":true})
func can_invite(visit_id: StringName) -> bool:
 if _session.narrative==null or not _session.narrative.sessions.is_empty() or (_session.personal!=null and _session.personal.active()):return false
 if participation_blocked.is_valid() and bool(participation_blocked.call()):return false
 if bool(_state.invitations.get(str(visit_id),{}).get("offered",false)):return false
 for topic in topics_for(visit_id):
  if bool(_data.topics[topic.id].automatic):return true
 return false
func action_known(id: String) -> bool:
 return id!="trial_complete" and _data.actions.has(id)
func topic_actor(id: String) -> String:
 return str(_data.topics.get(id,{}).get("actor",""))
func dialogue_context(id: String) -> Dictionary:
 var activity: Dictionary=_state.activity
 var appointment := float(activity.not_before)
 var minute := fposmod(appointment,1440.0)
 return {"topic_id":id,"trial_week":activity.outcome=="week_trial","appointment_label":"يوم %d الساعة %02d:%02d" % [floori(appointment/1440.0)+1,int(minute)/60,int(minute)%60],"localization_args":{"appointment_label":NarrativeLocalization.date(appointment)}}
func heard_topic(id: String) -> void:
 if not _data.topics.has(id):return
 var action := str(_data.topics[id].action)
 if action.is_empty() or done(action):_state.topic_history[id]=_session.clock.day
