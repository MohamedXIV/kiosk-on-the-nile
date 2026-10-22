class_name Atmosphere
extends CanvasLayer
var _data: Dictionary
var _shade: ColorRect
func configure(data: Dictionary) -> void:
 _data = data.duplicate(true)
 layer = 0
 _shade = ColorRect.new()
 _shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(_shade)
func present(minutes: float, location: StringName) -> void:
 var timing: Dictionary = _data.night
 var minute := fposmod(minutes,1440)
 var ratio := clampf((minute-float(timing.start))/(float(timing.end)-float(timing.start)),0,1)
 var factor := lerpf(float(timing.afternoon_factor),float(timing.night_factor),ratio)
 if minute<float(timing.morning_end): factor=float(timing.night_factor)
 _shade.color = Color(Color(timing.color),factor*float(timing.opacity) if location==&"kiosk" else 0)
