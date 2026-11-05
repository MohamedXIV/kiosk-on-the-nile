class_name JourneyPanel
extends PanelContainer
var _session: GameSession
var _text: UiText
var _label := SheetControls.label()
var _return: Button
var _heading := SheetControls.label()
var _progress := ProgressBar.new()
var _continuity := SheetControls.label()
func configure(text: UiText, session: GameSession) -> void:
 _text=text;_session=session;theme=text.make_theme()
 SheetControls.shell(self,680,180,130)
 var box := VBoxContainer.new();box.add_theme_constant_override("separation",14);add_child(box)
 var scroll := VBoxContainer.new();var viewport := SheetControls.scroll(scroll);viewport.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(viewport)
 SheetControls.title(_heading);scroll.add_child(_heading)
 var card := SheetControls.card(scroll);card.add_child(_label)
 _progress.show_percentage=false;_progress.custom_minimum_size.y=12;card.add_child(_progress)
 SheetControls.muted(_continuity);scroll.add_child(_continuity)
 _return=SheetControls.key_button(text,"journey_return",func():session.travel.begin_return());SheetControls.primary(_return);box.add_child(_return)
 hide()
func present() -> void:
 visible=not _session.locations.is_physical(_session.location_id)
 if not visible:return
 var data: Dictionary=_session.travel.journey.data
 var route := _session.travel.route()
 var phase := str(data.get("phase",""))
 _heading.text=OutingText.route(route,str(data.get("route_id","")))
 _label.text=_text.text("journey_browsing" if phase=="browsing" else "journey_returning" if phase=="returning" else "journey_outbound",{"place":OutingText.route(route,str(data.get("route_id",""))),"minutes":ceili(maxf(0,float(data.get("due_at",0))-_session.clock.world_minutes))})
 _continuity.text=OutingText.t("world_continues")
 _progress.visible=phase in ["outbound","returning"]
 var started := float(data.get("started_at",0))
 var duration := float(data.get("due_at",0))-started
 _progress.value=clampf((_session.clock.world_minutes-started)/duration*100.0,0,100) if duration>0 else 100.0
 _return.visible=phase=="browsing"
