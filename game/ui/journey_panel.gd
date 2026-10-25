class_name JourneyPanel
extends PanelContainer
var _session: GameSession
var _text: UiText
var _label := SheetControls.label()
var _return: Button
func configure(text: UiText, session: GameSession) -> void:
 _text=text;_session=session;theme=text.make_theme()
 anchor_left=0.18;anchor_right=0.82;anchor_top=0.25;anchor_bottom=0.65
 var box := VBoxContainer.new();add_child(box)
 var scroll := VBoxContainer.new();var viewport := SheetControls.scroll(scroll);viewport.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(viewport)
 scroll.add_child(_label)
 _return=text.key_button("journey_return",func():session.travel.begin_return());box.add_child(_return)
 hide()
func present() -> void:
 visible=not _session.locations.is_physical(_session.location_id)
 if not visible:return
 var data: Dictionary=_session.travel.journey.data
 var route := _session.travel.route()
 var phase := str(data.get("phase",""))
 _label.text=_text.text("journey_browsing" if phase=="browsing" else "journey_returning" if phase=="returning" else "journey_outbound",{"place":OutingText.route(route,str(data.get("route_id",""))),"minutes":ceili(maxf(0,float(data.get("due_at",0))-_session.clock.world_minutes))})+"\n"+OutingText.t("world_continues")
 _return.visible=phase=="browsing"
