class_name NarrativeTypes
extends RefCounted
class Frame extends RefCounted:
 var result: ActionResult = ActionResult.success()
 var loc_id: String=""
 var loc_args: Dictionary={}
 var text: String = ""
 var speaker_id: StringName
 var duration: float = 5.5
 var effects: Array[Dictionary] = []
 var choices: Array[Dictionary] = []
 var autonomous: String=""
 var ended: bool = false
 func to_dict() -> Dictionary:
  var record := {"text":text,"speaker_id":str(speaker_id),"duration":duration,"effects":effects.duplicate(true),"choices":choices.duplicate(true),"ended":ended}
  if loc_id!="" or not loc_args.is_empty():record.merge({"loc_id":loc_id,"loc_args":loc_args.duplicate(true)})
  if not autonomous.is_empty():record["autonomous"]=autonomous
  return record
 static func from_dict(data: Dictionary) -> Frame:
  var value := Frame.new()
  value.autonomous=str(data.get("autonomous",""))
  value.text = data.get("text", "")
  value.loc_id=str(data.get("loc_id",""))
  value.loc_args=data.get("loc_args",{}).duplicate(true)
  value.speaker_id = StringName(data.get("speaker_id", ""))
  value.duration = float(data.get("duration", 5.5))
  value.effects.assign(data.get("effects", []))
  value.choices.assign(data.get("choices", []))
  value.ended = bool(data.get("ended", false))
  return value
