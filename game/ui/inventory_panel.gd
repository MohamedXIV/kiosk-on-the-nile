class_name InventoryPanel
extends PanelContainer
var _session: GameSession
var _text: UiText
var _rows := VBoxContainer.new()
var _feedback := Label.new()
func configure(text: UiText, session: GameSession) -> void:
 _session=session
 _text=text
 theme=text.make_theme()
 anchor_left=0.2
 anchor_right=0.8
 anchor_top=0.2
 anchor_bottom=0.85
 var column := VBoxContainer.new()
 add_child(column)
 column.add_child(UiText.label(text.text("inventory_title")))
 var scroll := ScrollContainer.new()
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.custom_minimum_size.y=180
 column.add_child(scroll)
 _rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(_rows)
 _feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 column.add_child(_feedback)
 column.add_child(UiText.button(text.text("close"),hide))
 hide()
func open() -> void:
 refresh()
 show()
func refresh() -> void:
 for row in _rows.get_children():_rows.remove_child(row);row.queue_free()
 var state := _session.items.snapshot()
 for container in state.containers.values():
  if container.location_id!=str(_session.location_id) and container.kind!="purchase_bag":continue
  if not container.kind in ["dry","cold","purchase_bag","storage"]:continue
  var entries := _session.items.items_in(StringName(container.id))
  var count := 0
  for item in entries:count+=int(item.quantity)
  var title := _text.text("inventory_bag") if container.kind=="purchase_bag" else _text.text("inventory_cold") if container.kind=="cold" else _text.text("inventory_furniture") if container.kind=="storage" else _text.text("inventory_dry")
  _rows.add_child(UiText.label(title+" · %d/%d" % [count,int(container.capacity)]))
  if container.kind=="cold" and _session.items.get_item(_session.inventory.held_id()).get("kind")=="batch":
   var storage_id := StringName(container.id)
   _rows.add_child(UiText.button(_text.text("recipe_store_bowl"),func():_apply(_session.inventory.store_held(storage_id))))
  if container.kind=="purchase_bag":
   var id := StringName(container.id)
   _rows.add_child(UiText.button(_text.text("inventory_unpack"),func():_apply(_session.inventory.unpack_purchase_bag(id,_session.location_id))))
  for item in entries:
   var row := HBoxContainer.new()
   var label := UiText.label(str(_session.items.definition(StringName(item.definition_id)).label)+" × "+str(item.quantity))
   label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   row.add_child(label)
   if item.kind=="batch":
    var batch_id := StringName(item.id)
    row.add_child(UiText.button(_text.text("recipe_take_bowl"),func():_apply(_session.inventory.pick_up_storage(batch_id))))
   elif container.kind!="purchase_bag":
    var item_id := StringName(item.id)
    row.add_child(UiText.button(_text.text("inventory_pack"),func():_apply(_session.inventory.pack(item_id))))
   _rows.add_child(row)
func _apply(result: ActionResult) -> void:
 _feedback.text=_text.text("inventory_partial") if result.ok and not result.details.get("remaining",[]).is_empty() else _text.outcome(result)
 refresh()
