class_name Hud
extends Control
signal consume_requested
signal supplier_requested
signal tuning_requested
signal clean_floor_requested
signal travel_requested(route_id: StringName)
signal inventory_requested
signal arrange_requested
signal save_requested
signal notebook_requested
signal diagnostics_requested
var dialogue: DialoguePanel
var sleep_panel: SleepPanel
var notebook: Notebook
var toast: ToastStack
var _session: GameSession
var _text: UiText
var _strip: StatusStrip
var _menu: PopupPanel
var _prompt_panel: PanelContainer
var _prompt: Label
var _station: Label
var _thought: Label
func configure(text: UiText) -> void:
 _text = text
 theme = text.make_theme()
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 var margin := float(text.data.hud.margin)
 _strip = StatusStrip.new()
 _strip.anchor_right = 1
 _strip.offset_left = margin
 _strip.offset_right = -margin
 _strip.offset_top = margin
 add_child(_strip)
 _strip.configure(text)
 _strip.menu_requested.connect(_open_menu)
 _menu = PopupPanel.new()
 _menu.theme = theme
 add_child(_menu)
 var actions := VBoxContainer.new()
 var menu_scroll := ScrollContainer.new()
 menu_scroll.custom_minimum_size=Vector2(280,180)
 _menu.add_child(menu_scroll)
 actions.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 menu_scroll.add_child(actions)
 for entry in [{"key":"clean_floor","action":func():clean_floor_requested.emit()},{"key":"inventory","action":func():inventory_requested.emit()},{"key":"arrange","action":func():arrange_requested.emit()},{"key":"save","action":func():save_requested.emit()},{"key":"notebook","action":func():notebook_requested.emit()},{"key":"diagnostics","action":func():diagnostics_requested.emit()}]:
  var callback: Callable = entry.action
  actions.add_child(text.key_button(entry.key,func():_menu.hide();callback.call()))
 actions.add_child(text.key_button("supplier_phone",func():_menu.hide();supplier_requested.emit()))
 actions.add_child(text.key_button("consume",func():_menu.hide();consume_requested.emit()))
 for entry in [{"id":"district","key":"district_trip"},{"id":"market","key":"shop_market"},{"id":"appliances","key":"shop_appliances"},{"id":"homewares","key":"shop_homewares"}]:
  var route_id := StringName(entry.id)
  actions.add_child(text.key_button(entry.key,func():_menu.hide();travel_requested.emit(route_id)))
 actions.add_child(UiText.button(text.text("fatigue_accessibility"),func():
  if _session!=null:_session.fatigue.visual_scale=0.35 if _session.fatigue.visual_scale>0.5 else 0.0 if _session.fatigue.visual_scale>0 else 1.0
  _menu.hide()))
 actions.add_child(LocaleService.current.picker())
 var tuning_button := UiText.button(text.text("tuning"),func():_menu.hide();tuning_requested.emit())
 tuning_button.name="TuningButton"
 actions.add_child(tuning_button)
 var help := UiText.label(text.text("help"))
 help.custom_minimum_size.x = 280
 help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 help.add_theme_font_size_override("font_size",15)
 actions.add_child(help)
 var prompt_panel := PanelContainer.new()
 _prompt_panel = prompt_panel
 prompt_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
 prompt_panel.anchor_left = 1.0-float(text.data.hud.prompt_width_ratio)
 prompt_panel.anchor_right = 0.98
 prompt_panel.anchor_top = 1
 prompt_panel.anchor_bottom = 1
 prompt_panel.offset_top = -18
 prompt_panel.offset_bottom = -18
 add_child(prompt_panel)
 var prompts := VBoxContainer.new()
 prompt_panel.add_child(prompts)
 _prompt = UiText.label()
 _prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 prompts.add_child(_prompt)
 _station = UiText.label()
 _station.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 prompts.add_child(_station)
 dialogue = DialoguePanel.new()
 dialogue.anchor_left = 1.0-float(text.data.hud.dialogue_width_ratio)
 dialogue.anchor_right = 0.98
 dialogue.anchor_top = 0
 dialogue.anchor_bottom = 0
 add_child(dialogue)
 dialogue.configure(text)
 notebook = Notebook.new()
 add_child(notebook)
 notebook.configure(text)
 var sleep_scrim := ColorRect.new()
 sleep_scrim.color = Color(text.data.sleep_dim_color)
 sleep_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 sleep_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
 sleep_scrim.hide()
 add_child(sleep_scrim)
 sleep_panel = SleepPanel.new()
 add_child(sleep_panel)
 sleep_panel.configure(text)
 sleep_panel.visibility_changed.connect(func():sleep_scrim.visible=sleep_panel.visible)
 toast = ToastStack.new()
 toast.text_direction = Control.TEXT_DIRECTION_RTL
 toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 toast.anchor_left = 0.2
 toast.anchor_right = 0.8
 toast.anchor_top = 0.75
 toast.anchor_bottom = 0.83
 toast.duration = float(text.data.toasts.duration)
 add_child(toast)
func bind(session: GameSession) -> void:
 _menu.find_child("TuningButton",true,false).visible=session.config.section("tuning").dev_panel_enabled
 _session = session
 notebook.bind_session(session)
 _thought=UiText.label("")
 _thought.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 _thought.anchor_left=0.05;_thought.anchor_right=0.48;_thought.anchor_top=0.65;_thought.anchor_bottom=0.8
 _thought.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(_thought)
func present(target: InteractionTarget) -> void:
 if _session==null: return
 _strip.present(_session)
 dialogue.position.y = _strip.position.y+_strip.size.y+float(_text.data.hud.margin)
 _prompt.text = _text.text("interaction",{"primary":target.primary}) if target else ""
 var secondary: String = target.secondary if target else ""
 if secondary.is_empty() and _session.cooking.held_item(): secondary = _text.text("consume")
 if not secondary.is_empty(): _prompt.text += "\n"+_text.text("secondary",{"secondary":secondary})
 var station_labels := PackedStringArray()
 for id in _session.cooking.station_ids():
  var status := StationController.new(_session.cooking,str(_text.data.input.interact_primary[0])).status_label(StringName(id),true)
  if not status.is_empty(): station_labels.append(status)
 _station.text = "  ·  ".join(station_labels)
 var cleaning := _session.hygiene.active_action()
 if not cleaning.is_empty():_station.text+="\n"+_text.text("clean_progress",{"minutes":ceili(maxf(0,float(cleaning.required_minutes)-float(cleaning.completed_minutes)))})
 var penalty := _session.mood_policy.quality_penalty(_session.needs.mood)
 if penalty>0 and not station_labels.is_empty(): _station.text += "\n"+_text.text("work_mood_hint",{"penalty":penalty})
 _prompt.visible = not _prompt.text.is_empty()
 _station.visible = not _station.text.is_empty()
 _prompt_panel.visible = _prompt.visible or _station.visible
 _prompt_panel.offset_top = _prompt_panel.offset_bottom-_prompt_panel.get_combined_minimum_size().y
 var focused := _session.narrative.focused_session()
 if notebook.visible or sleep_panel.visible:dialogue.hide()
 elif _session.personal.active():dialogue.present_personal(_session.personal.view(),_session.narrative)
 else:dialogue.present(focused,_session.narrative.choices(focused))
 var thought := _session.inner.view()
 _thought.text="" if thought.is_empty() else _text.text("thought_name")+": "+str(thought.text)
 _thought.visible=not thought.is_empty() and not _session.personal.active() and focused==null and not notebook.visible and not sleep_panel.visible

func _open_menu() -> void:
 _menu.size=Vector2i(320,int(minf(560,get_viewport_rect().size.y-_strip.size.y-35)))
 _menu.popup()
 _menu.position = Vector2i(int(_strip.position.x),int(_strip.position.y+_strip.size.y+8))

func top_occupied_height() -> float:
 return _strip.position.y+_strip.size.y+float(_text.data.hud.margin)

func suppress_prompts() -> void:
 _prompt_panel.hide()
 _thought.hide()
