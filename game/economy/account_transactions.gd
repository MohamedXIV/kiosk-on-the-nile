class_name AccountTransactions
extends RefCounted
signal changed
var _session: GameSession
var _dirty: bool=true
var _seen_account_revision: int=-1
var _next_check: float=-1
func configure(session: GameSession) -> void:
 _session=session
 changed.connect(func():_dirty=true)
func _channel(creditor: String) -> bool:
 if not _session.running:return false
 if creditor=="district":return _session.location_id==&"district" and _session.travel.journey.data.get("route_id")=="district" and _session.travel.journey.data.get("phase")=="browsing"
 return creditor=="abdul_karim" and _session.presence.near_actor(&"abdul_karim")
func pay(quote_id: String, request_id: String) -> ActionResult:
 var prepared := _session.accounts.prepare_payment(quote_id,request_id,_session.wallet.balance)
 if not prepared.ok or prepared.details.get("duplicate",false):return prepared
 if not _channel(str(prepared.details.receipt.creditor)):return _fail("creditor_not_present")
 var receipt: Dictionary=prepared.details.receipt
 receipt["journal_name"]=UiText.localized("records.accounts.name",{},"دفتر المستحقات".format({}))
 receipt["journal_text"]=UiText.localized("records.accounts.payment",{"amount":"%.2f" % (float(receipt.net)/100.0),"creditor":receipt.creditor_name,"receipt":receipt.id},"دفعت {amount} ج.م إلى {creditor}؛ الإيصال {receipt}.".format({"amount":"%.2f" % (float(receipt.net)/100.0),"creditor":receipt.creditor_name,"receipt":receipt.id}))
 prepared.details.state.receipts[receipt.id]=receipt
 var event := _event(receipt)
 var result := _publish(prepared.details.state,_session.commitments.snapshot(),int(receipt.wallet_after),_session.relationships.snapshot(),[event])
 return ActionResult.success({"receipt":receipt,"cue":"coin"}) if result.ok else result
func accept_offer(offer_id: String, request_id: String) -> ActionResult:
 var prepared := _session.commitments.prepare_accept(offer_id,request_id,_session.wallet.balance)
 if not prepared.ok or prepared.details.get("duplicate",false):return prepared
 if not _channel("abdul_karim"):return _fail("creditor_not_present")
 var receipt: Dictionary=prepared.details.receipt
 receipt["creditor_name"]=_session.presence.profile(&"abdul_karim").name
 receipt["journal_name"]=UiText.localized("records.accounts.name",{},"دفتر المستحقات".format({}))
 receipt["journal_text"]=UiText.localized("records.accounts.loan_accepted",{"amount":"%.2f" % (float(receipt.cash_delta)/100.0),"creditor":receipt.creditor_name},"اتفقنا على سلفة {amount} ج.م من {creditor}، ورد أصلها في الموعد الموضح في الدفتر.".format({"amount":"%.2f" % (float(receipt.cash_delta)/100.0),"creditor":receipt.creditor_name})) if receipt.kind=="loan_accepted" else UiText.localized("records.accounts.extension",{"creditor":receipt.creditor_name},"اتفقت مع {creditor} على مهلة جديدة؛ أصل المستحق لم يتغير.".format({"creditor":receipt.creditor_name}))
 prepared.details.state.receipts[receipt.id]=receipt
 var result := _publish(_session.accounts.snapshot(),prepared.details.state,int(receipt.wallet_after),_session.relationships.snapshot(),[_event(receipt)])
 return ActionResult.success({"receipt":receipt,"cue":"coin" if receipt.cash_delta>0 else "chime"}) if result.ok else result
func pay_loan(loan_id: String, request_id: String) -> ActionResult:
 var prepared := _session.commitments.prepare_repayment(loan_id,request_id,_session.wallet.balance)
 if not prepared.ok or prepared.details.get("duplicate",false):return prepared
 if not _channel("abdul_karim"):return _fail("creditor_not_present")
 var receipt: Dictionary=prepared.details.receipt
 receipt["creditor_name"]=_session.presence.profile(&"abdul_karim").name
 receipt["journal_name"]=UiText.localized("records.accounts.name",{},"دفتر المستحقات".format({}))
 receipt["journal_text"]=UiText.localized("records.accounts.loan_repaid",{"amount":"%.2f" % (float(-int(receipt.cash_delta))/100.0),"creditor":receipt.creditor_name,"receipt":receipt.id},"رددت أصل السلفة {amount} ج.م إلى {creditor}؛ الإيصال {receipt}.".format({"amount":"%.2f" % (float(-int(receipt.cash_delta))/100.0),"creditor":receipt.creditor_name,"receipt":receipt.id}))
 prepared.details.state.receipts[receipt.id]=receipt
 var result := _publish(_session.accounts.snapshot(),prepared.details.state,int(receipt.wallet_after),_session.relationships.snapshot(),[_event(receipt)])
 return ActionResult.success({"receipt":receipt,"cue":"coin"}) if result.ok else result
func tick(_frame: Dictionary) -> ActionResult:
 if not _dirty and _seen_account_revision==_session.accounts.revision and _session.clock.world_minutes<_next_check:return ActionResult.success()
 var due := false
 for bill in _session.accounts.state.obligations.values():
  if not bill.get("announced",false):due=true;break
 if not due:
  for promise in _session.commitments.state.promises.values():
   if promise.status!="pending":continue
   if _session.clock.world_minutes>=float(promise.deadline):due=true;break
   var outstanding := 0
   for target in promise.targets:outstanding+=_session.accounts.remaining(target)
   if outstanding==0:due=true;break
 if not due:
  for loan in _session.commitments.state.loans.values():
   if loan.status=="pending" and (loan.paid==loan.principal or _session.clock.world_minutes>=float(loan.due_at)):due=true;break
 if not due:
  _dirty=false;_seen_account_revision=_session.accounts.revision;_next_check=INF
  for promise in _session.commitments.state.promises.values():
   if promise.status=="pending":_next_check=minf(_next_check,float(promise.deadline))
  for loan in _session.commitments.state.loans.values():
   if loan.status=="pending":_next_check=minf(_next_check,float(loan.due_at))
  return ActionResult.success()
 var book := _session.accounts.snapshot()
 var commitments := _session.commitments.snapshot()
 var relations := _session.relationships.snapshot()
 var events: Array[Dictionary]=[]
 for bill in book.obligations.values():
  if bill.get("announced",false):continue
  bill["announced"]=true
  events.append(_system("bill:"+str(bill.id),UiText.localized("records.accounts.bill_due",{"label":ItemText.source("notebook.lease."+str(bill.lease),str(bill.label)),"amount":"%.2f" % (float(int(bill.gross)-int(bill.paid))/100.0)},"استحق {label}: {amount} ج.م. راجع دفتر الأسبوع.".format({"label":ItemText.source("notebook.lease."+str(bill.lease),str(bill.label)),"amount":"%.2f" % (float(int(bill.gross)-int(bill.paid))/100.0)}))))
 for promise in commitments.promises.values():
  if promise.status!="pending":continue
  var outstanding := 0
  for target in promise.targets:outstanding+=_session.accounts.remaining(target)
  var status := "fulfilled" if outstanding==0 else "broken" if _session.clock.world_minutes>=float(promise.deadline) else ""
  if status.is_empty():continue
  promise.status=status
  promise.assessed_at=_session.clock.world_minutes
  _adjust(relations,_session.config.section("accounts")["promise_fulfilled" if status=="fulfilled" else "promise_broken"])
  events.append(_system("promise:"+str(promise.id)+":"+status,UiText.localized("records.accounts.promise_fulfilled",{},"وفيت بوعد السداد.".format({})) if status=="fulfilled" else UiText.localized("records.accounts.promise_broken",{},"فات موعد وعد السداد؛ أصل الدين ما زال مستحقًا، ويمكنك الكلام والاتفاق من جديد.".format({}))))
 for loan in commitments.loans.values():
  if loan.get("status","pending")!="pending":continue
  var status := "fulfilled" if loan.paid==loan.principal else "broken" if _session.clock.world_minutes>=float(loan.due_at) else ""
  if status.is_empty():continue
  loan["status"]=status
  loan["assessed_at"]=_session.clock.world_minutes
  _adjust(relations,_session.config.section("accounts")["promise_fulfilled" if status=="fulfilled" else "promise_broken"])
  events.append(_system("loan:"+str(loan.id)+":"+status,UiText.localized("records.accounts.loan_fulfilled",{},"رددت السلفة كما اتفقت.".format({})) if status=="fulfilled" else UiText.localized("records.accounts.loan_broken",{},"موعد رد السلفة عدى؛ السداد والاعتذار يفضلوا متاحين.".format({}))))
 if events.is_empty():return ActionResult.success()
 return _publish(book,commitments,_session.wallet.balance,relations,events)
func personal_moment(source: String, repair: bool = false) -> ActionResult:
 if not _channel("abdul_karim"):return _fail("creditor_not_present")
 var candidate := _session.commitments.snapshot()
 var key := "repair:"+source if repair else "about:%d" % _session.clock.day
 if candidate.moments.has(key):return ActionResult.success({"duplicate":true})
 if repair:
  var found := false
  for p in candidate.promises.values():
   if p.status=="broken" and not p.repaired:p.repaired=true;found=true
  for loan in candidate.loans.values():
   if loan.get("status")=="broken" and not loan.get("repaired",false):loan.repaired=true;found=true
  if not found:return _fail("nothing_to_repair")
 candidate.moments[key]={"at":_session.clock.world_minutes,"source":source,"repair":repair}
 var relations := _session.relationships.snapshot()
 _adjust(relations,_session.config.section("accounts").promise_repair if repair else _session.config.section("accounts").personal_moment)
 return _publish(_session.accounts.snapshot(),candidate,_session.wallet.balance,relations,[])
func _adjust(relations: Dictionary, delta: Dictionary) -> void:
 if not relations.values.has("player"):relations.values.player={}
 if not relations.values.player.has("abdul_karim"):relations.values.player.abdul_karim={}
 for axis in ["familiarity","trust"]:
  relations.values.player.abdul_karim[axis]=clampf(float(relations.values.player.abdul_karim.get(axis,0))+float(delta[axis]),0,100)
func _publish(book: Dictionary, commitments: Dictionary, cash: int, relations: Dictionary, events: Array[Dictionary]) -> ActionResult:
 var valid := _session.accounts.validate_state(book)
 if not valid.ok:return valid
 valid=_session.commitments.validate_state(commitments)
 if not valid.ok:return valid
 var wallet := WalletService.new()
 valid=wallet.restore({"balance":cash})
 if not valid.ok:return valid
 var relationships := RelationshipStore.new(_session.config.section("social"),_session.presence.actor_ids()+["player"])
 valid=relationships.restore(relations)
 if not valid.ok:return valid
 var journal := InteractionJournal.new()
 journal.configure(_session.presence.actor_ids(),_session.clock)
 valid=journal.restore(_session.journal.snapshot())
 if not valid.ok:return valid
 for event in events:
  valid=journal.append_once(event)
  if not valid.ok:return valid
 # Every owner above is validated; observers run only after all publish.
 _session.accounts.state=book.duplicate(true)
 _session.commitments.state=commitments.duplicate(true)
 _session.wallet.balance=cash
 _session.relationships.restore(relations)
 _session.journal.restore(journal.snapshot())
 changed.emit()
 return ActionResult.success()
func _event(receipt: Dictionary) -> Dictionary:
 return {"id":"finance:"+str(receipt.id),"chapter":"accounts","actor":"system","name":str(receipt.get("journal_name","دفتر المستحقات")),"text":str(receipt.journal_text),"channel":"system","at":float(receipt.at)}
func _system(id: String, value: String) -> Dictionary:
 return {"id":"finance:"+id,"chapter":"accounts","actor":"system","name":UiText.localized("records.accounts.name",{},"دفتر المستحقات".format({})),"text":value,"channel":"system","at":_session.clock.world_minutes}
func validate_links() -> ActionResult:
 for receipt in _session.accounts.state.receipts.values()+_session.commitments.state.receipts.values():
  if not receipt.get("journal_text") is String:return _fail("missing_financial_journal")
  var event := _session.journal.event("finance:"+str(receipt.id))
  if event.is_empty() or StableJson.stringify(event)!=StableJson.stringify(_event(receipt)):return _fail("invalid_financial_journal")
 return ActionResult.success()
func _fail(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,StringName(key))
