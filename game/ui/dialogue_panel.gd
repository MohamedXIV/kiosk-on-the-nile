class_name DialoguePanel
extends PanelContainer
signal choice_selected(session_id: StringName, choice_id: StringName)
signal advance_requested
signal topic_selected(key: String)
signal leave_requested
var _box: VBoxContainer
var _scroll: ScrollContainer
var _signature: String=""
var _maximum_height_ratio: float=0.42
var _text: UiText
func _ready() -> void:
 _scroll=ScrollContainer.new()
 _scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 add_child(_scroll)
 _box=VBoxContainer.new()
 _box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _scroll.add_child(_box)
 hide()
func configure(text: UiText) -> void:
 _text=text
 add_theme_font_size_override("font_size",int(text.data.hud.dialogue_font_size))
 _maximum_height_ratio=float(text.data.hud.dialogue_max_height_ratio)
func present(conversation: ConversationSession, choices: Array[Dictionary]) -> void:
 if conversation==null or choices.is_empty():hide();_signature="";return
 var signature := str(LocaleService.current.revision if LocaleService.current else 0)+str(conversation.id)+":"+str(conversation.beat)+JSON.stringify(choices)
 if _begin(signature):
  _line(LocalizedNarrative.line(conversation.current))
  _choices(conversation,choices)
 _fit()
func present_personal(view: Dictionary, director: NarrativeDirector) -> void:
 var conversation: ConversationSession=view.get("conversation")
 var signature := str(LocaleService.current.revision if LocaleService.current else 0)+JSON.stringify([view.get("actor_id"),str(conversation.id) if conversation else "",conversation.beat if conversation else 0,view.topics,view.opening])
 if _begin(signature):
  _line(LocalizedNarrative.speaker(str(view.actor_id),str(view.name)))
  if conversation:
   for event in view.get("recent",[]):
    var preceding := UiText.label(str(event.name)+": "+str(event.text))
    preceding.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    preceding.modulate.a=0.65
    _box.add_child(preceding)
   _line(LocalizedNarrative.line(conversation.current))
   var choices := director.choices(conversation)
   if choices.is_empty():_button(_text.text("dialogue_continue"),func():advance_requested.emit())
   else:_choices(conversation,choices)
  else:
   _line(_text.text("dialogue_topics"))
   for topic in view.topics:_button(str(topic.label),func():topic_selected.emit(str(topic.key)))
  _button(_text.text("dialogue_leave"),func():leave_requested.emit())
 _fit()
func _begin(signature: String) -> bool:
 if signature==_signature:return false
 _signature=signature
 for child in _box.get_children():child.free()
 _scroll.scroll_vertical=0
 return true
func _line(value: String) -> void:
 var label := UiText.label(value)
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 _box.add_child(label)
func _button(value: String, action: Callable) -> void:
 var button := UiText.button(value,action)
 button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 _box.add_child(button)
func _choices(conversation: ConversationSession, choices: Array[Dictionary]) -> void:
 for choice in choices:
  _button(LocalizedNarrative.choice(choice,conversation.current),func():choice_selected.emit(conversation.id,StringName(choice.id)))
func _fit() -> void:
 var style := get_theme_stylebox("panel")
 var desired := _box.get_combined_minimum_size().y+style.get_minimum_size().y
 offset_bottom=offset_top+minf(desired,get_viewport_rect().size.y*_maximum_height_ratio)
 show()
