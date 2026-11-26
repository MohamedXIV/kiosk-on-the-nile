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
var top_inset: float=122.0
const PANEL_WIDTH := 460.0
const EDGE := 16.0
const MIN_SCROLL_HEIGHT := 96.0
const MIN_PANEL_HEIGHT := 220.0
var _text: UiText
func _ready() -> void:
 theme_type_variation="DialogueFrame"
 _layout=VBoxContainer.new()
 _layout.add_theme_constant_override("separation",10)
 add_child(_layout)
 _speaker=SheetControls.label()
 _speaker.theme_type_variation="SpeakerTag"
 # The speaker must retain a real horizontal line before the scroll area is measured.
 _speaker.autowrap_mode=TextServer.AUTOWRAP_OFF
 _speaker.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 _speaker.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _speaker.custom_minimum_size.y=36
 _layout.add_child(_speaker)
 _scroll=ScrollContainer.new()
 _scroll.follow_focus=true
 _scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 _scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 _scroll.custom_minimum_size.y=MIN_SCROLL_HEIGHT
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
 label.theme_type_variation="DialogueLine"
 _box.add_child(label)
 return label
func _button(value: String, action: Callable, primary: bool=false) -> void:
 var button := SheetControls.button(value,action)
 button.custom_minimum_size=Vector2(0,44)
 if primary:SheetControls.primary(button)
 else:button.theme_type_variation="QuietButton"
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
 var width := minf(PANEL_WIDTH,viewport.x-EDGE*2)
 var top := maxf(EDGE,top_inset)
 # Reserve an explicit reading area. Auto-wrapped labels report misleading
 # minimum heights before their container has received its width.
 var available := maxf(MIN_SCROLL_HEIGHT,viewport.y-top-EDGE)
 var height := minf(available,maxf(MIN_PANEL_HEIGHT,viewport.y*_maximum_height_ratio))
 anchor_left=0;anchor_right=0;anchor_top=0;anchor_bottom=0
 offset_left=viewport.x-width-EDGE
 offset_right=viewport.x-EDGE
 offset_top=top
 offset_bottom=top+height
 show()
