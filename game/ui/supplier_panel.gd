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
 SheetControls.shell(self)
 var root := VBoxContainer.new();root.add_theme_constant_override("separation",12);add_child(root)
 SheetControls.header(root,text.key_label("supplier_title"),text,func():session.contact.panel_requested=false;hide())
 var box := VBoxContainer.new();var scroll := SheetControls.scroll(box);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(scroll)
 var columns := SheetControls.columns(box,820)
 var account := VBoxContainer.new();account.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(account)
 var account_card := SheetControls.card(account)
 _readable(_summary);account_card.add_child(_summary)
 var funds := HFlowContainer.new();funds.add_theme_constant_override("h_separation",8);account_card.add_child(funds)
 _number(_deposit,1,1000,10);_deposit.suffix="ج.م";funds.add_child(_deposit)
 funds.add_child(_button("deposit",func():_apply(session.supply_transactions.deposit("fathi",roundi(_deposit.value*100),"deposit:"+str(Time.get_ticks_usec())))))
 funds.add_child(_button("settle",func():_apply(session.supply_transactions.settle("settle:"+str(Time.get_ticks_usec())))))
 account_card.add_child(_cash)
 account_card.add_child(_button("pause",func():
  if session.contracts.state.active!="":_apply(session.contracts.pause(str(session.contracts.state.versions[session.contracts.state.active].contract_id),"pause:"+str(Time.get_ticks_usec())))))
 var order := VBoxContainer.new();order.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(order)
 var basket_card := SheetControls.card(order)
 var basket_heading := _label("basket");SheetControls.title(basket_heading);basket_card.add_child(basket_heading)
 var basket := HFlowContainer.new();basket.add_theme_constant_override("h_separation",16);basket_card.add_child(basket)
 for id in session.config.section("suppliers").catalog:
  var column := VBoxContainer.new();column.custom_minimum_size.x=128;basket.add_child(column)
  column.add_child(_item_label(str(id)))
  var count := SpinBox.new();_number(count,0,int(session.config.section("suppliers").catalog[id].daily_stock),2 if id=="tea_portion" else 0)
  column.add_child(count);_basket[id]=count
 var schedule_card := SheetControls.card(order)
 var schedule := HFlowContainer.new();schedule.add_theme_constant_override("h_separation",12);schedule_card.add_child(schedule)
 _number(_hour,0,23,int(session.config.section("suppliers").delivery_minute)/60);_hour.suffix="ساعة";schedule.add_child(_hour)
 _number(_minute,0,59,int(session.config.section("suppliers").delivery_minute)%60);_minute.suffix="دقيقة";schedule.add_child(_minute)
 var weekdays := HFlowContainer.new();weekdays.add_theme_constant_override("h_separation",8);schedule_card.add_child(weekdays)
 for index in range(7):
  var check := CheckBox.new();UiText.bind_control(check,"supply.day",{"day":index+1});check.button_pressed=true;check.custom_minimum_size=Vector2(84,44);weekdays.add_child(check);_days.append(check)
 var week_help := _label("week_help");SheetControls.muted(week_help);schedule_card.add_child(week_help)
 _destination.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_destination.fit_to_longest_item=false;schedule_card.add_child(_destination)
 for label in ["رصيد مقدم","آجل — وافق فتحي على سقف الحساب","نقدي — حضور وتأكيد عند الموعد"]:_mode.add_item(label)
 _mode.fit_to_longest_item=false;schedule_card.add_child(_mode)
 _leave.button_pressed=true;UiText.bind_control(_leave,"supply.leave");_leave.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_leave.custom_minimum_size.y=44;schedule_card.add_child(_leave)
 UiText.bind_control(_once,"supply.once",{"minutes":float(session.config.section("suppliers").extra_delay_minutes)});_once.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_once.custom_minimum_size.y=44;schedule_card.add_child(_once)
 var quote_button := _button("quote",_quote);SheetControls.primary(quote_button);schedule_card.add_child(quote_button)
 var review := SheetControls.card(box)
 _readable(_preview);review.add_child(_preview)
 var review_actions := HFlowContainer.new();review_actions.add_theme_constant_override("h_separation",8);review.add_child(review_actions)
 _accept=_button("accept",_sign);SheetControls.primary(_accept);_accept.disabled=true;review_actions.add_child(_accept)
 review_actions.add_child(_button("decline",func():_quote_id="";_accept.disabled=true;_preview.text=_t("declined")))
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
 var label := SheetControls.label(_t(key));UiText.bind_control(label,"supply."+key)
 return label
func _item_label(id: String) -> Label:
 var label := SheetControls.label(ItemText.definition(_session,id));label.set_meta("item_definition",id)
 return label
func _button(key: String, action: Callable) -> Button:
 var button := SheetControls.button(_t(key),action);UiText.bind_control(button,"supply."+key)
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

func _readable(control: RichTextLabel) -> void:
 control.fit_content=true
 control.scroll_active=false
 control.selection_enabled=true
 control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 control.text_direction=Control.TEXT_DIRECTION_AUTO
func _number(control: SpinBox, minimum: float, maximum: float, initial: float) -> void:
 control.min_value=minimum;control.max_value=maximum;control.value=initial;control.step=1
 control.update_on_text_changed=true
 control.custom_minimum_size=Vector2(112,44)
 control.get_line_edit().text_direction=Control.TEXT_DIRECTION_LTR
