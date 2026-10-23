class_name VisitorPanel
extends PanelContainer
var _session: GameSession
var _text: UiText
var _visit_id: StringName
var _heading := Label.new()
var _recall := Button.new()
var _talk := Button.new()
func configure(text: UiText, session: GameSession) -> void:
 _session=session
 _text=text
 theme=text.make_theme()
 set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 offset_left=-200;offset_right=200;offset_top=-120;offset_bottom=120
 var box := VBoxContainer.new()
 add_child(box)
 box.add_child(_heading)
 _recall=UiText.button(text.text("recall_order"),func():hide();await _session.recall_order(_visit_id))
 _talk=UiText.button(text.text("personal_talk"),func():hide();await _session.talk(_visit_id))
 box.add_child(_recall)
 box.add_child(_talk)
 box.add_child(UiText.button(text.text("close"),hide))
 hide()
func present(visit_id: StringName) -> void:
 _visit_id=visit_id
 if not _valid():return
 var visit: VisitState=_session.visitors.visits[str(visit_id)]
 _heading.text=_text.text("visitor_actions",{"name":_session.visitors.character(visit.character_id).name})
 show()
 _refresh()
func _process(_delta: float) -> void:
 if visible:_refresh()
func _refresh() -> void:
 if not _valid():hide();return
 _recall.disabled=_session.service.pending_for(_visit_id)==null or _session.narrative.speech_active(_visit_id)
 _talk.disabled=not _session.narrative.can_talk(_visit_id)
func _valid() -> bool:
 if not _session.visitors.is_available(_visit_id):return false
 var visit: VisitState=_session.visitors.visits[str(_visit_id)]
 return _session.location_id==visit.pose.location_id and _session.player_ground.distance_to(visit.pose.ground)<=float(_session.config.section("visitors").interaction_radius)
