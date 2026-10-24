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
var _cash := VBoxContainer.new()
func configure(text: UiText, session: GameSession) -> void:
 _session=session;_text=text;theme=text.make_theme()
 anchor_left=0.1;anchor_right=0.9;anchor_top=0.15;anchor_bottom=0.94
 var root := VBoxContainer.new();add_child(root)
 root.add_child(UiText.label(text.text("supplier_title")))
 var scroll := ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;root.add_child(scroll)
 var box := VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(box)
 _summary.custom_minimum_size.y=150;_summary.text_direction=Control.TEXT_DIRECTION_RTL;box.add_child(_summary)
 var funds := HFlowContainer.new();box.add_child(funds)
 _deposit.min_value=1;_deposit.max_value=1000;_deposit.value=10;_deposit.step=1;_deposit.suffix="ج.م";_deposit.update_on_text_changed=true;funds.add_child(_deposit)
 funds.add_child(UiText.button("ادفع رصيدًا مقدمًا",func():_apply(session.supply_transactions.deposit("fathi",roundi(_deposit.value*100),"deposit:"+str(Time.get_ticks_usec())))))
 funds.add_child(UiText.button("سدّد كل أصل الحساب",func():_apply(session.supply_transactions.settle("settle:"+str(Time.get_ticks_usec())))))
 box.add_child(_cash)
 box.add_child(UiText.label("السلة — الكمية صفر تعني عدم الطلب"))
 var basket := HFlowContainer.new();box.add_child(basket)
 for id in session.config.section("suppliers").catalog:
  var column := VBoxContainer.new();basket.add_child(column)
  column.add_child(UiText.label(str(session.items.definition(StringName(id)).label)))
  var count := SpinBox.new();count.min_value=0;count.max_value=20;count.step=1;count.update_on_text_changed=true;count.value=2 if id=="tea_portion" else 0
  count.custom_minimum_size.x=120;column.add_child(count);_basket[id]=count
 var schedule := HFlowContainer.new();box.add_child(schedule)
 _hour.min_value=0;_hour.max_value=23;_hour.value=7;_hour.suffix="ساعة";_hour.update_on_text_changed=true;schedule.add_child(_hour)
 _minute.min_value=0;_minute.max_value=59;_minute.value=0;_minute.suffix="دقيقة";_minute.update_on_text_changed=true;schedule.add_child(_minute)
 var weekdays := HFlowContainer.new();box.add_child(weekdays)
 for label in ["اليوم ١","٢","٣","٤","٥","٦","٧"]:
  var check := CheckBox.new();check.text=label;check.button_pressed=true;weekdays.add_child(check);_days.append(check)
 box.add_child(UiText.label("أيام الأسبوع حسب دورة أيام اللعبة؛ أول يوم في الدورة هو اليوم ١"))
 box.add_child(_destination)
 for label in ["رصيد مقدم","آجل — وافق فتحي على سقف الحساب","نقدي — حضور وتأكيد عند الموعد"]:_mode.add_item(label)
 box.add_child(_mode)
 _leave.text="أسمح بترك الدفعة في التخزين المحدد أثناء غيابي";_leave.button_pressed=true;box.add_child(_leave)
 _once.text="طلب إضافي مرة واحدة — بعد دقيقتين بدل الجدول الدوري";box.add_child(_once)
 box.add_child(UiText.button("اعرض الاتفاق والأسعار قبل الموافقة",_quote))
 _preview.custom_minimum_size.y=160;_preview.text_direction=Control.TEXT_DIRECTION_RTL;box.add_child(_preview)
 _accept=UiText.button("أوافق على العرض المعروض",_sign);_accept.disabled=true;box.add_child(_accept)
 box.add_child(UiText.button("ارفض العرض من غير اتفاق",func():_quote_id="";_accept.disabled=true;_preview.text="لم توافق على شيء."))
 box.add_child(UiText.button("أوقف الاتفاق الدوري للمواعيد التالية",func():
  if session.contracts.state.active!="":_apply(session.contracts.pause(str(session.contracts.state.versions[session.contracts.state.active].contract_id),"pause:"+str(Time.get_ticks_usec())))))
 _feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;root.add_child(_feedback)
 root.add_child(UiText.button("ارجع للمكالمة",func():session.contact.panel_requested=false;hide()))
 hide()
func present() -> void:
 var was := visible
 visible=_session.contact.panel_requested and _session.contact.available()
 if not visible:return
 if not was:
  _feedback.text="";_summary.text=SupplierText.summary(_session);_destinations();_cash_rows()
 elif _session.clock.tick%60==0:_summary.text=SupplierText.summary(_session);_cash_rows()
func _destinations() -> void:
 var previous := str(_destination.get_selected_metadata()) if _destination.item_count>0 else ""
 _destination.clear()
 for c in _session.items.snapshot().containers.values():
  if _session.contracts.destination_snapshot(str(c.id)).is_empty():continue
  _destination.add_item(("ثلاجة " if c.kind=="cold" else "تخزين جاف ")+("الكشك" if c.location_id=="kiosk" else "السطح"))
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
 _quote_id=str(result.details.quote.id);_preview.text=SupplierText.terms(_session,result.details.quote);_accept.disabled=false;_feedback.text="ده عرض فقط؛ لا بضاعة أو فلوس اتحركت. قبول عرض جديد يعدّل الاتفاق الدوري الحالي للمستقبل."
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
  _cash.add_child(UiText.button("أدفع وأستلم الدفعة النقدية الموجودة الآن",func():_apply(_session.supply_transactions.deliver(id,true))))
func _apply(result: ActionResult) -> void:
 _feedback.text="تم، والتفاصيل محفوظة في دفتر الحساب." if result.ok else _message(result)
 _summary.text=SupplierText.summary(_session);_cash_rows()
func _message(result: ActionResult) -> String:
 return {"supplier_storage_invalid":"اختار تخزينًا مناسبًا للسلة وحجم الدفعة؛ البارد في الثلاجة والجاف في التخزين الجاف.","invalid_supplier_basket":"راجع السلة والكميات المتاحة.","insufficient_funds":"الفلوس اللي معاك لا تكفي.","stale_supplier_quote":"العرض انتهى أو المكان اتغير؛ اعرض اتفاقًا جديدًا.","supplier_contact_required":"لازم تكون في المكالمة وقريب من التليفون.","nothing_due":"ما فيش مبلغ متبقي عليك."}.get(str(result.message_key),_text.outcome(result))
