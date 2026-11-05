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
var _age_labels: Array[Dictionary]=[]
var _age_elapsed: float=0
const KINDS := ["","purchase_bag","dry","cold","storage"]
func configure(text: UiText, session: GameSession) -> void:
 _session=session;_text=text;theme=text.make_theme()
 SheetControls.shell(self)
 var column := VBoxContainer.new();column.add_theme_constant_override("separation",10);add_child(column)
 SheetControls.header(column,_heading,text,hide)
 SheetControls.muted(_hint);column.add_child(_hint)
 var hands := PanelContainer.new();hands.theme_type_variation="Inset";column.add_child(hands);hands.add_child(_held)
 var controls := SheetControls.columns(column,640);controls.add_theme_constant_override("separation",8)
 _search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_search.clear_button_enabled=true;controls.add_child(_search)
 _search.text_changed.connect(func(_value):_dirty=true;_reset_scroll=true)
 _filter.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_filter.fit_to_longest_item=false;_filter.clip_text=true;controls.add_child(_filter)
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
func _process(delta: float) -> void:
 if not visible:return
 if _location!=str(_session.location_id):_dirty=true
 if _dirty:_render()
 _age_elapsed+=delta
 if _age_elapsed>=0.5:
  _age_elapsed=0
  for entry in _age_labels:
   if is_instance_valid(entry.label):entry.label.text=ItemText.item_details(_session,entry.item)
func _render() -> void:
 _dirty=false;_location=str(_session.location_id)
 var focus_key := _focused_key()
 var scroll := 0.0 if _reset_scroll else _scroll.get_v_scroll_bar().value
 _reset_scroll=false
 _age_labels.clear()
 SheetControls.clear(_rows)
 var state := _session.items.storage_view()
 var held := _session.items.get_item(_session.inventory.held_id())
 _held.text=ItemText.t("held",{"item":ItemText.instance(_session,held)}) if not held.is_empty() else ItemText.t("hands_empty")
 if not held.is_empty():
  var held_card := SheetControls.card(_rows)
  var detail := SheetControls.label(ItemText.item_details(_session,held));held_card.add_child(detail)
  if held.attributes.has("freshness"):_age_labels.append({"label":detail,"item":held})
  if held.attributes.has("freshness") and held.get("kind") in ["prepared","ingredient"]:
   var discard := _action(UiText.localized("ui.discard_held",{},"Discard held food"),"discard",func():_apply(_session.inventory.discard_held()))
   discard.theme_type_variation="DangerButton";held_card.add_child(discard)
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
  var container_title := SheetControls.label(ItemText.t("capacity",{"name":title,"used":used,"capacity":int(container.capacity)}));SheetControls.title(container_title);card.add_child(container_title)
  if container.kind=="storage" and not entries.is_empty():card.add_child(SheetControls.label(_text.text("inventory_furniture")))
  var container_id := StringName(str(container.id))
  if container.kind=="cold" and held.get("kind") in ["batch","prepared"]:
   var store := _action(_text.text("recipe_store_bowl"),"store:"+str(container_id),func():_apply(_session.inventory.store_held(container_id)))
   SheetControls.primary(store);card.add_child(store)
  if container.kind=="purchase_bag" and used>0:
   var unpack := _action(_text.text("inventory_unpack"),"unpack:"+str(container_id),func():_apply(_session.inventory.unpack_purchase_bag(container_id,_session.location_id)))
   SheetControls.primary(unpack);card.add_child(unpack)
  if entries.is_empty():card.add_child(SheetControls.label(ItemText.t("empty_container")))
  for item in entries:
   var item_card := PanelContainer.new();item_card.theme_type_variation="Inset";card.add_child(item_card)
   var row := SheetControls.columns(item_card,680);row.add_theme_constant_override("separation",12)
   var content := HBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",12);row.add_child(content)
   var glyph := preload("res://game/ui/item_glyph.gd").new();glyph.configure(_session.items.definition(StringName(str(item.definition_id))));glyph.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;content.add_child(glyph)
   var detail := VBoxContainer.new();detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_child(detail)
   var item_label := SheetControls.label(ItemText.t("quantity",{"name":ItemText.instance(_session,item),"quantity":int(item.quantity)}))
   item_label.custom_minimum_size.y=float(_text.data.theme.font_size)*1.4
   detail.add_child(item_label)
   var description := ItemText.item_details(_session,item)
   if description!="":
    var age_label := SheetControls.label(description);SheetControls.muted(age_label);detail.add_child(age_label)
    if item.attributes.has("freshness"):_age_labels.append({"label":age_label,"item":item})
   var count := int(reserved.get(item.id,0))
   if count>0:detail.add_child(SheetControls.label(ItemText.t("reserved",{"count":count})))
   var item_id := StringName(str(item.id))
   if item.kind in ["batch","prepared"] and container.kind=="cold":
    var take := _action(_text.text("recipe_take_bowl"),"take:"+str(item_id),func():_apply(_session.inventory.pick_up_storage(item_id)))
    SheetControls.primary(take)
    take.disabled=not held.is_empty();row.add_child(take)
   elif container.kind!="purchase_bag":
    var pack := _action(_text.text("inventory_pack"),"pack:"+str(item_id),func():_apply(_session.inventory.pack(item_id)))
    pack.disabled=count>0;row.add_child(pack)
 if shown==0:_rows.add_child(SheetControls.label(ItemText.t("no_items")))
 if _last_result:
  _feedback.text=_text.text("inventory_partial") if _last_result.ok and not _last_result.details.get("remaining",[]).is_empty() else ItemText.missing(_session,_text,_last_result)
 _feedback.visible=not _feedback.text.is_empty()
 _scroll.get_v_scroll_bar().set_deferred("value",scroll)
 _restore_focus(focus_key)
func _apply(result: ActionResult) -> void:
 _last_result=result;_dirty=true
func _action(value: String, key: String, action: Callable) -> Button:
 var button := SheetControls.button(value,action);button.set_meta("inventory_focus",key);button.custom_minimum_size.x=0
 return button
func _focused_key() -> String:
 var focused := get_viewport().gui_get_focus_owner()
 return str(focused.get_meta("inventory_focus","")) if focused!=null and is_ancestor_of(focused) else ""
func _restore_focus(key: String) -> void:
 if key.is_empty():return
 for control in _rows.find_children("*","Button",true,false):
  if str(control.get_meta("inventory_focus",""))==key and not control.disabled:
   control.call_deferred("grab_focus");return
