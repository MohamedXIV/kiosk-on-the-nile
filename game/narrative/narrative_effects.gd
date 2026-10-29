class_name NarrativeEffects
extends RefCounted
var supply_provider: Callable
var finance_provider: Callable
var service_provider: Callable
var home_provider: Callable
var semantic_provider: Callable
var _committing: bool = false
var _semantic_sources: Dictionary = {}
var relationships: RelationshipStore
var social_life: SocialLife
var _knowledge: KnowledgeBook
var _needs: NeedsService
var _facts: Array
var _applied: Dictionary = {}
func _init(knowledge: KnowledgeBook, needs: NeedsService, facts: Array) -> void:
 _knowledge = knowledge
 _needs = needs
 _facts = facts.duplicate()
func valid(effect: Dictionary) -> bool:
 var scope: Variant=effect.get("scope","hearing")
 if not scope in ["hearing","world"]:return false
 if scope=="world" and effect.get("kind")!="peer_relation":return false
 match effect.get("kind"):
  "semantic":return scope=="hearing" and semantic_provider.is_valid() and effect.get("action_id") is String and effect.action_id.is_valid_identifier()
  "peer_relation":return scope=="world" and relationships!=null and effect.get("from") is String and effect.get("to") is String and effect.from!="player" and effect.to!="player" and effect.from!=effect.to and effect.get("axis") is String and ContentValidation.bounded(effect.get("amount"),-10,10) and relationships.can_adjust(StringName(effect.from),StringName(effect.to),StringName(effect.axis),float(effect.amount))
  "supply":return supply_provider.is_valid() and effect.get("action_id") in ["manage","emergency"]
  "finance":return finance_provider.is_valid() and effect.get("action_id") in ["pay_housing","pay_partial","repay_loan","personal","repair","accept_offer","decline_offer","offer_day_1","offer_day_3","offer_day_7","offer_loan_0","offer_loan_1","offer_loan_2"]
  "service":return service_provider.is_valid() and effect.get("action_id") in ["accept","accept_gift","decline"]
  "home":return home_provider.is_valid() and effect.get("action_id") in ["invite","cancel","heard","goodbye"]
  "social":return social_life!=null and effect.get("action_id") is String and social_life.action_known(effect.action_id)
  "mood": return ContentValidation.bounded(effect.get("amount"),-100,100)
  "learn": return effect.get("fact_id") in _facts and effect.get("note") is String
 return false
func apply(effect: Dictionary, occurrence_id: StringName, speaker: String = "", participants: PackedStringArray = PackedStringArray()) -> ActionResult:
 if effect.get("kind")=="semantic":return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"semantic_context_required")
 if not valid(effect): return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_narrative_effect")
 if _applied.has(str(occurrence_id)): return ActionResult.success({"duplicate":true})
 match effect.kind:
  "peer_relation":
   var result := relationships.adjust(StringName(effect.from),StringName(effect.to),StringName(effect.axis),float(effect.amount))
   if not result.ok:return result
  "supply":
   var result: ActionResult=supply_provider.call(effect.action_id,str(occurrence_id),participants)
   if not result.ok:return result
  "finance":
   var result: ActionResult=finance_provider.call(effect.action_id,str(occurrence_id),participants)
   if not result.ok:return result
  "service":
   var result: ActionResult=service_provider.call(effect.action_id,participants)
   if not result.ok:return result
  "home":
   var result: ActionResult=home_provider.call(effect.action_id,str(occurrence_id),speaker,participants)
   if not result.ok:return result
  "social":
   var result := social_life.apply(effect.action_id,str(occurrence_id),speaker)
   if not result.ok:return result
  "mood": _needs.apply_delta(0,0,float(effect.amount))
  "learn": _knowledge.learn(StringName(effect.fact_id),effect.note,str(occurrence_id))
 _applied[str(occurrence_id)] = true
 return ActionResult.success()
func applied(id: String) -> bool:return _applied.has(id)
func apply_semantic(conversation: ConversationSession) -> ActionResult:
 if _committing or not semantic_provider.is_valid():return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"semantic_commit_busy")
 _committing=true
 var result: ActionResult=semantic_provider.call(conversation)
 _committing=false
 return result
func publish_knowledge(ticket: Dictionary, receipts: Array, frame: Dictionary, social_ticket: Dictionary = {}, relationship_ticket: Dictionary = {}, presence: Dictionary = {}) -> ActionResult:
 if not _committing:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"semantic_context_required")
 var valid:=_knowledge.assertions.can_commit(ticket)
 if not valid.ok:return valid
 if social_ticket.is_empty()!=relationship_ticket.is_empty():return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"incomplete_social_transaction")
 if not social_ticket.is_empty():
  valid=social_life.memory.can_commit(social_ticket)
  if not valid.ok:return valid
  valid=relationships.can_commit(relationship_ticket)
  if not valid.ok:return valid
 var sources := {}
 for receipt in receipts:
  if _applied.has(receipt.id) or _semantic_sources.has(receipt.id) or ticket.receipts.get(receipt.id)!=receipt:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"semantic_receipt_collision")
  var assertions: Array=[]
  for id in receipt.assertions:
   if not ticket.records.get(id) is Dictionary:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_knowledge_assertions")
   assertions.append(ticket.records[id].duplicate(true))
  sources[receipt.id]={"receipt":receipt.duplicate(true),"assertions":assertions,"frame":frame.duplicate(true)}
  if not receipt.get("social",[]).is_empty():
   if presence.size()!=receipt.participants.size():return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"ambiguous_social_presence_proof")
   for actor in receipt.participants:
    if not presence.get(actor) is String or presence[actor].is_empty():return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"missing_social_presence_proof")
   for actor in receipt.get("visits",{}):
    if receipt.visits[actor]!=presence.get(actor):return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_social_presence_proof")
   sources[receipt.id]["presence"]=presence.duplicate(true)
   var rows: Array=[]
   for i in range(receipt.social.size()):
    var id: String=receipt.id+"/social/"+str(i)
    if not social_ticket.get("events",{}).get(id) is Dictionary:return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"incomplete_social_transaction")
    rows.append(social_ticket.events[id].duplicate(true))
   sources[receipt.id]["social"]=rows
 # All candidates are validated. These publications have no callbacks/awaits.
 _knowledge.assertions.publish(ticket)
 if not social_ticket.is_empty():
  social_life.memory.publish(social_ticket);relationships.publish(relationship_ticket)
 for id in sources:
  _applied[id]=true;_semantic_sources[id]=sources[id]
 return ActionResult.success()
func semantic_source(id: String) -> Dictionary:return _semantic_sources.get(id,{}).duplicate(true)
func semantic_source_ids() -> Array:return _semantic_sources.keys()
func snapshot() -> Dictionary:
 var result := {"applied":_applied.duplicate()}
 if not _semantic_sources.is_empty():result["semantic_sources"]=_semantic_sources.duplicate(true)
 return result
func restore(data: Dictionary) -> ActionResult:
 if not data.get("applied") is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_effect_history")
 for value in data.applied.values():
  if value != true: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_effect_history")
 var sources: Variant=data.get("semantic_sources",{})
 if not sources is Dictionary:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_semantic_source")
 for id in sources:
  var source: Variant=sources[id]
  if not id is String or not data.applied.has(id) or not NarrativePolicyValidation.fields(source,["receipt","assertions","frame"],["social","presence"]) or not source.receipt is Dictionary or not source.assertions is Array or not source.get("social",[]) is Array or not source.get("presence",{}) is Dictionary or not source.frame is Dictionary:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_semantic_source")
 _applied = data.applied.duplicate()
 _semantic_sources=sources.duplicate(true)
 return ActionResult.success()
