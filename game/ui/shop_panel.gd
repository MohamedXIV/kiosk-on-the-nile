class_name ShopPanel
extends PanelContainer
var _session: GameSession
var _text: UiText
var _shop_id: StringName
var _cards := VBoxContainer.new()
var _details := SheetControls.label()
var _heading := SheetControls.label()
var _feedback := SheetControls.label()
var _wallet := SheetControls.label()
var _search := LineEdit.new()
var _quantity := SpinBox.new()
var _confirm: Button
var _selected: Dictionary={}
var _offers: Array[Dictionary]=[]
var _quote: ShopQuote
var _request_id: StringName
var _revision: int=-1
var _locale_revision: int=-1
var _journey_id: String=""
var _last_result: ActionResult
var _bought: bool=false
var _updating: bool=false
func configure(text: UiText, session: GameSession) -> void:
 _session=session;_text=text;theme=text.make_theme()
 anchor_left=0.06;anchor_right=0.94;anchor_top=0.16;anchor_bottom=0.96
 var column := VBoxContainer.new();add_child(column)
 column.add_child(_heading)
 column.add_child(_wallet)
 _search.placeholder_text=OutingText.t("search")
 _search.text_changed.connect(func(_value):_render_cards())
 column.add_child(_search)
 var body := HBoxContainer.new();body.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(body)
 var scroll := SheetControls.scroll(_cards);scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.size_flags_stretch_ratio=0.9;body.add_child(scroll)
 var detail_column := VBoxContainer.new()
 var detail_scroll := SheetControls.scroll(detail_column);detail_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(detail_scroll)
 detail_column.add_child(_details)
 detail_column.add_child(text.key_label("shop_quantity"))
 _quantity.min_value=1;_quantity.max_value=1;_quantity.step=1;_quantity.value=1
 _quantity.value_changed.connect(func(_value):
  if not _updating:_invalidate();_update_details())
 _quantity.get_line_edit().text_changed.connect(func(_value):
  if not _updating:_invalidate();_feedback.text="")
 detail_column.add_child(_quantity)
 detail_column.add_child(SheetControls.key_button(text,"shop_review",_review))
 _confirm=SheetControls.key_button(text,"shop_confirm",_purchase);_confirm.disabled=true;detail_column.add_child(_confirm)
 detail_column.add_child(_feedback)
 column.add_child(SheetControls.key_button(text,"journey_return",_return))
 hide()
func present() -> void:
 var route := _session.travel.route()
 var shop_id := StringName(str(route.get("shop_id","")))
 visible=_session.travel.can_shop(shop_id)
 if not visible:return
 var journey_id := str(_session.travel.journey.data.get("id",""))
 if journey_id!=_journey_id:
  _journey_id=journey_id;_shop_id=shop_id;_selected={};_search.text="";_invalidate();_revision=-1
 var revision := _session.shops.revision()
 var locale_revision := LocaleService.current.revision
 if revision!=_revision:
  _revision=revision;_offers=_session.shops.offers(_shop_id);_invalidate();_refresh_selection();_render_cards();_update_details()
 if locale_revision!=_locale_revision:
  _locale_revision=locale_revision;_search.placeholder_text=OutingText.t("search");_render_cards();_update_details()
 _heading.text=OutingText.route(route,str(_session.travel.journey.data.get("route_id","")))
 _wallet.text=OutingText.t("wallet",{"amount":"%.2f" % (_session.wallet.balance/100.0)})
func _refresh_selection() -> void:
 var found := false
 for value in _offers:
  if value.id==_selected.get("id"):_selected=value;found=true;break
 if not found:_selected=_offers[0] if not _offers.is_empty() else {}
func _render_cards() -> void:
 SheetControls.clear(_cards)
 var count := 0
 for value in _offers:
  var original := str(value.label)
  var names := LocaleService.current.source_variants("shop."+str(_shop_id)+".offer."+str(value.id)+".label",original)
  if not _search.text.strip_edges().is_empty() and not _search.text.strip_edges().to_lower() in "\n".join(names).to_lower():continue
  count+=1
  var card := ProductCard.new();_cards.add_child(card)
  card.configure(value,_session.items.definition(StringName(value.contents[0].definition_id)),_text,_shop_id)
  var offer_id := str(value.id)
  card.selected.connect(func(_id):_select(offer_id))
 if count==0:_cards.add_child(SheetControls.label(OutingText.t("empty_offers")))
func _select(id: String) -> void:
 for value in _offers:
  if value.id==id:
   if _selected.get("id")!=id:_invalidate();_quantity.set_value_no_signal(1)
   _selected=value;_update_details();return
func _invalidate() -> void:
 _quote=null;_last_result=null;_bought=false
 if _confirm!=null:_confirm.disabled=true
func _update_details() -> void:
 _confirm.disabled=_quote==null
 if _selected.is_empty():_details.text=OutingText.t("choose_offer");_quantity.editable=false;_feedback.text="";return
 var lines := PackedStringArray([OutingText.offer(_shop_id,_selected,"label"),OutingText.offer(_shop_id,_selected,"description"),_text.text("shop_price",{"price":"%.2f" % (int(_selected.price_minor)/100.0),"stock":_selected.available})])
 for part in _selected.contents:
  var definition := _session.items.definition(StringName(part.definition_id))
  lines.append(OutingText.t("contents",{"name":ItemText.definition(_session,str(part.definition_id)),"quantity":int(part.quantity)}))
  if definition.has("footprint"):lines.append(_text.text("shop_size",{"width":float(definition.footprint[0])*0.25,"depth":float(definition.footprint[1])*0.25}))
  if definition.get("mountable",false):lines.append(_text.text("shop_requires_counter"))
  for capability in _session.config.section("equipment").get(part.definition_id,{}).get("capabilities",[]):lines.append(ItemText.capability(str(capability)))
 _details.text="\n".join(lines)
 _updating=true;_quantity.max_value=maxi(1,int(_selected.available));_quantity.editable=int(_selected.available)>0;_updating=false
 _feedback.text= _text.text("shop_total",{"price":"%.2f" % (_quote.total_minor/100.0)}) if _quote!=null else _text.text("shop_bought") if _bought else _text.outcome(_last_result) if _last_result!=null else ""
func _review() -> void:
 _quantity.apply()
 if _selected.is_empty():return
 _invalidate()
 _last_result=_session.shops.quote(_shop_id,[{"offer_id":_selected.id,"quantity":int(_quantity.value)}])
 if _last_result.ok:_quote=_last_result.details.quote;_request_id=StringName("purchase:"+_quote.id)
 _update_details()
func _purchase() -> void:
 _quantity.apply()
 if _quote==null:return
 _confirm.disabled=true
 var result := _session.shops.purchase(_quote,_request_id)
 _quote=null
 # Synchronize owner revision before displaying the command result.
 _revision=_session.shops.revision();_offers=_session.shops.offers(_shop_id);_refresh_selection();_render_cards()
 _last_result=result;_bought=result.ok;_update_details()
func _return() -> void:
 var result := _session.travel.begin_return()
 if not result.ok:_last_result=result;_update_details()
