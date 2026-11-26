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
var _header: HBoxContainer
var _header_spacer: Control
var _reading: ScrollContainer
var _reading_box: VBoxContainer
var _history: VBoxContainer
var _history_toggle: Button
var _current_line: Label
var _compact: bool=false
var _layout_configured: bool=false
var _scroll: ScrollContainer
var _signature: String=""
var top_inset: float=122.0
var _text: UiText
func _ready() -> void:
 theme_type_variation="CompactDialogueFrame"
 clip_contents=true
 _layout=VBoxContainer.new()
 _layout.add_theme_constant_override("separation",4)
 add_child(_layout)
 _header=HBoxContainer.new()
 _header.add_theme_constant_override("separation",6)
 _layout.add_child(_header)
 _speaker=SheetControls.label()
 _speaker.theme_type_variation="SpeakerTag"
 # The speaker must retain a real horizontal line before the scroll area is measured.
 _speaker.autowrap_mode=TextServer.AUTOWRAP_OFF
 _speaker.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 _speaker.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _speaker.custom_minimum_size.y=36
 _header.add_child(_speaker)
 _header_spacer=Control.new()
 _header_spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE
 _header_spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _header.add_child(_header_spacer)
 var body := HBoxContainer.new()
 body.add_theme_constant_override("separation",6)
 body.size_flags_vertical=Control.SIZE_EXPAND_FILL
 _layout.add_child(body)
 _reading=ScrollContainer.new()
 _reading.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 _reading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _reading.size_flags_stretch_ratio=1.2
 _reading.size_flags_vertical=Control.SIZE_EXPAND_FILL
 _reading.custom_minimum_size=Vector2(96,44)
 body.add_child(_reading)
 _reading_box=VBoxContainer.new()
 _reading_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _reading_box.add_theme_constant_override("separation",4)
 _reading.add_child(_reading_box)
 _scroll=ScrollContainer.new()
 _scroll.follow_focus=true
 _scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 _scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 _scroll.custom_minimum_size=Vector2(96,44)
 _scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _scroll.size_flags_stretch_ratio=1.0
 body.add_child(_scroll)
 _box=VBoxContainer.new()
 _box.add_theme_constant_override("separation",4)
 _box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _scroll.add_child(_box)
 hide()
func configure(text: UiText) -> void:
 _text=text
 theme=CozyTheme.make_compact()
func present(conversation: ConversationSession, choices: Array[Dictionary], speaker_name: String="") -> void:
 var joined: bool=conversation!=null and bool(conversation.context_extra.get("peer_participating",false))
 if conversation==null or (choices.is_empty() and not joined):hide();_signature="";return
 var signature := str(LocaleService.current.revision if LocaleService.current else 0)+str(conversation.id)+":"+str(conversation.beat)+JSON.stringify(choices)
 if _begin(signature,speaker_name):
  _current_line=_line(LocalizedNarrative.line(conversation.current))
  if choices.is_empty():_button(_text.text("dialogue_continue"),func():group_advance_requested.emit(conversation.id),true)
  else:_choices(conversation,choices)
  if joined:_leave_button(func():group_leave_requested.emit(conversation.id))
 _fit()
func present_personal(view: Dictionary, director: NarrativeDirector) -> void:
 var conversation: ConversationSession=view.get("conversation")
 var signature := str(LocaleService.current.revision if LocaleService.current else 0)+JSON.stringify([view.get("actor_id"),str(conversation.id) if conversation else "",conversation.beat if conversation else 0,view.topics,view.opening])
 if _begin(signature,NotebookView.name(str(view.actor_id),str(view.name))):
  if conversation:
   # Current speech and choices remain first in compact mode; the preceding
   # lines remain available through a history disclosure, not deleted.
   var recent: Array=view.get("recent",[])
   if not recent.is_empty():
    _history=VBoxContainer.new()
    _reading_box.add_child(_history)
    _history.hide()
    for event in recent:
     var preceding := SheetControls.label(str(event.name)+": "+str(event.text))
     SheetControls.muted(preceding)
     _history.add_child(preceding)
   _current_line=_line(LocalizedNarrative.line(conversation.current))
   var choices := director.choices(conversation)
   if choices.is_empty():_button(_text.text("dialogue_continue"),func():advance_requested.emit(),true)
   else:_choices(conversation,choices)
   if is_instance_valid(_history):
    _history_toggle=SheetControls.button(_text.text("journal_title"),_toggle_history)
    _history_toggle.toggle_mode=true
    _history_toggle.custom_minimum_size=Vector2(0,44)
    _box.add_child(_history_toggle)
  else:
   SheetControls.muted(_line(_text.text("dialogue_topics")))
   for topic in view.topics:_button(OutingText.manual_topic(topic),func():topic_selected.emit(str(topic.key)))
  _leave_button(func():leave_requested.emit())
 _fit()
func _begin(signature: String, speaker_name: String="") -> bool:
 if signature==_signature:return false
 _signature=signature
 for child in _box.get_children():child.free()
 for child in _reading_box.get_children():child.free()
 if is_instance_valid(_leave):_leave.free()
 _history=null;_history_toggle=null;_current_line=null
 _layout_configured=false
 _speaker.text=speaker_name
 _speaker.visible=not speaker_name.is_empty()
 _scroll.scroll_vertical=0
 _reading.scroll_vertical=0
 return true
func _line(value: String) -> Label:
 var label := SheetControls.label(value)
 label.text_direction=Control.TEXT_DIRECTION_AUTO
 label.theme_type_variation="DialogueLine"
 _reading_box.add_child(label)
 return label
func _button(value: String, action: Callable, primary: bool=false) -> void:
 var button := SheetControls.button(value,action)
 button.custom_minimum_size=Vector2(0,44)
 if primary:SheetControls.primary(button)
 else:button.theme_type_variation="QuietButton"
 _box.add_child(button)
func _leave_button(action: Callable) -> void:
 _leave=SheetControls.button(UiText.localized("ui.dialogue_leave_short"),action)
 _leave.tooltip_text=_text.text("dialogue_leave")
 _leave.theme_type_variation="QuietButton"
 _leave.custom_minimum_size=Vector2(92,44)
 _header.add_child(_leave)
func _choices(conversation: ConversationSession, choices: Array[Dictionary]) -> void:
 for choice in choices:
  _button(LocalizedNarrative.choice(choice,conversation.current),func():choice_selected.emit(conversation.id,StringName(choice.id)))
func _toggle_history() -> void:
 if not is_instance_valid(_history):return
 _history.visible=_history_toggle.button_pressed
 if _history.visible:_reading.ensure_control_visible.call_deferred(_history)
 else:_reading.set_deferred("scroll_vertical",0)

func _fit() -> void:
 var extent := get_viewport_rect().size
 _compact=CozyTheme.compact_for(extent)
 var envelope := SheetControls.gameplay_rect(extent,top_inset)
 _speaker.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
 _speaker.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 var font := _speaker.get_theme_font("font")
 var name_width := font.get_string_size(_speaker.text,HORIZONTAL_ALIGNMENT_LEFT,-1,_speaker.get_theme_font_size("font_size")).x+30.0
 _speaker.custom_minimum_size.x=clampf(name_width,96.0,minf(280.0,maxf(96.0,envelope.size.x-125.0)))
 _speaker.tooltip_text=_speaker.text
 if not _layout_configured:
  _layout_configured=true
  if is_instance_valid(_history):_reading_box.move_child(_history,_reading_box.get_child_count()-1)
  _reading.set_deferred("scroll_vertical",0)
  _scroll.set_deferred("scroll_vertical",0)
 set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 position=envelope.position
 size=envelope.size
 show()
