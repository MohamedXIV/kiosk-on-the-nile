class_name VisitorPanel
extends PanelContainer
var _session: GameSession
var _text: UiText
var _visit_id: StringName
var _heading := SheetControls.label()
var _order := SheetControls.label()
var _recall: Button
var _talk: Button
var _topics := VBoxContainer.new()
var _topic_key := ""
var _elapsed: float=0
func configure(text: UiText, session: GameSession) -> void:
 _session=session;_text=text;theme=text.make_theme()
 anchor_left=0.16;anchor_right=0.84;anchor_top=0.16;anchor_bottom=0.94
 var box := VBoxContainer.new();add_child(box)
 SheetControls.header(box,_heading,text,hide)
 box.add_child(_order)
 var scroll := SheetControls.scroll(_topics);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(scroll)
 _recall=text.key_button("recall_order",_recall_order);_recall.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(_recall)
 _talk=text.key_button("personal_talk",_personal_talk);_talk.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(_talk)
 LocaleService.current.changed.connect(func():_topic_key="";if visible:_refresh())
 hide()
func present(visit_id: StringName) -> void:
 _visit_id=visit_id;_topic_key=""
 if not _valid():hide();return
 show();_refresh()
func _process(delta: float) -> void:
 if not visible:return
 _elapsed+=delta
 if _elapsed<0.25:return
 _elapsed=0;_refresh()
func _refresh() -> void:
 if not _valid():hide();return
 var visit: VisitState=_session.visitors.visits[str(_visit_id)]
 var actor_name := NotebookView.name(str(visit.character_id),str(_session.visitors.character(visit.character_id).name))
 _heading.text=_text.text("visitor_actions",{"name":actor_name})
 var busy := _session.narrative.speech_active(_visit_id)
 var order := _session.service.pending_for(_visit_id)
 _order.text=OutingText.t("pending_order",{"food":OutingText.order(_session,order.food_id)}) if order!=null else OutingText.t("no_order")
 _recall.disabled=order==null or busy
 _talk.disabled=not _session.narrative.can_talk(_visit_id)
 var topics := _session.social_life.topics_for(_visit_id)
 var key := str(_visit_id)+JSON.stringify(topics)+str(busy)+str(LocaleService.current.revision)
 if key==_topic_key:return
 _topic_key=key;SheetControls.clear(_topics)
 for topic in topics:
  var button := SheetControls.button(OutingText.topic(topic),_select.bind(str(topic.id)));button.disabled=busy;_topics.add_child(button)
 if topics.is_empty():_topics.add_child(SheetControls.label(OutingText.t("no_topics")))
func _select(id: String) -> void:
 hide();await _session.social_life.start_topic(_visit_id,id)
func _recall_order() -> void:
 hide();await _session.recall_order(_visit_id)
func _personal_talk() -> void:
 hide();await _session.talk(_visit_id)
func _valid() -> bool:
 if not _session.visitors.is_available(_visit_id):return false
 var visit: VisitState=_session.visitors.visits[str(_visit_id)]
 return _session.location_id==visit.pose.location_id and _session.player_ground.distance_to(visit.pose.ground)<=float(_session.config.section("visitors").interaction_radius)
