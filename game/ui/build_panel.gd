class_name BuildPanel
extends PanelContainer
signal closed
var _controller: BuildController
var _text: UiText
var _choices := OptionButton.new()
var _status := Label.new()
var _x := SpinBox.new()
var _y := SpinBox.new()
var _host := OptionButton.new()
var _rotation: int = 0
var _updating: bool = false
var _piece_art: ItemGlyph
var _tools_scroll: ScrollContainer
var _actions: HBoxContainer
var _rotate: Button
var _confirm: Button
var _store: Button
const DOCK_WIDTH := 840.0
const DOCK_HEIGHT := 268.0
const DOCK_EDGE := 12.0
const FIELD_HEIGHT := 44.0
func configure(text: UiText, controller: BuildController, session: GameSession) -> void:
 _controller=controller
 _text=text
 theme=text.make_theme()
 layout_direction=Control.LAYOUT_DIRECTION_INHERITED
 # Arrangement remains a dock: the uncovered world still receives placement clicks.
 theme_type_variation=&"ArrangementDock"
 get_viewport().size_changed.connect(_fit_dock)
 _fit_dock()
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",6)
 add_child(box)
 SheetControls.header(box,text.key_label("arrange_title"),text,func():_controller.cancel();hide();closed.emit(),"actions","SectionNile")
 # Only the selection/placement tools scroll. Close and action buttons stay visible.
 var body := VBoxContainer.new()
 body.add_theme_constant_override("separation",6)
 _tools_scroll=SheetControls.scroll(body)
 _tools_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 _tools_scroll.custom_minimum_size.y=72
 box.add_child(_tools_scroll)
 var tools := SheetControls.columns(body,600)
 tools.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
 tools.add_theme_constant_override("separation",8)
 var piece := VBoxContainer.new()
 piece.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 piece.add_theme_constant_override("separation",4)
 tools.add_child(piece)
 var selection := HBoxContainer.new()
 selection.add_theme_constant_override("separation",6)
 piece.add_child(selection)
 _piece_art=ItemGlyph.new()
 _piece_art.custom_minimum_size=Vector2(52,52)
 _piece_art.hide()
 selection.add_child(_piece_art)
 _choices.fit_to_longest_item=false
 _choices.clip_text=true
 _choices.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _choices.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 _choices.custom_minimum_size.y=FIELD_HEIGHT
 selection.add_child(_choices)
 _choices.item_selected.connect(func(index):_select(StringName(_choices.get_item_metadata(index))))
 var placement := VBoxContainer.new()
 placement.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 placement.add_theme_constant_override("separation",4)
 tools.add_child(placement)
 var coordinates := HFlowContainer.new()
 coordinates.layout_direction=Control.LAYOUT_DIRECTION_LTR
 coordinates.add_theme_constant_override("h_separation",6)
 placement.add_child(coordinates)
 for pair in [["X",_x],["Y",_y]]:
  var coordinate := HBoxContainer.new()
  coordinate.add_theme_constant_override("separation",4)
  coordinates.add_child(coordinate)
  var axis := UiText.label(pair[0])
  axis.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  coordinate.add_child(axis)
  var field: SpinBox=pair[1]
  field.min_value=-256
  field.max_value=256
  field.step=1
  field.custom_minimum_size=Vector2(92,FIELD_HEIGHT)
  field.get_line_edit().text_direction=Control.TEXT_DIRECTION_LTR
  field.get_line_edit().alignment=HORIZONTAL_ALIGNMENT_CENTER
  coordinate.add_child(field)
  field.value_changed.connect(func(_value):if not _updating:_preview())
 _host.fit_to_longest_item=false
 _host.clip_text=true
 _host.custom_minimum_size.y=FIELD_HEIGHT
 _host.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
 placement.add_child(_host)
 _host.item_selected.connect(_select_host)
 _status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 _status.theme_type_variation="Muted"
 body.add_child(_status)
 _actions=HBoxContainer.new()
 _actions.add_theme_constant_override("separation",6)
 box.add_child(_actions)
 _rotate=SheetControls.key_button(text,"arrange_rotate",rotate_selection)
 _confirm=SheetControls.key_button(text,"arrange_confirm",func():_controller.confirm())
 SheetControls.primary(_confirm)
 _store=SheetControls.key_button(text,"arrange_store",func():_controller.store_selected();_refresh_choices())
 for button in [_rotate,_confirm,_store]:
  button.custom_minimum_size=Vector2(88,44)
  button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  _actions.add_child(button)
 LocaleService.current.changed.connect(func():
  _refresh_choices(true)
  _present_result())
 _controller.changed.connect(_present_result)
 session.spaces.changed.connect(func(_id,_revision):_refresh_choices())
 hide()
func open() -> void:
 _refresh_choices()
 _present_result()
 show()
func _refresh_choices(preserve_preview: bool = false) -> void:
 var selected := str(_controller.request.instance_id) if _controller.request!=null else ""
 _updating=true
 _choices.clear()
 _host.clear()
 _host.add_item(_text.text("arrange_floor"))
 _host.set_item_metadata(0,"")
 for item in _controller.choices():
  _choices.add_item(ItemText.source("item."+str(item.definition_id),str(item.label))+("" if item.placed else " · "+_text.text("arrange_stored")))
  _choices.set_item_metadata(_choices.item_count-1,item.id)
  if item.id==selected:_choices.select(_choices.item_count-1)
  var definition := _controller_items_definition(item)
  if item.placed and definition.get("surface",false):
   _host.add_item(ItemText.source("item."+str(item.definition_id),str(item.label))+" · "+item.id)
   _host.set_item_metadata(_host.item_count-1,item.id)
 _updating=false
 if selected!="" and _choices.item_count>0 and not preserve_preview:_select(StringName(selected))
 elif selected!="" and preserve_preview:
  for index in range(_host.item_count):
   if str(_host.get_item_metadata(index))==str(_controller.request.host_id):_host.select(index);break
 else:
  _choices.select(-1)
  _choices.text=_text.text("arrange_select_piece")
  _piece_art.hide()
 _update_enabled()
func _controller_items_definition(item: Dictionary) -> Dictionary:
 return _controller.definition(StringName(item.definition_id))
func _select(id: StringName) -> void:
 _controller.select(id)
 if _controller.request==null:
  _update_enabled()
  return
 var definition_id := _controller_items_definition_for_request()
 _piece_art.configure(_controller.definition(StringName(definition_id)),definition_id)
 _piece_art.show()
 _updating=true
 _x.value=_controller.request.cell.x
 _y.value=_controller.request.cell.y
 _rotation=_controller.request.rotation
 for i in range(_host.item_count):
  if str(_host.get_item_metadata(i))==str(_controller.request.host_id):_host.select(i);break
 _updating=false
 _update_enabled()
func move_cursor(cell: Vector2i) -> void:
 _updating=true
 _x.value=cell.x
 _y.value=cell.y
 _updating=false
 _preview()
func rotate_selection() -> void:
 if _controller.request==null:return
 _rotation=(_rotation+1)%4
 _preview()
func _preview() -> void:
 if _controller.request==null:return
 var host_id := StringName(str(_host.get_item_metadata(_host.selected))) if _host.item_count>0 else &""
 _controller.preview(Vector2i(int(_x.value),int(_y.value)),_rotation,host_id,&"top" if not host_id.is_empty() else &"")
func _update_enabled() -> void:
 if not is_instance_valid(_confirm):return
 var selected := _controller.request!=null
 _rotate.disabled=not selected
 _confirm.disabled=not selected
 _store.disabled=not selected
 _x.editable=selected
 _y.editable=selected
 _host.disabled=not selected
func _present_result() -> void:
 _update_enabled()
 _status.text=_text.text("arrange_help") if _controller.last_result.ok else _text.outcome(_controller.last_result)
 if _controller.request!=null:
  var policy: Dictionary=_controller.definition(StringName(_controller_items_definition_for_request())).get("placement",{})
  var key := "arrange_inside" if policy.get("environment")=="interior" else "arrange_outside" if policy.get("environment")=="exterior" else "arrange_either"
  _status.text+="\n"+_text.text(key)

func _controller_items_definition_for_request() -> String:
 for item in _controller.choices():
  if item.id==str(_controller.request.instance_id):return str(item.definition_id)
 return ""
func ground_clicked(point: Vector2, height_ratio: float = 0.0) -> void:
 var hit := _controller.instance_at(point,height_ratio)
 if not hit.is_empty():
  var hit_definition: Dictionary={}
  for item in _controller.choices():
   if item.id==str(hit):hit_definition=_controller.definition(StringName(item.definition_id));break
  if _controller.request!=null and hit_definition.get("surface",false) and _controller.definition(StringName(_controller_items_definition_for_request())).get("mountable",false):
   for index in range(_host.item_count):
    if str(_host.get_item_metadata(index))==str(hit):_host.select(index);_select_host(index);return
  _select(hit)
  for index in range(_choices.item_count):
   if str(_choices.get_item_metadata(index))==str(hit):_choices.select(index);break
  return
 if _controller.request==null:
  _status.text=_text.text("arrange_select_piece")
  return
 _host.select(0)
 move_cursor(Vector2i(floori(point.x/0.25),floori(point.y/0.25)))

func _select_host(index: int) -> void:
 if _updating:return
 var id := StringName(str(_host.get_item_metadata(index)))
 var host := _controller.host_placement(id)
 if not host.is_empty():
  _updating=true
  _x.value=int(host.cell[0])
  _y.value=int(host.cell[1])
  _rotation=int(host.rotation)
  _updating=false
 _preview()

func _fit_dock() -> void:
 var viewport := get_viewport_rect().size
 var compact := CozyTheme.compact_for(viewport)
 theme=CozyTheme.for_viewport(viewport)
 var width := minf(DOCK_WIDTH,maxf(160,viewport.x-(16 if compact else 80)))
 var height := minf(DOCK_HEIGHT,viewport.y*(0.46 if compact else 0.44))
 if CozyTheme.short_landscape_for(viewport):height=maxf(212.0,height)
 set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 position=Vector2((viewport.x-width)*0.5,viewport.y-height-DOCK_EDGE)
 size=Vector2(width,height)
