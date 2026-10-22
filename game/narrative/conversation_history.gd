class_name ConversationHistory
extends RefCounted
## A topic is consumed by committed speech, not by an E press or opening Ink.
## Keep the latest occurrence per authored topic/character, not an endless log.
var _records: Dictionary = {}
func select(encounter: StringName, definition: Dictionary, visit: VisitState, session: GameSession, mode: int) -> Dictionary:
 for topic: Dictionary in definition.get("topics",[]):
  if not topic.modes.any(func(value):return int(value)==mode) or (topic.has("characters") and not str(visit.character_id) in topic.characters): continue
  if not session.conditions.permits(topic.get("requires",{}),PackedStringArray([str(visit.id)])): continue
  if session.visitors.visit_count(visit.character_id)<int(topic.get("minimum_visits",0)): continue
  if topic.get("requires_previous_service",false) and session.visitors.history.previous_service(str(visit.character_id),visit.id).is_empty(): continue
  var key := _key(str(encounter),str(topic.id),str(visit.character_id))
  var previous: Dictionary = _records.get(key,{})
  var scope := "once" if topic.scope=="once" else "day_%d" % session.clock.day if topic.scope=="day" else str(visit.id)
  if previous.get("scope")==scope: continue
  return {"topic_id":str(topic.id),"key":key,"scope":scope,"variant":(int(previous.get("variant",-1))+1)%int(topic.variants)}
 return {}
func commit(selection: Dictionary) -> void:
 if not selection.is_empty(): _records[selection.key]=selection.duplicate(true)
func snapshot() -> Dictionary:
 return _records.duplicate(true)
func restore(data: Dictionary, definitions: Dictionary, characters: Dictionary) -> ActionResult:
 for key in data:
  var record: Variant = data[key]
  if not record is Dictionary or record.get("key")!=key or not record.get("topic_id") is String or not record.get("scope") is String or not ContentValidation.integer(record.get("variant")): return _invalid()
  var found := false
  for encounter in definitions:
   for topic: Dictionary in definitions[encounter].get("topics",[]):
    for actor in characters:
     if key==_key(encounter,str(topic.id),actor) and record.topic_id==topic.id:
      found = record.variant>=0 and record.variant<int(topic.variants) and (record.scope=="once" if topic.scope=="once" else _numbered(record.scope,"day_") if topic.scope=="day" else _numbered(record.scope,"visit_"))
  if not found: return _invalid()
 _records = data.duplicate(true)
 return ActionResult.success()
func contains(selection: Dictionary) -> bool:
 return not selection.is_empty() and _records.get(selection.get("key",""),{})==selection
static func _numbered(value: String, prefix: String) -> bool:
 return value.begins_with(prefix) and value.trim_prefix(prefix).is_valid_int() and int(value.trim_prefix(prefix))>=1
static func _key(encounter: String, topic: String, actor: String) -> String:
 return encounter+"/"+topic+"/"+actor
func _invalid() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_topic_history")
