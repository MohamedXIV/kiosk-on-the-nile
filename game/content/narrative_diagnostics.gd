class_name NarrativeDiagnostics
extends RefCounted
## Offline conservative author assistance. Warnings never change permissions.
static func inspect(bundle: Dictionary) -> Dictionary:
 var report: Dictionary={"errors":[],"warnings":[],"limits":["No general proof of arbitrary Ink reachability.","Source analysis matches fact types, not all possible role substitutions."]}
 var checked:=SemanticNarrative.validate(bundle)
 if not checked.ok:
  var path: String=str(checked.details.get("path","narrative_policies"))
  report.errors.append({"reason":"invalid_contract","file":_file(path),"path":path,"message":str(checked.message_key)})
  return report
 var catalog: Dictionary=bundle.get("narrative_policies",SemanticNarrative.empty_catalog())
 var compiled: Dictionary=checked.details
 var sources: Dictionary={}
 for seed in bundle.get("narrative_knowledge",{}).get("initial",[]):sources[seed.fact.type]=true
 for actions in bundle.get("narrative_knowledge",{}).get("actions",{}).values():
  for action in actions.values():
   for assertion in action.assertions+action.get("choice_assertions",[]):sources[assertion.fact.type]=true
 for topic_id in compiled.topics:
  var topic: Dictionary=compiled.topics[topic_id]
  for group in ["stages","choices","actions"]:
   for id in topic[group]:
    var path: String="topics/"+str(topic_id)+"/"+group+"/"+str(id)
    _walk(topic[group][id],path,sources,report.warnings)
 var story_topics: Dictionary={}
 for encounter in bundle.get("encounters",{}).values():
  if not encounter.has("semantic_topic"):continue
  if not story_topics.has(encounter.story):story_topics[encounter.story]=[]
  if not encounter.semantic_topic in story_topics[encounter.story]:story_topics[encounter.story].append(encounter.semantic_topic)
 for story in story_topics:
  var raw: Dictionary=bundle.get("story_"+str(story),{})
  var mapped:=InkChoiceMap.compile(raw)
  if not mapped.ok:
   report.errors.append({"reason":"invalid_ink_choice_map","file":"content/stories/"+str(story)+".ink.json","path":str(story),"message":str(mapped.message_key)})
   continue
  var action_ids: Dictionary={}
  var effect_ids: Dictionary={}
  for topic in story_topics[story]:
   for id in catalog.topics[topic].get("actions",{}):action_ids[id]=true
   for id in bundle.get("narrative_knowledge",{}).get("actions",{}).get(topic,{}):effect_ids[id]=true
  if story_topics[story].size()>1:report.warnings.append({"reason":"shared_story_binding_unproven","file":"content/stories/"+str(story)+".ink.json","path":str(story),"message":"IDs are checked against the story catalog only; branch-to-active-topic attribution is not proven. Split stories or verify each encounter binding explicitly.","topics":story_topics[story].duplicate()})
  _ink_actions(raw,[],action_ids,effect_ids,"content/stories/"+str(story)+".ink.json",report.errors)
  var ids: Dictionary={}
  for topic in story_topics[story]:
   for id in catalog.topics[topic].get("choices",{}):ids[id]=true
  for target in mapped.details.choices:
   var id: String=mapped.details.choices[target]
   if not ids.has(id):report.errors.append({"reason":"unknown_ink_choice","file":"content/stories/"+str(story)+".ink.json","path":str(target),"message":id})
 return report
static func _file(path: String) -> String:
 var section:=path.get_slice("/",0).get_slice(".",0)
 return "content/"+section+".json"
static func _walk(rule: Dictionary, path: String, sources: Dictionary, warnings: Array) -> void:
 if rule.op=="knowledge" and rule.fact.type!="legacy_player_fact" and not sources.has(rule.fact.type):warnings.append({"reason":"no_declared_fact_source","file":"content/narrative_policies.json","path":path,"message":rule.fact.type})
 if rule.op=="all":
  var intervals: Dictionary={}
  for child in rule.rules:
   if child.op!="relationship":continue
   var key:=StableJson.stringify([child.from,child.to,child.axis])
   if not intervals.has(key):intervals[key]={"lower":-INF,"upper":INF,"lower_open":false,"upper_open":false}
   var interval: Dictionary=intervals[key]
   var value:=float(child.value)
   if child.compare in [">=",">","=="] and value>=float(interval.lower):
    interval.lower_open=(child.compare==">") or (value==float(interval.lower) and interval.lower_open);interval.lower=value
   if child.compare in ["<=","<","=="] and value<=float(interval.upper):
    interval.upper_open=(child.compare=="<") or (value==float(interval.upper) and interval.upper_open);interval.upper=value
  for key in intervals:
   var interval: Dictionary=intervals[key]
   if interval.lower>interval.upper or (interval.lower==interval.upper and (interval.lower_open or interval.upper_open)):warnings.append({"reason":"contradictory_direct_all","file":"content/narrative_policies.json","path":path,"message":key})
 if rule.op in ["all","any"]:
  for i in range(rule.rules.size()):_walk(rule.rules[i],path+"/"+str(i),sources,warnings)
 elif rule.op=="not":_walk(rule.rule,path+"/not",sources,warnings)

static func _ink_actions(value: Variant, path: Array, actions: Dictionary, effects: Dictionary, file: String, errors: Array) -> void:
 if value is String:
  var prefix: String="^effect:semantic|" if value.begins_with("^effect:semantic|") else "^policy_action:" if value.begins_with("^policy_action:") else ""
  if prefix.is_empty():return
  var id: String=value.trim_prefix(prefix).strip_edges()
  if not actions.has(id) or (prefix=="^effect:semantic|" and not effects.has(id)):errors.append({"reason":"unknown_ink_action","file":file,"path":"/".join(path),"message":id})
 elif value is Array:
  for i in range(value.size()):_ink_actions(value[i],path+[str(i)],actions,effects,file,errors)
 elif value is Dictionary:
  for key in value:_ink_actions(value[key],path+[str(key)],actions,effects,file,errors)

static func manifest_paths(report: Dictionary, manifest: Dictionary, directory: String) -> Dictionary:
 var result:=report.duplicate(true)
 var sections: Dictionary=manifest.get("sections",{}) if manifest.get("sections",{}) is Dictionary else {}
 for group in ["errors","warnings"]:
  for row in result.get(group,[]):
   if not row.has("file"):continue
   var file: String=str(row.file).trim_prefix("content/")
   var section: String="story_"+file.get_file().trim_suffix(".ink.json") if file.begins_with("stories/") else file.trim_suffix(".json")
   row.file=directory.path_join(str(sections.get(section,file)))
 return result
static func load_error(result: ActionResult, manifest: Dictionary, directory: String) -> Dictionary:
 var path: String=str(result.details.get("path","manifest"))
 return manifest_paths({"errors":[{"reason":str(result.message_key),"path":path,"file":_file(path),"details":result.details}],"warnings":[]},manifest,directory)
