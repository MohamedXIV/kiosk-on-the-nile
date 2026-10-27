class_name TitleScreen
extends Control
signal new_requested
signal continue_requested
func configure(text: UiText, can_continue: bool) -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 theme = text.make_theme()
 var background := ColorRect.new()
 background.color = Color("#12171b")
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(background)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(center)
 var panel := PanelContainer.new()
 center.add_child(panel)
 var box := VBoxContainer.new()
 box.custom_minimum_size.x = 580
 box.add_theme_constant_override("separation",18)
 panel.add_child(box)
 var heading := text.key_label("title")
 heading.add_theme_font_size_override("font_size",42)
 heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 box.add_child(heading)
 var subtitle := text.key_label("subtitle")
 subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 box.add_child(subtitle)
 box.add_child(text.key_button("new_game",func():new_requested.emit()))
 var continue_button := text.key_button("continue",func():continue_requested.emit())
 continue_button.disabled = not can_continue
 box.add_child(continue_button)

 box.add_child(LocaleService.current.picker())
