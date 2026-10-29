class_name SemanticSocialMemory
extends RefCounted
## SocialLife-owned heard memory; score gains remain in RelationshipStore.
var enabled: bool = false
var revision: int = 0
var _session: GameSession
var _schemas: Dictionary
var _cap: float
var _events: Dictionary = {}
var _indexes: Dictionary = {"introductions":{},"days":{},"consents":{},"consumed":{},"positive":{}}
func configure(session: GameSession) -> void:
 _session=session;_schemas=SemanticNarrative.schemas(session.config.data)
 _cap=float(session.config.data.get("narrative_social",{}).get("daily_gain_cap",session.config.data.social_life.relationships.daily_cap))
 enabled=false
 for actions in session.config.data.get("narrative_knowledge",{}).get("actions",{}).values():
  for action in actions.values():enabled=enabled or not action.get("social",[]).is_empty()
static func pair(from: String, to: String) -> String:return StableJson.stringify([from,to])
func acquaintance(observer: String, other: String) -> Dictionary:
 var key:=pair(observer,other);var intro: Dictionary=_indexes.introductions.get(key,{})
 return {"introduced":not intro.is_empty(),"introduced_at":intro.get("at",-1),"calendar_days":floori(_session.clock.world_minutes/1440.0)-floori(float(intro.get("at",_session.clock.world_minutes))/1440.0),"shared_days":_indexes.days.get(key,{}).size(),"source":intro.get("source","")}
func people(observer: String) -> Array:
 var result: Array=[]
 for key in _indexes.introductions:
  var actors: Array=JSON.parse_string(key)
  if actors[0]==observer:result.append(actors[1])
 return result
func consent(grantor: String, recipient: String, purpose: String, scope: String) -> Dictionary:
 var key:=StableJson.stringify([grantor,recipient,purpose,scope])
 var latest: Dictionary=_indexes.consents.get(key,{})
 return {"allowed":not latest.is_empty() and latest.decision=="grant" and _session.clock.world_minutes<float(latest.at)+float(latest.duration),"source":latest.get("source",""),"decision":latest.get("decision","")}
func occurred(kind: String, observer: String, other: String) -> bool:
 var key:=pair(observer,other)
 return _indexes.introductions.has(key) if kind=="introduction" else not _indexes.days.get(key,{}).is_empty() if kind=="company" else false
static func scope_key(identity: Dictionary, scope: String, actors: Array, evidence: String, at: float, visits: Dictionary) -> String:
 var key := {"identity":identity,"scope":scope,"actors":actors}
 if scope=="day":key["day"]=floori(at/1440.0)
 if scope=="evidence":key["evidence"]=evidence
 if scope=="visit":
  var handles := {}
  for actor in actors:
   if actor=="player":continue
   if not visits.get(actor) is String or visits[actor].is_empty():return ""
   handles[actor]=visits[actor]
  if handles.is_empty():return ""
  key["visits"]=handles
 return StableJson.stringify(key)
func unused(key: String) -> bool:return not _indexes.consumed.has(key)
func positive_used(from: String, to: String, at: float) -> float:return float(_indexes.positive.get(StableJson.stringify([from,to,floori(at/1440.0)]),0))
func positive_totals() -> Dictionary:return _indexes.positive.duplicate()
func event(id: String) -> Dictionary:return _events.get(id,{}).duplicate(true)
func snapshot() -> Dictionary:return {"events":_events.duplicate(true)}
func prepare(receipts: Array) -> ActionResult:
 var events := _events.duplicate(true)
 var sources: Dictionary=_session.knowledge.assertions.snapshot().receipts
 for receipt in receipts:
  sources[receipt.id]=receipt
  for i in range(receipt.get("social",[]).size()):
   var id: String=receipt.id+"/social/"+str(i)
   if events.has(id):return _fail()
   var effect: Dictionary=receipt.social[i]
   var legacy_used:=_session.social_life.legacy_positive_used(effect.from,effect.to,float(receipt.at)) if effect.kind=="relationship" else 0.0
   events[id]={"id":id,"source":receipt.id,"index":i,"effect":effect.duplicate(true),"applied":0,"legacy_used":legacy_used}
 var derived := _derive(events,sources,false)
 if not derived.ok:return derived
 return ActionResult.success({"revision":revision,"events":derived.details.events,"gains":derived.details.gains,"sources":sources})
func can_commit(ticket: Dictionary) -> ActionResult:
 if ticket.get("revision")!=revision or not ticket.get("events") is Dictionary or not ticket.get("sources") is Dictionary:return _fail()
 for id in _events:
  if ticket.events.get(id)!=_events[id]:return _fail()
 return _derive(ticket.events,ticket.sources,true)
func publish(ticket: Dictionary) -> void:
 _events=ticket.events.duplicate(true);_indexes=_derive(_events,ticket.sources,true).details.indexes;revision+=1
func restore(data: Variant) -> ActionResult:
 var derived := inspect(data)
 if not derived.ok:return derived
 _events=data.events.duplicate(true);_indexes=derived.details.indexes;revision+=1
 return ActionResult.success()
func inspect(data: Variant) -> ActionResult:
 if not NarrativePolicyValidation.fields(data,["events"]) or not data.events is Dictionary:return _fail()
 return _derive(data.events,_session.knowledge.assertions.snapshot().receipts,true)
func validate_links() -> ActionResult:
 for receipt in _session.knowledge.assertions.receipts():
  var source:=_session.effects.semantic_source(receipt.id)
  var effects: Array=receipt.get("social",[])
  if source.get("social",[]).size()!=effects.size() or (not effects.is_empty() and not enabled):return _fail()
  for i in range(effects.size()):
   var id: String=receipt.id+"/social/"+str(i)
   var row:=event(id)
   if row.is_empty() or not NarrativePolicyValidation.equivalent(source.social[i],row):return _fail()
   if row.effect.kind=="relationship":
    var gain: Dictionary={"id":id,"source":receipt.id,"from":row.effect.from,"to":row.effect.to,"axis":row.effect.axis,"amount":row.applied}
    if not NarrativePolicyValidation.equivalent(_session.relationships.semantic_gain(id),gain):return _fail()
 for id in _session.relationships.semantic_gain_ids():
  if event(str(id)).get("effect",{}).get("kind")!="relationship":return _fail()
 var legacy_days:=_session.social_life.legacy_daily()
 for day in legacy_days:
  for actor in legacy_days[day]:
   var legacy:=_session.social_life.legacy_positive_used(str(actor),"player",float(int(day)-1)*1440.0)
   if legacy+positive_used(str(actor),"player",float(int(day)-1)*1440.0)>maxf(_cap,float(_session.config.data.social_life.relationships.daily_cap))+0.001:return _fail()
 return ActionResult.success()
func _derive(events: Dictionary, sources: Dictionary, check_applied: bool) -> ActionResult:
 var ordered: Array=[]
 for id in events:
  var row: Variant=events[id]
  if not NarrativePolicyValidation.fields(row,["id","source","index","effect","applied","legacy_used"]) or row.id!=id or not row.source is String or not ContentValidation.integer(row.index) or row.index<0 or not ContentValidation.number(row.applied) or not ContentValidation.bounded(row.legacy_used,0,float(_session.config.data.social_life.relationships.daily_cap)) or not SemanticSocialValidation.valid(row.effect,_schemas,[],{},true):return _fail()
  if row.effect.kind!="relationship" and row.legacy_used!=0:return _fail()
  var receipt: Variant=sources.get(row.source)
  if not receipt is Dictionary or not receipt.get("social") is Array or int(row.index)>=receipt.social.size() or row.effect!=receipt.social[int(row.index)] or id!=row.source+"/social/"+str(int(row.index)):return _fail()
  ordered.append(row.duplicate(true))
 ordered.sort_custom(func(a,b):return int(a.index)<int(b.index) if sources[a.source].order==sources[b.source].order else sources[a.source].order<sources[b.source].order)
 var indexes := {"introductions":{},"days":{},"consents":{},"consumed":{}};var daily := {};var gained := {};var normalized := {};var gains: Array=[]
 for row in ordered:
  var r: Dictionary=sources[row.source];var e: Dictionary=row.effect;var applied:=0.0
  var day:=floori(float(r.at)/1440.0)
  match e.kind:
   "introduction":
    if e.observer!=r.listener or e.other!=r.speaker:return _fail()
    var key:=pair(e.observer,e.other)
    if not indexes.introductions.has(key):indexes.introductions[key]={"at":r.at,"source":row.source}
   "company":
    if not _heard_pair(e.observer,e.other,r):return _fail()
    var key:=pair(e.observer,e.other)
    if not indexes.days.has(key):indexes.days[key]={}
    indexes.days[key][str(day)]=row.source
   "relationship":
    if not _heard_pair(e.from,e.to,r):return _fail()
    var key:=StableJson.stringify([r.topic,r.action,e.from,e.to,e.axis,day])
    var daily_key:=StableJson.stringify([e.from,e.to,day])
    if not gained.has(key):
     applied=minf(float(e.amount),maxf(0,_cap-float(row.legacy_used)-float(daily.get(daily_key,0)))) if float(e.amount)>0 else float(e.amount)
     gained[key]=true;daily[daily_key]=float(daily.get(daily_key,0))+maxf(0,applied)
    gains.append({"id":row.id,"source":row.source,"from":e.from,"to":e.to,"axis":e.axis,"amount":applied})
   "consent":
    if e.grantor!=r.speaker or e.recipient!=r.listener:return _fail()
    var key:=StableJson.stringify([e.grantor,e.recipient,e.purpose,e.scope])
    indexes.consents[key]={"at":r.at,"duration":e.duration,"decision":e.decision,"source":row.source}
   "consume":
    if not e.actors.all(func(a):return a in [r.speaker,r.listener]):return _fail()
    var key:=scope_key(r.identity,e.scope,e.actors,str(e.get("evidence","")),float(r.at),r.get("visits",{}))
    if key.is_empty() or indexes.consumed.has(key):return _fail()
    indexes.consumed[key]=row.source
  if check_applied and row.applied!=applied:return _fail()
  row.applied=applied;normalized[row.id]=row
 indexes["positive"]=daily
 return ActionResult.success({"events":normalized,"indexes":indexes,"gains":gains})
static func _heard_pair(from: String, to: String, receipt: Dictionary) -> bool:return from!=to and from in [receipt.speaker,receipt.listener] and to in [receipt.speaker,receipt.listener]
static func _fail() -> ActionResult:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_semantic_social_memory")
