class_name SupplierPanel
extends PanelContainer
var _session: GameSession
var _text: UiText
var _summary := RichTextLabel.new()
var _preview := RichTextLabel.new()
var _feedback := Label.new()
var _basket: Dictionary={}
var _days: Array[CheckBox]=[]
var _hour := SpinBox.new()
var _minute := SpinBox.new()
var _destination := OptionButton.new()
var _mode := OptionButton.new()
var _leave := CheckBox.new()
var _once := CheckBox.new()
var _deposit := SpinBox.new()
var _quote_id: String=""
var _accept: Button
var _summary_tick: int=-1
var _cash := VBoxContainer.new()
func configure(text: UiText, session: GameSession) -> void:
 _session=session;_text=text;theme=text.make_theme()
 anchor_left=0.1;anchor_right=0.9;anchor_top=0.15;anchor_bottom=0.94
 var root := VBoxContainer.new();add_child(root)
 root.add_child(text.key_label("supplier_title"))
 var scroll := ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;root.add_child(scroll)
 var box := VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(box)
 _summary.custom_minimum_size.y=150;_summary.text_direction=Control.TEXT_DIRECTION_RTL;box.add_child(_summary)
 var funds := HFlowContainer.new();box.add_child(funds)
 _deposit.min_value=1;_deposit.max_value=1000;_deposit.value=10;_deposit.step=1;_deposit.suffix="ج.م";_deposit.update_on_text_changed=true;funds.add_child(_deposit)
 funds.add_child(_button("deposit",func():_apply(session.supply_transactions.deposit("fathi",roundi(_deposit.value*100),"deposit:"+str(Time.get_ticks_usec())))))
 funds.add_child(_button("settle",func():_apply(session.supply_transactions.settle("settle:"+str(Time.get_ticks_usec())))))
 box.add_child(_cash)
 box.add_child(_label("basket"))
 var basket := HFlowContainer.new();box.add_child(basket)
 for id in session.config.section("suppliers").catalog:
  var column := VBoxContainer.new();basket.add_child(column)
  column.add_child(_item_label(str(id)))
  var count := SpinBox.new();count.min_value=0;count.max_value=int(session.config.section("suppliers").catalog[id].daily_stock);count.step=1;count.update_on_text_changed=true;count.value=2 if id=="tea_portion" else 0
  count.custom_minimum_size.x=120;column.add_child(count);_basket[id]=count
 var schedule := HFlowContainer.new();box.add_child(schedule)
 _hour.min_value=0;_hour.max_value=23;_hour.value=int(session.config.section("suppliers").delivery_minute)/60;_hour.suffix="ساعة";_hour.update_on_text_changed=true;schedule.add_child(_hour)
 _minute.min_value=0;_minute.max_value=59;_minute.value=int(session.config.section("suppliers").delivery_minute)%60;_minute.suffix="دقيقة";_minute.update_on_text_changed=true;schedule.add_child(_minute)
 var weekdays := HFlowContainer.new();box.add_child(weekdays)
 for label in ["اليوم ١","٢","٣","٤","٥","٦","٧"]:
  var check := CheckBox.new();check.text=label;UiText.bind_control(check,"supply.day",{"day":_days.size()+1});check.button_pressed=true;weekdays.add_child(check);_days.append(check)
 box.add_child(_label("week_help"))
 box.add_child(_destination)
 for label in ["رصيد مقدم","آجل — وافق فتحي على سقف الحساب","نقدي — حضور وتأكيد عند الموعد"]:_mode.add_item(label)
 box.add_child(_mode)
 _leave.text="أسمح بترك الدفعة في التخزين المحدد أثناء غيابي";_leave.button_pressed=true;UiText.bind_control(_leave,"supply.leave");box.add_child(_leave)
 _once.text="طلب إضافي مرة واحدة — بعد %s دقيقة بدل الجدول الدوري" % str(float(session.config.section("suppliers").extra_delay_minutes));UiText.bind_control(_once,"supply.once",{"minutes":float(session.config.section("suppliers").extra_delay_minutes)});box.add_child(_once)
 box.add_child(_button("quote",_quote))
 _preview.custom_minimum_size.y=160;_preview.text_direction=Control.TEXT_DIRECTION_RTL;box.add_child(_preview)
 _accept=_button("accept",_sign);_accept.disabled=true;box.add_child(_accept)
 box.add_child(_button("decline",func():_quote_id="";_accept.disabled=true;_preview.text=_t("declined")))
 box.add_child(_button("pause",func():
  if session.contracts.state.active!="":_apply(session.contracts.pause(str(session.contracts.state.versions[session.contracts.state.active].contract_id),"pause:"+str(Time.get_ticks_usec())))))
 _feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;root.add_child(_feedback)
 root.add_child(_button("back",func():session.contact.panel_requested=false;hide()))
 LocaleService.current.changed.connect(_refresh_language)
 _refresh_language()
 hide()
func present() -> void:
 var was := visible
 visible=_session.contact.panel_requested and _session.contact.available()
 if not visible:return
 if not was:
  _feedback.text="";_summary.text=SupplierText.summary(_session);_destinations();_cash_rows()
  _summary_tick=_session.clock.tick
 elif _session.clock.tick-_summary_tick>=60:
  _summary.text=SupplierText.summary(_session);_cash_rows()
  _summary_tick=_session.clock.tick
func _destinations() -> void:
 var previous := str(_destination.get_selected_metadata()) if _destination.item_count>0 else ""
 _destination.clear()
 for c in _session.items.snapshot().containers.values():
  if _session.contracts.destination_snapshot(str(c.id)).is_empty():continue
  _destination.add_item(_t(("cold_" if c.kind=="cold" else "dry_")+("kiosk" if c.location_id=="kiosk" else "roof")))
  _destination.set_item_metadata(_destination.item_count-1,str(c.id))
  if c.id==previous:_destination.select(_destination.item_count-1)
func _quote() -> void:
 var basket: Dictionary={}
 for id in _basket:
  if _basket[id].value>0:basket[id]=int(_basket[id].value)
 var days: Array=[]
 for index in range(_days.size()):
  if _days[index].button_pressed:days.append(index)
 var result := _session.contracts.quote({"basket":basket,"weekdays":days,"minute":int(_hour.value)*60+int(_minute.value),"destination":str(_destination.get_selected_metadata()),"mode":["prepaid","credit","cash"][_mode.selected],"leave_goods":_leave.button_pressed,"once":_once.button_pressed})
 if not result.ok:_feedback.text=_message(result);return
 _quote_id=str(result.details.quote.id);_preview.text=SupplierText.terms(_session,result.details.quote);_accept.disabled=false;_feedback.text=_t("offer_only")
func _sign() -> void:
 if _quote_id=="":return
 var active := str(_session.contracts.state.active)
 var q: Dictionary=_session.contracts.state.quotes[_quote_id]
 var request := "sign:"+_quote_id
 var result := _session.contracts.amend(str(_session.contracts.state.versions[active].contract_id),_quote_id,request) if active!="" and not q.once else _session.contracts.accept(_quote_id,request)
 if result.ok:_accept.disabled=true
 _apply(result)
func _cash_rows() -> void:
 for child in _cash.get_children():_cash.remove_child(child);child.queue_free()
 for o in _session.deliveries.cash_waiting():
  var id := str(o.id)
  _cash.add_child(_button("confirm_cash",func():_apply(_session.supply_transactions.deliver(id,true))))
func _apply(result: ActionResult) -> void:
 _feedback.text=_t("done") if result.ok else _message(result)
 _summary.text=SupplierText.summary(_session);_cash_rows()
func _message(result: ActionResult) -> String:
 var key: String = {"supplier_storage_invalid":"storage_invalid","invalid_supplier_basket":"invalid_basket","insufficient_funds":"insufficient","stale_supplier_quote":"stale","supplier_contact_required":"contact","nothing_due":"nothing_due"}.get(str(result.message_key),"")
 return _t(str(key)) if key!="" else _text.outcome(result)
func _t(key: String, args: Dictionary = {}) -> String:return UiText.localized("supply."+key,args,key)
func _label(key: String) -> Label:
 var label := UiText.label(_t(key));UiText.bind_control(label,"supply."+key)
 return label
func _item_label(id: String) -> Label:
 var label := UiText.label(ItemText.definition(_session,id));label.set_meta("item_definition",id)
 return label
func _button(key: String, action: Callable) -> Button:
 var button := UiText.button(_t(key),action);UiText.bind_control(button,"supply."+key)
 return button
func _refresh_language() -> void:
 if _session==null:return
 UiText.refresh_tree(self)
 for id in _basket:
  var label: Label=_basket[id].get_parent().get_child(0)
  label.text=ItemText.definition(_session,str(id))
 _hour.suffix=_t("hour");_minute.suffix=_t("minute");_deposit.suffix=_t("currency")
 var selected := _mode.selected
 _mode.clear()
 for id in ["prepaid","credit","cash"]:_mode.add_item(_t(id))
 _mode.select(maxi(0,selected))
 _destinations()
 _summary.text=SupplierText.summary(_session)
 if _quote_id!="":_preview.text=SupplierText.terms(_session,_session.contracts.state.quotes[_quote_id])
 _cash_rows()
