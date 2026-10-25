class_name FinancialDialogue
extends RefCounted
## Explicit chapter preparation owns frozen offers; context reads never create terms.
var _session: GameSession
func configure(session: GameSession) -> void:_session=session
func prepare(chapter: String, actor: String) -> void:
 if chapter.is_empty():return
 if actor=="abdul_karim":_prepare_housing(chapter)
 elif actor=="fathi":_prepare_supplier(chapter)
func context(chapter: String, actor: String) -> Dictionary:
 return _housing_context(chapter) if actor=="abdul_karim" else _supplier_context(chapter)
func _prepare_housing(chapter: String) -> void:
 if not _session.accounts.state.chapters.has(chapter):
  _session.accounts.tick({})
  var snapshot_data := {"extension_targets":_session.accounts.housing_targets(),"id":chapter,"pay_quote":"","partial_quote":"","loan_id":str(_session.commitments.active_loan().get("id",""))}
  for offer_id in ["settle","partial"]:
   var amount := 0
   if offer_id=="partial":
    var remaining := 0
    for bill in _session.accounts.outstanding("abdul_karim"):remaining+=_session.accounts.remaining(bill.id)
    amount=mini(remaining,int(_session.config.section("accounts").partial_minor))
   var quote := _session.accounts.quote("housing_lease",offer_id,_session.clock.world_minutes,amount)
   if quote.ok:
    var id := str(quote.details.quote.id)
    _session.accounts.state.quotes[id]["chapter"]=chapter
    snapshot_data["pay_quote" if offer_id=="settle" else "partial_quote"]=id
  _session.accounts.state.chapters[chapter]=snapshot_data
func _prepare_supplier(chapter: String) -> void:
 if not _session.contracts.state.emergency_quotes.has(chapter):
  var data := _session.config.section("suppliers")
  var e: Dictionary=data.emergency
  _session.contracts.state.emergency_quotes[chapter]={"name":str(_session.presence.profile(&"fathi").name),"goods_minor":int(e.price_minor),"fee_minor":0,"total_minor":int(e.price_minor),"emergency_cap":int(e.cap_minor),"due_minutes":float(data.invoice_due_minutes),"food_id":str(e.food_id),"recipe_id":str(e.recipe_id),"mode":"credit","lines":[]}
func _housing_context(chapter: String) -> Dictionary:
 if chapter.is_empty() or not _session.accounts.state.chapters.has(chapter):return {}
 var saved: Dictionary=_session.accounts.state.chapters[chapter]
 var due: Dictionary=_session.accounts.state.quotes.get(saved.pay_quote,{})
 var partial: Dictionary=_session.accounts.state.quotes.get(saved.partial_quote,{})
 var loan: Dictionary=_session.commitments.state.loans.get(saved.loan_id,{})
 var loan_remaining := int(loan.get("principal",0))-int(loan.get("paid",0))
 var pending := pending_financial_offer(chapter)
 var now := _session.clock.world_minutes
 var latest := now
 for target in saved.extension_targets:
  var p := _session.accounts.resolve_period(str(target))
  if not p.is_empty():latest=maxf(latest,float(p.end))
 var context_data := {"has_housing_due":not due.is_empty(),"can_negotiate":not saved.extension_targets.is_empty(),"housing_due_label":"%.2f" % (float(due.get("net",0))/100.0),"partial_label":"%.2f" % (float(partial.get("net",0))/100.0),"can_pay_housing":not due.is_empty() and _session.wallet.balance>=int(due.net),"can_partial_housing":not partial.is_empty() and _session.wallet.balance>=int(partial.net),"extend_1":_session.commitments.eligible(1),"extend_3":_session.commitments.eligible(3),"extend_7":_session.commitments.eligible(7),"extension_1_date":AccountText.date(latest+1440),"extension_3_date":AccountText.date(latest+4320),"extension_7_date":AccountText.date(latest+10080),"agreed_date":AccountText.date(float(pending.get("deadline",now))),"has_loan":loan_remaining>0,"loan_remaining_label":"%.2f" % (float(loan_remaining)/100.0),"can_repay_loan":loan_remaining>0 and _session.wallet.balance>=loan_remaining,"can_loan":_session.commitments.eligible(),"about_today":_session.commitments.state.moments.has("about:%d" % _session.clock.day),"can_focus":_session.actions.preview(&"personal_focus").ok,"known_abdul_family":_session.knowledge.has(&"KNOWN_ABDUL_FAMILY"),"can_repair":false,"loan_duration_label":"%.1f يوم" % (float(_session.config.section("accounts").loan.duration_minutes)/1440.0)}
 for promise in _session.commitments.state.promises.values():
  if promise.status=="broken" and not promise.repaired:context_data.can_repair=true
 for loan_record in _session.commitments.state.loans.values():
  if loan_record.get("status")=="broken" and not loan_record.get("repaired",false):context_data.can_repair=true
 var amounts: Array=_session.config.section("accounts").loan.amounts
 for index in range(3):
  var amount := int(amounts[index]) if index<amounts.size() else 0
  context_data["loan_%d" % index]=amount>0 and amount<=int(_session.commitments.state.budget_minor)
  context_data["loan_%d_label" % index]="%.2f" % (float(amount)/100.0)
 return context_data
func pending_financial_offer(chapter: String) -> Dictionary:
 var found: Dictionary={}
 for offer in _session.commitments.state.offers.values():
  if offer.get("chapter","")==chapter and not offer.get("declined",false) and (found.is_empty() or float(offer.at)>=float(found.at)):found=offer
 return found.duplicate(true)
func financial_effect(action: String, source: String, participants: PackedStringArray) -> ActionResult:
 if participants.size()!=1:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"creditor_not_present")
 var actor: Variant=_session.presence.record(participants[0])
 if actor==null or actor.character_id!=&"abdul_karim" or not _session.presence.near_actor(&"abdul_karim"):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"creditor_not_present")
 var chapter := source.get_slice("/",0)
 var saved: Dictionary=_session.accounts.state.chapters.get(chapter,{})
 if saved.is_empty():return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"stale_financial_offer")
 if action in ["pay_housing","pay_partial"]:return _session.finance.pay(str(saved["pay_quote" if action=="pay_housing" else "partial_quote"]),"ink:"+source)
 if action=="repay_loan":return _session.finance.pay_loan(str(saved.loan_id),"ink:"+source)
 if action=="personal":return _session.finance.personal_moment(source)
 if action=="repair":return _session.finance.personal_moment(source,true)
 if action=="accept_offer":
  var offer := pending_financial_offer(chapter)
  return _session.finance.accept_offer(str(offer.get("id","")),"ink:"+source)
 if action=="decline_offer":
  var offer := pending_financial_offer(chapter)
  if not offer.is_empty():_session.commitments.state.offers[offer.id]["declined"]=true
  return ActionResult.success()
 var offered := ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"invalid_financial_action")
 if action.begins_with("offer_day_"):offered=_session.commitments.offer("extension",int(action.trim_prefix("offer_day_")),saved.extension_targets)
 elif action.begins_with("offer_loan_"):
  var index := int(action.trim_prefix("offer_loan_"))
  var amounts: Array=_session.config.section("accounts").loan.amounts
  if index>=0 and index<amounts.size():offered=_session.commitments.offer("loan",int(amounts[index]))
 if offered.ok:_session.commitments.state.offers[offered.details.offer.id]["chapter"]=chapter
 return offered
func _supplier_context(chapter: String) -> Dictionary:
 if not _session.contracts.state.emergency_quotes.has(chapter):return {}
 var quote: Dictionary=_session.contracts.state.emergency_quotes[chapter]
 var available := _session.inventory.held_id().is_empty() and SupplierLedger.remaining(_session.accounts.state.supplier,true)+int(quote.total_minor)<=int(quote.emergency_cap)
 var reason_code := "unpaid"
 var reason := "لسه في ساندوتش على حسابك؛ نخلص حسابه الأول، وبعدها أقدر أوصلك واحد تاني."
 if not _session.inventory.held_id().is_empty():reason_code="hands";reason="حط اللي في إيدك في مكان مناسب الأول عشان تستلم الساندوتش."
 var stock: Dictionary=_session.deliveries.state.stock_days.get(str(floori(_session.clock.world_minutes/1440.0)),{}).get("emergency",{})
 if not stock.is_empty() and int(stock.used)>=int(stock.capacity):available=false;reason_code="stock";reason="الساندوتشات الجاهزة خلصت عندي النهارده. أقدر أرتب لك من المتاح بكرة."
 return {"emergency_label":"%.2f" % (float(quote.total_minor)/100.0),"emergency_available":available,"emergency_reason":reason,"localization_args":{"amount":"%.2f" % (float(quote.total_minor)/100.0),"reason":{"text_ref":"story.supplier.reason."+reason_code}}}
func supplier_effect(action: String, source: String, participants: PackedStringArray) -> ActionResult:
 if not _session.contact.available() or participants.size()!=1 or str(_session.contact.current.id)!=participants[0]:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"supplier_contact_required")
 if action=="manage":_session.contact.panel_requested=true;return ActionResult.success()
 if action=="emergency":return _session.supply_transactions.emergency(source)
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"invalid_supplier_action")
