class_name StatusStrip
extends HBoxContainer
signal menu_requested
signal inventory_requested
signal notebook_requested
signal outings_requested
signal settings_requested
var _text: UiText
var _clock: Label
var _money: Label
var _state: Label
var _day_icon: TextureRect
var _day_period: int=-1
var _day_locale_revision: int=-1
var _periods: Array=[]
var _period_textures: Array[Texture2D]=[]
var _held: Label
var _bars: Dictionary={}
var _save_feedback: Label
var _menu_button: Button
var _need_labels: Array[Label]=[]
var _shortcut_buttons: Dictionary={}
var _popup_anchor: Button
var _day: Label
const CLOCK_ART = preload("res://assets/ui/nile/clock.svg")
func configure(text: UiText) -> void:
 _text=text
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_theme_constant_override("separation",8)
 var left := VBoxContainer.new()
 left.mouse_filter=Control.MOUSE_FILTER_IGNORE
 left.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
 left.add_theme_constant_override("separation",4)
 left.custom_minimum_size.x=246
 add_child(left)
 var time_row := HBoxContainer.new()
 time_row.mouse_filter=Control.MOUSE_FILTER_IGNORE
 time_row.add_theme_constant_override("separation",6)
 left.add_child(time_row)
 var dial := TextureRect.new()
 dial.texture=CLOCK_ART
 dial.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 dial.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 dial.custom_minimum_size=Vector2(104,104)
 dial.mouse_filter=Control.MOUSE_FILTER_IGNORE
 time_row.add_child(dial)
 var face := VBoxContainer.new()
 face.mouse_filter=Control.MOUSE_FILTER_IGNORE
 face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 face.offset_left=10;face.offset_right=-10;face.offset_top=9;face.offset_bottom=-11
 face.alignment=BoxContainer.ALIGNMENT_CENTER
 face.add_theme_constant_override("separation",0)
 dial.add_child(face)
 var settings: Dictionary=text.data.hud
 var icons: Dictionary=settings.get("icons",{})
 _periods=icons.get("day_periods",[])
 if not _periods.is_empty():
  _day_icon=_icon("",26)
  _day_icon.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
  face.add_child(_day_icon)
  for period: Dictionary in _periods:_period_textures.append(load(period.path) as Texture2D)
 _clock=UiText.label()
 _clock.add_theme_font_size_override("font_size",18)
 _clock.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 _clock.set_meta("centered",true)
 face.add_child(_clock)
 _day=UiText.label()
 _day.add_theme_font_size_override("font_size",12)
 _day.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 _day.set_meta("centered",true)
 face.add_child(_day)
 var info := VBoxContainer.new()
 info.custom_minimum_size.x=126
 info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 info.mouse_filter=Control.MOUSE_FILTER_IGNORE
 info.add_theme_constant_override("separation",4)
 time_row.add_child(info)
 var wallet := _badge(info)
 wallet.add_child(_kit_icon("money",22))
 _money=UiText.label()
 _money.add_theme_font_size_override("font_size",15)
 wallet.add_child(_money)
 var state_badge := _badge(info)
 _state=UiText.label()
 _state.add_theme_font_size_override("font_size",12)
 _state.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 _state.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 state_badge.add_child(_state)
 _held=UiText.label()
 _held.add_theme_font_size_override("font_size",13)
 _held.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 left.add_child(_held)
 _held.hide()
 _save_feedback=UiText.label()
 _save_feedback.add_theme_font_size_override("font_size",13)
 _save_feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 left.add_child(_save_feedback)
 _save_feedback.hide()
 var spacer := Control.new()
 spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE
 spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 add_child(spacer)
 var right := VBoxContainer.new()
 right.mouse_filter=Control.MOUSE_FILTER_IGNORE
 right.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
 right.add_theme_constant_override("separation",5)
 add_child(right)
 var needs := _badge(right)
 for key in ["hunger","rest","mood"]:
  var meter := VBoxContainer.new()
  meter.add_theme_constant_override("separation",1)
  meter.custom_minimum_size.x=55
  needs.add_child(meter)
  var icon := _kit_icon(key,24)
  icon.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
  meter.add_child(icon)
  var caption := text.key_label(key)
  caption.add_theme_font_size_override("font_size",12)
  caption.set_meta("centered",true)
  caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  _need_labels.append(caption)
  meter.add_child(caption)
  var bar := ProgressBar.new()
  bar.custom_minimum_size=Vector2(52,7)
  bar.show_percentage=false
  var colors: Dictionary={"hunger":"#b88340","rest":"#37818a","mood":"#78964b"}
  bar.add_theme_stylebox_override("fill",CozyTheme.box(Color(colors[key]),Color.TRANSPARENT,3,0))
  bar.add_theme_stylebox_override("background",CozyTheme.box(Color("#ddc6a2"),Color.TRANSPARENT,3,0))
  meter.add_child(bar)
  _bars[key]=bar
 var shortcuts := HBoxContainer.new()
 shortcuts.mouse_filter=Control.MOUSE_FILTER_IGNORE
 shortcuts.add_theme_constant_override("separation",4)
 right.add_child(shortcuts)
 _shortcut(shortcuts,"bag",func():inventory_requested.emit())
 _shortcut(shortcuts,"notebook",func():notebook_requested.emit())
 _shortcut(shortcuts,"outings",func():outings_requested.emit())
 _shortcut(shortcuts,"settings",func():settings_requested.emit())
 _menu_button=_shortcut(shortcuts,"actions",func():menu_requested.emit())
 _refresh_shortcuts()
 LocaleService.current.changed.connect(_refresh_shortcuts)

func _badge(parent: VBoxContainer) -> HBoxContainer:
 var panel := PanelContainer.new()
 panel.theme_type_variation="HudBadge"
 panel.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
 parent.add_child(panel)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",5)
 panel.add_child(row)
 return row

func _kit_icon(key: String, extent: float) -> TextureRect:
 var icon := _icon("",extent)
 icon.texture=CozyTheme.icon_texture(key)
 return icon

func _shortcut(parent: HBoxContainer, key: String, action: Callable) -> Button:
 var button := UiText.button("",func():pass)
 button.custom_minimum_size=Vector2(44,44)
 button.theme_type_variation="QuietButton"
 button.icon=CozyTheme.icon_texture(key)
 button.expand_icon=true
 button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
 button.add_theme_constant_override("icon_max_width",26)
 button.pressed.connect(func():
  _popup_anchor=button
  action.call())
 parent.add_child(button)
 _shortcut_buttons[key]=button
 return button

func _refresh_shortcuts() -> void:
 _shortcut_buttons.bag.tooltip_text=_text.text("inventory")
 _shortcut_buttons.notebook.tooltip_text=_text.text("notebook")
 _shortcut_buttons.outings.tooltip_text=UiText.localized("cozy.outings")
 _shortcut_buttons.settings.tooltip_text=UiText.localized("cozy.settings")
 _shortcut_buttons.actions.tooltip_text=_text.text("menu")

func menu_anchor() -> Rect2:
 return (_popup_anchor if is_instance_valid(_popup_anchor) else _menu_button).get_global_rect()

func show_save_status(key: String) -> void:
 _save_feedback.visible=not key.is_empty()
 if not key.is_empty():
  _save_feedback.text=_text.text(key)
  UiText.bind_control(_save_feedback,"ui."+key)
func present(session: GameSession) -> void:
 var compact := get_viewport_rect().size.x<700
 for caption in _need_labels:caption.visible=not compact
 var minute := int(session.clock.minutes)%1440
 _clock.text="%02d:%02d" % [minute/60,minute%60]
 _day.text=("اليوم %s" if LocaleService.current.rtl() else "Day %s") % session.clock.day
 _clock.tooltip_text=_text.text("day_time",{"day":session.clock.day,"hour":"%02d" % (minute/60),"minute":"%02d" % (minute%60)})
 if _day_icon!=null:
  var period_index: int=0
  for index in _periods.size():
   if minute>=int(_periods[index].start_minute):period_index=index
  var locale_revision: int=LocaleService.current.revision if LocaleService.current else 0
  if period_index!=_day_period or locale_revision!=_day_locale_revision:
   _day_locale_revision=locale_revision
   _day_period=period_index
   _day_icon.texture=_period_textures[period_index]
   _day_icon.tooltip_text=_text.text(_periods[period_index].label)
   _day.tooltip_text=_day_icon.tooltip_text
 _money.text = _text.text("money",{"amount":"%.2f" % (session.wallet.balance/100.0)})
 _state.text = _text.text("open") if session.kiosk_open else _text.text("closed")
 if not session.accounts.business_allowed():_state.text+=" · "+_text.text("hud_business_suspended")
 if not session.actions.preview(&"personal_focus").ok:_state.text+=" · "+_text.text("hud_needs_sleep")
 elif session.needs.rest<session.tuning.value("fatigue_warning"):_state.text+=" · "+_text.text("hud_tired")
 _state.tooltip_text=_text.text("hud_focus",{"rest":"%.1f" % session.needs.rest,"focus":"%.1f" % session.alertness.effective_focus()})
 if session.fatigue.visual_scale<1:_state.tooltip_text+=" · "+_text.text("hud_fatigue_visual",{"percent":"%.0f" % (session.fatigue.visual_scale*100)})
 var held := session.items.get_item(session.inventory.held_id())
 _held.text = _text.text("held",{"item":ItemText.instance(session,held)}) if not held.is_empty() else _text.text("empty_hands")
 _held.tooltip_text = _held.text
 _held.visible=not held.is_empty()
 for key in _bars:
  _bars[key].value = session.needs.get(key)
  _bars[key].tooltip_text = _text.text(key)

func _icon(path: String, extent: float) -> TextureRect:
 var icon := TextureRect.new()
 icon.custom_minimum_size=Vector2.ONE*extent
 icon.mouse_filter=Control.MOUSE_FILTER_PASS
 icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 if not path.is_empty():icon.texture=load(path) as Texture2D
 return icon

func focus_menu() -> void:
 var origin := _popup_anchor if is_instance_valid(_popup_anchor) else _menu_button
 if is_instance_valid(origin) and origin.is_visible_in_tree():origin.grab_focus()
