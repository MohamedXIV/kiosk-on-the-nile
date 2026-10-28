class_name NarrativeEffects
extends RefCounted
var supply_provider: Callable
var finance_provider: Callable
var service_provider: Callable
var home_provider: Callable
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
func snapshot() -> Dictionary:
 return {"applied":_applied.duplicate()}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("applied") is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_effect_history")
 for value in data.applied.values():
  if value != true: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_effect_history")
 _applied = data.applied.duplicate()
 return ActionResult.success()
