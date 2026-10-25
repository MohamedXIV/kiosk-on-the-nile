class_name SupplierText
extends RefCounted
static func _t(key: String, args: Dictionary = {}) -> String:
 return UiText.localized("supply."+key,args,key)
static func date(at: float) -> String:
 var minute := int(fposmod(at,1440.0))
 return _t("date",{"day":floori(at/1440)+1,"hour":"%02d" % (minute/60),"minute":"%02d" % (minute%60)})
static func reason(key: String) -> String:
 var source := {"storage_changed":"مكان التخزين اتحرك أو لم يعد متاحًا؛ راجع الاتفاق","storage_full":"التخزين لا يسع الدفعة كاملة","permission_required":"لم تأذن بترك البضاعة أثناء غيابك","cash_presence_required":"الدفع النقدي يحتاج حضورك وتأكيدك","cash_confirmation_expired":"لم تؤكد الدفع في مهلة الاستلام","prepaid_insufficient":"الرصيد المقدم لا يكفي","credit_limit":"الدفعة تتجاوز سقف الآجل المتفق عليه","cash_insufficient":"النقد لا يكفي","stock_missing":"المورد لا يملك السلة كاملة اليوم"}
 return UiText.localized("supply.reason."+key,{},str(source.get(key,key)))
static func terms(session: GameSession, q: Dictionary) -> String:
 var lines := PackedStringArray()
 for line in q.lines:
  var item := UiText.localized("item."+str(line.definition_id),{},str(session.items.definition(StringName(line.definition_id)).label))
  lines.append(_t("line",{"item":item,"quantity":int(line.quantity),"price":"%.2f" % (float(line.unit_minor)/100.0)}))
 lines.append(_t("total",{"goods":"%.2f" % (float(q.goods_minor)/100.0),"fee":"%.2f" % (float(q.fee_minor)/100.0),"total":"%.2f" % (float(q.total_minor)/100.0)}))
 var storage := _t(("cold_" if q.destination.kind=="cold" else "dry_")+("kiosk" if q.destination.location_id=="kiosk" else "roof"))
 lines.append(_t("time",{"hour":"%02d" % (int(q.minute)/60),"minute":"%02d" % (int(q.minute)%60),"storage":storage,"mode":_t(str(q.mode))}))
 var days := PackedStringArray()
 for value in q.weekdays:days.append(str(int(value)+1))
 lines.append(_t("once_terms",{"minutes":float(q.extra_delay)}) if q.once else _t("days",{"days":"، ".join(days) if LocaleService.current==null or LocaleService.current.rtl() else ", ".join(days)}))
 lines.append(_t("allowed" if q.leave_goods else "required"))
 if q.mode=="credit":lines.append(_t("limit",{"amount":"%.2f" % (float(q.credit_cap)/100.0)}))
 return "\n".join(lines)
static func summary(session: GameSession) -> String:
 var ledger: Dictionary=session.accounts.state.supplier
 var name := LocalizedNarrative.speaker("fathi",str(session.presence.profile(&"fathi").name))
 var lines := PackedStringArray([_t("balance",{"name":name,"prepaid":"%.2f" % (float(ledger.prepaid)/100.0),"owed":"%.2f" % (float(SupplierLedger.remaining(ledger))/100.0)})])
 if session.contracts.state.active!="":
  var v: Dictionary=session.contracts.state.versions[session.contracts.state.active]
  lines.append(_t("active")+"\n"+terms(session,v))
  lines.append(_t("next",{"date":date(SupplierContracts.next_time(v,session.clock.world_minutes))}))
 else:lines.append(_t("none"))
 for v in session.contracts.state.versions.values():
  if v.id==session.contracts.state.active:continue
  lines.append(_t("extra" if v.once else "previous")+" · "+date(float(v.accepted_at))+"\n"+terms(session,v))
  if v.once and not session.deliveries.state.occurrences.has(DeliveryService.identity(v.id,float(v.first_at))):lines.append(_t("pending",{"date":date(float(v.first_at))}))
 for invoice in ledger.invoices.values():
  var remaining := int(invoice.total)-int(invoice.paid)
  lines.append(_t("invoice",{"name":invoice.name,"amount":"%.2f" % (float(remaining)/100.0),"date":date(float(invoice.due_at)),"status":_t("paid" if remaining==0 else "overdue" if session.clock.world_minutes>=float(invoice.due_at) else "upcoming")}))
 var history := session.deliveries.occurrences()
 for o in history.slice(maxi(0,history.size()-8)):
  lines.append(date(float(o.scheduled_at))+" · "+_t("delivered" if o.status=="delivered" else "wait_cash" if o.cash_waiting else "skipped" if o.status=="skipped" else "scheduled")+(": "+reason(str(o.reason)) if o.reason!="" else ""))
 for r in ledger.receipts.values():lines.append(str(r.journal_text))
 return "\n\n".join(lines)
