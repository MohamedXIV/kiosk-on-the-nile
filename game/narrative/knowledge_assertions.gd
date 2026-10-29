class_name KnowledgeAssertions
extends RefCounted
## Canonical per-knower assertions and their immutable hearing receipts.
var schemas: Dictionary = {}
var types: Dictionary = {}
var enabled: bool = false
var revision: int = 0
var _records: Dictionary = {}
var _receipts: Dictionary = {}
var _index: Dictionary = {}
var _seeds: Dictionary = {}
var _episodes: Dictionary = {}
var _clock: GameClock
func configure(schema: Dictionary, fact_types: Dictionary, seeds: Array, clock: GameClock) -> ActionResult:
 schemas=schema.duplicate(true);types=fact_types.duplicate(true);_clock=clock
 enabled=not types.is_empty() or not seeds.is_empty()
 _records={};_receipts={};_index={};_seeds={};revision=0
 for seed in seeds:
  var record := {"id":"seed/"+str(seed.id),"knower":seed.knower,"fact":seed.fact.duplicate(true),"kind":"initial","speaker":"","source":"seed/"+str(seed.id),"at":clock.world_minutes,"parent":""}
  _seeds[record.id]=record
  _records[record.id]=record.duplicate(true)
 _reindex()
 return ActionResult.success()
static func term_valid(term: Variant, fact_types: Dictionary, schema: Dictionary) -> bool:
 if not NarrativePolicyValidation.fields(term,["type","args"]) or not term.type is String or not fact_types.has(term.type) or not term.args is Dictionary or not NarrativePolicyValidation.same_keys(term.args,fact_types[term.type]):return false
 for key in term.args:
  if not NarrativePolicyValidation.typed(term.args[key],fact_types[term.type][key],schema):return false
 return true
static func term_key(term: Dictionary) -> String:return StableJson.stringify(term)
func query(knower: String, term: Dictionary, kinds: Array = ["initial","heard","relayed","observed"]) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for id in _index.get(knower,{}).get(term_key(term),[]):
  var record: Dictionary=_records[id]
  if record.kind in kinds:result.append(record.duplicate(true))
 result.sort_custom(func(a,b):
  var left: int=int(_receipts.get(a.source,{}).get("order",0));var right: int=int(_receipts.get(b.source,{}).get("order",0))
  return a.id<b.id if left==right else left<right)
 return result
func record(id: String) -> Dictionary:return _records.get(id,{}).duplicate(true)
func receipt(id: String) -> Dictionary:return _receipts.get(id,{}).duplicate(true)
func receipts() -> Array:return _receipts.values().duplicate(true)
func has_episode(episode: String) -> bool:return _episodes.has(episode)
func next_order() -> int:return _receipts.size()+1
func prepare(receipts_to_add: Array, assertions_to_add: Array) -> ActionResult:
 var records := _records.duplicate(true);var heard := _receipts.duplicate(true)
 for receipt_value in receipts_to_add:
  if not receipt_value is Dictionary or not receipt_value.get("id") is String:return _fail()
  if heard.has(receipt_value.id) and heard[receipt_value.id]!=receipt_value:return _fail()
  heard[receipt_value.id]=receipt_value.duplicate(true)
 for assertion in assertions_to_add:
  if not assertion is Dictionary or not assertion.get("id") is String:return _fail()
  if records.has(assertion.id) and records[assertion.id]!=assertion:return _fail()
  records[assertion.id]=assertion.duplicate(true)
 var validation := _validate(records,heard)
 if not validation.ok:return validation
 return ActionResult.success({"revision":revision,"records":records,"receipts":heard})
func commit(ticket: Dictionary) -> ActionResult:
 if ticket.get("revision")!=revision or not ticket.get("records") is Dictionary or not ticket.get("receipts") is Dictionary:return _fail()
 for id in _records:
  if ticket.records.get(id)!=_records[id]:return _fail()
 for id in _receipts:
  if ticket.receipts.get(id)!=_receipts[id]:return _fail()
 var valid := _validate(ticket.records,ticket.receipts)
 if not valid.ok:return valid
 _records=ticket.records.duplicate(true);_receipts=ticket.receipts.duplicate(true);revision+=1;_reindex()
 return ActionResult.success()
func snapshot() -> Dictionary:return {"records":_records.duplicate(true),"receipts":_receipts.duplicate(true)}
func restore(data: Variant) -> ActionResult:
 if not NarrativePolicyValidation.fields(data,["records","receipts"]) or not data.records is Dictionary or not data.receipts is Dictionary:return _fail()
 var result := _validate(data.records,data.receipts)
 if not result.ok:return result
 _records=data.records.duplicate(true);_receipts=data.receipts.duplicate(true);revision+=1;_reindex()
 return ActionResult.success()
func _validate(records: Dictionary, heard: Dictionary) -> ActionResult:
 for id in _seeds:
  if records.get(id)!=_seeds[id]:return _fail()
 for id in heard:
  var r: Variant=heard[id]
  if not NarrativePolicyValidation.fields(r,["id","episode","beat","topic","action","speaker","listener","at","order","catalog","knowledge_catalog","identity","encounter","participants","story","story_hash","assertions"]) or id!=r.id or not r.episode is String or not r.episode.begins_with("conversation_") or not ContentValidation.integer(r.beat) or r.beat<1 or not r.topic is String or not r.topic.is_valid_identifier() or not r.action is String or not r.action.is_valid_identifier() or not _actor(r.speaker) or not _actor(r.listener) or r.speaker==r.listener or not ContentValidation.bounded(r.at,0,_clock.world_minutes) or not ContentValidation.integer(r.order) or r.order<1 or r.order>heard.size() or not r.catalog is String or r.catalog.length()!=64 or not r.knowledge_catalog is String or not r.identity is Dictionary or not r.encounter is String or not r.participants is Array or not r.participants.all(func(a):return _actor(a)) or not r.speaker in r.participants or not r.story is String or not r.story_hash is String or r.story_hash.length()!=64 or not r.assertions is Array or r.assertions.is_empty() or id!=receipt_id(r.episode,int(r.beat),r.action,r.listener):return _fail()
  var seen := {}
  for assertion_id in r.assertions:
   if not assertion_id is String or seen.has(assertion_id) or not records.get(assertion_id) is Dictionary or records[assertion_id].get("source")!=id:return _fail()
   seen[assertion_id]=true
 for id in records:
  var r: Variant=records[id]
  if not NarrativePolicyValidation.fields(r,["id","knower","fact","kind","speaker","source","at","parent"]) or id!=r.id or not _actor(r.knower) or not term_valid(r.fact,types,schemas) or not r.kind in ["initial","heard","relayed"] or not r.source is String or not r.parent is String or not r.speaker is String or not ContentValidation.bounded(r.at,0,_clock.world_minutes):return _fail()
  if r.kind=="initial":
   if not _seeds.has(id) or r!=_seeds[id]:return _fail()
   continue
  var receipt_value: Variant=heard.get(r.source)
  if not receipt_value is Dictionary or not id in receipt_value.assertions or r.knower!=receipt_value.listener or r.speaker!=receipt_value.speaker or r.at!=receipt_value.at:return _fail()
  if r.kind=="heard" and not r.parent.is_empty():return _fail()
  if r.kind=="relayed":
   var parent: Variant=records.get(r.parent)
   if not parent is Dictionary or parent.get("knower")!=r.speaker or parent.get("fact")!=r.fact or not ContentValidation.number(parent.get("at")) or parent.at>r.at:return _fail()
   if parent.get("kind")!="initial":
    var upstream: Variant=heard.get(parent.get("source"))
    if not upstream is Dictionary or not ContentValidation.integer(upstream.get("order")) or upstream.order>=receipt_value.order or (upstream.episode==receipt_value.episode and upstream.beat>=receipt_value.beat):return _fail()
  var cursor: String=id;var visited := {}
  while not cursor.is_empty():
   if visited.has(cursor) or not records.has(cursor):return _fail()
   visited[cursor]=true;cursor=str(records[cursor].get("parent",""))
 var orders := {}
 for r in heard.values():
  var order_id := int(r.order)
  if orders.has(order_id):return _fail()
  orders[order_id]=r.at
 var previous := -1.0
 for order in range(1,heard.size()+1):
  if not orders.has(order) or float(orders[order])<previous:return _fail()
  previous=float(orders[order])
 return ActionResult.success()
static func receipt_id(episode: String, beat: int, action: String, listener: String) -> String:return "%s/%d/semantic/%s/%s" % [episode,beat,action,listener]
func _actor(value: Variant) -> bool:return NarrativePolicyValidation.typed(value,"actor",schemas)
func _reindex() -> void:
 _index={};_episodes={}
 for heard in _receipts.values():_episodes[heard.episode]=true
 for id in _records:
  var record_value: Dictionary=_records[id];var key:=term_key(record_value.fact)
  if not _index.has(record_value.knower):_index[record_value.knower]={}
  if not _index[record_value.knower].has(key):_index[record_value.knower][key]=[]
  _index[record_value.knower][key].append(id)
static func _fail() -> ActionResult:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_knowledge_assertions")
