class_name InventoryPanel
extends PanelContainer
var _session: GameSession
var _text: UiText
var _rows := VBoxContainer.new()
var _heading := SheetControls.label()
var _hint := SheetControls.label()
var _held := SheetControls.label()
var _search := LineEdit.new()
var _filter := OptionButton.new()
var _scroll: ScrollContainer
var _feedback := SheetControls.label()
var _last_result: ActionResult
var _dirty: bool=true
var _changing: bool=false
var _reset_scroll: bool=false
var _location: String=""
const KINDS := ["","purchase_bag","dry","cold","storage"]
func configure(text: UiText, session: GameSession) -> void:
 _session=session;_text=text;theme=text.make_theme()
 anchor_left=0.08;anchor_right=0.92;anchor_top=0.16;anchor_bottom=0.96
 var column := VBoxContainer.new();column.add_theme_constant_override("separation",10);add_child(column)
 SheetControls.header(column,_heading,text,hide)
 column.add_child(_hint);column.add_child(_held)
 var controls := HBoxContainer.new();controls.add_theme_constant_override("separation",8);column.add_child(controls)
 _search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_search.clear_button_enabled=true;controls.add_child(_search)
 _search.text_changed.connect(func(_value):_dirty=true;_reset_scroll=true)
 _filter.custom_minimum_size.x=220;_filter.fit_to_longest_item=false;_filter.clip_text=true;controls.add_child(_filter)
 _filter.item_selected.connect(func(_index):if not _changing:_dirty=true;_reset_scroll=true)
 _scroll=SheetControls.scroll(_rows);_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(_scroll)
 column.add_child(_feedback)
 session.items.changed.connect(func(_revision):_dirty=true)
 LocaleService.current.changed.connect(_refresh_language)
 _refresh_language()
 hide()
func _kind_label(kind: String) -> String:
 if kind=="":return ItemText.t("all_storage")
 if kind=="storage":return ItemText.t("furniture")
 return _text.text("inventory_bag" if kind=="purchase_bag" else "inventory_cold" if kind=="cold" else "inventory_furniture" if kind=="storage" else "inventory_dry")
func _refresh_language() -> void:
 _heading.text=_text.text("inventory_title");_hint.text=ItemText.t("inventory_hint")
 _search.placeholder_text=ItemText.t("inventory_search")
 var kind := str(_filter.get_selected_metadata()) if _filter.selected>=0 else ""
 _changing=true;_filter.clear()
 for value in KINDS:
  _filter.add_item(_kind_label(value));_filter.set_item_metadata(_filter.item_count-1,value)
  if kind==value:_filter.select(_filter.item_count-1)
 _changing=false;_dirty=true
func open() -> void:
 _render();show()
func refresh() -> void:_dirty=true
func _process(_delta: float) -> void:
 if not visible:return
 if _location!=str(_session.location_id):_dirty=true
 if _dirty:_render()
func _render() -> void:
 _dirty=false;_location=str(_session.location_id)
 var scroll := 0.0 if _reset_scroll else _scroll.get_v_scroll_bar().value
 _reset_scroll=false
 SheetControls.clear(_rows)
 var state := _session.items.storage_view()
 var held := _session.items.get_item(_session.inventory.held_id())
 _held.text=ItemText.t("held",{"item":ItemText.instance(_session,held)}) if not held.is_empty() else ItemText.t("hands_empty")
 var reserved: Dictionary={}
 for lines in state.reservations.values():
  for line in lines:reserved[line.item_id]=int(reserved.get(line.item_id,0))+int(line.quantity)
 var containers: Array=[];var totals: Dictionary={}
 for container in state.containers.values():
  if container.location_id!=_location and container.kind!="purchase_bag":continue
  if not container.kind in KINDS:continue
  containers.append(container);totals[container.kind]=int(totals.get(container.kind,0))+1
 containers.sort_custom(func(a,b):return str(a.id)<str(b.id))
 var ordinals: Dictionary={};var shown := 0
 var selected := str(_filter.get_selected_metadata()) if _filter.selected>=0 else ""
 var query := _search.text.strip_edges().to_lower()
 for container in containers:
  ordinals[container.kind]=int(ordinals.get(container.kind,0))+1
  if selected!="" and selected!=container.kind:continue
  var entries: Array[Dictionary]=[];var used := 0
  for item in state.items.values():
   if item.container_id!=container.id:continue
   used+=int(item.quantity)
   if query=="" or query in ItemText.search_names(_session,item):entries.append(item)
  entries.sort_custom(func(a,b):return str(a.id)<str(b.id))
  if entries.is_empty() and query!="":continue
  var card := SheetControls.card(_rows);shown+=1
  var title := _kind_label(str(container.kind))
  if int(totals[container.kind])>1:title+=" · "+str(ordinals[container.kind])
  card.add_child(SheetControls.label(ItemText.t("capacity",{"name":title,"used":used,"capacity":int(container.capacity)})))
  if container.kind=="storage" and not entries.is_empty():card.add_child(SheetControls.label(_text.text("inventory_furniture")))
  var container_id := StringName(str(container.id))
  if container.kind=="cold" and held.get("kind")=="batch":card.add_child(SheetControls.button(_text.text("recipe_store_bowl"),func():_apply(_session.inventory.store_held(container_id))))
  if container.kind=="purchase_bag" and used>0:card.add_child(SheetControls.button(_text.text("inventory_unpack"),func():_apply(_session.inventory.unpack_purchase_bag(container_id,_session.location_id))))
  if entries.is_empty():card.add_child(SheetControls.label(ItemText.t("empty_container")))
  for item in entries:
   var row := HBoxContainer.new();row.add_theme_constant_override("separation",8);card.add_child(row)
   var detail := VBoxContainer.new();detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(detail)
   var item_label := SheetControls.label(ItemText.t("quantity",{"name":ItemText.instance(_session,item),"quantity":int(item.quantity)}))
   item_label.custom_minimum_size.y=float(_text.data.theme.font_size)*1.4
   detail.add_child(item_label)
   var description := ItemText.item_details(_session,item)
   if description!="":detail.add_child(SheetControls.label(description))
   var count := int(reserved.get(item.id,0))
   if count>0:detail.add_child(SheetControls.label(ItemText.t("reserved",{"count":count})))
   var item_id := StringName(str(item.id))
   if item.kind=="batch":
    var take := SheetControls.button(_text.text("recipe_take_bowl"),func():_apply(_session.inventory.pick_up_storage(item_id)))
    take.custom_minimum_size.x=200
    take.disabled=not held.is_empty();row.add_child(take)
   elif container.kind!="purchase_bag":
    var pack := SheetControls.button(_text.text("inventory_pack"),func():_apply(_session.inventory.pack(item_id)))
    pack.custom_minimum_size.x=200
    pack.disabled=count>0;row.add_child(pack)
 if shown==0:_rows.add_child(SheetControls.label(ItemText.t("no_items")))
 if _last_result:
  _feedback.text=_text.text("inventory_partial") if _last_result.ok and not _last_result.details.get("remaining",[]).is_empty() else ItemText.missing(_session,_text,_last_result)
 _feedback.visible=not _feedback.text.is_empty()
 _scroll.get_v_scroll_bar().set_deferred("value",scroll)
func _apply(result: ActionResult) -> void:
 _last_result=result;_dirty=true
