class_name NarrativeTypes
extends RefCounted
class Frame extends RefCounted:
 var result: ActionResult = ActionResult.success()
 var text: String = ""
 var speaker_id: StringName
 var duration: float = 5.5
 var effects: Array[Dictionary] = []
 var choices: Array[Dictionary] = []
 var ended: bool = false
 func to_dict() -> Dictionary:
  return {"text":text,"speaker_id":str(speaker_id),"duration":duration,"effects":effects.duplicate(true),"choices":choices.duplicate(true),"ended":ended}
 static func from_dict(data: Dictionary) -> Frame:
  var value := Frame.new()
  value.text = data.get("text", "")
  value.speaker_id = StringName(data.get("speaker_id", ""))
  value.duration = float(data.get("duration", 5.5))
  value.effects.assign(data.get("effects", []))
  value.choices.assign(data.get("choices", []))
  value.ended = bool(data.get("ended", false))
  return value
