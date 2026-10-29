class_name SemanticNarrative
extends RefCounted
## Read-only adapters and lifecycle identity; state stays in existing owners.
var policy := NarrativePolicy.new()
var knowledge_actions := NarrativeKnowledge.new()
var _session: GameSession
static func empty_catalog() -> Dictionary:
 return {"contract_version":1,"profiles":{},"policies":{},"topics":{},"fact_types":{}}
static func schemas(bundle: Dictionary) -> Dictionary:
 var actors: Array=bundle.get("visitors",{}).get("characters",{}).keys()+bundle.get("residential_visits",{}).get("profiles",{}).keys()+bundle.get("suppliers",{}).get("profiles",{}).keys()+["player"]
 return {"types":{"actor":actors,"recipe":bundle.get("recipe_workflows",{}).keys(),"location":bundle.get("locations",{}).keys(),"fact":bundle.get("social",{}).get("facts",[])},"axes":bundle.get("social",{}).get("relationship_defaults",{}).keys(),"channels":["personal","hearing"],"queries":{"kiosk.open":{},"recipe.attempted":{"recipe":"recipe"},"recipe.completed":{"recipe":"recipe"}},"events":{}}
static func validate(bundle: Dictionary) -> ActionResult:
 var compiled := NarrativePolicyValidation.compile(bundle.get("narrative_policies",empty_catalog()),schemas(bundle))
 if not compiled.ok:return compiled
 var knowledge_validation := NarrativeKnowledgeValidation.validate(bundle,compiled.details)
 if not knowledge_validation.ok:return knowledge_validation
 var fact_types: Dictionary=bundle.get("narrative_policies",{}).get("fact_types",{})
 if fact_types.has("legacy_player_fact") and fact_types.legacy_player_fact!={"id":"fact"}:return ContentValidation.fail("narrative_policies.legacy_player_fact")
 for id in bundle.get("encounters",{}):
  var entry: Dictionary=bundle.encounters[id]
  if not entry.has("semantic_topic"):continue
  if not entry.semantic_topic is String or not compiled.details.topics.has(entry.semantic_topic) or not entry.get("semantic_bindings") is Dictionary or entry.has("topics") or entry.has("social_topic") or not entry.get("requires",{}).is_empty() or not entry.get("offer_requires",{}).is_empty() or not entry.get("choice_conditions",{}).is_empty():return ContentValidation.fail("encounters."+id+".semantic_contract")
  var topic: Dictionary=compiled.details.topics[entry.semantic_topic]
  if not NarrativePolicyValidation.same_keys(entry.semantic_bindings,topic.bindings):return ContentValidation.fail("encounters."+id+".semantic_bindings")
  for key in entry.semantic_bindings:
   var ref: Variant=entry.semantic_bindings[key]
   if ref is Dictionary:
    if not NarrativePolicyValidation.fields(ref,["participant"]) or not ContentValidation.integer(ref.participant) or ref.participant<0 or ref.participant>=16 or topic.bindings[key]!="actor":return ContentValidation.fail("encounters."+id+".participant_binding")
   elif not NarrativePolicyValidation.typed(ref,topic.bindings[key],compiled.details.schemas):return ContentValidation.fail("encounters."+id+".literal_binding")
 return compiled
func configure(session: GameSession) -> ActionResult:
 _session=session
 var compiled := validate(session.config.data)
 if not compiled.ok:return compiled
 policy.configure(compiled.details,{"relationship":_relationship,"time_window":_time_window,"available":_available,"near":_near,"domain":_domain,"knowledge":_knowledge},_resolve_handle)
 var knowledge_config: Dictionary=session.config.data.get("narrative_knowledge",NarrativeKnowledgeValidation.empty_catalog())
 var configured := session.knowledge.assertions.configure(compiled.details.schemas,session.config.data.get("narrative_policies",{}).get("fact_types",{}),knowledge_config.initial,session.clock)
 if not configured.ok:return configured
 knowledge_actions.configure(session)
 session.effects.semantic_provider=knowledge_actions.commit
 return ActionResult.success()
func _resolve_handle(id: String) -> Dictionary:return _session.presence.resolve(StringName(id))
func _record(actor: String) -> Variant:
 if actor=="player":return null
 for v in _session.visitors.visits.values():
  if str(v.character_id)==actor:return v
 for v in [_session.residential.current,_session.contact.current]:
  if v!=null and str(v.character_id)==actor:return v
 return null
func _relationship(rule: Dictionary, _context: NarrativeContext) -> Dictionary:
 var score := _session.relationships.value(StringName(rule.from),StringName(rule.to),StringName(rule.axis))
 return NarrativePolicy.answer(NarrativePolicy.compare(score,rule.compare,float(rule.value)),[{"value":score,"from":rule.from,"to":rule.to,"axis":rule.axis}])
func _time_window(rule: Dictionary, _context: NarrativeContext) -> Dictionary:
 return NarrativePolicy.answer(_session.clock.minutes>=float(rule.start) and _session.clock.minutes<=float(rule.end))
func _available(rule: Dictionary, _context: NarrativeContext) -> Dictionary:
 for actor in rule.actors:
  if actor=="player":continue
  var v: Variant=_record(actor)
  if v==null or not _session.presence.is_available(v.id):return NarrativePolicy.answer(false)
 return NarrativePolicy.answer(true)
func _near(rule: Dictionary, _context: NarrativeContext) -> Dictionary:
 var poses: Array=[]
 for actor in rule.actors:
  var v: Variant=_record(actor)
  if actor!="player" and v==null:return NarrativePolicy.answer(false)
  poses.append(_session.player_pose if actor=="player" else v.pose)
 var radius := 3.4 if rule.channel=="personal" else float(_session.config.data.spatial.hearing_radius)
 for a in poses:
  for b in poses:
   if a.location_id!=b.location_id or a.ground.distance_to(b.ground)>radius:return NarrativePolicy.answer(false)
 return NarrativePolicy.answer(true)
func _domain(rule: Dictionary, _context: NarrativeContext) -> Dictionary:
 match rule.id:
  "kiosk.open":return NarrativePolicy.answer(_session.kiosk_open)
  "recipe.attempted":return NarrativePolicy.answer(_session.learning.context(StringName(rule.args.recipe)).attempted)
  "recipe.completed":return NarrativePolicy.answer(_session.learning.context(StringName(rule.args.recipe)).completed)
 return {"status":"invalid","reason":"domain_provider_unavailable"}
func _knowledge(rule: Dictionary, _context: NarrativeContext) -> Dictionary:
 if rule.fact.type!="legacy_player_fact":
  var assertions := _session.knowledge.query_assertions(rule.knower,rule.fact,rule.provenance_kinds)
  return NarrativePolicy.answer(not assertions.is_empty(),assertions.map(func(r):return {"assertion":r.id,"knower":r.knower,"source":r.source,"kind":r.kind,"at":r.at,"parent":r.parent}))
 # Explicit compatibility capability, never substitute player data for an NPC.
 if rule.knower!="player" or rule.fact.type!="legacy_player_fact" or not NarrativePolicyValidation.fields(rule.fact.args,["id"]):return {"status":"invalid","reason":"actor_knowledge_provider_unavailable"}
 var record: Dictionary=_session.knowledge.record(StringName(rule.fact.args.id))
 if record.is_empty():return NarrativePolicy.answer(false)
 var kind := "initial" if record.source=="initial" else "heard" if record.has("speaker") and record.has("at") else ""
 if kind.is_empty():
  var parts := str(record.source).split("/")
  if parts.size()==3 and _session.effects.applied(str(record.source)):
   var heard := _session.journal.event(parts[0]+"/"+parts[1]+"/speech")
   if heard.get("chapter")==parts[0] and heard.get("channel")=="speech":kind="heard"
 if kind.is_empty():return {"status":"invalid","reason":"knowledge_provenance_unavailable"}
 return NarrativePolicy.answer(kind in rule.provenance_kinds,[{"source":record.source,"kind":kind}])
func _context(entry: Dictionary, participants: PackedStringArray, turn: Dictionary = {}, saved: Dictionary = {}) -> ActionResult:
 var values := {};var handles := {}
 for key in entry.semantic_bindings:
  var ref: Variant=entry.semantic_bindings[key]
  if ref is Dictionary:
   if int(ref.participant)>=participants.size():return _fail()
   var actor: Variant=_session.presence.record(participants[int(ref.participant)])
   if actor==null:return _fail()
   values[key]=str(actor.character_id)
  else:values[key]=ref
 var bound := policy.bind(entry.semantic_topic,values,{},turn,saved)
 if not bound.ok:return bound
 var context: NarrativeContext=bound.details.context
 for role in context.stable_roles:
  for participant in participants:
   var actor: Variant=_session.presence.record(participant)
   if actor!=null and str(actor.character_id)==context.stable_roles[role]:handles[role]=str(participant)
 return policy.bind(entry.semantic_topic,values,handles,turn,saved)
func start_proof(entry: Dictionary, participants: PackedStringArray, episode: String) -> ActionResult:
 var bound := _context(entry,participants)
 if not bound.ok:return bound
 var context: NarrativeContext=bound.details.context
 if not policy.evaluate(context,"start").allowed:return _fail()
 return ActionResult.success({"proof":{"identity":context.identity(),"catalog":policy.identity(),"episode":episode,"at":_session.clock.world_minutes,"receipt":"","actors":Array(participants).map(func(p):return str(_session.presence.record(p).character_id))}})
func decide(entry: Dictionary, participants: PackedStringArray, stage: String, key: String = "", conversation: ConversationSession = null, listener: String = "player") -> PolicyDecision:
 var turn := {}
 if conversation!=null:
  if not str(conversation.current.speaker_id).is_empty():turn.speaker=str(conversation.current.speaker_id)
  turn.listener=listener
 # Only declared turn roles are supplied to the binder.
 var id := str(entry.semantic_topic)
 if not policy.has_topic(id):return PolicyDecision.make("invalid","unknown_semantic_topic")
 var declared: Array=policy._compiled.topics[id].get("turn_roles",[])
 for role in turn.keys():
  if not role in declared:turn.erase(role)
 var bound := _context(entry,participants,turn)
 if not bound.ok:return PolicyDecision.make("invalid","invalid_policy_bindings")
 var context: NarrativeContext=bound.details.context
 if conversation!=null:
  if not proof_valid(conversation,context):return PolicyDecision.make("invalid","invalid_policy_start_proof")
  var proof: Dictionary=conversation.context_extra.semantic_start
  var actual: Array=[]
  for participant_id in participants:
   var person: Variant=_session.presence.record(participant_id)
   if person==null:return PolicyDecision.make("invalid","policy_actor_departed")
   actual.append(str(person.character_id))
  if actual!=proof.actors:return PolicyDecision.make("invalid","policy_actor_changed")
  if proof.receipt.is_empty() and stage not in ["start","offer"]:
   var unconsumed := policy.evaluate(context,"start")
   if not unconsumed.allowed:return unconsumed
 return policy.evaluate(context,stage,key)
func proof_valid(conversation: ConversationSession, context: NarrativeContext) -> bool:
 var proof: Variant=conversation.context_extra.get("semantic_start")
 if not NarrativePolicyValidation.fields(proof,["identity","catalog","episode","at","receipt","actors"]) or proof.identity!=context.identity() or proof.catalog!=policy.identity() or proof.episode!=str(conversation.id) or not ContentValidation.bounded(proof.at,0,_session.clock.world_minutes) or not proof.receipt is String or not proof.actors is Array or not proof.actors.all(func(a):return NarrativePolicyValidation.typed(a,"actor",policy._compiled.schemas)):return false
 if proof.receipt.is_empty():return not _session.journal.has_speech(str(conversation.id)) and not _session.knowledge.assertions.has_episode(str(conversation.id))
 var semantic_receipt := _session.knowledge.assertions.receipt(proof.receipt)
 if not semantic_receipt.is_empty():
  return semantic_receipt.episode==str(conversation.id) and semantic_receipt.beat<=conversation.beat and semantic_receipt.at>=proof.at and semantic_receipt.identity==context.identity() and semantic_receipt.catalog==policy.identity() and semantic_receipt.knowledge_catalog==knowledge_actions.identity and semantic_receipt.participants==proof.actors and _session.effects.applied(proof.receipt)
 var event := _session.journal.event(proof.receipt)
 var suffix: String = proof.receipt.trim_prefix(str(conversation.id)+"/").trim_suffix("/speech")
 return suffix.is_valid_int() and int(suffix)>0 and int(suffix)<=conversation.heard_beat and proof.receipt==str(conversation.id)+"/"+suffix+"/speech" and event.get("chapter")==str(conversation.id) and event.get("channel")=="speech" and float(event.get("at",-1))>=float(proof.at) and event.get("actor") in proof.actors
func mark_heard(conversation: ConversationSession) -> void:
 if not conversation.context_extra.has("semantic_start") or not conversation.context_extra.semantic_start.receipt.is_empty():return
 var id := "%s/%d/speech" % [conversation.id,conversation.beat]
 if not _session.journal.event(id).is_empty():conversation.context_extra.semantic_start.receipt=id
static func _fail() -> ActionResult:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"semantic_policy_unavailable")

func validate_detached(entry: Dictionary, record: Dictionary) -> bool:
 var proof: Variant=record.get("context_extra",{}).get("semantic_start")
 if not proof is Dictionary or not proof.get("identity") is Dictionary or not NarrativePolicyValidation.fields(proof.identity,["topic","bindings","roles"]) or proof.identity.topic!=entry.semantic_topic or not proof.identity.bindings is Dictionary or not proof.identity.roles is Dictionary or not proof.get("actors") is Array or not record.get("participants") is Array or proof.actors.size()!=record.participants.size():return false
 var bound := policy.bind(entry.semantic_topic,proof.identity.bindings,{}, {},proof.identity.roles)
 if not bound.ok:return false
 for key in entry.semantic_bindings:
  var ref: Variant=entry.semantic_bindings[key]
  if ref is Dictionary:
   if int(ref.participant)>=proof.actors.size() or proof.identity.bindings[key]!=proof.actors[int(ref.participant)]:return false
  elif proof.identity.bindings[key]!=ref:return false
 var c := ConversationSession.new();c.id=StringName(str(record.get("id","")));c.beat=int(record.get("beat",0));c.heard_beat=int(record.get("heard_beat",0));c.context_extra=record.context_extra
 return proof_valid(c,bound.details.context)
