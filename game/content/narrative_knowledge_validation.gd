class_name NarrativeKnowledgeValidation
extends RefCounted
static func empty_catalog() -> Dictionary:return {"initial":[],"actions":{}}
static func validate(bundle: Dictionary, compiled: Dictionary) -> ActionResult:
 var social_config:=SemanticSocialValidation.validate_config(bundle)
 if not social_config.ok:return social_config
 var data: Variant=bundle.get("narrative_knowledge",empty_catalog())
 if not NarrativePolicyValidation.fields(data,["initial","actions"],["legacy_player_aliases"]) or not data.initial is Array or not data.actions is Dictionary:return _fail("catalog")
 var types: Dictionary=bundle.get("narrative_policies",{}).get("fact_types",{})
 if not data.get("legacy_player_aliases",{}) is Dictionary:return _fail("legacy_player_aliases")
 for id in data.get("legacy_player_aliases",{}):
  if not id in bundle.social.facts or not KnowledgeAssertions.term_valid(data.legacy_player_aliases[id],types,compiled.schemas):return _fail("legacy_player_alias")
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
   if not topic.actions.has(action_id) or not NarrativePolicyValidation.fields(action,["listeners","assertions"],["channel","social","choice","domain","choice_assertions"]) or not action.get("channel","hearing") in compiled.schemas.channels or not action.listeners is Array or action.listeners.is_empty() or action.listeners.size()>16 or not action.assertions is Array or not action.get("social",[]) is Array or (action.assertions.is_empty() and action.get("social",[]).is_empty()) or action.assertions.size()>16 or action.get("social",[]).size()>16:return _fail(path)
   if action.has("choice") and (not action.choice is String or not topic.choices.has(action.choice)):return _fail(path+"/choice")
   if action.has("domain"):
    var domain: Variant=action.domain
    if not NarrativePolicyValidation.fields(domain,["provider","command","actor","scope"]) or domain.provider!="home" or not domain.command in ["invite","cancel","heard","goodbye"] or not NarrativePolicyValidation.reference_valid(domain.actor,"actor",roles,topic.bindings,compiled.schemas) or not NarrativePolicyValidation.reference_valid(domain.scope,"string",roles,topic.bindings,compiled.schemas) or action.listeners!=[{"actor":"player"}] or (domain.command!="heard" and not action.has("choice")):return _fail(path+"/domain")
   for effect in action.get("social",[]):
    if not SemanticSocialValidation.valid(effect,compiled.schemas,roles,topic.bindings):return _fail(path+"/social")
   for listener in action.listeners:
    if not NarrativePolicyValidation.reference_valid(listener,"actor",topic.roles.keys(),topic.bindings,compiled.schemas):return _fail(path+"/listener")
   if action.has("choice_assertions"):
    if action.has("domain") or not action.has("choice") or action.listeners!=[{"actor":"player"}] or not action.choice_assertions is Array or action.choice_assertions.is_empty() or action.choice_assertions.size()>16:return _fail(path+"/choice_assertions")
    for assertion in action.choice_assertions:
     if not NarrativePolicyValidation.fields(assertion,["kind","fact","parent"]) or assertion.kind!="relayed" or assertion.parent!={"actor":"player"} or not _term(assertion.fact,types,compiled.schemas,topic.roles.keys(),topic.bindings):return _fail(path+"/choice_assertion")
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
