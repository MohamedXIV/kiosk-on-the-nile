class_name DistrictPanel
extends PanelContainer
var _session: GameSession
var _text: UiText
var _details := RichTextLabel.new()
var _heading := SheetControls.label()
var _document := SheetControls.label()
var _feedback := Label.new()
var _quote_id: String=""
var _pay: Button
var _feedback_key: String=""
var _feedback_result: ActionResult
func configure(text: UiText, session: GameSession) -> void:
 _session=session;_text=text;theme=text.make_theme()
 SheetControls.shell(self,940)
 var root := VBoxContainer.new();root.add_theme_constant_override("separation",12);add_child(root)
 var heading := text.key_label("district_title");SheetControls.title(heading);root.add_child(heading)
 var box := VBoxContainer.new();var scroll := SheetControls.scroll(box);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(scroll)
 var columns := SheetControls.columns(box,740)
 var offers := VBoxContainer.new();offers.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(offers)
 var choices := SheetControls.card(offers)
 choices.add_child(_button("district.settle",func():_quote("settle")))
 for id in session.config.section("accounts").advance_offers:
  var offer: Dictionary=session.config.section("accounts").advance_offers[id]
  choices.add_child(_button("district.offer",func():_quote(str(id)),{"periods":int(offer.periods),"discount":int(offer.discount_percent)}))
 var records := VBoxContainer.new();records.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(records)
 var record := SheetControls.card(records)
 SheetControls.title(_heading);record.add_child(_heading)
 SheetControls.muted(_document);record.add_child(_document)
 _details.fit_content=true;_details.scroll_active=false;_details.selection_enabled=true;_details.text_direction=Control.TEXT_DIRECTION_AUTO
 _details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;record.add_child(_details)
 _pay=_button("district.pay",func():
  var result := session.district.pay()
  _feedback_key="district.paid" if result.ok else "";_feedback_result=null if result.ok else result
  _refresh_feedback()
  if result.ok:_pay.disabled=true;_refresh())
 SheetControls.primary(_pay);record.add_child(_pay)
 _feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;root.add_child(_feedback)
 root.add_child(SheetControls.key_button(text,"journey_return",func():session.travel.begin_return()))
 if LocaleService.current:LocaleService.current.changed.connect(_refresh_language)
 hide()
func _quote(id: String) -> void:
 var result := _session.district.quote(id)
 _feedback_key="";_feedback_result=null if result.ok else result
 _refresh_feedback()
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
  _heading.text="";_document.text=""
  NotebookView.readable_text(_details,NotebookView.accounts(_session))
  return
 var paid_id := str(_session.accounts.state.requests.get(str(_session.district.state.request_id),""))
 var receipt: Dictionary=_session.accounts.state.receipts.get(paid_id,{})
 _heading.text=UiText.localized("district.heading",{"name":str(q.creditor_name),"amount":NotebookView.money(int(q.net))})
 _document.text=UiText.localized("district.receipt",{"id":paid_id.trim_prefix("account_receipt_"),"date":SupplierText.date(float(receipt.at))}) if not receipt.is_empty() else UiText.localized("district.expires",{"date":SupplierText.date(float(q.expires))})
 _document.theme_type_variation=&"Heading" if not receipt.is_empty() else &"Muted"
 var lines := PackedStringArray()
 for line in q.lines:lines.append(UiText.localized("district.line",{"start":SupplierText.date(float(line.start)),"end":SupplierText.date(float(line.end)),"gross":NotebookView.money(int(line.gross)),"discount":NotebookView.money(int(line.discount)),"net":NotebookView.money(int(line.net))}))
 NotebookView.readable_text(_details,"\n\n".join(lines))
 if not receipt.is_empty():
  _pay.disabled=true
  _feedback_key="district.already_paid";_feedback_result=null;_refresh_feedback()

func _button(id: String, action: Callable, args: Dictionary = {}) -> Button:
 var control := SheetControls.button(UiText.localized(id,args),action);UiText.bind_control(control,id,args)
 return control
func _refresh_feedback() -> void:
 _feedback.text=UiText.localized(_feedback_key) if not _feedback_key.is_empty() else _text.outcome(_feedback_result) if _feedback_result!=null else ""
func _refresh_language() -> void:
 UiText.refresh_tree(self)
 _refresh()
 _refresh_feedback()
