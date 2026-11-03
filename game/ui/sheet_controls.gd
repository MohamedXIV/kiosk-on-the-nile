class_name SheetControls
extends RefCounted
## Native presentation builders. Services remain the only owners of gameplay state.
static func label(value: String = "") -> Label:
 var control := UiText.label(value)
 control.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 return control
static func button(value: String, action: Callable) -> Button:
 var control := UiText.button(value,action)
 control.focus_mode=Control.FOCUS_ALL
 control.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 control.custom_minimum_size.x=120
 control.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
 return control
static func clear(parent: Control) -> void:
 for child in parent.get_children():parent.remove_child(child);child.queue_free()
static func card(parent: VBoxContainer) -> VBoxContainer:
 var panel := PanelContainer.new();panel.theme_type_variation="Card";parent.add_child(panel)
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
 title(heading)
 heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 row.add_child(heading)
 var close_button := text.key_button("close",close)
 close_button.custom_minimum_size.x=96
 close_button.theme_type_variation="QuietButton"
 close_button.focus_mode=Control.FOCUS_ALL
 row.add_child(close_button)
static func key_button(text: UiText, key: String, action: Callable) -> Button:
 var control := text.key_button(key,action)
 control.focus_mode=Control.FOCUS_ALL
 control.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 return control

static func title(control: Label) -> void:
 control.theme_type_variation="Heading"
 control.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
static func muted(control: Label) -> void:
 control.theme_type_variation="Muted"
static func primary(control: Button) -> void:
 control.theme_type_variation="PrimaryButton"
static func shell(panel: Control, width: float=1100, top: float=122, bottom: float=18) -> void:
 panel.theme_type_variation="Sheet"
 panel.set_meta("sheet_width",width)
 panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 var reference: WeakRef=weakref(panel)
 var queue_fit := func():_queue_sheet_fit(reference,width,top,bottom)
 panel.get_viewport().size_changed.connect(queue_fit)
 panel.minimum_size_changed.connect(queue_fit)
 panel.visibility_changed.connect(queue_fit)
 queue_fit.call()
static func _queue_sheet_fit(reference: WeakRef, width: float, top: float, bottom: float) -> void:
 var panel: Control=reference.get_ref()
 if not is_instance_valid(panel) or not panel.is_inside_tree() or panel.get_meta("sheet_fit_pending",false):return
 panel.set_meta("sheet_fit_pending",true)
 _fit_sheet.call_deferred(reference,width,top,bottom)
static func _fit_sheet(reference: WeakRef, width: float, top: float, bottom: float) -> void:
 var panel: Control=reference.get_ref()
 if not is_instance_valid(panel) or not panel.is_inside_tree():return
 panel.set_meta("sheet_fit_pending",false)
 var extent := panel.get_viewport_rect().size
 var margin := 16.0 if extent.x>=700 else 8.0
 var available := minf(width,extent.x-margin*2)
 var inset := minf(top,extent.y*0.22)
 panel.position=Vector2((extent.x-available)*0.5,inset)
 panel.size=Vector2(available,maxf(120,extent.y-inset-bottom))
static func columns(parent: Control, collapse_width: float=760) -> BoxContainer:
 var row := BoxContainer.new()
 row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 row.size_flags_vertical=Control.SIZE_EXPAND_FILL
 parent.add_child(row)
 row.resized.connect(func():row.vertical=row.size.x<collapse_width)
 return row
static func focus_first(root: Control) -> void:
 if not root.is_visible_in_tree():return
 for child in root.get_children():
  if child is Control and child.is_visible_in_tree():
   if child.focus_mode==Control.FOCUS_ALL and not child is ScrollContainer and not (child is BaseButton and child.disabled):
    child.grab_focus();return
   focus_first(child)
   var owner := root.get_viewport().gui_get_focus_owner()
   if owner!=null and root.is_ancestor_of(owner):return
