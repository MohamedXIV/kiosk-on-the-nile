class_name DialoguePanel
extends PanelContainer
signal choice_selected(session_id: StringName, choice_id: StringName)
var _box: VBoxContainer
var _signature: String = ""
func _ready() -> void:
 _box = VBoxContainer.new()
 add_child(_box)
 hide()
func present(conversation: ConversationSession, choices: Array[Dictionary]) -> void:
 if conversation==null or choices.is_empty():
  hide()
  _signature = ""
  return
 var signature := str(conversation.id)+":"+str(conversation.beat)+JSON.stringify(choices)
 if signature==_signature: show();return
 _signature = signature
 for child in _box.get_children(): child.queue_free()
 var heading := UiText.label(conversation.current.text)
 heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 heading.custom_minimum_size.x = 360
 _box.add_child(heading)
 for choice in choices:
  var session_id := conversation.id
  var choice_id := StringName(choice.id)
  var control := UiText.button(choice.text,func():choice_selected.emit(session_id,choice_id))
  control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  _box.add_child(control)
 show()
