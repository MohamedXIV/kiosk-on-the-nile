class_name CozyTheme
extends RefCounted
## Presentation tokens shared by every native game surface. No domain state.
const INK := Color("#543c2b")
const MUTED := Color("#79634e")
const IVORY := Color("#f5e8ce")
const SAGE := Color("#496133")
const LINE := Color("#ac8d66")
static var _theme: Theme
static func make() -> Theme:
 if _theme!=null:return _theme
 var t := Theme.new()
 t.default_font=load("res://assets/fonts/Cairo.ttf")
 t.default_font_size=16
 for kind in ["Label","RichTextLabel","Button","OptionButton","CheckBox","LineEdit","TextEdit","SpinBox","TabBar","PopupMenu"]:
  t.set_color("font_color",kind,INK)
  t.set_color("font_hover_color",kind,INK)
  t.set_color("font_pressed_color",kind,INK)
  t.set_color("font_focus_color",kind,INK)
  t.set_color("font_disabled_color",kind,Color("#87928a"))
  t.set_color("font_outline_color",kind,Color.TRANSPARENT)
 t.set_color("default_color","RichTextLabel",INK)
 t.set_stylebox("panel","PanelContainer",box(IVORY,LINE,18,18))
 t.set_type_variation("Sheet","PanelContainer")
 t.set_stylebox("panel","Sheet",box(IVORY,LINE,22,22,true))
 t.set_type_variation("Card","PanelContainer")
 t.set_stylebox("panel","Card",box(Color("#f0f2e9"),Color("#e0e5d9"),14,14))
 t.set_type_variation("Inset","PanelContainer")
 t.set_stylebox("panel","Inset",box(Color("#e8eee2"),Color.TRANSPARENT,12,12))
 t.set_type_variation("Heading","Label")
 t.set_font_size("font_size","Heading",23)
 t.set_type_variation("Muted","Label")
 t.set_color("font_color","Muted",MUTED)
 t.set_font_size("font_size","Muted",14)
 for kind in ["Button","OptionButton"]:
  t.set_stylebox("normal",kind,box(Color("#e8eee2"),LINE,10,12))
  t.set_stylebox("hover",kind,box(Color("#dce7d6"),Color("#a6bca5"),10,12))
  t.set_stylebox("pressed",kind,box(Color("#cbdcc4"),SAGE,10,12))
  t.set_stylebox("disabled",kind,box(Color("#edf0e8"),Color("#e1e5dc"),10,12))
  t.set_stylebox("focus",kind,focus_box())
  for state in ["normal","hover","pressed","disabled","focus"]:t.set_stylebox(state+"_mirrored",kind,t.get_stylebox(state,kind))
  t.set_constant("h_separation",kind,10)
 t.set_type_variation("PrimaryButton","Button")
 for state in ["normal","hover","pressed"]:
  t.set_stylebox(state,"PrimaryButton",box(SAGE if state=="normal" else Color("#365944") if state=="hover" else Color("#2b4938"),Color.TRANSPARENT,10,12))
  t.set_color("font_"+state+"_color","PrimaryButton",IVORY)
 t.set_color("font_color","PrimaryButton",IVORY)
 t.set_color("font_hover_color","PrimaryButton",IVORY)
 t.set_color("font_pressed_color","PrimaryButton",IVORY)
 t.set_color("font_focus_color","PrimaryButton",IVORY)
 for state in ["normal","hover","pressed"]:t.set_stylebox(state+"_mirrored","PrimaryButton",t.get_stylebox(state,"PrimaryButton"))
 t.set_type_variation("QuietButton","Button")
 t.set_stylebox("normal","QuietButton",box(Color.TRANSPARENT,LINE,10,12))
 t.set_stylebox("normal_mirrored","QuietButton",t.get_stylebox("normal","QuietButton"))
 t.set_type_variation("DangerButton","Button")
 t.set_color("font_color","DangerButton",Color("#864d3f"))
 t.set_stylebox("normal","DangerButton",box(Color("#f4e8df"),Color("#e3cfc2"),10,12))
 t.set_stylebox("normal_mirrored","DangerButton",t.get_stylebox("normal","DangerButton"))
 for kind in ["LineEdit","TextEdit"]:
  t.set_stylebox("normal",kind,box(Color("#ffffff"),LINE,10,10))
  t.set_stylebox("read_only",kind,box(Color("#edf0e8"),LINE,10,10))
  t.set_stylebox("focus",kind,focus_box())
  t.set_color("caret_color",kind,SAGE)
  t.set_color("selection_color",kind,Color("#c9ddbd"))
  t.set_color("font_placeholder_color",kind,MUTED)
 t.set_stylebox("background","ProgressBar",box(Color("#dce3d5"),Color.TRANSPARENT,5,0))
 t.set_stylebox("fill","ProgressBar",box(Color("#809b73"),Color.TRANSPARENT,5,0))
 t.set_icon("checked","CheckBox",load("res://assets/ui/cozy/check.svg"))
 t.set_icon("unchecked","CheckBox",load("res://assets/ui/cozy/unchecked.svg"))
 t.set_icon("checked_disabled","CheckBox",load("res://assets/ui/cozy/check.svg"))
 t.set_icon("unchecked_disabled","CheckBox",load("res://assets/ui/cozy/unchecked.svg"))
 t.set_icon("arrow","OptionButton",load("res://assets/ui/cozy/down.svg"))
 t.set_constant("arrow_margin","OptionButton",12)
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
  t.set_font_size("font_size",kind,16)
 t.set_constant("separation","VBoxContainer",12)
 t.set_constant("separation","HBoxContainer",12)
 for kind in ["HFlowContainer","VFlowContainer"]:
  t.set_constant("h_separation",kind,10)
  t.set_constant("v_separation",kind,10)
 for kind in ["HScrollBar","VScrollBar"]:
  t.set_stylebox("scroll",kind,box(Color("#e4e9df"),Color.TRANSPARENT,5,3))
  for state in ["grabber","grabber_highlight","grabber_pressed"]:
   t.set_stylebox(state,kind,box(Color("#93aa87"),Color.TRANSPARENT,5,5))
 _apply_nile_assets(t)
 _apply_story_surfaces(t)
 _apply_work_surfaces(t)
 _apply_daily_surfaces(t)
 _apply_review_surfaces(t)
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

# Original scalable game artwork; texture cells protect the corner pixels.
const FRAME_ATLAS = preload("res://assets/ui/nile/frames.svg")
const ICON_ATLAS = preload("res://assets/ui/nile/icons.svg")
const FRAME_CELL := Vector2(80,48)
const FRAME_COLUMNS := 5
const ICON_CELL := 48
const ICON_INDEX := {"bag":0,"notebook":1,"outings":2,"settings":3,"actions":4,"money":5,"hunger":6,"rest":7,"mood":8}
static func texture_box(index: int, padding: int = 12, vertical_padding: int = 8) -> StyleBoxTexture:
 var style := StyleBoxTexture.new()
 style.texture=FRAME_ATLAS
 style.region_rect=Rect2(Vector2(index%FRAME_COLUMNS, floori(float(index)/FRAME_COLUMNS))*FRAME_CELL,FRAME_CELL)
 for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:
  style.set_texture_margin(side,12)
  style.set_content_margin(side,padding if side==SIDE_LEFT or side==SIDE_RIGHT else vertical_padding)
 return style
static func icon_texture(key: String) -> Texture2D:
 var result := AtlasTexture.new()
 result.atlas=ICON_ATLAS
 result.region=Rect2(int(ICON_INDEX[key])*ICON_CELL,0,ICON_CELL,ICON_CELL)
 result.filter_clip=true
 return result
static func _apply_nile_assets(t: Theme) -> void:
 t.set_stylebox("panel","PanelContainer",texture_box(0,16,12))
 t.set_stylebox("panel","Sheet",texture_box(0,22,16))
 t.set_stylebox("panel","Card",texture_box(1,14,10))
 t.set_stylebox("panel","Inset",texture_box(2,12,8))
 t.set_stylebox("panel","PopupPanel",texture_box(0,16,12))
 t.set_stylebox("panel","PopupMenu",texture_box(3,12,9))
 t.set_type_variation("HudBadge","PanelContainer")
 t.set_stylebox("panel","HudBadge",texture_box(3,10,6))
 t.set_type_variation("NileButton","Button")
 for kind in ["Button","OptionButton","PrimaryButton","QuietButton","DangerButton","NileButton"]:
  var start: int={"Button":4,"OptionButton":4,"PrimaryButton":8,"QuietButton":4,"DangerButton":16,"NileButton":12}[kind]
  for index in range(4):
   var state: String=["normal","hover","pressed","disabled"][index]
   var style := texture_box(start+index,12,7)
   # The painted face ends above the atlas shadow. Center text in the face,
   # not in the full cell including its lower shadow (2 px optical correction).
   style.set_content_margin(SIDE_TOP,5)
   style.set_content_margin(SIDE_BOTTOM,9)
   t.set_stylebox(state,kind,style)
   t.set_stylebox(state+"_mirrored",kind,style)
  var ink := IVORY if kind in ["PrimaryButton","DangerButton","NileButton"] else INK
  for property in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:t.set_color(property,kind,ink)
  t.set_color("font_disabled_color",kind,Color("#756b60"))
  t.set_stylebox("focus",kind,focus_box())
  t.set_stylebox("focus_mirrored",kind,t.get_stylebox("focus",kind))

# Distinct tactile surfaces; the same accessibility and localization primitives.
const NOTEBOOK_ART = preload("res://assets/ui/nile/notebook.svg")
const PAPER_ART = preload("res://assets/ui/nile/paper.svg")
const SPEECH_ART = preload("res://assets/ui/nile/speech.svg")
static func story_box(art: Texture2D,margin: int,padding: int,vertical: int) -> StyleBoxTexture:
 var style := StyleBoxTexture.new()
 style.texture=art
 for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:
  style.set_texture_margin(side,margin)
  style.set_content_margin(side,padding if side==SIDE_LEFT or side==SIDE_RIGHT else vertical)
 return style
static func _apply_story_surfaces(t: Theme) -> void:
 for kind in ["NotebookCover","NotebookPage","TitleTray","DialogueFrame","PersonPage"]:
  t.set_type_variation(kind,"PanelContainer")
 t.set_stylebox("panel","NotebookCover",story_box(NOTEBOOK_ART,18,22,16))
 t.set_stylebox("panel","NotebookPage",story_box(PAPER_ART,8,14,12))
 t.set_stylebox("panel","PersonPage",story_box(PAPER_ART,8,14,12))
 t.set_stylebox("panel","TitleTray",texture_box(3,16,12))
 t.set_stylebox("panel","DialogueFrame",box(Color.TRANSPARENT,Color.TRANSPARENT,0,0))
 t.set_type_variation("SpeakerTag","Label")
 t.set_stylebox("normal","SpeakerTag",texture_box(12,14,5))
 t.set_color("font_color","SpeakerTag",IVORY)
 t.set_font_size("font_size","SpeakerTag",18)
 t.set_type_variation("DialogueLine","Label")
 t.set_stylebox("normal","DialogueLine",story_box(SPEECH_ART,18,16,12))
 t.set_font_size("font_size","DialogueLine",17)
 t.set_type_variation("NotebookTabs","TabBar")
 t.set_stylebox("tab_selected","NotebookTabs",texture_box(12,14,6))
 t.set_stylebox("tab_hovered","NotebookTabs",texture_box(5,14,6))
 t.set_stylebox("tab_unselected","NotebookTabs",texture_box(4,14,6))
 t.set_color("font_selected_color","NotebookTabs",IVORY)
 t.set_color("font_unselected_color","NotebookTabs",INK)
 t.set_color("font_hovered_color","NotebookTabs",INK)
 t.set_type_variation("NotebookSection","Label")
 t.set_color("font_color","NotebookSection",Color("#24616b"))
 t.set_font_size("font_size","NotebookSection",20)

# Distinct work surfaces: a storage tray, a seller's board, and recipe paper.
static func _apply_work_surfaces(t: Theme) -> void:
 for kind in ["InventoryBag","ShopBoard","CookingBoard","StorageTray","ItemSlot","SelectedItemSlot","ItemDetail","StationTray","RecipePaper","OrderSlip"]:
  t.set_type_variation(kind,"PanelContainer")
 t.set_stylebox("panel","InventoryBag",story_box(NOTEBOOK_ART,18,20,14))
 t.set_stylebox("panel","ShopBoard",texture_box(0,20,14))
 t.set_stylebox("panel","CookingBoard",story_box(NOTEBOOK_ART,18,20,14))
 t.set_stylebox("panel","StorageTray",texture_box(2,12,9))
 t.set_stylebox("panel","ItemSlot",texture_box(1,8,6))
 t.set_stylebox("panel","SelectedItemSlot",texture_box(5,8,6))
 t.set_stylebox("panel","ItemDetail",story_box(PAPER_ART,8,12,9))
 t.set_stylebox("panel","RecipePaper",story_box(PAPER_ART,8,14,10))
 t.set_stylebox("panel","StationTray",texture_box(2,12,8))
 t.set_stylebox("panel","OrderSlip",story_box(PAPER_ART,8,12,8))
 t.set_type_variation("ShopHeading","Label")
 t.set_font_size("font_size","ShopHeading",20)
 t.set_color("font_color","ShopHeading",Color("#24616b"))
 t.set_type_variation("PriceTag","Label")
 t.set_font_size("font_size","PriceTag",14)
 t.set_color("font_color","PriceTag",Color("#78562c"))

const RECEIPT_ART=preload("res://assets/ui/nile/receipt.svg")
static func _apply_daily_surfaces(t: Theme) -> void:
 for kind in ["JourneyTicket","ArrangementDock","ReceiptSheet","SupplierLedger","MenuBoard","SleepCard","VisitorNote","SettingsPage"]:
  t.set_type_variation(kind,"PanelContainer")
 t.set_stylebox("panel","JourneyTicket",story_box(PAPER_ART,8,18,14))
 t.set_stylebox("panel","ArrangementDock",texture_box(2,12,7))
 t.set_stylebox("panel","ReceiptSheet",story_box(RECEIPT_ART,12,18,16))
 t.set_stylebox("panel","SupplierLedger",story_box(NOTEBOOK_ART,18,18,12))
 t.set_stylebox("panel","MenuBoard",story_box(NOTEBOOK_ART,18,18,12))
 t.set_stylebox("panel","SleepCard",texture_box(3,14,10))
 t.set_stylebox("panel","VisitorNote",story_box(PAPER_ART,8,14,10))
 t.set_stylebox("panel","SettingsPage",story_box(PAPER_ART,8,12,10))
 t.set_type_variation("Notice","Label")
 t.set_stylebox("normal","Notice",texture_box(3,14,9))
 t.set_color("font_color","Notice",INK)
 t.set_font_size("font_size","Notice",15)

# The first rendered review exposed a nearly monochrome card treatment.
# Semantic headings give the work surfaces their own identity without new state.
static func _apply_review_surfaces(t: Theme) -> void:
 for entry in [["SectionOlive",8],["SectionNile",12],["SectionClay",16]]:
  var kind: String=entry[0]
  t.set_type_variation(kind,"PanelContainer")
  t.set_stylebox("panel",kind,texture_box(int(entry[1]),12,7))
 t.set_type_variation("NotebookBook","TabContainer")
 t.set_stylebox("panel","NotebookBook",story_box(PAPER_ART,8,14,12))
 for kind in ["TabContainer","NotebookBook"]:
  t.set_stylebox("tab_selected",kind,texture_box(12,14,6))
  t.set_stylebox("tab_hovered",kind,texture_box(5,14,6))
  t.set_stylebox("tab_unselected",kind,texture_box(4,14,6))
  t.set_color("font_selected_color",kind,IVORY)
  t.set_color("font_unselected_color",kind,INK)
  t.set_color("font_hovered_color",kind,INK)
 for kind in ["LineEdit","TextEdit"]:
  t.set_stylebox("normal",kind,box(Color("#fff4df"),LINE,8,9))
