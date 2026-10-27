class_name PeerSaveLinks
extends RefCounted
static func validate(session: GameSession) -> ActionResult:
 var state := session.visitors.peers.snapshot()
 var active: Dictionary=state.active
 var policy: Dictionary=session.config.section("visitors").get("peer_encounters",{})
 for conversation: ConversationSession in session.narrative.sessions.values():
  if not conversation.context_extra.has("peer_id"):continue
  var supported := false
  if policy.get("enabled",false) and conversation.participants.size()==2:
   var a: Variant=session.presence.record(conversation.participants[0])
   var b: Variant=session.presence.record(conversation.participants[1])
   if a!=null and b!=null:
    for pair: Dictionary in policy.get("pairs",{}).values():
     if pair.initiator==str(a.character_id) and pair.target==str(b.character_id) and pair.encounter==str(conversation.encounter_id):supported=true
  if not supported:
   session.narrative.cancel(conversation.id)
   continue
  if active.is_empty() or active.phase!="conversing" or active.conversation!=str(conversation.id) or active.id!=conversation.context_extra.peer_id or active.encounter!=str(conversation.encounter_id):return _fail()
  if conversation.participants!=PackedStringArray([active.initiator,active.target]):return _fail()
  var joined: Variant=conversation.context_extra.get("peer_participating",false)
  if not joined is bool or bool(conversation.context_extra.get("manual_read",false))!=joined:return _fail()
 if active.is_empty():return ActionResult.success()
 for id in [active.initiator,active.target]:
  if session.service.pending_for(StringName(id))!=null or session.personal.holds_visit(StringName(id)):return _fail()
 var a: VisitState=session.visitors.visits[active.initiator]
 var bounds: Array=session.config.section("locations")[str(a.pose.location_id)].navigation_bounds
 for key in ["goal","observed","target_point"]:
  var point: Array=active[key]
  if point[0]<bounds[0] or point[1]<bounds[1] or point[0]>bounds[2] or point[1]>bounds[3]:return _fail()
 for conversation: ConversationSession in session.narrative.sessions.values():
  if str(conversation.id)!=active.conversation and (active.initiator in conversation.participants or active.target in conversation.participants):return _fail()
 if active.phase=="conversing":
  var conversation: ConversationSession=session.narrative.sessions.get(active.conversation)
  if conversation==null or conversation.context_extra.get("peer_id")!=active.id or conversation.encounter_id!=StringName(active.encounter) or conversation.participants!=PackedStringArray([active.initiator,active.target]):return _fail()
 elif session.visitors.awareness.recalled(a.id,str(session.visitors.visits[active.target].character_id)).is_empty():return _fail()
 return ActionResult.success()
static func _fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_peer_links")
