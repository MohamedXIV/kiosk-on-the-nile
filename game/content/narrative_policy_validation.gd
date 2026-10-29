class_name NarrativePolicyValidation
extends RefCounted
## Compile authored data once. Expanded nodes contain no policy/profile calls.
var _data: Dictionary
var _schemas: Dictionary
var _error: String = ""
var _nodes: int = 0
static func same_keys(a: Dictionary, b: Dictionary) -> bool:
 return a.size()==b.size() and a.keys().all(func(k):return b.has(k))
static func equivalent(a: Variant, b: Variant) -> bool:return StableJson.stringify(a)==StableJson.stringify(b)
static func fields(value: Variant, required: Array, optional: Array = []) -> bool:
 if not value is Dictionary:return false
 for key in required:
  if not value.has(key):return false
 return value.keys().all(func(k):return k in required or k in optional)
static func typed(value: Variant, kind: String, schemas: Dictionary) -> bool:
 if kind=="number":return ContentValidation.number(value)
 if kind in ["string","event"]:return value is String and not value.is_empty() and value.length()<=128
 return value is String and value in schemas.get("types",{}).get(kind,[])
static func compile(data: Variant, schemas: Dictionary) -> ActionResult:
 var compiler := NarrativePolicyValidation.new();compiler._schemas=schemas
 return compiler._compile(data)
func _bad(path: String) -> Dictionary:
 if _error.is_empty():_error=path
 return {}
static func _unique_count(values: Array) -> int:
 var seen := {}
 for value in values:seen[value]=true
 return seen.size()
func _ids(value: Variant) -> bool:
 return value is Array and value.all(func(v):return v is String and v.is_valid_identifier()) and value.size()==_unique_count(value)
func _ref(value: Variant, kind: String, roles: Array, bindings: Dictionary) -> bool:
 return reference_valid(value,kind,roles,bindings,_schemas)
static func reference_valid(value: Variant, kind: String, roles: Array, bindings: Dictionary, schemas: Dictionary) -> bool:
 if value is Dictionary:
  if fields(value,["role"]):return kind=="actor" and value.role is String and value.role in roles
  if fields(value,["actor"]):return kind=="actor" and typed(value.actor,kind,schemas)
  if fields(value,["binding"]):return value.binding is String and bindings.get(value.binding)==kind
  return false
 return typed(value,kind,schemas) and kind!="actor"
func _refs(value: Variant, roles: Array, bindings: Dictionary) -> bool:
 return value is Array and not value.is_empty() and value.size()<=16 and value.all(func(v):return _ref(v,"actor",roles,bindings))
func _compile(data: Variant) -> ActionResult:
 if not fields(data,["contract_version","profiles","policies","topics","fact_types"]) or (not ContentValidation.integer(data.contract_version) or data.contract_version!=1):return ContentValidation.fail("narrative_policies.catalog")
 for key in ["profiles","policies","topics","fact_types"]:
  if not data[key] is Dictionary:return ContentValidation.fail("narrative_policies."+key)
 _data=data.duplicate(true)
 var profile_fields := {}
 for id in _data.profiles:
  if not id is String or not id.is_valid_identifier() or not _data.profiles[id] is Dictionary or _data.profiles[id].is_empty():return ContentValidation.fail("narrative_policies.profile")
  for key in _data.profiles[id]:
   if not key is String or not key.is_valid_identifier() or not ContentValidation.bounded(_data.profiles[id][key],0,100000):return ContentValidation.fail("narrative_policies.profile_field")
   profile_fields[key]=0
 for id in _data.fact_types:
  if not id is String or not id.is_valid_identifier() or not _data.fact_types[id] is Dictionary:return ContentValidation.fail("narrative_policies.fact_type")
  for type in _data.fact_types[id].values():
   if not type is String or (not _schemas.get("types",{}).has(type) and not type in ["string","number"]):return ContentValidation.fail("narrative_policies.fact_argument")
 for id in _data.policies:
  var p: Variant=_data.policies[id]
  if not id is String or not id.is_valid_identifier() or not fields(p,["roles","parameters","requires"]) or not _ids(p.roles) or not p.parameters is Dictionary:return ContentValidation.fail("narrative_policies.policy")
  var params := {}
  for key in p.parameters:
   if not key is String or not key.is_valid_identifier() or p.parameters[key]!="profile" or _data.profiles.is_empty():return ContentValidation.fail("narrative_policies.parameter")
   # Structural validation must not choose an unrelated profile by insertion
   # order. Each real call below still validates its selected profile's fields.
   params[key]=profile_fields
  _nodes=0
  _expand(p.requires,p.roles,{},params,[],0,0)
  if not _error.is_empty():return ContentValidation.fail("narrative_policies.policies."+id+"/"+_error)
 var topics := {}
 for id in _data.topics:
  var topic: Variant=_data.topics[id]
  if not id is String or not id.is_valid_identifier() or not fields(topic,["bindings","roles","stages"],["turn_roles","distinct_roles","choices","actions"]) or not topic.bindings is Dictionary or not topic.roles is Dictionary or not topic.stages is Dictionary or not fields(topic.stages,["start","continuation"],["offer"]):return ContentValidation.fail("narrative_policies.topic")
  for key in topic.bindings:
   if not key is String or not key.is_valid_identifier() or (not _schemas.get("types",{}).has(topic.bindings[key]) and not topic.bindings[key] in ["string","number","event"]):return ContentValidation.fail("narrative_policies.binding_type")
  if not _ids(topic.roles.keys()) or (not _ids(topic.get("turn_roles",[])) or not topic.get("turn_roles",[]).all(func(v):return v in ["speaker","listener"])) or topic.roles.size()>16 or topic.get("turn_roles",[]).size()>2:return ContentValidation.fail("narrative_policies.roles")
  for role in topic.roles:
   if not _ref(topic.roles[role],"actor",[],topic.bindings) or role in topic.get("turn_roles",[]):return ContentValidation.fail("narrative_policies.role_binding")
  var distinct: Variant=topic.get("distinct_roles",[])
  if not distinct is Array:return ContentValidation.fail("narrative_policies.distinct_roles")
  for pair in distinct:
   if not pair is Array or pair.size()!=2 or pair[0]==pair[1] or not pair.all(func(v):return v in topic.roles):return ContentValidation.fail("narrative_policies.distinct_roles")
  var out: Dictionary=topic.duplicate(true)
  for group in ["stages","choices","actions"]:
   if not topic.get(group,{}) is Dictionary:return ContentValidation.fail("narrative_policies.rules")
   out[group]={}
   var roles: Array=topic.roles.keys()
   if group!="stages":roles+=topic.get("turn_roles",[])
   for key in topic.get(group,{}):
    if not key is String or not key.is_valid_identifier():return ContentValidation.fail("narrative_policies.rule_id")
    _nodes=0
    out[group][key]=_expand(topic[group][key],roles,topic.bindings,{},[],0,0)
    if not _error.is_empty():return ContentValidation.fail("narrative_policies.topics."+id+"/"+group+"/"+key+"/"+_error)
  if not out.stages.has("offer"):out.stages.offer=out.stages.start
  topics[id]=out
 return ActionResult.success({"topics":topics,"schemas":_schemas.duplicate(true),"identity":StableJson.stringify(_data).sha256_text()})
func _substitute(value: Variant, role_map: Dictionary, params: Dictionary, depth: int = 0) -> Variant:
 if depth>28 or (value is Array and value.size()>256) or (value is Dictionary and value.size()>32):
  _bad("narrative_policies.substitution_limit");return null
 if value is Dictionary:
  if fields(value,["role"]) and role_map.has(value.role):return role_map[value.role].duplicate(true)
  if fields(value,["parameter","field"]):
   var profile: Variant=params.get(value.parameter)
   return profile.get(value.field) if profile is Dictionary else null
  var out := {}
  for key in value:out[key]=_substitute(value[key],role_map,params,depth+1)
  return out
 if value is Array:return value.map(func(v):return _substitute(v,role_map,params,depth+1))
 return value
func _expand(raw: Variant, roles: Array, bindings: Dictionary, params: Dictionary, stack: Array, depth: int, named: int) -> Dictionary:
 _nodes+=1
 var path := "narrative_policies.rule/"+str(_nodes)
 if depth>24 or _nodes>256 or named>8 or not raw is Dictionary:return _bad(path+"/limit_or_shape")
 var r: Variant=_substitute(raw,{},params)
 if not r is Dictionary or not r.get("op") is String:return _bad(path+"/operator")
 if r.op in ["all","any"]:
  if not fields(r,["op","rules"]) or not r.rules is Array or r.rules.is_empty():return _bad(path+"/children")
  var children: Array=[]
  for part in r.rules:children.append(_expand(part,roles,bindings,params,stack,depth+1,named))
  return {"op":r.op,"rules":children}
 if r.op=="not":
  if not fields(r,["op","rule"]):return _bad(path+"/not")
  return {"op":"not","rule":_expand(r.rule,roles,bindings,params,stack,depth+1,named)}
 if r.op=="policy":
  if not fields(r,["op","id","roles","parameters"]) or not _data.policies.has(r.id) or r.id in stack or not r.roles is Dictionary or not r.parameters is Dictionary:return _bad(path+"/policy")
  var p: Dictionary=_data.policies[r.id]
  if not (r.roles.size()==p.roles.size() and p.roles.all(func(k):return r.roles.has(k))) or not same_keys(r.parameters,p.parameters):return _bad(path+"/policy_signature")
  for ref in r.roles.values():
   if not _ref(ref,"actor",roles,bindings):return _bad(path+"/policy_role")
  var resolved := {}
  for key in r.parameters:
   if not r.parameters[key] is String or not _data.profiles.has(r.parameters[key]):return _bad(path+"/profile")
   resolved[key]=_data.profiles[r.parameters[key]]
  return _expand(_substitute(p.requires,r.roles,resolved),roles,bindings,{},stack+[r.id],depth+1,named+1)
 var ok := false
 match r.op:
  "relationship":ok=fields(r,["op","from","to","axis","compare","value"]) and _ref(r.from,"actor",roles,bindings) and _ref(r.to,"actor",roles,bindings) and r.axis in _schemas.get("axes",[]) and r.compare in [">=",">","==","<=","<"] and ContentValidation.number(r.value)
  "knowledge":
   ok=fields(r,["op","knower","fact","provenance_kinds"]) and _ref(r.knower,"actor",roles,bindings) and fields(r.fact,["type","args"]) and _data.fact_types.has(r.fact.type) and r.fact.args is Dictionary and same_keys(r.fact.args,_data.fact_types[r.fact.type]) and r.provenance_kinds is Array and not r.provenance_kinds.is_empty()
   if ok:
    for key in r.fact.args:
     if not _ref(r.fact.args[key],_data.fact_types[r.fact.type][key],roles,bindings):ok=false
    for kind in r.provenance_kinds:
     if not kind in ["heard","initial","relayed","observed"]:ok=false
  "acquaintance":ok=fields(r,["op","observer","other","calendar_days","shared_days"]) and _ref(r.observer,"actor",roles,bindings) and _ref(r.other,"actor",roles,bindings) and ContentValidation.integer(r.calendar_days) and r.calendar_days>=0 and ContentValidation.integer(r.shared_days) and r.shared_days>=0
  "consent":ok=fields(r,["op","grantor","recipient","purpose","scope"]) and _ref(r.grantor,"actor",roles,bindings) and _ref(r.recipient,"actor",roles,bindings) and typed(r.purpose,"string",_schemas) and _ref(r.scope,"string",roles,bindings)
  "domain","event":
   var registry: Dictionary=_schemas.get("queries" if r.op=="domain" else "events",{})
   ok=fields(r,["op","id","args"]) and registry.has(r.id) and r.args is Dictionary and same_keys(r.args,registry[r.id])
   if ok:
    for key in r.args:
     if not _ref(r.args[key],registry[r.id][key],roles,bindings):ok=false
  "available":ok=fields(r,["op","actors"]) and _refs(r.actors,roles,bindings)
  "near":ok=fields(r,["op","actors","channel"]) and _refs(r.actors,roles,bindings) and r.channel in _schemas.get("channels",[])
  "time_window":ok=fields(r,["op","start","end"]) and ContentValidation.bounded(r.start,0,1440) and ContentValidation.bounded(r.end,0,1440) and r.start<=r.end
  "unused":ok=fields(r,["op","scope","actors"],["evidence"]) and r.scope in ["once","day","visit","evidence"] and _refs(r.actors,roles,bindings) and (r.scope!="evidence" or _ref(r.get("evidence"),"string",roles,bindings))
 if not ok:return _bad(path+"/"+str(r.op))
 return r
