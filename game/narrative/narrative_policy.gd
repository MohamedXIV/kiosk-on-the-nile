class_name NarrativePolicy
extends RefCounted
## Pure decisions over compiled data and explicitly registered read-only providers.
var _compiled: Dictionary = {}
var _providers: Dictionary = {}
var resolver: Callable
var calls: int = 0
var nodes: int = 0
var elapsed_usec: int = 0
func configure(compiled: Dictionary, providers: Dictionary, handle_resolver: Callable) -> void:
 _compiled=compiled.duplicate(true);_providers=providers.duplicate();resolver=handle_resolver
func has_topic(id: String) -> bool:return _compiled.get("topics",{}).has(id)
func identity() -> String:return str(_compiled.get("identity",""))
func topic_ids() -> Array:return _compiled.get("topics",{}).keys()
func bind(id: String, bindings: Variant, handles: Variant, turn: Dictionary = {}, saved_roles: Dictionary = {}) -> ActionResult:
 if not has_topic(id):return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"unknown_semantic_topic")
 return NarrativeContext.bind(id,_compiled.topics[id],bindings,handles,_compiled.schemas,resolver,turn,saved_roles)
func evaluate(context: NarrativeContext, stage: String, key: String = "", explain: bool = false) -> PolicyDecision:
 var start := Time.get_ticks_usec();calls+=1
 var result: PolicyDecision
 if not has_topic(context.topic_id):result=PolicyDecision.make("invalid","unknown_semantic_topic")
 else:
  var definition: Dictionary=_compiled.topics[context.topic_id]
  var group := "choices" if stage=="choice" else "actions" if stage=="action" else "stages"
  var id := key if group!="stages" else "continuation" if stage=="resume" else stage
  if not definition[group].has(id):result=PolicyDecision.make("invalid","unknown_policy_stage",stage+"/"+id)
  else:result=_evaluate(definition[group][id],context,stage+"/"+id,explain)
 elapsed_usec+=Time.get_ticks_usec()-start
 return result
func _evaluate(rule: Dictionary, context: NarrativeContext, path: String, explain: bool) -> PolicyDecision:
 nodes+=1
 if rule.op in ["all","any"]:
  var children: Array[PolicyDecision]=[]
  for i in range(rule.rules.size()):children.append(_evaluate(rule.rules[i],context,path+"/"+str(i),explain))
  var invalid := children.any(func(c):return c.status=="invalid")
  var allowed := children.all(func(c):return c.allowed) if rule.op=="all" else children.any(func(c):return c.allowed)
  var result := PolicyDecision.make("invalid" if invalid else "allowed" if allowed else "blocked")
  for child in children:
   if explain:result.evidence.append_array(child.evidence)
   if (invalid and child.status=="invalid") or (not invalid and not allowed and not child.allowed):result.reasons.append_array(child.reasons)
  return result
 if rule.op=="not":
  var child := _evaluate(rule.rule,context,path+"/not",explain)
  if child.status=="invalid":return child
  return PolicyDecision.make("blocked" if child.allowed else "allowed","policy_negated" if child.allowed else "",path,child.evidence if explain else [])
 var resolved: Variant=context.resolve(rule)
 if resolved==null:return PolicyDecision.make("invalid","missing_policy_role",path)
 var provider: Variant=_providers.get(rule.op)
 if not provider is Callable or not provider.is_valid():return PolicyDecision.make("invalid","policy_provider_unavailable",path+"/"+rule.op)
 var value: Variant=provider.call(resolved,context)
 if not value is Dictionary or not value.get("status") in ["allowed","blocked","invalid"] or not value.get("evidence",[]) is Array or not value.get("reason","") is String:return PolicyDecision.make("invalid","invalid_policy_provider_result",path)
 var reason := str(value.get("reason",""))
 if reason.is_empty() and value.status!="allowed":reason="policy_"+rule.op+"_"+value.status
 return PolicyDecision.make(value.status,reason,path,value.get("evidence",[]) if explain else [])
static func answer(allowed: bool, evidence: Array = []) -> Dictionary:
 return {"status":"allowed" if allowed else "blocked","evidence":evidence}
static func compare(value: float, operator: String, threshold: float) -> bool:
 match operator:
  ">=":return value>=threshold
  ">":return value>threshold
  "==":return value==threshold
  "<=":return value<=threshold
  "<":return value<threshold
 return false
