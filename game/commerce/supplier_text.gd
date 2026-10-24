class_name SupplierText
extends RefCounted
static func reason(key: String) -> String:
 return {"storage_changed":"مكان التخزين اتحرك أو لم يعد متاحًا؛ راجع الاتفاق","storage_full":"التخزين لا يسع الدفعة كاملة","permission_required":"لم تأذن بترك البضاعة أثناء غيابك","cash_presence_required":"الدفع النقدي يحتاج حضورك وتأكيدك","cash_confirmation_expired":"لم تؤكد الدفع في مهلة الاستلام","prepaid_insufficient":"الرصيد المقدم لا يكفي","credit_limit":"الدفعة تتجاوز سقف الآجل المتفق عليه","cash_insufficient":"النقد لا يكفي","stock_missing":"المورد لا يملك السلة كاملة اليوم"}.get(key,key)
static func terms(session: GameSession, q: Dictionary) -> String:
 var lines := PackedStringArray()
 for line in q.lines:lines.append("%s × %d · %.2f ج.م للوحدة" % [session.items.definition(StringName(line.definition_id)).label,int(line.quantity),float(line.unit_minor)/100.0])
 lines.append("بضاعة %.2f + توصيل %.2f = %.2f ج.م" % [float(q.goods_minor)/100.0,float(q.fee_minor)/100.0,float(q.total_minor)/100.0])
 lines.append("%02d:%02d · %s · %s" % [int(q.minute)/60,int(q.minute)%60,("ثلاجة " if q.destination.kind=="cold" else "تخزين جاف ")+("الكشك" if q.destination.location_id=="kiosk" else "السطح"),{"prepaid":"رصيد مقدم","credit":"آجل متفق عليه","cash":"نقدي عند الاستلام بعد التأكيد"}.get(q.mode,q.mode)])
 var days := PackedStringArray()
 for value in q.weekdays:days.append(str(int(value)+1))
 lines.append("طلب مرة واحدة بعد %g دقيقة من الموافقة" % float(q.extra_delay) if q.once else "أيام الدورة: "+"، ".join(days))
 lines.append("مسموح تركها في غيابك" if q.leave_goods else "حضورك لازم؛ لم تأذن بتركها")
 if q.mode=="credit":lines.append("سقف الحساب %.2f ج.م" % (float(q.credit_cap)/100.0))
 return "\n".join(lines)
static func summary(session: GameSession) -> String:
 var ledger: Dictionary=session.accounts.state.supplier
 var lines := PackedStringArray(["حساب %s: مقدم %.2f · متبقي عليك %.2f ج.م" % [str(session.presence.profile(&"fathi").name),float(ledger.prepaid)/100.0,float(SupplierLedger.remaining(ledger))/100.0]])
 if session.contracts.state.active!="":
  var v: Dictionary=session.contracts.state.versions[session.contracts.state.active]
  lines.append("الاتفاق الحالي:\n"+terms(session,v))
  lines.append("الموعد التالي: "+AccountText.date(SupplierContracts.next_time(v,session.clock.world_minutes)))
 else:lines.append("لا اتفاق دوري شغال؛ الرصيد القديم محفوظ.")
 for v in session.contracts.state.versions.values():
  if v.id==session.contracts.state.active:continue
  var title := "طلب إضافي" if v.once else "اتفاق سابق"
  lines.append(title+" · "+AccountText.date(float(v.accepted_at))+"\n"+terms(session,v))
  if v.once and not session.deliveries.state.occurrences.has(DeliveryService.identity(v.id,float(v.first_at))):lines.append("ينتظر التسليم: "+AccountText.date(float(v.first_at)))
 for invoice in ledger.invoices.values():
  var remaining := int(invoice.total)-int(invoice.paid)
  lines.append("فاتورة %s: المتبقي %.2f · %s · %s" % [invoice.name,float(remaining)/100.0,AccountText.date(float(invoice.due_at)),"مدفوعة" if remaining==0 else "متأخرة" if session.clock.world_minutes>=float(invoice.due_at) else "قادم سدادها"])
 var history := session.deliveries.occurrences()
 for o in history.slice(maxi(0,history.size()-8)):
  lines.append("%s · %s%s" % [AccountText.date(float(o.scheduled_at)),"وصلت" if o.status=="delivered" else "في انتظار تأكيد الدفع" if o.cash_waiting else "لم تصل" if o.status=="skipped" else "مجدولة",": "+reason(str(o.reason)) if o.reason!="" else ""])
 for r in ledger.receipts.values():lines.append(str(r.journal_text))
 return "\n\n".join(lines)
