class_name DistrictPanel
extends PanelContainer
var _session: GameSession
var _text: UiText
var _details := RichTextLabel.new()
var _feedback := Label.new()
var _quote_id: String=""
var _pay: Button
func configure(text: UiText, session: GameSession) -> void:
 _session=session;_text=text;theme=text.make_theme()
 anchor_left=0.1;anchor_right=0.9;anchor_top=0.17;anchor_bottom=0.9
 var box := VBoxContainer.new();add_child(box)
 box.add_child(UiText.label(text.text("district_title")))
 var choices := HFlowContainer.new();box.add_child(choices)
 choices.add_child(UiText.button("اعرض المستحقات",func():_quote("settle")))
 for id in session.config.section("accounts").advance_offers:
  var offer: Dictionary=session.config.section("accounts").advance_offers[id]
  var label := "%d أسبوع مقدم · خصم %d%%" % [int(offer.periods),int(offer.discount_percent)]
  choices.add_child(UiText.button(label,func():_quote(str(id))))
 _details.size_flags_vertical=Control.SIZE_EXPAND_FILL
 _details.custom_minimum_size.y=150;_details.text_direction=Control.TEXT_DIRECTION_RTL
 box.add_child(_details)
 _pay=UiText.button("ادفع العرض المعروض",func():
  var result := session.district.pay()
  _feedback.text="تم السداد والإيصال محفوظ في الكشكول." if result.ok else text.outcome(result)
  if result.ok:_pay.disabled=true;_refresh())
 box.add_child(_pay)
 _feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(_feedback)
 box.add_child(UiText.button(text.text("journey_return"),func():session.travel.begin_return()))
 hide()
func _quote(id: String) -> void:
 var result := _session.district.quote(id)
 _feedback.text="" if result.ok else _text.outcome(result)
 _quote_id=""
 _refresh()
func present() -> void:
 var was_visible := visible
 visible=_session.district.available()
 if not visible:return
 _session.district.open()
 if not was_visible or str(_session.district.state.quote_id)!=_quote_id:_refresh()
func _refresh() -> void:
 _quote_id=str(_session.district.state.quote_id)
 var q: Dictionary=_session.accounts.state.quotes.get(_quote_id,{})
 _pay.disabled=q.is_empty()
 if q.is_empty():
  _details.text=AccountText.ledger(_session)
  return
 var paid_id := str(_session.accounts.state.requests.get(str(_session.district.state.request_id),""))
 var receipt: Dictionary=_session.accounts.state.receipts.get(paid_id,{})
 var heading := "%s · الإجمالي %.2f ج.م" % [q.creditor_name,float(q.net)/100.0]
 heading+="\nإيصال سداد رقم %s · %s" % [paid_id.trim_prefix("account_receipt_"),AccountText.date(float(receipt.at))] if not receipt.is_empty() else "\nالعرض صالح حتى "+AccountText.date(float(q.expires))
 var lines := PackedStringArray([heading])
 for line in q.lines:lines.append("من %s\nإلى %s\nأساسي %.2f − خصم %.2f = %.2f ج.م" % [AccountText.date(float(line.start)),AccountText.date(float(line.end)),float(line.gross)/100.0,float(line.discount)/100.0,float(line.net)/100.0])
 _details.text="\n\n".join(lines)
 if not receipt.is_empty():
  _pay.disabled=true
  _feedback.text="السداد محفوظ بالفعل؛ مفيش خصم جديد عند الاستكمال."
