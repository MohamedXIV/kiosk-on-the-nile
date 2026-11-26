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
 control.follow_focus=true
 control.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 column.add_theme_constant_override("separation",12)
 control.add_child(column)
 return control
static func banner(parent: VBoxContainer, icon_key: String, kind: String) -> HBoxContainer:
 var panel := PanelContainer.new()
 panel.theme_type_variation=kind
 parent.add_child(panel)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",10)
 panel.add_child(row)
 var art := TextureRect.new()
 art.texture=CozyTheme.icon_texture(icon_key)
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 art.custom_minimum_size=Vector2(32,32)
 art.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 row.add_child(art)
 return row
static func header(parent: VBoxContainer, heading: Label, text: UiText, close: Callable, icon_key: String="", banner_kind: String="") -> void:
 var row: HBoxContainer
 if not banner_kind.is_empty() and not icon_key.is_empty():
  row=banner(parent,icon_key,banner_kind)
 else:
  row=HBoxContainer.new();parent.add_child(row)
 title(heading)
 if not banner_kind.is_empty():heading.add_theme_color_override("font_color",CozyTheme.IVORY)
 heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 row.add_child(heading)
 var close_button := text.key_button("close",close)
 close_button.custom_minimum_size.x=96
 close_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
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
 if panel.get_meta("gameplay_overlay",false):
  panel.theme=CozyTheme.make_compact()
  var envelope := gameplay_rect(extent)
  panel.position=envelope.position
  panel.size=envelope.size
  return
 var compact := CozyTheme.compact_for(extent)
 var desired_theme := CozyTheme.for_viewport(extent)
 if panel.theme!=desired_theme:panel.theme=desired_theme
 var margin := 8.0 if compact else 16.0
 var available := minf(width,extent.x-margin*2)
 var inset := minf(top,CozyTheme.COMPACT_HUD_CLEARANCE) if compact else minf(top,extent.y*0.22)
 var lower_margin := minf(bottom,10.0) if compact else bottom
 panel.position=Vector2((extent.x-available)*0.5,inset)
 panel.size=Vector2(available,maxf(120,extent.y-inset-lower_margin))
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

# Both core interactions use this area budget, including their frame and header.
# Leave a small rounding/layout allowance; 25% is the acceptance ceiling.
const GAMEPLAY_AREA_LIMIT := 0.25
const GAMEPLAY_AREA_TARGET := 0.24
const GAMEPLAY_EDGE := 8.0
const GAMEPLAY_MAX_WIDTH := 760.0
const GAMEPLAY_MAX_HEIGHT := 220.0
static func gameplay_rect(extent: Vector2, top_clearance: float=0.0) -> Rect2:
 var width_ratio := 0.54 if CozyTheme.short_landscape_for(extent) else 0.70 if CozyTheme.compact_for(extent) else 0.80
 var width := floorf(maxf(1.0,minf(GAMEPLAY_MAX_WIDTH,minf(extent.x-GAMEPLAY_EDGE*2,extent.x*width_ratio))))
 var available_height := maxf(1.0,extent.y-top_clearance-GAMEPLAY_EDGE)
 var height := floorf(minf(GAMEPLAY_MAX_HEIGHT,minf(available_height,extent.x*extent.y*GAMEPLAY_AREA_TARGET/width)))
 return Rect2(Vector2(floorf((extent.x-width)*0.5),extent.y-height-GAMEPLAY_EDGE),Vector2(width,height))
static func gameplay_area_ratio(rect: Rect2, extent: Vector2) -> float:
 return rect.size.x*rect.size.y/maxf(1.0,extent.x*extent.y)
