class_name NarrativeKnowledge
extends RefCounted
## Prepare heard knowledge/social batches; domain owners keep their authority.
var _session: GameSession
var _actions: Dictionary = {}
var identity: String = ""
func configure(session: GameSession) -> void:
 _session=session
 var data: Dictionary=session.config.data.get("narrative_knowledge",NarrativeKnowledgeValidation.empty_catalog())
 _actions=data.actions.duplicate(true);identity=StableJson.stringify(data).sha256_text()
func _book() -> KnowledgeAssertions:return _session.knowledge.assertions
func _action(topic: String, id: String) -> Dictionary:return _actions.get(topic,{}).get(id,{})
func _pose(actor: String) -> ActorPose:
 if actor=="player":return _session.player_pose if _session.locations.is_physical(_session.location_id) else null
 var record: Variant=_session.semantic._record(actor)
 return record.pose if record!=null and _session.presence.is_available(record.id) else null
func can_hear(speaker: String, listener: String, channel: String) -> bool:
 if speaker==listener:return false
 var source := _pose(speaker);var target := _pose(listener)
 if source==null or target==null or source.location_id!=target.location_id:return false
 var radius := 3.4 if channel=="personal" else float(_session.config.data.spatial.hearing_radius)
 return source.ground.distance_to(target.ground)<=radius
func _context(entry: Dictionary, c: ConversationSession, listener: String) -> ActionResult:
 var declared: Array=_session.semantic.policy._compiled.topics[entry.semantic_topic].get("turn_roles",[])
 var turn := {}
 if "speaker" in declared:turn.speaker=str(c.current.speaker_id)
 if "listener" in declared:turn.listener=listener
 return _session.semantic._context(entry,c.participants,turn,{},c.context_extra.semantic_start.identity.bindings)
func _authorized(entry: Dictionary, c: ConversationSession, listener: String) -> PolicyDecision:
 var continuation := _session.semantic.decide(entry,c.participants,"continuation","",c,listener)
 if not continuation.allowed:return continuation
 return _session.semantic.decide(entry,c.participants,"action",c.current.policy_action,c,listener)
func commit(c: ConversationSession) -> ActionResult:
 var entry: Dictionary=_session.config.data.encounters[str(c.encounter_id)]
 if not entry.has("semantic_topic") or c.current.text.is_empty() or c.current.effects.size()!=1 or c.current.effects[0].get("kind")!="semantic" or c.current.effects[0].get("action_id")!=c.current.policy_action:return _fail()
 var action := _action(entry.semantic_topic,c.current.policy_action)
 if action.is_empty():return _fail()
 var speaker := str(c.current.speaker_id)
 var bound := _context(entry,c,"player")
 if not bound.ok:return _fail()
 var context: NarrativeContext=bound.details.context
 var audience: Variant=context.resolve(action.listeners)
 if not audience is Array:return _fail()
 var seen := {};var receipts_to_add: Array=[];var assertions_to_add: Array=[];var eligible: Array=[]
 for listener in audience:
  if not listener is String or seen.has(listener):return _fail()
  seen[listener]=true
  if not can_hear(speaker,listener,action.get("channel","hearing")):continue
  var id := KnowledgeAssertions.receipt_id(str(c.id),c.beat,c.current.policy_action,listener)
  var existing := _book().receipt(id)
  if not existing.is_empty():
   if not _receipt_source(existing,entry,context.identity(),c,speaker):return _fail()
   continue
  if action.has("choice") and not NarrativeChoice.valid(_session,c.context_extra.get("semantic_choice"),str(c.id),c.beat,str(c.encounter_id),action.choice,_session.clock.world_minutes):return _fail()
  var decision := _authorized(entry,c,listener)
  if decision.status=="invalid":return _fail()
  if not decision.allowed:continue
  bound=_context(entry,c,listener)
  if not bound.ok:return _fail()
  var resolved: Variant=bound.details.context.resolve(action.assertions)
  if not resolved is Array:return _fail()
  var social: Variant=bound.details.context.resolve(action.get("social",[]))
  if not social is Array:return _fail()
  var ids: Array=[]
  for i in range(resolved.size()):
   var declaration: Dictionary=resolved[i]
   var parent := ""
   if declaration.kind=="relayed":
    if declaration.parent!=speaker:return _fail()
    var sources := _book().query(speaker,declaration.fact)
    if sources.is_empty():return _fail()
    parent=sources[0].id
   var assertion_id := id+"/"+str(i);ids.append(assertion_id)
   assertions_to_add.append({"id":assertion_id,"knower":listener,"fact":declaration.fact,"kind":declaration.kind,"speaker":speaker,"source":id,"at":_session.clock.world_minutes,"parent":parent})
  var story: StoryDefinition=_session.narrative._stories[entry.story]
  receipts_to_add.append({"id":id,"episode":str(c.id),"beat":c.beat,"topic":entry.semantic_topic,"action":c.current.policy_action,"speaker":speaker,"listener":listener,"at":_session.clock.world_minutes,"order":_book().next_order()+receipts_to_add.size(),"catalog":_session.semantic.policy.identity(),"knowledge_catalog":identity,"identity":context.identity(),"encounter":str(c.encounter_id),"participants":c.context_extra.semantic_start.actors.duplicate(),"story":str(story.id),"story_hash":story.sha256,"assertions":ids})
  if action.has("choice"):receipts_to_add[-1]["choice"]=c.context_extra.semantic_choice.duplicate(true)
  if action.has("domain"):
   var command: Variant=bound.details.context.resolve(action.domain)
   if not command is Dictionary or command.actor!=speaker or listener!="player":return _fail()
   command["source"]=id;receipts_to_add[-1]["domain"]=command
  if not social.is_empty() or action.has("domain"):
   receipts_to_add[-1]["social"]=social
   receipts_to_add[-1]["visits"]=visits(bound.details.context)
  if action.has("choice_assertions"):
   if listener!="player" or speaker=="player" or not can_hear("player",speaker,action.get("channel","hearing")):return _fail()
   var choice_id:=KnowledgeAssertions.receipt_id(str(c.id),c.beat,c.current.policy_action,speaker)
   if not _book().receipt(choice_id).is_empty():return _fail()
   var choice_receipt: Dictionary=receipts_to_add[-1].duplicate(true)
   choice_receipt.erase("social");choice_receipt.erase("visits");choice_receipt.erase("domain")
   choice_receipt.id=choice_id;choice_receipt.speaker="player";choice_receipt.listener=speaker;choice_receipt["origin"]="choice";choice_receipt.assertions=[]
   var resolved_choice: Variant=bound.details.context.resolve(action.choice_assertions)
   if not resolved_choice is Array:return _fail()
   for i in range(resolved_choice.size()):
    var declaration: Dictionary=resolved_choice[i]
    var upstream:=_book().query("player",declaration.fact)
    if upstream.is_empty():return _fail()
    var assertion_id:=choice_id+"/"+str(i);choice_receipt.assertions.append(assertion_id)
    assertions_to_add.append({"id":assertion_id,"knower":speaker,"fact":declaration.fact,"kind":"relayed","speaker":"player","source":choice_id,"at":_session.clock.world_minutes,"parent":upstream[0].id})
   choice_receipt.order=_book().next_order()+receipts_to_add.size()
   receipts_to_add.append(choice_receipt)
  eligible.append(listener)
 if receipts_to_add.is_empty():return ActionResult.success({"duplicate_or_unheard":true})
 var prepared := _book().prepare(receipts_to_add,assertions_to_add)
 if not prepared.ok:return prepared
 var social_ticket: Dictionary={};var relationship_ticket: Dictionary={}
 if receipts_to_add.any(func(r):return not r.get("social",[]).is_empty()):
  var candidate:=_session.social_life.memory.prepare(receipts_to_add)
  if not candidate.ok:return candidate
  social_ticket=candidate.details
  candidate=_session.relationships.prepare_gains(social_ticket.gains)
  if not candidate.ok:return candidate
  relationship_ticket=candidate.details
 var domain_ticket: Dictionary={}
 if action.has("domain"):
  if receipts_to_add.size()!=1:return _fail()
  var command: Dictionary=receipts_to_add[0].domain
  var candidate:=_session.residential.prepare_semantic(command.command,command.actor,command.source,command.scope)
  if not candidate.ok:return candidate
  domain_ticket=candidate.details
 # No await and no publication/signals before the whole batch is ready.
 for listener in eligible:
  if not can_hear(speaker,listener,action.get("channel","hearing")) or not _authorized(entry,c,listener).allowed:return _fail()
 var presence := {}
 for participant in c.participants:
  var actual: Variant=_session.presence.record(participant)
  if actual==null:return _fail()
  presence[str(actual.character_id)]=str(participant)
 var result := _session.effects.publish_knowledge(prepared.details,receipts_to_add,c.current.to_dict(),social_ticket,relationship_ticket,presence,domain_ticket)
 if not result.ok:return result
 if c.context_extra.semantic_start.receipt.is_empty():c.context_extra.semantic_start.receipt=receipts_to_add[0].id
 return ActionResult.success()
static func visits(context: NarrativeContext) -> Dictionary:
 var result := {}
 for role in context.handles:result[context.roles[role]]=context.handles[role]
 return result
func _receipt_source(r: Dictionary, entry: Dictionary, bound_identity: Dictionary, c: ConversationSession, speaker: String) -> bool:
 return r.episode==str(c.id) and r.beat==c.beat and r.action==c.current.policy_action and r.speaker==speaker and r.identity==bound_identity and r.catalog==_session.semantic.policy.identity() and r.knowledge_catalog==identity and r.encounter==str(c.encounter_id) and r.story==entry.story and r.story_hash==c.runtime._definition.sha256 and (not r.has("choice") or NarrativePolicyValidation.equivalent(r.choice,c.context_extra.get("semantic_choice")))
func validate_links(next_episode: int) -> ActionResult:
 for receipt_value in _book().receipts():
  var r: Dictionary=receipt_value
  var source := _session.effects.semantic_source(r.id)
  if source.is_empty() or source.receipt!=r or source.assertions.size()!=r.assertions.size() or source.frame.get("speaker_id")!=(r.listener if r.get("origin")=="choice" else r.speaker) or source.frame.get("policy_action")!=r.action or source.frame.get("effects")!=[{"kind":"semantic","action_id":r.action}] or not source.frame.get("text") is String or source.frame.text.is_empty():return _fail()
  for i in range(r.assertions.size()):
   if source.assertions[i]!=_book().record(r.assertions[i]):return _fail()
  if not _session.effects.applied(r.id) or not _session.narrative.valid_sequence(r.episode,"conversation_",next_episode) or r.catalog!=_session.semantic.policy.identity() or r.knowledge_catalog!=identity or not _session.config.data.encounters.has(r.encounter):return _fail()
  var entry: Dictionary=_session.config.data.encounters[r.encounter]
  if entry.has("semantic_actor") and (r.participants.is_empty() or r.participants[0]!=entry.semantic_actor):return _fail()
  if entry.get("semantic_topic")!=r.topic or entry.story!=r.story or not _session.narrative._stories.has(r.story) or _session.narrative._stories[r.story].sha256!=r.story_hash:return _fail()
  if not NarrativePolicyValidation.fields(r.identity,["topic","bindings","roles"]) or not r.identity.bindings is Dictionary or not r.identity.roles is Dictionary:return _fail()
  var bound := _session.semantic.policy.bind(r.topic,r.identity.bindings,{}, {},r.identity.roles)
  if not bound.ok or bound.details.context.identity()!=r.identity:return _fail()
  for key in entry.semantic_bindings:
   var ref: Variant=entry.semantic_bindings[key]
   if ref is Dictionary:
    if ref.has("query"):
     if not _session.semantic.evidence_binding_valid(ref,str(r.identity.bindings[key])):return _fail()
     continue
    if int(ref.participant)>=r.participants.size() or r.identity.bindings[key]!=r.participants[int(ref.participant)]:return _fail()
   elif r.identity.bindings[key]!=ref:return _fail()
  var action := _action(r.topic,r.action)
  if action.is_empty():return _fail()
  if action.has("choice"):
   if not NarrativeChoice.valid(_session,r.get("choice"),r.episode,int(r.beat),r.encounter,action.choice,float(r.at)):return _fail()
  elif r.has("choice"):return _fail()
  if action.has("choice_assertions") and r.get("origin","")!="choice":
   var side:=_book().receipt(KnowledgeAssertions.receipt_id(r.episode,int(r.beat),r.action,r.speaker))
   if side.get("origin")!="choice" or side.speaker!="player" or side.listener!=r.speaker or side.episode!=r.episode or side.beat!=r.beat:return _fail()
  var context: NarrativeContext=bound.details.context
  var choice_origin: bool=r.get("origin")=="choice"
  if r.has("origin") and (not choice_origin or r.speaker!="player" or not r.listener in r.participants or not action.has("choice_assertions") or r.has("social") or r.has("domain") or r.has("visits")):return _fail()
  if choice_origin:
   var counterpart:=_book().receipt(KnowledgeAssertions.receipt_id(r.episode,int(r.beat),r.action,"player"))
   if counterpart.get("speaker")!=r.listener or counterpart.get("origin","")=="choice":return _fail()
   for field in ["episode","beat","topic","action","at","catalog","knowledge_catalog","identity","encounter","participants","story","story_hash","choice"]:
    if not NarrativePolicyValidation.equivalent(counterpart.get(field),r.get(field)):return _fail()
   if not NarrativePolicyValidation.equivalent(_session.effects.semantic_source(counterpart.id).get("frame"),source.frame):return _fail()
  var declarations: Array=action.get("choice_assertions",[]) if choice_origin else action.assertions
  var audience: Variant=[r.listener] if choice_origin else context.resolve(action.listeners)
  if not audience is Array or not r.listener in audience or r.assertions.size()!=declarations.size():return _fail()
  var declared: Array=_session.semantic.policy._compiled.topics[r.topic].get("turn_roles",[])
  if "speaker" in declared:context.roles.speaker=r.speaker
  if "listener" in declared:context.roles.listener=r.listener
  if action.has("domain"):
   var command: Variant=context.resolve(action.domain)
   if not command is Dictionary or command.actor!=r.speaker or r.listener!="player":return _fail()
   command["source"]=r.id
   if not NarrativePolicyValidation.equivalent(r.get("domain"),command) or not _session.residential.semantic_commands.has(r.id):return _fail()
  elif r.has("domain"):return _fail()
  if not r.get("social",[]).is_empty() or r.has("domain"):
   var presence: Variant=source.get("presence")
   if not presence is Dictionary or presence.size()!=r.participants.size():return _fail()
   for actor in presence:
    if not actor in r.participants or not presence[actor] is String or presence[actor].is_empty():return _fail()
   var expected_visits := {}
   for actor in context.roles.values():
    if presence.has(actor):expected_visits[actor]=presence[actor]
   if not NarrativePolicyValidation.equivalent(r.get("visits",{}),expected_visits):return _fail()
  var expected: Variant=context.resolve(declarations)
  if not expected is Array:return _fail()
  if not NarrativePolicyValidation.equivalent(r.get("social",[]),context.resolve([] if choice_origin else action.get("social",[]))):return _fail()
  for i in range(expected.size()):
   var assertion := _book().record(r.assertions[i])
   if r.assertions[i]!=r.id+"/"+str(i) or assertion.fact!=expected[i].fact or assertion.kind!=expected[i].kind:return _fail()
   if assertion.kind=="relayed" and expected[i].parent!=r.speaker:return _fail()
 for id in _session.effects.snapshot().applied:
  if str(id).contains("/semantic/") and _book().receipt(str(id)).is_empty():return _fail()
 for id in _session.effects.semantic_source_ids():
  if _book().receipt(str(id)).is_empty():return _fail()
 return _session.social_life.memory.validate_links()
static func _fail() -> ActionResult:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_semantic_knowledge")
