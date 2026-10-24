class_name SupplyTransactions
extends RefCounted
var _session: GameSession
func configure(session: GameSession) -> void:_session=session
func deposit(supplier_id: String, amount_minor: int, request_id: String) -> ActionResult:
 if supplier_id!="fathi" or not _session.contact.available():return _fail("supplier_contact_required")
 var ledger: Dictionary=_session.accounts.state.supplier
 if ledger.requests.has(request_id):return _repeat(ledger,request_id,"deposit",amount_minor)
 if request_id=="" or amount_minor<=0 or amount_minor>10000000:return _fail("invalid_supplier_amount")
 if _session.wallet.balance<amount_minor:return _fail("insufficient_funds")
 var book := _session.accounts.snapshot()
 var receipt := SupplierLedger.receipt(book.supplier,request_id,"deposit",_session.clock.world_minutes,_session.wallet.balance,-amount_minor,amount_minor,{"amount":amount_minor})
 receipt["journal_text"]="دفعت %.2f ج.م رصيدًا مقدمًا لعم فتحي؛ ليس رسم تفعيل أو دينًا." % (float(amount_minor)/100.0)
 return _publish(book,_session.items.candidate(),_session.deliveries.snapshot(),receipt)
func settle(request_id: String) -> ActionResult:
 if not _session.contact.available():return _fail("supplier_contact_required")
 var ledger: Dictionary=_session.accounts.state.supplier
 if ledger.requests.has(request_id):return ActionResult.success({"duplicate":true})
 var total := SupplierLedger.remaining(ledger)
 if request_id=="" or total<=0:return _fail("nothing_due")
 if _session.wallet.balance<total:return _fail("insufficient_funds")
 var book := _session.accounts.snapshot()
 var payments: Dictionary={}
 for invoice in book.supplier.invoices.values():
  var amount := int(invoice.total)-int(invoice.paid)
  if amount>0:payments[invoice.id]=amount;invoice.paid=int(invoice.total)
 var receipt := SupplierLedger.receipt(book.supplier,request_id,"settlement",_session.clock.world_minutes,_session.wallet.balance,-total,0,{"payments":payments})
 receipt["journal_text"]="سددت أصل حساب عم فتحي: %.2f ج.م؛ من غير زيادة." % (float(total)/100.0)
 return _publish(book,_session.items.candidate(),_session.deliveries.snapshot(),receipt)
func deliver(occurrence_id: String, confirm_cash: bool = false, sleeping: bool = false) -> ActionResult:
 var occurrence: Dictionary=_session.deliveries.state.occurrences.get(occurrence_id,{})
 if occurrence.is_empty():return _fail("invalid_delivery")
 if occurrence.status!="scheduled":return ActionResult.success({"duplicate":true})
 var terms: Dictionary=_session.contracts.state.versions.get(occurrence.version_id,{})
 if terms.is_empty():return _fail("invalid_delivery")
 var local := not sleeping and _session.locations.is_physical(_session.location_id) and str(_session.location_id)==str(terms.destination.location_id)
 if not _session.contracts.destination_valid(terms.destination):return _skip(occurrence_id,"storage_changed")
 if not _session.contracts.basket_fits(terms.lines,terms.destination):return _skip(occurrence_id,"storage_full")
 if not local and not terms.leave_goods:return _skip(occurrence_id,"permission_required")
 if terms.mode=="cash":
  if not local:return _skip(occurrence_id,"cash_presence_required")
  if not confirm_cash:
   if _session.clock.world_minutes>float(occurrence.scheduled_at)+float(terms.cash_wait):return _skip(occurrence_id,"cash_confirmation_expired")
   _session.deliveries.state.occurrences[occurrence_id].cash_waiting=true
   return ActionResult.success()
  if not _session.contact.available():return _fail("supplier_contact_required")
 var ledger: Dictionary=_session.accounts.state.supplier
 if terms.mode=="prepaid" and int(ledger.prepaid)<int(terms.total_minor):return _skip(occurrence_id,"prepaid_insufficient")
 if terms.mode=="credit" and SupplierLedger.remaining(ledger)+int(terms.total_minor)>int(terms.credit_cap):return _skip(occurrence_id,"credit_limit")
 if terms.mode=="cash" and _session.wallet.balance<int(terms.total_minor):return _skip(occurrence_id,"cash_insufficient")
 var delivery := _session.deliveries.snapshot()
 var stock_result := _stock(delivery,terms.lines,float(occurrence.scheduled_at),false)
 if not stock_result.ok:return _skip(occurrence_id,"stock_missing")
 var grants: Array[Dictionary]=[]
 for line in terms.lines:grants.append({"definition_id":str(line.definition_id),"quantity":int(line.quantity),"container_id":str(terms.destination.id),"attributes":{"supply_occurrence":occurrence_id}})
 var prepared := _session.items.prepare_grants(grants)
 if not prepared.ok:return _skip(occurrence_id,"storage_full")
 return _complete(occurrence_id,terms,prepared.details.change,delivery,stock_result.details.units,false)
func emergency(source: String) -> ActionResult:
 if not _session.contact.available():return _fail("supplier_contact_required")
 var occurrence_id := "emergency:"+source
 if _session.deliveries.state.occurrences.has(occurrence_id):return ActionResult.success({"duplicate":true})
 var terms: Dictionary=_session.contracts.state.get("emergency_quotes",{}).get(source.get_slice("/",0),{})
 if terms.is_empty():return _fail("stale_supplier_quote")
 if not _session.inventory.held_id().is_empty():return _fail("hands_busy")
 if SupplierLedger.remaining(_session.accounts.state.supplier,true)+int(terms.total_minor)>int(terms.emergency_cap):return _fail("emergency_credit_limit")
 var now := _session.clock.world_minutes
 var delivery := _session.deliveries.snapshot()
 var result := _stock(delivery,[],now,true)
 if not result.ok:return _fail("out_of_stock")
 delivery.occurrences[occurrence_id]={"id":occurrence_id,"version_id":"","scheduled_at":now,"status":"scheduled","reason":"","evaluated_at":-1.0,"receipt":"","grants":[],"emergency":true,"cash_waiting":false}
 var id := "food_%d" % int(_session.items.snapshot().next_id)
 var prepared := _session.items.prepare_grants([{"id":id,"definition_id":"prepared_food","quantity":1,"container_id":"player_hand","attributes":{"id":id,"recipe_id":terms.recipe_id,"food_id":terms.food_id,"quality_score":2,"quality_key":_session.foods.definition(StringName(terms.food_id)).quality_keys[2],"sugar_id":"","personal_use":true,"supply_occurrence":occurrence_id}}])
 if not prepared.ok:return prepared
 return _complete(occurrence_id,terms,prepared.details.change,delivery,result.details.units,true)
func _stock(candidate: Dictionary, lines: Array, at: float, emergency_food: bool) -> ActionResult:
 var data := _session.config.section("suppliers")
 var day := str(floori(at/1440.0))
 if not candidate.stock_days.has(day):candidate.stock_days[day]={}
 var units: Dictionary={"emergency":1} if emergency_food else {}
 if not emergency_food:
  for line in lines:units[str(line.definition_id)]=int(line.quantity)
 for id in units:
  if not candidate.stock_days[day].has(id):candidate.stock_days[day][id]={"capacity":int(data.emergency.daily_stock) if id=="emergency" else int(data.catalog.get(id,{}).get("daily_stock",0)),"used":0}
  var slot: Dictionary=candidate.stock_days[day][id]
  if int(slot.used)+int(units[id])>int(slot.capacity):return _fail("out_of_stock")
  slot.used=int(slot.used)+int(units[id])
 return ActionResult.success({"units":units})
func _complete(id: String, terms: Dictionary, items: ItemChangeSet, delivery: Dictionary, stock_units: Dictionary, emergency_food: bool) -> ActionResult:
 var book := _session.accounts.snapshot()
 var occurrence: Dictionary=delivery.occurrences[id]
 var grants: Array=[]
 for item in items.state.items.values():
  if item.attributes.get("supply_occurrence")==id and _session.items.get_item(StringName(item.id)).is_empty():grants.append({"id":str(item.id),"definition_id":str(item.definition_id),"quantity":int(item.quantity)})
 var total := int(terms.total_minor)
 var cash_delta := -total if terms.mode=="cash" else 0
 var pre_delta := -total if terms.mode=="prepaid" else 0
 var at := _session.clock.world_minutes
 var detail := {"occurrence":id,"goods_minor":int(terms.goods_minor),"fee_minor":int(terms.fee_minor),"total_minor":total,"mode":str(terms.mode),"name":str(terms.name),"lines":terms.get("lines",[]).duplicate(true),"grants":grants,"emergency":emergency_food}
 var receipt := SupplierLedger.receipt(book.supplier,"delivery:"+id,"delivery",at,_session.wallet.balance,cash_delta,pre_delta,detail)
 if terms.mode=="credit":book.supplier.invoices[id]={"id":id,"name":str(terms.name),"at":at,"due_at":at+float(terms.due_minutes),"total":total,"paid":0,"emergency":emergency_food}
 receipt["journal_text"]="وصلت %s؛ بضاعة %.2f + توصيل %.2f = %.2f ج.م، %s. الإيصال محفوظ." % ["لقمة على الحساب" if emergency_food else "دفعة المورد",float(terms.goods_minor)/100.0,float(terms.fee_minor)/100.0,float(total)/100.0,"على الحساب" if terms.mode=="credit" else "مدفوعة"]
 occurrence.merge({"status":"delivered","reason":"","evaluated_at":at,"receipt":receipt.id,"grants":grants,"stock_units":stock_units.duplicate(true),"cash_waiting":false},true)
 return _publish(book,items,delivery,receipt)
func _skip(id: String, reason: String) -> ActionResult:
 var delivery := _session.deliveries.snapshot()
 var occurrence: Dictionary=delivery.occurrences[id]
 occurrence.merge({"status":"skipped","reason":reason,"evaluated_at":_session.clock.world_minutes,"cash_waiting":false},true)
 var event := {"id":"supply:skip:"+id,"chapter":"supply","actor":"system","name":"دفتر التوريد","text":"لم تصل دفعة المورد: "+SupplierText.reason(reason)+". لا بضاعة ولا خصم أو توصيل مدفوع لهذا الموعد.","channel":"system","at":_session.clock.world_minutes}
 var result := _session.deliveries.validate_state(delivery)
 if not result.ok:return result
 var journal := InteractionJournal.new();journal.configure(_session.presence.actor_ids(),_session.clock)
 result=journal.restore(_session.journal.snapshot())
 if not result.ok:return result
 result=journal.append_once(event)
 if not result.ok:return result
 _session.deliveries.state=delivery;_session.journal.restore(journal.snapshot())
 return ActionResult.success({"skipped":true,"reason":reason})
func _publish(book: Dictionary, items: ItemChangeSet, delivery: Dictionary, receipt: Dictionary) -> ActionResult:
 var valid := _session.accounts.validate_state(book)
 if not valid.ok:return valid
 valid=_session.items.validate_change(items)
 if not valid.ok:return valid
 valid=_session.deliveries.validate_state(delivery)
 if not valid.ok:return valid
 if receipt.wallet_after<0:return _fail("insufficient_funds")
 var journal := InteractionJournal.new();journal.configure(_session.presence.actor_ids(),_session.clock)
 valid=journal.restore(_session.journal.snapshot())
 if not valid.ok:return valid
 valid=journal.append_once(_event(receipt))
 if not valid.ok:return valid
 # Every candidate above is valid. No await or signal exposes a partial commit.
 var committed := _session.items.commit(items,false)
 if not committed.ok:return committed
 _session.accounts.state=book;_session.deliveries.state=delivery;_session.wallet.balance=int(receipt.wallet_after);_session.journal.restore(journal.snapshot())
 _session.items.changed.emit(_session.items.revision);_session.finance.changed.emit()
 return ActionResult.success({"receipt":receipt.duplicate(true)})
func _event(receipt: Dictionary) -> Dictionary:return {"id":"supply:receipt:"+str(receipt.id),"chapter":"supply","actor":"system","name":"دفتر التوريد","text":receipt.journal_text,"channel":"system","at":receipt.at}
func _repeat(ledger: Dictionary, request: String, kind: String, amount: int) -> ActionResult:
 var receipt: Dictionary=ledger.receipts[ledger.requests[request]]
 return ActionResult.success({"duplicate":true}) if receipt.kind==kind and receipt.detail.get("amount")==amount else _fail("stale_supplier_quote")
func validate_links() -> ActionResult:
 var ledger: Dictionary=_session.accounts.state.supplier
 var used: Dictionary={}
 var grant_ids: Dictionary={}
 for receipt in ledger.receipts.values():
  var event: Dictionary={}
  for row in _session.journal.snapshot().events:
   if row.id=="supply:receipt:"+str(receipt.id):event=row;break
  if StableJson.stringify(event)!=StableJson.stringify(_event(receipt)):return _fail("supplier_journal_mismatch")
  if receipt.kind!="delivery":continue
  var d: Dictionary=receipt.detail
  var o: Dictionary=_session.deliveries.state.occurrences.get(d.occurrence,{})
  if o.is_empty() or o.status!="delivered" or o.receipt!=receipt.id or o.evaluated_at!=receipt.at or StableJson.stringify(o.grants)!=StableJson.stringify(d.get("grants")) or not o.get("stock_units") is Dictionary:return _fail("supplier_delivery_mismatch")
  if not o.emergency:
   var v: Dictionary=_session.contracts.state.versions[o.version_id]
   for key in ["goods_minor","fee_minor","total_minor","mode","name","lines"]:
    if StableJson.stringify(d.get(key))!=StableJson.stringify(v.get(key)):return _fail("supplier_invoice_terms")
  var day := str(floori(float(o.scheduled_at)/1440.0))
  if not used.has(day):used[day]={}
  for key in o.stock_units:used[day][key]=int(used[day].get(key,0))+int(o.stock_units[key])
  for grant in o.grants:
   if not grant is Dictionary or grant_ids.has(grant.get("id")) or not grant.get("id") is String or not ContentValidation.integer(grant.get("quantity")) or grant.quantity<1:return _fail("duplicate_supplier_grant")
   grant_ids[grant.id]=o.id
   var item := _session.items.get_item(StringName(grant.id))
   if item.is_empty():item=_session.items.snapshot().consumed.get(grant.id,{}).get("item",{})
   if not item.is_empty() and (item.definition_id!=grant.definition_id or int(item.quantity)>int(grant.quantity) or item.attributes.get("supply_occurrence")!=o.id):return _fail("supplier_item_source")
 for item in _session.items.snapshot().items.values():
  if item.attributes.has("supply_occurrence") and grant_ids.get(item.id)!=item.attributes.supply_occurrence:return _fail("orphan_supplier_item")
 for o in _session.deliveries.state.occurrences.values():
  if o.status=="delivered" and not ledger.receipts.has(o.receipt):return _fail("missing_supplier_invoice")
 for day in _session.deliveries.state.stock_days:
  for key in _session.deliveries.state.stock_days[day]:
   if int(used.get(day,{}).get(key,0))!=int(_session.deliveries.state.stock_days[day][key].used):return _fail("supplier_stock_mismatch")
 return ActionResult.success()
func _fail(key: String) -> ActionResult:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,StringName(key))
