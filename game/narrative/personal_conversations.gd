class_name PersonalConversations
extends RefCounted
## One personal focus; paused Ink belongs to the actor, not a departed visit.
var _session: GameSession
var _hub: Dictionary={}
var _paused: Dictionary={}
var _opening: bool=false
func configure(session: GameSession) -> void:
 _session=session
 session.narrative.chapter_finished.connect(_finished)
func active() -> bool:
 return not _hub.is_empty()
func holds_visit(id: StringName) -> bool:
 return active() and _hub.visit_id==str(id)
func can_open(id: StringName) -> bool:
 var visit: VisitState=_session.visitors.visits.get(str(id))
 return visit!=null and (_paused.has(str(visit.character_id)) or holds_visit(id) or not _session.narrative.manual_topics_for(id).is_empty())
func open_for(id: StringName) -> ActionResult:
 if _opening or not _near(id):return _fail()
 if holds_visit(id):return ActionResult.success()
 if _session.narrative.speech_active(id):return _fail()
 leave()
 var visit: VisitState=_session.visitors.visits[str(id)]
 _hub={"visit_id":str(id),"actor_id":str(visit.character_id),"session_id":""}
 if _paused.has(_hub.actor_id):
  _opening=true
  var result := await _session.narrative.resume_record(_paused[_hub.actor_id],id)
  _opening=false
  if result.ok:
   _hub.session_id=result.details.session_id
   _paused.erase(_hub.actor_id)
  return result
 return ActionResult.success()
func adopt(conversation: ConversationSession) -> void:
 if conversation.participants.size()!=1:return
 var visit: VisitState=_session.visitors.visits.get(conversation.participants[0])
 if visit==null:return
 if active() and _hub.session_id!=str(conversation.id):return
 _hub={"visit_id":str(visit.id),"actor_id":str(visit.character_id),"session_id":str(conversation.id)}
func select_topic(key: String) -> ActionResult:
 if not active() or _opening or not _near(StringName(_hub.visit_id)) or not _hub.session_id.is_empty():return _fail()
 _opening=true
 var result := await _session.narrative.start_manual_topic(StringName(_hub.visit_id),key)
 _opening=false
 if result.ok and active():_hub.session_id=result.details.session_id
 return result
func advance() -> ActionResult:
 if not active() or _hub.session_id.is_empty():return _fail()
 return _session.narrative.advance_manual(StringName(_hub.session_id))
func leave() -> void:
 if _opening:return
 if active() and not _hub.session_id.is_empty():
  var conversation: ConversationSession=_session.narrative.sessions.get(_hub.session_id)
  if conversation!=null:
   if not conversation.encounter_id in [&"service_availability",&"orders"]:_paused[_hub.actor_id]=conversation.snapshot()
   _session.narrative.cancel(conversation.id)
 _hub={}
func tick() -> void:
 if active() and not _opening:
  var conversation: ConversationSession=_session.narrative.sessions.get(_hub.session_id)
  if not _near(StringName(_hub.visit_id)) or (conversation!=null and not _session.narrative.available_for(conversation)):leave()
func view() -> Dictionary:
 if not active():return {}
 var conversation: ConversationSession=_session.narrative.sessions.get(_hub.session_id)
 return {"actor_id":_hub.actor_id,"name":_session.visitors.character(StringName(_hub.actor_id)).get("name",""),"conversation":conversation,"topics":_session.narrative.manual_topics_for(StringName(_hub.visit_id)) if conversation==null else [],"opening":_opening}
func _finished(id: StringName, _reason: StringName) -> void:
 if active() and _hub.session_id==str(id):_hub.session_id=""
func _near(id: StringName) -> bool:
 if not _session.visitors.is_available(id):return false
 var visit: VisitState=_session.visitors.visits[str(id)]
 return _session.location_id==visit.pose.location_id and _session.player_ground.distance_to(visit.pose.ground)<=float(_session.config.section("spatial").hearing_radius)
func snapshot() -> Dictionary:
 return {"hub":_hub.duplicate(true),"paused":_paused.duplicate(true)}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("hub") is Dictionary or not data.get("paused") is Dictionary:return _fail()
 if not data.hub.is_empty():
  for key in ["actor_id","visit_id","session_id"]:
   if not data.hub.get(key) is String:return _fail()
  var visit: VisitState=_session.visitors.visits.get(data.hub.visit_id)
  if visit==null or str(visit.character_id)!=data.hub.actor_id:return _fail()
 for actor in data.paused:
  var record: Variant=data.paused[actor]
  if not _session.config.section("visitors").characters.has(actor) or not record is Dictionary or not record.get("runtime") is Dictionary or not record.get("context_extra") is Dictionary or not record.get("id") is String or not record.get("encounter_id") is String or not record.get("participants") is Array or record.participants.size()!=1 or record.encounter_id in ["service_availability","orders"]:return _fail()
  if record.context_extra.get("character_id",actor)!=actor:return _fail()
  if not record.runtime.get("frame") is Dictionary or record.runtime.frame.get("speaker_id","") not in ["",actor]:return _fail()
 _hub=data.hub.duplicate(true)
 _paused=data.paused.duplicate(true)
 return ActionResult.success()
func validate_links() -> ActionResult:
 var ids: Dictionary={}
 for actor in _paused:
  var record: Dictionary=_paused[actor]
  if ids.has(record.id) or _session.narrative.sessions.has(record.id):return _fail()
  ids[record.id]=true
  var valid := await _session.narrative.validate_paused(record)
  if not valid.ok:return valid
 if active() and not _hub.session_id.is_empty():
  var conversation: ConversationSession=_session.narrative.sessions.get(_hub.session_id)
  if conversation==null or conversation.participants!=PackedStringArray([str(_hub.visit_id)]) or not _session.narrative.manual(conversation):return _fail()
 # Legacy manual chapters gain a hub at their existing cursor, without replay.
 if not active():
  for conversation: ConversationSession in _session.narrative.sessions.values():
   if _session.narrative.manual(conversation):adopt(conversation);break
 return ActionResult.success()
func _fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"conversation_unavailable")
