class_name KnowledgeBook
extends RefCounted
var _facts: Dictionary = {}
var _catalog: Array = []
var _notes: Array[String] = []
var aliases: Dictionary={}
var assertions := KnowledgeAssertions.new()
func fork() -> KnowledgeBook:
 var result:=KnowledgeBook.new()
 result._facts=_facts.duplicate(true);result._catalog=_catalog.duplicate();result._notes=_notes.duplicate();result.assertions=assertions.fork();result.aliases=aliases.duplicate(true)
 return result
func query_assertions(knower: String, fact: Dictionary, kinds: Array = ["initial","heard","relayed","observed"]) -> Array[Dictionary]:return assertions.query(knower,fact,kinds)
func _init(config: Dictionary = {}) -> void:
 _catalog = config.get("facts",[]).duplicate()
 for fact in config.get("initial_facts",[]): _facts[str(fact)] = {"source":"initial"}
 for note in config.get("initial_notes",[]): _notes.append(str(note))
func record(fact: StringName) -> Dictionary:
 if aliases.has(str(fact)):
  var rows:=assertions.query("player",aliases[str(fact)])
  if rows.is_empty():return {}
  var row: Dictionary=rows[0]
  return {"source":row.source,"speaker":row.speaker,"at":row.at}
 return _facts.get(str(fact),{}).duplicate(true)
func has(fact: StringName) -> bool:
 return not record(fact).is_empty()
func learn(fact: StringName, note: String, source: String = "") -> bool:
 if aliases.has(str(fact)) or has(fact) or (not _catalog.is_empty() and not str(fact) in _catalog): return false
 _facts[str(fact)] = {"source":source,"note":note}
 if not note.is_empty(): _notes.push_front(note)
 return true
func learn_from(fact: StringName, note: String, source: String, speaker: String, at: float) -> bool:
 if not learn(fact,note,source):return false
 _facts[str(fact)]["speaker"]=speaker
 _facts[str(fact)]["at"]=at
 return true
func notes() -> PackedStringArray:
 return PackedStringArray(_notes)
func snapshot() -> Dictionary:
 var result := {"facts":_facts.duplicate(true),"notes":_notes.duplicate()}
 if assertions.enabled:result["assertions"]=assertions.snapshot()
 return result
func restore(data: Dictionary) -> ActionResult:
 if not data.get("facts") is Dictionary or not data.get("notes") is Array:
  return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_knowledge")
 for id in data.facts:
  if aliases.has(id):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"duplicate_semantic_fact_authority")
  if (not _catalog.is_empty() and not id in _catalog) or not data.facts[id] is Dictionary or not data.facts[id].get("source") is String: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_fact_provenance")
 for record in data.facts.values():
  if record.has("speaker") or record.has("at"):
   if not record.get("speaker") is String or record.speaker.is_empty() or not ContentValidation.number(record.get("at")) or record.at<0:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_fact_provenance")
 for note in data.notes:
  if not note is String: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_note")
 if assertions.enabled:
  var result := assertions.restore(data.get("assertions"))
  if not result.ok:return result
 elif data.has("assertions"):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"unsupported_knowledge_assertions")
 _facts = data.facts.duplicate(true)
 _notes.assign(data.notes)
 return ActionResult.success()
func note_sources() -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for record in _facts.values():
  if record.get("note","").is_empty() or not str(record.source).begins_with("conversation_"):continue
  result.append({"chapter":str(record.source).get_slice("/",0),"label":str(record.note)})
 return result
