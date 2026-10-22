class_name ConversationSession
extends RefCounted
var id: StringName
var encounter_id: StringName
var participants := PackedStringArray()
var runtime: InkRuntime
var current := NarrativeTypes.Frame.new()
var beat: int = 0
var elapsed: float = 0
var choice_elapsed: float = 0
var optional: bool = false
var finished: bool = false
var context_extra: Dictionary = {}
var topic_selection: Dictionary = {}
func choice_id(choice: Dictionary) -> StringName:
 return StringName("%s:%d:%s" % [id,beat,choice.id])
func snapshot() -> Dictionary:
 return {"id":str(id),"encounter_id":str(encounter_id),"participants":Array(participants),"beat":beat,"elapsed":elapsed,"choice_elapsed":choice_elapsed,"optional":optional,"finished":finished,"topic_selection":topic_selection.duplicate(true),"context_extra":context_extra.duplicate(true),"runtime":runtime.snapshot() if runtime else {}}
