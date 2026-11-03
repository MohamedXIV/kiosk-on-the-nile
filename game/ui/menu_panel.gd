class_name MenuPanel
extends PanelContainer
var _session: GameSession
var _text: UiText
var _rows := VBoxContainer.new()
var _heading := SheetControls.label()
var _feedback := SheetControls.label()
var _scroll: ScrollContainer
var _draft_prices: Dictionary={}
func configure(text: UiText, session: GameSession) -> void:
 _session=session;_text=text;theme=text.make_theme()
 SheetControls.shell(self,960)
 var column := VBoxContainer.new();column.add_theme_constant_override("separation",14);add_child(column)
 SheetControls.header(column,_heading,text,hide)
 _scroll=SheetControls.scroll(_rows);_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(_scroll)
 column.add_child(_feedback);_feedback.hide()
 LocaleService.current.changed.connect(_render)
 hide()
func open() -> void:_render();show()
func _render() -> void:
 if _session==null:return
 var scroll_offset := _scroll.get_v_scroll_bar().value
 var focused := get_viewport().gui_get_focus_owner()
 var focus_key := str(focused.get_meta("price_focus","")) if focused!=null and is_ancestor_of(focused) else ""
 _heading.text=UiText.localized("menu.title",{},"Menu and prices")
 SheetControls.clear(_rows)
 var hint := SheetControls.label(UiText.localized("menu.price_hint",{},"Prices apply to new orders. Accepted orders keep their quote. Zero is an advertised price; personal hospitality is separate."));SheetControls.muted(hint);_rows.add_child(hint)
 var state := _session.menu.snapshot()
 var foods: Dictionary={}
 for variant in state.prices:
  var id := StringName(str(variant))
  var food := str(variant).get_slice("/",0)
  if not foods.has(food):
   var card := SheetControls.card(_rows)
   var title := SheetControls.label(UiText.localized("menu.food."+food,{},OutingText.order(_session,StringName(food))));SheetControls.title(title);card.add_child(title);foods[food]=card
  var label := UiText.localized("serving."+str(variant).get_slice("/",1),{},str(variant).get_slice("/",1))+" · "+UiText.localized("serving."+str(variant).get_slice("/",2),{},str(variant).get_slice("/",2))
  _price_row(foods[food],label,"food:"+str(id),int(state.prices[variant]),func(value):return _session.menu.set_price(id,value))
 for addition in state.addition_prices:
  var id := StringName(str(addition))
  var card := SheetControls.card(_rows)
  _price_row(card,UiText.localized("addition."+str(id),{},str(id)),"addition:"+str(id),int(state.addition_prices[addition]),func(value):return _session.menu.set_addition_price(id,value))
 _scroll.get_v_scroll_bar().set_deferred("value",scroll_offset)
 if not focus_key.is_empty():
  for control in _rows.find_children("*","Control",true,false):
   if str(control.get_meta("price_focus",""))==focus_key:control.call_deferred("grab_focus");break
func _price_row(card: VBoxContainer, label: String, key: String, amount: int, apply: Callable) -> void:
 var inset := PanelContainer.new();inset.theme_type_variation="Inset";card.add_child(inset)
 var row := SheetControls.columns(inset,640)
 row.add_child(SheetControls.label(label))
 var actions := HBoxContainer.new();actions.size_flags_horizontal=Control.SIZE_EXPAND_FILL;actions.add_theme_constant_override("separation",10);row.add_child(actions)
 var price := SpinBox.new();price.min_value=0;price.max_value=float(MenuService.LIMIT)/100.0;price.step=0.01;price.value=float(_draft_prices.get(key,amount))/100.0;price.size_flags_horizontal=Control.SIZE_EXPAND_FILL;price.custom_minimum_size.x=110;price.get_line_edit().text_direction=Control.TEXT_DIRECTION_LTR;price.get_line_edit().set_meta("price_focus",key+":edit");actions.add_child(price)
 price.value_changed.connect(func(value):_draft_prices[key]=roundi(value*100.0))
 var set_price := SheetControls.button(UiText.localized("menu.apply",{},"Set price"),func():
  var result: ActionResult=apply.call(roundi(price.value*100.0))
  _feedback.text=_text.outcome(result);_feedback.show())
 set_price.custom_minimum_size.x=0;set_price.size_flags_horizontal=Control.SIZE_EXPAND_FILL;set_price.set_meta("price_focus",key+":apply");SheetControls.primary(set_price);actions.add_child(set_price)
