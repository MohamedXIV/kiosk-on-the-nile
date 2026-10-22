class_name ShopPanel
extends PanelContainer
var _session: GameSession
var _text: UiText
var _shop_id: StringName
var _cards := VBoxContainer.new()
var _details := Label.new()
var _feedback := Label.new()
var _quantity := SpinBox.new()
var _confirm: Button
var _selected: Dictionary={}
var _quote: ShopQuote
var _request_id: StringName
var _revision: int=-1
func configure(text: UiText, session: GameSession) -> void:
 _session=session
 _text=text
 theme=text.make_theme()
 anchor_left=0.08
 anchor_right=0.92
 anchor_top=0.18
 anchor_bottom=0.9
 var column := VBoxContainer.new()
 add_child(column)
 column.add_child(UiText.label(text.text("shop_title")))
 var body := HBoxContainer.new()
 body.size_flags_vertical=Control.SIZE_EXPAND_FILL
 column.add_child(body)
 var scroll := ScrollContainer.new()
 scroll.custom_minimum_size=Vector2(260,200)
 scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 body.add_child(scroll)
 _cards.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(_cards)
 var detail_column := VBoxContainer.new()
 detail_column.custom_minimum_size.x=260
 detail_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 body.add_child(detail_column)
 _details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 _details.size_flags_vertical=Control.SIZE_EXPAND_FILL
 detail_column.add_child(_details)
 _quantity.min_value=1
 _quantity.max_value=20
 _quantity.step=1
 _quantity.value=1
 _quantity.value_changed.connect(func(_value):_quote=null;_update_details())
 detail_column.add_child(_quantity)
 detail_column.add_child(UiText.button(text.text("shop_review"),_review))
 _confirm=UiText.button(text.text("shop_confirm"),_purchase)
 _confirm.disabled=true
 detail_column.add_child(_confirm)
 _feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 column.add_child(_feedback)
 column.add_child(UiText.button(text.text("journey_return"),func():session.travel.begin_return()))
 hide()
func present() -> void:
 var route := _session.travel.route()
 var shop_id := StringName(str(route.get("shop_id","")))
 visible=_session.travel.can_shop(shop_id)
 if not visible:return
 var revision := int(_session.shops.snapshot().revision)
 if shop_id!=_shop_id or revision!=_revision:
  _shop_id=shop_id
  _revision=revision
  _refresh()
func _refresh() -> void:
 for child in _cards.get_children():child.free()
 _quote=null
 _confirm.disabled=true
 var offers := _session.shops.offers(_shop_id)
 var retained := false
 for offer in offers:
  var card := ProductCard.new()
  _cards.add_child(card)
  card.configure(offer,_session.items.definition(StringName(offer.contents[0].definition_id)),_text)
  var selected_offer: Dictionary=offer.duplicate(true)
  card.selected.connect(func(_id):_selected=selected_offer;_quote=null;_update_details())
  if _selected.get("id")==offer.id:_selected=offer;retained=true
 if not retained:_selected=offers[0] if not offers.is_empty() else {}
 _update_details()
func _update_details() -> void:
 _confirm.disabled=_quote==null
 if _selected.is_empty():_details.text="";return
 var descriptions := PackedStringArray([str(_selected.label),str(_selected.description)])
 for part in _selected.contents:
  var definition := _session.items.definition(StringName(part.definition_id))
  descriptions.append(str(definition.label)+" × "+str(part.quantity))
  if definition.has("footprint"):descriptions.append(_text.text("shop_size",{"width":float(definition.footprint[0])*0.25,"depth":float(definition.footprint[1])*0.25}))
  if definition.get("mountable",false):descriptions.append(_text.text("shop_requires_counter"))
  var capabilities: Array=_session.config.section("equipment").get(part.definition_id,{}).get("capabilities",[])
  var names: Dictionary=_text.data.get("capability_labels",{})
  for capability in capabilities:descriptions.append(str(names.get(capability,capability)))
 _details.text="\n".join(descriptions)
 _quantity.max_value=maxi(1,int(_selected.available))
func _review() -> void:
 if _selected.is_empty():return
 var result := _session.shops.quote(_shop_id,[{"offer_id":_selected.id,"quantity":int(_quantity.value)}])
 if not result.ok:_feedback.text=_text.outcome(result);return
 _quote=result.details.quote
 _request_id=StringName("purchase:"+_quote.id)
 _confirm.disabled=false
 _feedback.text=_text.text("shop_total",{"price":"%.2f" % (_quote.total_minor/100.0)})
func _purchase() -> void:
 if _quote==null:return
 _confirm.disabled=true
 var result := _session.shops.purchase(_quote,_request_id)
 _feedback.text=_text.text("shop_bought") if result.ok else _text.outcome(result)
 _quote=null
 _revision=-1
