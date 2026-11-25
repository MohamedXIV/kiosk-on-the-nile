class_name TitleScreen
extends Control
signal new_requested
signal continue_requested
var _feedback := SheetControls.label()
var _error: ActionResult
var _text: UiText
const SCENERY = preload("res://game/ui/title_scenery.gd")
var _masthead: VBoxContainer
var _actions: PanelContainer
var _heading: Label
func configure(text: UiText, can_continue: bool, config: SessionConfig=null) -> void:
 _text=text
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 theme=text.make_theme()
 var background := ColorRect.new()
 background.color=Color("#192e38")
 background.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(background)
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 if config!=null:
  var scene := SCENERY.new()
  add_child(scene)
  scene.configure(config)
 # A game title over the actual river, not a website hero inside a card.
 _masthead=VBoxContainer.new()
 _masthead.mouse_filter=Control.MOUSE_FILTER_IGNORE
 _masthead.add_theme_constant_override("separation",4)
 add_child(_masthead)
 var eyebrow := SheetControls.label(UiText.localized("cozy.title_eyebrow",{},"A little life by the river"))
 UiText.bind_control(eyebrow,"cozy.title_eyebrow")
 _title_ink(eyebrow,Color("#e5b94e"),15)
 _masthead.add_child(eyebrow)
 _heading=text.key_label("title")
 _heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 _title_ink(_heading,Color("#fff4dc"),42)
 _masthead.add_child(_heading)
 var subtitle := text.key_label("subtitle")
 subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 _title_ink(subtitle,Color("#e9d7b4"),16)
 _masthead.add_child(subtitle)
 _actions=PanelContainer.new()
 _actions.theme_type_variation="TitleTray"
 add_child(_actions)
 var content := VBoxContainer.new()
 content.add_theme_constant_override("separation",8)
 _actions.add_child(content)
 var continue_button := text.key_button("continue",func():continue_requested.emit())
 continue_button.disabled=not can_continue
 var new_button := text.key_button("new_game",func():new_requested.emit())
 if can_continue:SheetControls.primary(continue_button);content.add_child(continue_button);content.add_child(new_button)
 else:SheetControls.primary(new_button);content.add_child(new_button);content.add_child(continue_button)
 for button in [continue_button,new_button]:button.custom_minimum_size.y=48
 var settings := HBoxContainer.new()
 content.add_child(settings)
 var language := SheetControls.label(UiText.localized("cozy.language",{},"Language"))
 UiText.bind_control(language,"cozy.language");SheetControls.muted(language)
 settings.add_child(language)
 var picker := LocaleService.current.picker()
 picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 settings.add_child(picker)
 var hint := SheetControls.label(UiText.localized("cozy.title_hint",{},"Take your time. The corniche has room for a quiet day."))
 UiText.bind_control(hint,"cozy.title_hint")
 SheetControls.muted(hint)
 content.add_child(hint)
 _feedback.add_theme_color_override("font_color",Color("#864b3f"))
 content.add_child(_feedback)
 _feedback.hide()
 LocaleService.current.changed.connect(_update_error)
 LocaleService.current.changed.connect(_fit)
 resized.connect(_fit)
 _actions.minimum_size_changed.connect(_fit)
 _fit.call_deferred()
 (continue_button if can_continue else new_button).call_deferred("grab_focus")

func _title_ink(label: Label,ink: Color,point_size: int) -> void:
 label.set_meta("centered",true)
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label.add_theme_color_override("font_color",ink)
 label.add_theme_color_override("font_shadow_color",Color("#111f29"))
 label.add_theme_constant_override("shadow_offset_x",1)
 label.add_theme_constant_override("shadow_offset_y",2)
 label.add_theme_font_size_override("font_size",point_size)

func _fit() -> void:
 if not is_instance_valid(_actions):return
 var extent := size
 if extent.x<100 or extent.y<100:return
 var compact := extent.x<760
 var title_width := minf(extent.x-40,720)
 _heading.add_theme_font_size_override("font_size",34 if compact else 42)
 _masthead.position=Vector2((extent.x-title_width)*0.5,20 if compact else 30)
 _masthead.size=Vector2(title_width,0)
 var width := minf(332,extent.x-32)
 _actions.size=Vector2(width,_actions.get_combined_minimum_size().y)
 var x := (extent.x-width)*0.5 if compact else (24.0 if LocaleService.current.rtl() else extent.x-width-24)
 _actions.position=Vector2(x,maxf(_masthead.position.y+_masthead.size.y+12,extent.y-_actions.size.y-24))

func show_error(result: ActionResult) -> void:
 _error=result
 _update_error()
func _update_error() -> void:
 if _error==null:return
 _feedback.text=_text.outcome(_error) if _text.data.get("errors",{}).has(str(_error.message_key)) else _text.text("load_failed")
 _feedback.show()

static func boot(parent: Node) -> Label:
 var status := Label.new()
 status.theme=CozyTheme.make()
 status.text="بنجهّز القعدة…\nGetting things ready…"
 status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 status.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 status.add_theme_font_size_override("font_size",24)
 status.add_theme_stylebox_override("normal",CozyTheme.box(Color("#f5e8ce"),Color.TRANSPARENT,0,20))
 parent.add_child(status)
 status.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 return status
