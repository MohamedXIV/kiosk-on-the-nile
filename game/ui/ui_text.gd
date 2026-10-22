class_name UiText
extends RefCounted
var data: Dictionary
func _init(source: Dictionary) -> void:
 data = source.duplicate(true)
func text(key: String, values: Dictionary = {}) -> String:
 var context := values.duplicate()
 if data.has("input"):
  context.merge({"primary_key":data.input.interact_primary[0],"secondary_key":data.input.interact_secondary[0],"notebook_key":data.input.notebook[0],"move_keys":" / ".join([data.input.move_up[0],data.input.move_left[0],data.input.move_down[0],data.input.move_right[0]])},false)
 return str(data.get(key,key)).format(context)
func outcome(result: ActionResult) -> String:
 if result.ok: return text("saved") if result.details.get("saved",false) else text("success")
 return str(data.get("errors",{}).get(str(result.message_key),text("save_failed") if result.code==ActionResult.Code.IO_ERROR else text("action_unavailable")))
func make_theme() -> Theme:
 var theme := Theme.new()
 theme.default_font = load("res://assets/fonts/Cairo.ttf")
 theme.default_font_size = int(data.theme.font_size)
 theme.set_color("font_color","Label",Color(data.theme.text))
 var box := StyleBoxFlat.new()
 box.bg_color = Color(data.theme.background)
 box.border_color = Color(data.theme.border)
 box.set_border_width_all(1)
 box.set_corner_radius_all(12)
 box.content_margin_left = 16
 box.content_margin_right = 16
 box.content_margin_top = 12
 box.content_margin_bottom = 12
 theme.set_stylebox("panel","PanelContainer",box)
 var button := box.duplicate()
 button.bg_color = Color("#3d3023")
 theme.set_stylebox("normal","Button",button)
 var hover := button.duplicate()
 hover.bg_color = Color("#665039")
 theme.set_stylebox("hover","Button",hover)
 theme.set_stylebox("pressed","Button",box)
 return theme
static func label(value: String = "") -> Label:
 var control := Label.new()
 control.text = value
 control.text_direction = Control.TEXT_DIRECTION_RTL
 control.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 return control
static func button(value: String, callback: Callable) -> Button:
 var control := Button.new()
 control.text = value
 control.text_direction = Control.TEXT_DIRECTION_RTL
 control.focus_mode = Control.FOCUS_NONE
 control.pressed.connect(callback)
 return control
