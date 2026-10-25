class_name SheetControls
extends RefCounted
## Small native control builders shared by inventory and preparation sheets.
static func label(value: String = "") -> Label:
 var control := UiText.label(value)
 control.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
 control.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 return control
static func button(value: String, action: Callable) -> Button:
 var control := UiText.button(value,action)
 control.focus_mode=Control.FOCUS_ALL
 control.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 return control
static func clear(parent: Control) -> void:
 for child in parent.get_children():parent.remove_child(child);child.queue_free()
static func card(parent: VBoxContainer) -> VBoxContainer:
 var panel := PanelContainer.new();parent.add_child(panel)
 var column := VBoxContainer.new();column.add_theme_constant_override("separation",8);panel.add_child(column)
 return column
static func scroll(column: VBoxContainer) -> ScrollContainer:
 var control := ScrollContainer.new()
 control.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 column.add_theme_constant_override("separation",12)
 control.add_child(column)
 return control
static func header(parent: VBoxContainer, heading: Label, text: UiText, close: Callable) -> void:
 var row := HBoxContainer.new();parent.add_child(row)
 heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 row.add_child(heading)
 var close_button := text.key_button("close",close)
 close_button.focus_mode=Control.FOCUS_ALL
 row.add_child(close_button)
