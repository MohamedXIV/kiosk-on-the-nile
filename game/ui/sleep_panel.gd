class_name SleepPanel
extends PanelContainer
signal confirmed(hours: int)
var _routine: DailyRoutine
var _text: UiText
var _hours: SpinBox
var _preview: Label
var _confirm: Button
func configure(text: UiText) -> void:
 _text = text
 theme = text.make_theme()
 anchor_left = 0.23
 anchor_right = 0.77
 anchor_top = 0.16
 anchor_bottom = 0.78
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",14)
 add_child(box)
 box.add_child(UiText.label(text.text("sleep_title")))
 _hours = SpinBox.new()
 _hours.rounded = true
 _hours.suffix = text.text("sleep_hours_suffix")
 box.add_child(_hours)
 _preview = UiText.label()
 _preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 _preview.custom_minimum_size = Vector2(350,120)
 _preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
 box.add_child(_preview)
 _confirm = UiText.button(text.text("sleep_confirm"),func():confirmed.emit(int(_hours.value)))
 box.add_child(_confirm)
 box.add_child(UiText.button(text.text("sleep_cancel"),hide))
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
func _process(_delta: float) -> void:
 if visible and _routine: _refresh()
func _refresh() -> void:
 var result := _routine.preview(int(_hours.value))
 _confirm.disabled = not result.ok
 if not result.ok:
  _preview.text = _text.outcome(result)
  return
 var data: Dictionary = result.details
 var minute := int(data.wake_minutes)
 _preview.text = _text.text("sleep_preview",{"hours":data.requested_hours,"day":data.wake_day,"hour":"%02d" % (minute/60),"minute":"%02d" % (minute%60)})
 _preview.text += "\n"+(_text.text("sleep_oversleep",{"hours":data.extra_hours}) if data.extra_hours>0 else _text.text("sleep_on_time"))
 _preview.text += "\n"+_text.text("sleep_recovery")
