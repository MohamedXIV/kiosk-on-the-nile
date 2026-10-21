class_name KnowledgeBook
extends RefCounted
var _facts: Dictionary = {}
var _notes: Array[String] = []
func _init(config: Dictionary = {}) -> void:
 for fact in config.get("initial_facts",[]): _facts[str(fact)] = {"source":"initial"}
 for note in config.get("initial_notes",[]): _notes.append(str(note))
func has(fact: StringName) -> bool:
 return _facts.has(str(fact))
func learn(fact: StringName, note: String, source: String = "") -> bool:
 if has(fact): return false
 _facts[str(fact)] = {"source":source}
 if not note.is_empty(): _notes.push_front(note)
 return true
func notes() -> PackedStringArray:
 return PackedStringArray(_notes)
func snapshot() -> Dictionary:
 return {"facts":_facts.duplicate(true),"notes":_notes.duplicate()}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("facts") is Dictionary or not data.get("notes") is Array:
  return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_knowledge")
 for note in data.notes:
  if not note is String: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_note")
 _facts = data.facts.duplicate(true)
 _notes.assign(data.notes)
 return ActionResult.success()
