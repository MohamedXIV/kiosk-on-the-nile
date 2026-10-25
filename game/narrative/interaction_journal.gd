class_name InteractionJournal
extends RefCounted
## Append-only heard history. Reading it never replays narrative effects.
var _events: Array[Dictionary]=[]
var _ids: Dictionary={}
var _actors: Array=[]
var _clock: GameClock
func configure(actors: Array, clock: GameClock) -> void:
 _actors=actors.duplicate()+["player","system"]
 _clock=clock
func append_once(event: Dictionary) -> ActionResult:
 if not _valid(event):return _fail()
 if _ids.has(event.id):
  return ActionResult.success({"duplicate":true}) if StableJson.stringify(_events[int(_ids[event.id])])==StableJson.stringify(event) else _fail()
 if not _events.is_empty() and float(event.at)<float(_events.back().at)-0.001:return _fail()
 _ids[event.id]=_events.size()
 _events.append(event.duplicate(true))
 return ActionResult.success()
func entries(filters: Dictionary = {}) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for event in _events:
  if filters.get("actor","")!="" and event.actor!=filters.actor:continue
  if filters.get("channel","")!="" and event.channel!=filters.channel:continue
  if filters.get("chapter","")!="" and event.chapter!=filters.chapter:continue
  if int(filters.get("day",0))>0 and floori(float(event.at)/1440.0)+1!=int(filters.day):continue
  result.append(event.duplicate(true))
 return result
func event(id: String) -> Dictionary:
 return _events[int(_ids[id])].duplicate(true) if _ids.has(id) else {}
func snapshot() -> Dictionary:
 return {"events":_events.duplicate(true)}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("events") is Array:return _fail()
 var candidate := InteractionJournal.new()
 candidate.configure(_actors,_clock)
 for entry in data.events:
  if not entry is Dictionary or candidate._ids.has(entry.get("id","")):return _fail()
  var result := candidate.append_once(entry)
  if not result.ok:return result
 _events=candidate._events
 _ids=candidate._ids
 return ActionResult.success()
func _valid(e: Dictionary) -> bool:
 if e.has("text_ref") and (not e.text_ref is String or not e.get("parameters") is Dictionary or not e.get("canonical_text") is String or not e.get("locale") in ["ar_EG","en"]):return false
 if e.has("occurred_at") and not ContentValidation.bounded(e.occurred_at,0,float(e.get("at",-1))+0.001):return false
 return e.get("id") is String and not e.id.is_empty() and e.get("chapter") is String and e.get("actor") in _actors and e.get("name") is String and e.get("text") is String and not e.text.is_empty() and e.get("channel") in ["speech","choice","thought","system"] and ContentValidation.bounded(e.get("at"),0,_clock.world_minutes+0.001)
func _fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_interaction_journal")
