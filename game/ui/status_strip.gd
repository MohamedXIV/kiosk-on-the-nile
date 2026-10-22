class_name StatusStrip
extends PanelContainer
signal menu_requested
var _text: UiText
var _clock: Label
var _money: Label
var _state: Label
var _inventory: Label
var _held: Label
var _bars: Dictionary = {}
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
 heading.layout_direction = Control.LAYOUT_DIRECTION_RTL
 heading.add_theme_constant_override("separation",18)
 box.add_child(heading)
 _clock = UiText.label()
 heading.add_child(_clock)
 _money = UiText.label()
 heading.add_child(_money)
 _state = UiText.label()
 _state.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 heading.add_child(_state)
 var menu := UiText.button(text.text("menu"),func():menu_requested.emit())
 for state in ["normal","hover","pressed"]:
  var button_style: StyleBoxFlat = get_theme_stylebox(state,"Button").duplicate()
  button_style.content_margin_top = 2
  button_style.content_margin_bottom = 2
  menu.add_theme_stylebox_override(state,button_style)
 heading.add_child(menu)
 var details := HBoxContainer.new()
 details.layout_direction = Control.LAYOUT_DIRECTION_RTL
 details.add_theme_constant_override("separation",18)
 box.add_child(details)
 _inventory = UiText.label()
 details.add_child(_inventory)
 for key in ["hunger","rest","mood"]:
  var meter := HBoxContainer.new()
  meter.layout_direction = Control.LAYOUT_DIRECTION_RTL
  meter.add_child(UiText.label(text.text(key)))
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
func present(session: GameSession) -> void:
 var minute := int(session.clock.minutes)%1440
 _clock.text = _text.text("day_time",{"day":session.clock.day,"hour":"%02d" % (minute/60),"minute":"%02d" % (minute%60)})
 _money.text = _text.text("money",{"amount":"%.2f" % (session.wallet.balance/100.0)})
 _state.text = _text.text("open") if session.kiosk_open else _text.text("closed")
 var stock := session.cooking.inventory_snapshot()
 _inventory.text = _text.text("stock_short",{"tea":int(stock.tea),"kebda":int(stock.kebda)})
 _held.text = _text.text("held",{"item":session.cooking.item_label(session.cooking.held_item())}) if session.cooking.held_item() else _text.text("empty_hands")
 if not session.inventory.held_id().is_empty() and session.cooking.held_item()==null:_held.text=_text.text("held",{"item":session.items.definition(StringName(session.items.get_item(session.inventory.held_id()).definition_id)).label})
 _held.tooltip_text = _held.text
 for key in _bars:
  _bars[key].value = session.needs.get(key)
  _bars[key].tooltip_text = _text.text(key)
