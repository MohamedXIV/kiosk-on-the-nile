class_name StatusStrip
extends PanelContainer
signal menu_requested
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
var _bars: Dictionary = {}
var _save_feedback: Label
func configure(text: UiText) -> void:
 _text = text
 var settings: Dictionary = text.data.hud
 add_theme_font_size_override("font_size",int(settings.font_size))
 var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
 style.content_margin_top = 6
 style.content_margin_bottom = 6
 add_theme_stylebox_override("panel",style)
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",2)
 add_child(box)
 var heading := HBoxContainer.new()
 heading.layout_direction = Control.LAYOUT_DIRECTION_INHERITED
 heading.add_theme_constant_override("separation",18)
 box.add_child(heading)
 var clock_group := HBoxContainer.new()
 clock_group.layout_direction=Control.LAYOUT_DIRECTION_INHERITED
 heading.add_child(clock_group)
 var icons: Dictionary=settings.get("icons",{})
 _periods=icons.get("day_periods",[])
 if not _periods.is_empty():
  _day_icon=_icon("",float(icons.get("size",22)))
  clock_group.add_child(_day_icon)
  for period: Dictionary in _periods:_period_textures.append(load(period.path) as Texture2D)
 _clock = UiText.label()
 clock_group.add_child(_clock)
 _money = UiText.label()
 heading.add_child(_money)
 _state = UiText.label()
 _state.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 heading.add_child(_state)
 var menu := text.key_button("menu",func():menu_requested.emit())
 menu.focus_mode=Control.FOCUS_ALL
 menu.custom_minimum_size.x=80
 menu.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 for state in ["normal","hover","pressed"]:
  var button_style: StyleBoxFlat = get_theme_stylebox(state,"Button").duplicate()
  button_style.content_margin_top = 2
  button_style.content_margin_bottom = 2
  menu.add_theme_stylebox_override(state,button_style)
 heading.add_child(menu)
 var details := HBoxContainer.new()
 details.layout_direction = Control.LAYOUT_DIRECTION_INHERITED
 details.add_theme_constant_override("separation",18)
 box.add_child(details)
 for key in ["hunger","rest","mood"]:
  var meter := HBoxContainer.new()
  meter.layout_direction = Control.LAYOUT_DIRECTION_INHERITED
  if icons.get("needs",{}).has(key):meter.add_child(_icon(icons.needs[key],float(icons.get("size",22))))
  meter.add_child(text.key_label(key))
  var bar := ProgressBar.new()
  bar.custom_minimum_size = Vector2(float(settings.meter_width),8)
  bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
  bar.show_percentage = false
  var fill := StyleBoxFlat.new()
  fill.bg_color = Color(settings.meter_colors[key])
  fill.set_corner_radius_all(4)
  var background := fill.duplicate()
  background.bg_color = Color("#463c32")
  bar.add_theme_stylebox_override("fill",fill)
  bar.add_theme_stylebox_override("background",background)
  meter.add_child(bar)
  details.add_child(meter)
  _bars[key] = bar
 _held = UiText.label()
 _held.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 _held.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 _held.clip_text = true
 details.add_child(_held)
 _save_feedback=UiText.label()
 _save_feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 box.add_child(_save_feedback)
 _save_feedback.hide()
func show_save_status(key: String) -> void:
 _save_feedback.visible=not key.is_empty()
 if not key.is_empty():
  _save_feedback.text=_text.text(key)
  UiText.bind_control(_save_feedback,"ui."+key)
func present(session: GameSession) -> void:
 var minute := int(session.clock.minutes)%1440
 _clock.text = _text.text("day_time",{"day":session.clock.day,"hour":"%02d" % (minute/60),"minute":"%02d" % (minute%60)})
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
   _clock.tooltip_text=_day_icon.tooltip_text
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
