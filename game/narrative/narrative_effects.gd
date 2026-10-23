class_name NarrativeEffects
extends RefCounted
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
 match effect.get("kind"):
  "social":return social_life!=null and effect.get("action_id") is String and social_life.action_known(effect.action_id)
  "mood": return ContentValidation.bounded(effect.get("amount"),-100,100)
  "learn": return effect.get("fact_id") in _facts and effect.get("note") is String
 return false
func apply(effect: Dictionary, occurrence_id: StringName, speaker: String = "") -> ActionResult:
 if not valid(effect): return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_narrative_effect")
 if _applied.has(str(occurrence_id)): return ActionResult.success({"duplicate":true})
 match effect.kind:
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
