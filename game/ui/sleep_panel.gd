class_name SleepPanel
extends PanelContainer
signal confirmed(hours: int)
var _routine: DailyRoutine
var _text: UiText
var _hours: SpinBox
var _preview: Label
var _confirm: Button
var _cancel: Button
var _timing := SheetControls.label()
var _care := SheetControls.label()
func configure(text: UiText) -> void:
 _text = text
 theme = text.make_theme()
 SheetControls.shell(self,680,132,66)
 var root := VBoxContainer.new();root.add_theme_constant_override("separation",14);add_child(root)
 SheetControls.header(root,text.key_label("sleep_title"),text,hide)
 var box := VBoxContainer.new();var scroll := SheetControls.scroll(box);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(scroll)
 var duration := SheetControls.card(box)
 _hours = SpinBox.new()
 _hours.rounded = true
 _hours.update_on_text_changed = true
 _hours.suffix = text.text("sleep_hours_suffix")
 _hours.custom_minimum_size.y=48
 _hours.get_line_edit().text_direction=Control.TEXT_DIRECTION_LTR
 _hours.value_changed.connect(func(_value):if visible and _routine:_refresh())
 LocaleService.current.changed.connect(func():_hours.suffix=_text.text("sleep_hours_suffix"))
 duration.add_child(_hours)
 _preview = SheetControls.label()
 SheetControls.title(_preview)
 duration.add_child(_preview)
 duration.add_child(_timing)
 var care := SheetControls.card(box);SheetControls.muted(_care);care.add_child(_care)
 var actions := HFlowContainer.new();actions.add_theme_constant_override("h_separation",12);root.add_child(actions)
 _cancel = SheetControls.key_button(text,"sleep_cancel",hide);actions.add_child(_cancel)
 _confirm = SheetControls.key_button(text,"sleep_confirm",func():
  _refresh()
  if not _confirm.disabled:confirmed.emit(int(_hours.value)))
 SheetControls.primary(_confirm);actions.add_child(_confirm)
 hide()
func present(routine: DailyRoutine) -> void:
 _routine = routine
 var settings := routine.policy.sleep_settings()
 _hours.min_value = int(settings.minimum_hours)
 _hours.max_value = int(settings.maximum_hours)
 _hours.step = int(settings.step_hours)
 _hours.value = int(settings.default_hours)
 show()
 _refresh()
 _cancel.grab_focus()
func _process(_delta: float) -> void:
 if visible and _routine: _refresh()
func _refresh() -> void:
 var result := _routine.preview(int(_hours.value))
 _confirm.disabled = not result.ok
 if not result.ok:
  _preview.text = _text.outcome(result)
  _timing.text="";_care.text=""
  return
 var data: Dictionary = result.details
 var minute := int(data.wake_minutes)
 _preview.text = _text.text("sleep_preview",{"hours":data.requested_hours,"day":data.wake_day,"hour":"%02d" % (minute/60),"minute":"%02d" % (minute%60)})
 _timing.text = (_text.text("sleep_oversleep",{"hours":data.extra_hours}) if data.extra_hours>0 else _text.text("sleep_on_time"))
 _care.text = _text.text("sleep_recovery")
 if float(data.get("rest_multiplier",1))<1:_care.text+="\n"+_text.text("sleep_dirty_bed")
