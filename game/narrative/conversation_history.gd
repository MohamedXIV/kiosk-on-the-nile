class_name ConversationHistory
extends RefCounted
## A topic is consumed by committed speech, not by an E press or opening Ink.
## Keep the latest occurrence per authored topic/character, not an endless log.
var _records: Dictionary = {}
func select(encounter: StringName, definition: Dictionary, visit: VisitState, session: GameSession, mode: int, requested: String = "") -> Dictionary:
 for topic: Dictionary in definition.get("topics",[]):
  if not requested.is_empty() and topic.id!=requested:continue
  if not topic.modes.any(func(value):return int(value)==mode) or (topic.has("characters") and not str(visit.character_id) in topic.characters): continue
  if not session.conditions.permits(topic.get("requires",{}),PackedStringArray([str(visit.id)])): continue
  if session.visitors.visit_count(visit.character_id)<int(topic.get("minimum_visits",0)): continue
  if topic.get("requires_previous_service",false) and session.visitors.history.previous_service(str(visit.character_id),visit.id).is_empty(): continue
  var key := _key(str(encounter),str(topic.id),str(visit.character_id))
  var previous: Dictionary = _records.get(key,{})
  var scope := "once" if topic.scope=="once" else "day_%d" % session.clock.day if topic.scope=="day" else str(visit.id)
  var source_id := ""
  var source_type := str(topic.get("source_type","recipe"))
  if topic.scope=="evidence":
   if source_type=="visit":
    var context := session.customer_experience.context(visit.id)
    var kind := str(topic.get("observation_kind",""))
    source_id=str(context.get("visit_id","")) if kind=="dirty" else str(context.get("previous_visit_id","")) if kind=="improved" else str(context.get("food_visit_id",""))
    scope="experience:"+source_id
   else:
    source_id=str(session.learning.context(StringName(str(topic.get("recipe_id","")))).last_item_id)
    scope="result:"+source_id
   if source_id.is_empty():continue
  if previous.get("scope")==scope: continue
  return {"topic_id":str(topic.id),"key":key,"scope":scope,"variant":(int(previous.get("variant",-1))+1)%int(topic.variants),"source_id":source_id,"source_type":source_type}
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
      found = record.variant>=0 and record.variant<int(topic.variants) and _valid_scope(topic,record.scope)
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

static func _valid_scope(topic: Dictionary, scope: String) -> bool:
 match topic.scope:
  "once":return scope=="once"
  "day":return _numbered(scope,"day_")
  "visit":return _numbered(scope,"visit_")
  "evidence":
   if topic.get("source_type")=="visit":return scope.begins_with("experience:") and _numbered(scope.trim_prefix("experience:"),"visit_")
   return scope.begins_with("result:") and _numbered(scope.trim_prefix("result:"),"food_")
 return false

static func equivalent_selection(a: Dictionary, b: Dictionary) -> bool:
 var first := a.duplicate(true)
 var second := b.duplicate(true)
 for value in [first,second]:
  if not value.has("source_id"):value["source_id"]=""
  if not value.has("source_type"):value["source_type"]="recipe"
 return StableJson.stringify(first)==StableJson.stringify(second)
