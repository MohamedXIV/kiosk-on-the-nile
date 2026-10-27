@tool
extends VBoxContainer
signal edit_requested(edit: Dictionary)
signal reload_requested
signal export_requested
var document: LayoutDocument
var _location := OptionButton.new()
var _kind := OptionButton.new()
var _identity := LineEdit.new()
var _x := SpinBox.new()
var _y := SpinBox.new()
var _length := SpinBox.new()
var _depth := SpinBox.new()
var _axis := OptionButton.new()
var _status := Label.new()
var _preview := Control.new()
var _building_json := TextEdit.new()
func _ready() -> void:
 custom_minimum_size.x=300
 var title := Label.new()
 title.text="Living Spaces — developer authoring"
 add_child(title)
 add_child(_location)
 _location.item_selected.connect(func(_i):_preview.queue_redraw())
 for entry in ["walls","doors","rooms","buildings"]: _kind.add_item(entry)
 add_child(_kind)
 _identity.placeholder_text="Stable structure ID"
 add_child(_identity)
 for pair in [["Cell X",_x],["Cell Y",_y],["Length / room width",_length],["Room depth",_depth]]:
  var row := HBoxContainer.new()
  var label := Label.new()
  label.text=pair[0]
  row.add_child(label)
  var field: SpinBox = pair[1]
  field.min_value=-256 if field in [_x,_y] else 1
  field.max_value=256
  field.step=1
  field.value=1 if field in [_length,_depth] else 0
  row.add_child(field)
  add_child(row)
 _axis.add_item("x")
 _axis.add_item("y")
 add_child(_axis)
 _building_json.placeholder_text='Building JSON: {"id":"home","room_ids":["home_room"],"roof":{"height":2.2,"color":"#756653"},"service_windows":[]}'
 _building_json.custom_minimum_size.y=80
 add_child(_building_json)
 for entry in [["Add / replace",_edit.bind(false)],["Remove selected ID",_edit.bind(true)],["Reload JSON",func():reload_requested.emit()],["Validate and export",func():export_requested.emit()]]:
  var button := Button.new()
  button.text=entry[0]
  button.pressed.connect(entry[1])
  add_child(button)
 _preview.custom_minimum_size=Vector2(280,220)
 _preview.draw.connect(_draw_preview)
 add_child(_preview)
 _status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(_status)
func refresh() -> void:
 var selected := _location.get_item_text(_location.selected) if _location.item_count>0 else ""
 _location.clear()
 if document!=null and not document.bundle.is_empty():
  for id in document.bundle.spaces.locations:
   _location.add_item(id)
   if id==selected: _location.select(_location.item_count-1)
 _preview.queue_redraw()
func show_result(result: ActionResult) -> void:
 _status.text="Saved / valid" if result.ok else str(result.message_key)+" "+str(result.details)
func _edit(remove: bool) -> void:
 if _location.item_count==0 or _identity.text.strip_edges().is_empty(): return
 var kind := _kind.get_item_text(_kind.selected)
 var value := {"id":_identity.text.strip_edges()}
 if kind=="buildings":
  if not remove:
   var parsed: Variant=JSON.parse_string(_building_json.text)
   if not parsed is Dictionary:_status.text="Invalid building JSON";return
   value=parsed
   value.id=_identity.text.strip_edges()
 elif kind=="rooms":
  var cells: Array = []
  for x in range(int(_x.value),int(_x.value+_length.value)):
   for y in range(int(_y.value),int(_y.value+_depth.value)): cells.append([x,y])
  value["cells"]=cells
 else:
  value.merge({"cell":[int(_x.value),int(_y.value)],"axis":_axis.get_item_text(_axis.selected),"length":int(_length.value)})
  if kind=="doors": value.merge({"open":true,"usable":true})
 edit_requested.emit({"location_id":_location.get_item_text(_location.selected),"kind":kind,"value":value,"remove":remove})
func _draw_preview() -> void:
 if document==null or document.bundle.is_empty() or _location.item_count==0: return
 var space: Dictionary = document.bundle.spaces.locations[_location.get_item_text(_location.selected)]
 var center := _preview.size/2
 var scale := 8.0
 for x in range(-16,17): _preview.draw_line(center+Vector2(x*scale,-104),center+Vector2(x*scale,104),Color(0.4,0.4,0.4,0.4))
 for y in range(-13,14): _preview.draw_line(center+Vector2(-128,y*scale),center+Vector2(128,y*scale),Color(0.4,0.4,0.4,0.4))
 for kind in ["walls","doors"]:
  for edge in space[kind]:
   var start := center+Vector2(edge.cell[0],edge.cell[1])*scale
   var end := start+(Vector2(edge.length,0) if edge.axis=="x" else Vector2(0,edge.length))*scale
   _preview.draw_line(start,end,Color.ORANGE if kind=="doors" else Color.LIGHT_GRAY,4)
 for record in document.bundle.initial_layout.placements.values():
  if record.location_id!=_location.get_item_text(_location.selected) or record.host_id!="": continue
  var instance: Dictionary = {}
  for item in document.bundle.initial_layout.instances:
   if item.id==record.instance_id: instance=item;break
  var footprint: Array = document.bundle.items[instance.definition_id].footprint
  var dimensions := Vector2(footprint[0],footprint[1])
  if int(record.rotation)%2==1: dimensions=Vector2(dimensions.y,dimensions.x)
  _preview.draw_rect(Rect2(center+Vector2(record.cell[0],record.cell[1])*scale,dimensions*scale),Color(0.3,0.7,0.6,0.6))
