class_name NarrativeKnowledgeValidation
extends RefCounted
static func empty_catalog() -> Dictionary:return {"initial":[],"actions":{}}
static func validate(bundle: Dictionary, compiled: Dictionary) -> ActionResult:
 var data: Variant=bundle.get("narrative_knowledge",empty_catalog())
 if not NarrativePolicyValidation.fields(data,["initial","actions"]) or not data.initial is Array or not data.actions is Dictionary:return _fail("catalog")
 var types: Dictionary=bundle.get("narrative_policies",{}).get("fact_types",{})
 var ids := {}
 for seed in data.initial:
  if not NarrativePolicyValidation.fields(seed,["id","knower","fact"]) or not seed.id is String or not seed.id.is_valid_identifier() or ids.has(seed.id) or not NarrativePolicyValidation.typed(seed.knower,"actor",compiled.schemas) or not KnowledgeAssertions.term_valid(seed.fact,types,compiled.schemas) or seed.fact.type=="legacy_player_fact":return _fail("initial")
  ids[seed.id]=true
 for topic_id in data.actions:
  if not compiled.topics.has(topic_id) or not data.actions[topic_id] is Dictionary:return _fail("topic")
  var topic: Dictionary=compiled.topics[topic_id]
  var roles: Array=topic.roles.keys()+topic.get("turn_roles",[])
  for action_id in data.actions[topic_id]:
   var action: Variant=data.actions[topic_id][action_id]
   var path: String=str(topic_id)+"/"+str(action_id)
   if not topic.actions.has(action_id) or not NarrativePolicyValidation.fields(action,["listeners","assertions"],["channel"]) or not action.get("channel","hearing") in compiled.schemas.channels or not action.listeners is Array or action.listeners.is_empty() or action.listeners.size()>16 or not action.assertions is Array or action.assertions.is_empty() or action.assertions.size()>16:return _fail(path)
   for listener in action.listeners:
    if not NarrativePolicyValidation.reference_valid(listener,"actor",topic.roles.keys(),topic.bindings,compiled.schemas):return _fail(path+"/listener")
   for assertion in action.assertions:
    if not assertion is Dictionary or not assertion.get("kind") in ["heard","relayed"] or not NarrativePolicyValidation.fields(assertion,["kind","fact"],["parent"]) or not _term(assertion.fact,types,compiled.schemas,roles,topic.bindings):return _fail(path+"/assertion")
    if assertion.kind=="relayed":
     if not NarrativePolicyValidation.reference_valid(assertion.get("parent"),"actor",roles,topic.bindings,compiled.schemas):return _fail(path+"/parent")
    elif assertion.has("parent"):return _fail(path+"/parent")
 return ActionResult.success()
static func _term(term: Variant, types: Dictionary, schemas: Dictionary, roles: Array, bindings: Dictionary) -> bool:
 if not NarrativePolicyValidation.fields(term,["type","args"]) or not term.type is String or term.type=="legacy_player_fact" or not types.has(term.type) or not term.args is Dictionary or not NarrativePolicyValidation.same_keys(term.args,types[term.type]):return false
 for key in term.args:
  if not NarrativePolicyValidation.reference_valid(term.args[key],types[term.type][key],roles,bindings,schemas):return false
 return true
static func _fail(path: String) -> ActionResult:return ContentValidation.fail("narrative_knowledge/"+path)
