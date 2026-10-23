class_name VisitorPanel
extends PanelContainer
var _session: GameSession
var _text: UiText
var _visit_id: StringName
var _heading := Label.new()
var _recall := Button.new()
var _talk := Button.new()
var _topics := VBoxContainer.new()
var _topic_key := ""
func configure(text: UiText, session: GameSession) -> void:
 _session=session
 _text=text
 theme=text.make_theme()
 anchor_left=0.25;anchor_right=0.75;anchor_top=0.18;anchor_bottom=0.82
 var box := VBoxContainer.new()
 add_child(box)
 box.add_child(_heading)
 var scroll := ScrollContainer.new()
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 box.add_child(scroll)
 _topics.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(_topics)
 _recall=UiText.button(text.text("recall_order"),func():hide();await _session.recall_order(_visit_id))
 _talk=UiText.button(text.text("personal_talk"),func():hide();await _session.talk(_visit_id))
 box.add_child(_recall)
 box.add_child(_talk)
 box.add_child(UiText.button(text.text("close"),hide))
 hide()
func present(visit_id: StringName) -> void:
 _visit_id=visit_id
 _topic_key=""
 if not _valid():return
 var visit: VisitState=_session.visitors.visits[str(visit_id)]
 _heading.text=_text.text("visitor_actions",{"name":_session.visitors.character(visit.character_id).name})
 show()
 _refresh()
func _process(_delta: float) -> void:
 if visible:_refresh()
func _refresh() -> void:
 if not _valid():hide();return
 var busy := _session.narrative.speech_active(_visit_id)
 _recall.disabled=_session.service.pending_for(_visit_id)==null or busy
 _talk.disabled=not _session.narrative.can_talk(_visit_id)
 var topics := _session.social_life.topics_for(_visit_id)
 var key := str(_visit_id)+JSON.stringify(topics)+str(busy)
 if key==_topic_key:return
 _topic_key=key
 for child in _topics.get_children():child.free()
 for topic in topics:
  var button := UiText.button(topic.label,_select.bind(str(topic.id)))
  button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  button.disabled=busy
  _topics.add_child(button)
func _select(id: String) -> void:
 hide()
 await _session.social_life.start_topic(_visit_id,id)
func _valid() -> bool:
 if not _session.visitors.is_available(_visit_id):return false
 var visit: VisitState=_session.visitors.visits[str(_visit_id)]
 return _session.location_id==visit.pose.location_id and _session.player_ground.distance_to(visit.pose.ground)<=float(_session.config.section("visitors").interaction_radius)
