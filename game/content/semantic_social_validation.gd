class_name SemanticSocialValidation
extends RefCounted
static func validate_config(bundle: Dictionary) -> ActionResult:
 if not bundle.has("narrative_social"):return ActionResult.success()
 var data: Variant=bundle.narrative_social
 if not NarrativePolicyValidation.fields(data,["daily_gain_cap"]) or not ContentValidation.bounded(data.daily_gain_cap,0,100):return ContentValidation.fail("narrative_social.daily_gain_cap")
 return ActionResult.success()
static func valid(effect: Variant, schemas: Dictionary, roles: Array = [], bindings: Dictionary = {}, resolved: bool = false) -> bool:
 if not effect is Dictionary or not effect.get("kind") is String:return false
 var actor := func(value):return NarrativePolicyValidation.typed(value,"actor",schemas) if resolved else NarrativePolicyValidation.reference_valid(value,"actor",roles,bindings,schemas)
 var text := func(value):return NarrativePolicyValidation.typed(value,"string",schemas) if resolved else NarrativePolicyValidation.reference_valid(value,"string",roles,bindings,schemas)
 match effect.kind:
  "introduction","company":return NarrativePolicyValidation.fields(effect,["kind","observer","other"]) and actor.call(effect.observer) and actor.call(effect.other)
  "relationship":return NarrativePolicyValidation.fields(effect,["kind","from","to","axis","amount"]) and actor.call(effect.from) and actor.call(effect.to) and effect.axis in schemas.axes and ContentValidation.bounded(effect.amount,-10,10)
  "consent":return NarrativePolicyValidation.fields(effect,["kind","grantor","recipient","purpose","scope","decision","duration"]) and actor.call(effect.grantor) and actor.call(effect.recipient) and NarrativePolicyValidation.typed(effect.purpose,"string",schemas) and text.call(effect.scope) and effect.decision in ["grant","refuse","revoke"] and (ContentValidation.bounded(effect.duration,1,43200) if effect.decision=="grant" else ContentValidation.number(effect.duration) and effect.duration==0)
  "message":return NarrativePolicyValidation.fields(effect,["kind","stage","thread","subject","sender","recipient","courier"]) and effect.stage in ["request","reply","delivered"] and text.call(effect.thread) and text.call(effect.subject) and actor.call(effect.sender) and actor.call(effect.recipient) and actor.call(effect.courier)
  "consume":return NarrativePolicyValidation.fields(effect,["kind","scope","actors"],["evidence"]) and effect.scope in ["once","day","visit","evidence"] and effect.actors is Array and not effect.actors.is_empty() and effect.actors.size()<=16 and effect.actors.all(func(a):return actor.call(a)) and (not effect.has("evidence") or text.call(effect.evidence)) and (effect.scope!="evidence" or effect.has("evidence"))
 return false
