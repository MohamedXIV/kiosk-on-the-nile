class_name TitleScreen
extends Control
signal new_requested
signal continue_requested
var _feedback := SheetControls.label()
var _error: ActionResult
var _text: UiText
func configure(text: UiText, can_continue: bool) -> void:
 _text=text
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 theme=text.make_theme()
 var background := ColorRect.new()
 background.color=Color("#e4ebdf")
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(background)
 var river := Control.new()
 river.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 river.mouse_filter=Control.MOUSE_FILTER_IGNORE
 river.draw.connect(func():
  var w := river.size.x;var h := river.size.y
  river.draw_rect(Rect2(0,h*0.73,w,h*0.27),Color("#d2dfd1"))
  for index in range(5):
   var y := h*0.78+index*22
   river.draw_line(Vector2(w*0.1,y),Vector2(w*0.9,y),Color(0.4,0.55,0.45,0.12),1,true))
 river.resized.connect(river.queue_redraw)
 add_child(river)
 var panel := PanelContainer.new();add_child(panel)
 SheetControls.shell(panel,640,76,56)
 var content := VBoxContainer.new()
 var scroll := SheetControls.scroll(content);panel.add_child(scroll)
 content.alignment=BoxContainer.ALIGNMENT_CENTER
 content.add_theme_constant_override("separation",20)
 var eyebrow := SheetControls.label(UiText.localized("cozy.title_eyebrow",{},"A little life by the river"))
 UiText.bind_control(eyebrow,"cozy.title_eyebrow");SheetControls.muted(eyebrow);content.add_child(eyebrow)
 var heading := text.key_label("title");heading.add_theme_font_size_override("font_size",42)
 heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;content.add_child(heading)
 var subtitle := text.key_label("subtitle");subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 content.add_child(subtitle)
 var separator := HSeparator.new();content.add_child(separator)
 var continue_button := text.key_button("continue",func():continue_requested.emit())
 continue_button.disabled=not can_continue
 var new_button := text.key_button("new_game",func():new_requested.emit())
 if can_continue:SheetControls.primary(continue_button);content.add_child(continue_button);content.add_child(new_button)
 else:SheetControls.primary(new_button);content.add_child(new_button);content.add_child(continue_button)
 var settings := HBoxContainer.new();content.add_child(settings)
 var language := SheetControls.label(UiText.localized("cozy.language",{},"Language"));UiText.bind_control(language,"cozy.language");SheetControls.muted(language)
 settings.add_child(language)
 var picker := LocaleService.current.picker();picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL;settings.add_child(picker)
 var hint := SheetControls.label(UiText.localized("cozy.title_hint",{},"Take your time. The corniche has room for a quiet day."))
 UiText.bind_control(hint,"cozy.title_hint");SheetControls.muted(hint);content.add_child(hint)
 _feedback.add_theme_color_override("font_color",Color("#864b3f"));content.add_child(_feedback);_feedback.hide()
 LocaleService.current.changed.connect(_update_error)
 (continue_button if can_continue else new_button).call_deferred("grab_focus")

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
 status.add_theme_stylebox_override("normal",CozyTheme.box(Color("#e4ebdf"),Color.TRANSPARENT,0,20))
 status.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 parent.add_child(status)
 return status
