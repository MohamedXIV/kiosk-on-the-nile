class_name Hud
extends Control
signal save_requested
signal notebook_requested
signal diagnostics_requested
var dialogue: DialoguePanel
var sleep_panel: SleepPanel
var notebook: Notebook
var toast: ToastStack
var _session: GameSession
var _text: UiText
var _heading: Label
var _inventory: Label
var _prompt: Label
var _station: Label
var _bars: Dictionary = {}
func configure(text: UiText) -> void:
 _text = text
 theme = text.make_theme()
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 var panel := PanelContainer.new()
 panel.position = Vector2(18,18)
 panel.custom_minimum_size.x = 280
 add_child(panel)
 var box := VBoxContainer.new()
 panel.add_child(box)
 _heading = UiText.label()
 box.add_child(_heading)
 _inventory = UiText.label()
 box.add_child(_inventory)
 for key in ["hunger","rest","mood"]:
  var row := HBoxContainer.new()
  box.add_child(row)
  var bar := ProgressBar.new()
  bar.custom_minimum_size = Vector2(180,16)
  bar.show_percentage = false
  row.add_child(bar)
  row.add_child(UiText.label(text.text(key)))
  _bars[key] = bar
 var buttons := HBoxContainer.new()
 box.add_child(buttons)
 buttons.add_child(UiText.button(text.text("save"),func():save_requested.emit()))
 buttons.add_child(UiText.button(text.text("notebook"),func():notebook_requested.emit()))
 buttons.add_child(UiText.button(text.text("diagnostics"),func():diagnostics_requested.emit()))
 var prompt_panel := PanelContainer.new()
 prompt_panel.anchor_left = 0.3
 prompt_panel.anchor_right = 0.98
 prompt_panel.anchor_top = 1
 prompt_panel.anchor_bottom = 1
 prompt_panel.offset_top = -152
 prompt_panel.offset_bottom = -18
 add_child(prompt_panel)
 var prompts := VBoxContainer.new()
 prompt_panel.add_child(prompts)
 _prompt = UiText.label()
 _prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 prompts.add_child(_prompt)
 _station = UiText.label()
 prompts.add_child(_station)
 var help := UiText.label(text.text("help"))
 help.add_theme_font_size_override("font_size",14)
 help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 prompts.add_child(help)
 dialogue = DialoguePanel.new()
 dialogue.anchor_left = 0.53
 dialogue.anchor_right = 0.98
 dialogue.anchor_top = 0.05
 dialogue.anchor_bottom = 0.5
 add_child(dialogue)
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
 _session = session
func present(target: InteractionTarget) -> void:
 if _session==null: return
 var minute := int(_session.clock.minutes)%1440
 _heading.text = _text.text("day_time",{"day":_session.clock.day,"hour":"%02d" % (minute/60),"minute":"%02d" % (minute%60)})+"\n"+_text.text("money",{"amount":"%.2f" % (_session.wallet.balance/100.0)})
 _inventory.text = _text.text("stock",_session.cooking.inventory_snapshot())+"\n"+(_text.text("open") if _session.kiosk_open else _text.text("closed"))+"\n"+(_text.text("held",{"item":_session.cooking.item_label(_session.cooking.held_item())}) if _session.cooking.held_item() else _text.text("empty_hands"))
 for key in _bars: _bars[key].value = _session.needs.get(key)
 _prompt.text = _text.text("interaction",{"primary":target.primary}) if target else ""
 var secondary: String = target.secondary if target else ""
 if secondary.is_empty() and _session.cooking.held_item(): secondary = _text.text("consume")
 if not secondary.is_empty(): _prompt.text += "\n"+_text.text("secondary",{"secondary":secondary})
 var station_labels := PackedStringArray()
 for id in _session.cooking.station_ids():
  var status := StationController.new(_session.cooking,str(_text.data.input.interact_primary[0])).status_label(StringName(id),true)
  if not status.is_empty(): station_labels.append(status)
 _station.text = "  ·  ".join(station_labels)
 var penalty := _session.mood_policy.quality_penalty(_session.needs.mood)
 if penalty>0: _station.text += "\n"+_text.text("work_mood_hint",{"penalty":penalty})
 var focused := _session.narrative.focused_session()
 dialogue.present(focused,_session.narrative.choices(focused))
