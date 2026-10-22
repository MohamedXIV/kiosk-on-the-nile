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
func configure(text: UiText, controller: BuildController, session: GameSession) -> void:
 _controller=controller
 _text=text
 theme=text.make_theme()
 layout_direction=Control.LAYOUT_DIRECTION_RTL
 anchor_left=1
 anchor_right=1
 anchor_top=1
 anchor_bottom=1
 offset_left=-355
 offset_right=-18
 offset_top=-330
 offset_bottom=-95
 var box := VBoxContainer.new()
 add_child(box)
 box.add_child(UiText.label(text.text("arrange_title")))
 box.add_child(_choices)
 _choices.item_selected.connect(func(index):_select(StringName(_choices.get_item_metadata(index))))
 var coordinates := HBoxContainer.new()
 box.add_child(coordinates)
 for pair in [["X",_x],["Y",_y]]:
  coordinates.add_child(UiText.label(pair[0]))
  var field: SpinBox=pair[1]
  field.min_value=-256
  field.max_value=256
  field.step=1
  field.custom_minimum_size.x=90
  coordinates.add_child(field)
  field.value_changed.connect(func(_value):if not _updating:_preview())
 box.add_child(_host)
 _host.item_selected.connect(func(_index):if not _updating:_preview())
 var actions := HBoxContainer.new()
 box.add_child(actions)
 actions.add_child(UiText.button(text.text("arrange_rotate"),rotate_selection))
 actions.add_child(UiText.button(text.text("arrange_confirm"),func():_controller.confirm()))
 actions.add_child(UiText.button(text.text("arrange_store"),func():_controller.store_selected();_refresh_choices()))
 _status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 box.add_child(_status)
 box.add_child(UiText.button(text.text("arrange_close"),func():_controller.cancel();hide();closed.emit()))
 _controller.changed.connect(_present_result)
 session.spaces.changed.connect(func(_id,_revision):_refresh_choices())
 hide()
func open() -> void:
 _refresh_choices()
 show()
func _refresh_choices() -> void:
 var selected := str(_controller.request.instance_id) if _controller.request!=null else ""
 _updating=true
 _choices.clear()
 _host.clear()
 _host.add_item(_text.text("arrange_floor"))
 _host.set_item_metadata(0,"")
 for item in _controller.choices():
  _choices.add_item(str(item.label)+("" if item.placed else " · "+_text.text("arrange_stored")))
  _choices.set_item_metadata(_choices.item_count-1,item.id)
  if item.id==selected:_choices.select(_choices.item_count-1)
  var definition := _controller_items_definition(item)
  if item.placed and definition.get("surface",false):
   _host.add_item(item.label+" · "+item.id)
   _host.set_item_metadata(_host.item_count-1,item.id)
 _updating=false
 if _choices.item_count>0: _select(StringName(_choices.get_item_metadata(_choices.selected)))
func _controller_items_definition(item: Dictionary) -> Dictionary:
 return _controller.definition(StringName(item.definition_id))
func _select(id: StringName) -> void:
 _controller.select(id)
 if _controller.request==null: return
 _updating=true
 _x.value=_controller.request.cell.x
 _y.value=_controller.request.cell.y
 _rotation=_controller.request.rotation
 for i in range(_host.item_count):
  if str(_host.get_item_metadata(i))==str(_controller.request.host_id):_host.select(i);break
 _updating=false
func move_cursor(cell: Vector2i) -> void:
 _updating=true
 _x.value=cell.x
 _y.value=cell.y
 _updating=false
 _preview()
func rotate_selection() -> void:
 _rotation=(_rotation+1)%4
 _preview()
func _preview() -> void:
 var host_id := StringName(str(_host.get_item_metadata(_host.selected))) if _host.item_count>0 else &""
 _controller.preview(Vector2i(int(_x.value),int(_y.value)),_rotation,host_id,&"top" if not host_id.is_empty() else &"")
func _present_result() -> void:
 _status.text=_text.text("arrange_help") if _controller.last_result.ok else _text.outcome(_controller.last_result)
