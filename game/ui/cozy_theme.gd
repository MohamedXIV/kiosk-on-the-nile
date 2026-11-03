class_name CozyTheme
extends RefCounted
## Presentation tokens shared by every native game surface. No domain state.
const INK := Color("#293c35")
const MUTED := Color("#617168")
const IVORY := Color("#faf7ef")
const SAGE := Color("#466b57")
const LINE := Color("#d6ded1")
static var _theme: Theme
static func make() -> Theme:
 if _theme!=null:return _theme
 var t := Theme.new()
 t.default_font=load("res://assets/fonts/Cairo.ttf")
 t.default_font_size=18
 for kind in ["Label","RichTextLabel","Button","OptionButton","CheckBox","LineEdit","TextEdit","SpinBox","TabBar","PopupMenu"]:
  t.set_color("font_color",kind,INK)
  t.set_color("font_hover_color",kind,INK)
  t.set_color("font_pressed_color",kind,INK)
  t.set_color("font_focus_color",kind,INK)
  t.set_color("font_disabled_color",kind,Color("#87928a"))
  t.set_color("font_outline_color",kind,Color.TRANSPARENT)
 t.set_stylebox("panel","PanelContainer",box(IVORY,LINE,18,18))
 t.set_type_variation("Sheet","PanelContainer")
 t.set_stylebox("panel","Sheet",box(IVORY,LINE,22,22,true))
 t.set_type_variation("Card","PanelContainer")
 t.set_stylebox("panel","Card",box(Color("#f0f2e9"),Color("#e0e5d9"),14,14))
 t.set_type_variation("Inset","PanelContainer")
 t.set_stylebox("panel","Inset",box(Color("#e8eee2"),Color.TRANSPARENT,12,12))
 t.set_type_variation("Heading","Label")
 t.set_font_size("font_size","Heading",26)
 t.set_type_variation("Muted","Label")
 t.set_color("font_color","Muted",MUTED)
 t.set_font_size("font_size","Muted",16)
 for kind in ["Button","OptionButton"]:
  t.set_stylebox("normal",kind,box(Color("#e8eee2"),LINE,10,12))
  t.set_stylebox("hover",kind,box(Color("#dce7d6"),Color("#a6bca5"),10,12))
  t.set_stylebox("pressed",kind,box(Color("#cbdcc4"),SAGE,10,12))
  t.set_stylebox("disabled",kind,box(Color("#edf0e8"),Color("#e1e5dc"),10,12))
  t.set_stylebox("focus",kind,focus_box())
  t.set_constant("h_separation",kind,10)
 t.set_type_variation("PrimaryButton","Button")
 for state in ["normal","hover","pressed"]:
  t.set_stylebox(state,"PrimaryButton",box(SAGE if state=="normal" else Color("#365944") if state=="hover" else Color("#2b4938"),Color.TRANSPARENT,10,12))
  t.set_color("font_"+state+"_color","PrimaryButton",IVORY)
 t.set_color("font_color","PrimaryButton",IVORY)
 t.set_color("font_hover_color","PrimaryButton",IVORY)
 t.set_color("font_pressed_color","PrimaryButton",IVORY)
 t.set_color("font_focus_color","PrimaryButton",IVORY)
 t.set_type_variation("QuietButton","Button")
 t.set_stylebox("normal","QuietButton",box(Color.TRANSPARENT,LINE,10,12))
 t.set_type_variation("DangerButton","Button")
 t.set_color("font_color","DangerButton",Color("#864d3f"))
 t.set_stylebox("normal","DangerButton",box(Color("#f4e8df"),Color("#e3cfc2"),10,12))
 for kind in ["LineEdit","TextEdit"]:
  t.set_stylebox("normal",kind,box(Color("#ffffff"),LINE,10,10))
  t.set_stylebox("read_only",kind,box(Color("#edf0e8"),LINE,10,10))
  t.set_stylebox("focus",kind,focus_box())
  t.set_color("caret_color",kind,SAGE)
  t.set_color("selection_color",kind,Color("#c9ddbd"))
  t.set_color("font_placeholder_color",kind,MUTED)
 t.set_stylebox("background","ProgressBar",box(Color("#dce3d5"),Color.TRANSPARENT,5,0))
 t.set_stylebox("fill","ProgressBar",box(Color("#809b73"),Color.TRANSPARENT,5,0))
 t.set_stylebox("panel","PopupPanel",box(IVORY,LINE,18,14,true))
 t.set_stylebox("panel","PopupMenu",box(IVORY,LINE,12,10,true))
 t.set_stylebox("hover","PopupMenu",box(Color("#dce7d6"),Color.TRANSPARENT,8,6))
 t.set_constant("v_separation","PopupMenu",12)
 t.set_stylebox("panel","TabContainer",box(Color.TRANSPARENT,Color.TRANSPARENT,0,8))
 for state in ["tab_selected","tab_hovered","tab_unselected","tab_disabled"]:
  t.set_stylebox(state,"TabBar",box(Color("#dce7d6") if state=="tab_selected" else Color.TRANSPARENT,Color.TRANSPARENT,10,12))
  t.set_stylebox(state,"TabContainer",t.get_stylebox(state,"TabBar"))
 for kind in ["TabBar","TabContainer"]:
  t.set_color("font_selected_color",kind,INK)
  t.set_color("font_unselected_color",kind,MUTED)
  t.set_color("font_hovered_color",kind,INK)
  t.set_font_size("font_size",kind,17)
 t.set_constant("separation","VBoxContainer",12)
 t.set_constant("separation","HBoxContainer",12)
 for kind in ["HFlowContainer","VFlowContainer"]:
  t.set_constant("h_separation",kind,10)
  t.set_constant("v_separation",kind,10)
 for kind in ["HScrollBar","VScrollBar"]:
  t.set_stylebox("scroll",kind,box(Color("#e4e9df"),Color.TRANSPARENT,5,3))
  for state in ["grabber","grabber_highlight","grabber_pressed"]:
   t.set_stylebox(state,kind,box(Color("#93aa87"),Color.TRANSPARENT,5,5))
 _theme=t
 return _theme
static func box(fill: Color, border: Color, radius: int, padding: int, elevated: bool=false) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color=fill;style.border_color=border
 style.set_border_width_all(1 if border.a>0 else 0)
 style.set_corner_radius_all(radius)
 style.content_margin_left=padding;style.content_margin_right=padding
 style.content_margin_top=padding*0.65;style.content_margin_bottom=padding*0.65
 if elevated:
  style.shadow_color=Color(0.1,0.17,0.12,0.16);style.shadow_size=12;style.shadow_offset=Vector2(0,5)
 return style
static func focus_box() -> StyleBoxFlat:
 var style := box(Color.TRANSPARENT,Color("#769557"),10,0)
 style.set_border_width_all(3)
 style.expand_margin_left=2;style.expand_margin_right=2
 style.expand_margin_top=2;style.expand_margin_bottom=2
 return style
