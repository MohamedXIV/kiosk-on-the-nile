class_name JourneyPanel
extends PanelContainer
var _session: GameSession
var _text: UiText
var _label := Label.new()
var _return: Button
func configure(text: UiText, session: GameSession) -> void:
 _text=text
 _session=session
 theme=text.make_theme()
 anchor_left=0.22
 anchor_right=0.78
 anchor_top=0.3
 anchor_bottom=0.55
 var box := VBoxContainer.new()
 add_child(box)
 _label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 box.add_child(_label)
 _return=UiText.button(text.text("journey_return"),func():session.travel.begin_return())
 box.add_child(_return)
 hide()
func present() -> void:
 var data := _session.travel.snapshot().journey as Dictionary
 visible=not _session.locations.is_physical(_session.location_id)
 if not visible:return
 var route := _session.travel.route()
 var phase := str(data.get("phase",""))
 _label.text=_text.text("journey_browsing" if phase=="browsing" else "journey_returning" if phase=="returning" else "journey_outbound",{"place":route.get("label",""),"minutes":ceili(maxf(0,float(data.get("due_at",0))-_session.clock.world_minutes))})
 _return.visible=phase=="browsing"
