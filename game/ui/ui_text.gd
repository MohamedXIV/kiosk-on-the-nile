class_name UiText
extends RefCounted
var data: Dictionary
func _init(source: Dictionary) -> void:
 data = source.duplicate(true)
func text(key: String, values: Dictionary = {}) -> String:
 var context := values.duplicate()
 if data.has("input"):
  context.merge({"primary_key":data.input.interact_primary[0],"secondary_key":data.input.interact_secondary[0],"notebook_key":data.input.notebook[0],"move_keys":" / ".join([data.input.move_up[0],data.input.move_left[0],data.input.move_down[0],data.input.move_right[0]])},false)
 return localized("ui."+key,context,str(data.get(key,key)).format(context))
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
 control.text_direction = Control.TEXT_DIRECTION_RTL if LocaleService.current==null or LocaleService.current.rtl() else Control.TEXT_DIRECTION_LTR
 control.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if LocaleService.current==null or LocaleService.current.rtl() else HORIZONTAL_ALIGNMENT_LEFT
 return control
static func button(value: String, callback: Callable) -> Button:
 var control := Button.new()
 control.text = value
 control.text_direction = Control.TEXT_DIRECTION_RTL if LocaleService.current==null or LocaleService.current.rtl() else Control.TEXT_DIRECTION_LTR
 control.focus_mode = Control.FOCUS_NONE
 control.pressed.connect(callback)
 return control

static func localized(id: String, args: Dictionary = {}, fallback: String = "") -> String:
 return LocaleService.current.text(id,args,fallback) if LocaleService.current!=null else fallback
func key_label(key: String, args: Dictionary = {}) -> Label:
 var control := UiText.label(text(key,args));bind_control(control,"ui."+key,args)
 return control
func key_button(key: String, callback: Callable, args: Dictionary = {}) -> Button:
 var control := UiText.button(text(key,args),callback);bind_control(control,"ui."+key,args)
 return control
static func bind_control(control: Control, id: String, args: Dictionary = {}) -> void:
 control.set_meta("text_ref",id);control.set_meta("text_args",args.duplicate(true))
 control.set_meta("source_fallback",control.get("text"))
 control.set("text",localized(id,args,str(control.get("text"))))
static func refresh_tree(root: Node) -> void:
 if root is Control:
  root.layout_direction=Control.LAYOUT_DIRECTION_RTL if LocaleService.current.rtl() else Control.LAYOUT_DIRECTION_LTR
  if root is Label or root is Button or root is RichTextLabel:
   root.text_direction=Control.TEXT_DIRECTION_RTL if LocaleService.current.rtl() else Control.TEXT_DIRECTION_LTR
  if root.has_meta("text_ref"):root.set("text",localized(str(root.get_meta("text_ref")),root.get_meta("text_args",{}),str(root.get_meta("source_fallback",""))))
  if root is OptionButton and root.has_meta("locale_picker"):root.select(0 if LocaleService.current.rtl() else 1)
 for child in root.get_children():refresh_tree(child)
