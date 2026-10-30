class_name MenuPanel
extends PanelContainer
var _session: GameSession
var _text: UiText
var _rows := VBoxContainer.new()
var _heading := SheetControls.label()
var _feedback := SheetControls.label()
func configure(text: UiText, session: GameSession) -> void:
 _session=session;_text=text;theme=text.make_theme()
 anchor_left=0.08;anchor_right=0.92;anchor_top=0.16;anchor_bottom=0.96
 var column := VBoxContainer.new();add_child(column)
 SheetControls.header(column,_heading,text,hide)
 var scroll := SheetControls.scroll(_rows);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(scroll)
 column.add_child(_feedback)
 LocaleService.current.changed.connect(_render)
 hide()
func open() -> void:_render();show()
func _render() -> void:
 if _session==null:return
 _heading.text=UiText.localized("menu.title",{},"Menu and prices")
 SheetControls.clear(_rows)
 _rows.add_child(SheetControls.label(UiText.localized("menu.price_hint",{},"Prices apply to new orders. Accepted orders keep their quote. Zero is an advertised price; personal hospitality is separate.")))
 var state := _session.menu.snapshot()
 for variant in state.prices:
  var id := StringName(str(variant))
  var label := UiText.localized("menu.food."+str(variant).get_slice("/",0),{},OutingText.order(_session,StringName(str(variant).get_slice("/",0))))+" · "+UiText.localized("serving."+str(variant).get_slice("/",1),{},str(variant).get_slice("/",1))+" · "+UiText.localized("serving."+str(variant).get_slice("/",2),{},str(variant).get_slice("/",2))
  _price_row(label,int(state.prices[variant]),func(value):return _session.menu.set_price(id,value))
 for addition in state.addition_prices:
  var id := StringName(str(addition))
  _price_row(UiText.localized("addition."+str(id),{},str(id)),int(state.addition_prices[addition]),func(value):return _session.menu.set_addition_price(id,value))
func _price_row(label: String, amount: int, apply: Callable) -> void:
 var card := SheetControls.card(_rows);card.add_child(SheetControls.label(label))
 var row := HBoxContainer.new();card.add_child(row)
 var price := SpinBox.new();price.min_value=0;price.max_value=float(MenuService.LIMIT)/100.0;price.step=0.01;price.value=float(amount)/100.0;price.custom_minimum_size.x=240;row.add_child(price)
 row.add_child(SheetControls.button(UiText.localized("menu.apply",{},"Set price"),func():
  var result: ActionResult=apply.call(roundi(price.value*100.0))
  _feedback.text=_text.outcome(result)))
