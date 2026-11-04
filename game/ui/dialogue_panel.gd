class_name DialoguePanel
extends PanelContainer
signal choice_selected(session_id: StringName, choice_id: StringName)
signal advance_requested
signal topic_selected(key: String)
signal group_advance_requested(session_id: StringName)
signal group_leave_requested(session_id: StringName)
signal leave_requested
var _box: VBoxContainer
var _layout: VBoxContainer
var _speaker: Label
var _leave: Button
var _scroll: ScrollContainer
var _signature: String=""
var _maximum_height_ratio: float=0.42
var _text: UiText
func _ready() -> void:
 theme_type_variation="Sheet"
 _layout=VBoxContainer.new()
 _layout.add_theme_constant_override("separation",10)
 add_child(_layout)
 _speaker=SheetControls.label()
 SheetControls.title(_speaker)
 _layout.add_child(_speaker)
 _scroll=ScrollContainer.new()
 _scroll.follow_focus=true
 _scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 _scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 _layout.add_child(_scroll)
 _box=VBoxContainer.new()
 _box.add_theme_constant_override("separation",10)
 _box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _scroll.add_child(_box)
 hide()
func configure(text: UiText) -> void:
 _text=text
 theme=text.make_theme()
 _maximum_height_ratio=float(text.data.hud.dialogue_max_height_ratio)
func present(conversation: ConversationSession, choices: Array[Dictionary], speaker_name: String="") -> void:
 var joined: bool=conversation!=null and bool(conversation.context_extra.get("peer_participating",false))
 if conversation==null or (choices.is_empty() and not joined):hide();_signature="";return
 var signature := str(LocaleService.current.revision if LocaleService.current else 0)+str(conversation.id)+":"+str(conversation.beat)+JSON.stringify(choices)
 if _begin(signature,speaker_name):
  _line(LocalizedNarrative.line(conversation.current))
  if choices.is_empty():_button(_text.text("dialogue_continue"),func():group_advance_requested.emit(conversation.id),true)
  else:_choices(conversation,choices)
  if joined:_leave_button(func():group_leave_requested.emit(conversation.id))
 _fit()
func present_personal(view: Dictionary, director: NarrativeDirector) -> void:
 var conversation: ConversationSession=view.get("conversation")
 var signature := str(LocaleService.current.revision if LocaleService.current else 0)+JSON.stringify([view.get("actor_id"),str(conversation.id) if conversation else "",conversation.beat if conversation else 0,view.topics,view.opening])
 if _begin(signature,NotebookView.name(str(view.actor_id),str(view.name))):
  if conversation:
   for event in view.get("recent",[]):
    var preceding := _line(str(event.name)+": "+str(event.text))
    SheetControls.muted(preceding)
   _line(LocalizedNarrative.line(conversation.current))
   var choices := director.choices(conversation)
   if choices.is_empty():_button(_text.text("dialogue_continue"),func():advance_requested.emit(),true)
   else:_choices(conversation,choices)
  else:
   SheetControls.muted(_line(_text.text("dialogue_topics")))
   for topic in view.topics:_button(OutingText.manual_topic(topic),func():topic_selected.emit(str(topic.key)))
  _leave_button(func():leave_requested.emit())
 _fit()
func _begin(signature: String, speaker_name: String="") -> bool:
 if signature==_signature:return false
 _signature=signature
 for child in _box.get_children():child.free()
 if is_instance_valid(_leave):_leave.free()
 _speaker.text=speaker_name
 _speaker.visible=not speaker_name.is_empty()
 _scroll.scroll_vertical=0
 return true
func _line(value: String) -> Label:
 var label := SheetControls.label(value)
 label.text_direction=Control.TEXT_DIRECTION_AUTO
 _box.add_child(label)
 return label
func _button(value: String, action: Callable, primary: bool=false) -> void:
 var button := SheetControls.button(value,action)
 button.custom_minimum_size=Vector2(0,44)
 if primary:SheetControls.primary(button)
 _box.add_child(button)
func _leave_button(action: Callable) -> void:
 _leave=SheetControls.button(_text.text("dialogue_leave"),action)
 _leave.theme_type_variation="QuietButton"
 _leave.custom_minimum_size=Vector2(0,44)
 _layout.add_child(_leave)
func _choices(conversation: ConversationSession, choices: Array[Dictionary]) -> void:
 for choice in choices:
  _button(LocalizedNarrative.choice(choice,conversation.current),func():choice_selected.emit(conversation.id,StringName(choice.id)))
func _fit() -> void:
 var viewport := get_viewport_rect().size
 # Keep conversation beside the world at wide sizes and readable on narrow views.
 var width := minf(580,viewport.x-32)
 anchor_left=0;anchor_right=0;anchor_top=0;anchor_bottom=0
 offset_left=viewport.x-width-16
 offset_right=viewport.x-16
 offset_top=122
 var style := get_theme_stylebox("panel")
 var fixed_height := style.get_minimum_size().y+_speaker.get_combined_minimum_size().y+20
 if is_instance_valid(_leave):fixed_height+=_leave.get_combined_minimum_size().y+10
 var desired := _box.get_combined_minimum_size().y+fixed_height
 offset_bottom=offset_top+minf(desired,minf(viewport.y*_maximum_height_ratio,maxf(120,viewport.y-offset_top-18)))
 show()
