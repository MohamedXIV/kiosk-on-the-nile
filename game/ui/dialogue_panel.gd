class_name DialoguePanel
extends PanelContainer
signal choice_selected(session_id: StringName, choice_id: StringName)
var _box: VBoxContainer
var _scroll: ScrollContainer
var _signature: String = ""
var _maximum_height_ratio: float = 0.42
func _ready() -> void:
 _scroll = ScrollContainer.new()
 _scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 add_child(_scroll)
 _box = VBoxContainer.new()
 _box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 _scroll.add_child(_box)
 hide()
func configure(text: UiText) -> void:
 add_theme_font_size_override("font_size",int(text.data.hud.dialogue_font_size))
 _maximum_height_ratio = float(text.data.hud.dialogue_max_height_ratio)
func present(conversation: ConversationSession, choices: Array[Dictionary]) -> void:
 if conversation==null or choices.is_empty():
  hide()
  _signature = ""
  return
 var signature := str(conversation.id)+":"+str(conversation.beat)+JSON.stringify(choices)
 if signature!=_signature:
  _signature = signature
  for child in _box.get_children():
   _box.remove_child(child)
   child.queue_free()
  var heading := UiText.label(conversation.current.text)
  heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  _box.add_child(heading)
  for choice in choices:
   var session_id := conversation.id
   var choice_id := StringName(choice.id)
   var control := UiText.button(choice.text,func():choice_selected.emit(session_id,choice_id))
   control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
   _box.add_child(control)
  _scroll.scroll_vertical = 0
 var style := get_theme_stylebox("panel")
 var desired := _box.get_combined_minimum_size().y+style.get_minimum_size().y
 offset_bottom = offset_top+minf(desired,get_viewport_rect().size.y*_maximum_height_ratio)
 show()
