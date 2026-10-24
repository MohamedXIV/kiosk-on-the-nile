class_name CommitmentService
extends RefCounted
var _session: GameSession
var _data: Dictionary
var state: Dictionary={}
func configure(session: GameSession) -> void:
 _session=session
 _data=session.config.section("accounts")
 state=initial_state(_data)
static func initial_state(data: Dictionary) -> Dictionary:
 return {"budget_minor":int(data.loan.budget_minor),"initial_budget":int(data.loan.budget_minor),"offers":{},"loans":{},"promises":{},"moments":{},"receipts":{},"requests":{},"next_offer":1,"next_loan":1,"next_promise":1,"next_receipt":1}
func active_loan() -> Dictionary:
 for loan in state.loans.values():
  if int(loan.paid)<int(loan.principal):return loan.duplicate(true)
 return {}
func agenda() -> bool:
 return not _session.accounts.outstanding("abdul_karim").is_empty() or not active_loan().is_empty()
func eligible(days: int = 0) -> bool:
 var unrepaired := 0
 for promise in state.promises.values():
  if promise.status=="broken" and not promise.repaired:unrepaired+=1
 var from := _session.relationships.value(&"player",&"abdul_karim",&"familiarity")
 var trust := _session.relationships.value(&"player",&"abdul_karim",&"trust")
 if days==0:return from>=float(_data.loan.familiarity) and trust>=float(_data.loan.trust) and active_loan().is_empty()
 for rule in _data.extensions:
  if int(rule.days)==days:return from>=float(rule.familiarity) and trust>=float(rule.trust) and unrepaired<=int(rule.get("maximum_unrepaired",0))
 return false
func offer(kind: String, amount: int = 0) -> ActionResult:
 var now := _session.clock.world_minutes
 var details: Dictionary={}
 if kind=="loan":
  if not amount in _data.loan.amounts or not eligible() or amount>int(state.budget_minor):return _fail("loan_unavailable")
  details={"principal":amount,"duration":float(_data.loan.duration_minutes),"lender":"abdul_karim"}
 elif kind=="extension":
  if not eligible(amount):return _fail("extension_unavailable")
  var targets: Array=[]
  var latest := now
  for bill in _session.accounts.outstanding("abdul_karim"):
   targets.append(bill.id)
   latest=maxf(latest,float(bill.due_at))
  if targets.is_empty():return _fail("nothing_due")
  details={"targets":targets,"days":amount,"deadline":latest+amount*1440.0,"lender":"abdul_karim"}
 else:return _fail("invalid_financial_action")
 var id := "commit_offer_%d" % int(state.next_offer)
 state.next_offer=int(state.next_offer)+1
 details.merge({"id":id,"kind":kind,"at":now,"expires":now+float(_data.quote_minutes),"terms_hash":StableJson.stringify(_data).sha256_text()})
 state.offers[id]=details
 return ActionResult.success({"offer":details.duplicate(true)})
func prepare_accept(id: String, request: String, wallet: int) -> ActionResult:
 if state.requests.has(request):return _duplicate(request,id)
 var offer_data: Dictionary=state.offers.get(id,{})
 if request.is_empty() or offer_data.is_empty() or _session.clock.world_minutes>float(offer_data.expires) or offer_data.terms_hash!=StableJson.stringify(_data).sha256_text():return _fail("stale_financial_offer")
 if offer_data.get("declined",false):return _fail("stale_financial_offer")
 for receipt in state.receipts.values():
  if receipt.source==id and receipt.kind in ["loan_accepted","extension_accepted"]:return ActionResult.success({"duplicate":true,"receipt":receipt.duplicate(true)})
 var candidate := state.duplicate(true)
 var delta := 0
 var agreement_id := ""
 if offer_data.kind=="loan":
  if not eligible() or int(offer_data.principal)>int(candidate.budget_minor):return _fail("loan_unavailable")
  agreement_id="loan_%d" % int(candidate.next_loan)
  candidate.next_loan=int(candidate.next_loan)+1
  candidate.loans[agreement_id]={"id":agreement_id,"lender":"abdul_karim","principal":int(offer_data.principal),"paid":0,"due_at":_session.clock.world_minutes+float(offer_data.duration),"accepted_at":_session.clock.world_minutes,"offer_id":id,"status":"pending","assessed_at":-1.0,"repaired":false}
  candidate.budget_minor=int(candidate.budget_minor)-int(offer_data.principal)
  delta=int(offer_data.principal)
 else:
  if not eligible(int(offer_data.days)):return _fail("extension_unavailable")
  for target in offer_data.targets:
   if _session.accounts.remaining(target)<=0:return _fail("stale_financial_offer")
  for promise in candidate.promises.values():
   if promise.status=="pending" and promise.kind=="housing":promise.status="superseded"
  agreement_id="promise_%d" % int(candidate.next_promise)
  candidate.next_promise=int(candidate.next_promise)+1
  candidate.promises[agreement_id]={"id":agreement_id,"kind":"housing","creditor":"abdul_karim","targets":offer_data.targets.duplicate(),"deadline":float(offer_data.deadline),"accepted_at":_session.clock.world_minutes,"offer_id":id,"status":"pending","assessed_at":-1.0,"repaired":false}
 var receipt := _receipt(candidate,request,id,"loan_accepted" if offer_data.kind=="loan" else "extension_accepted",delta,wallet,agreement_id)
 return ActionResult.success({"state":candidate,"receipt":receipt,"cash_delta":delta})
func prepare_repayment(loan_id: String, request: String, wallet: int) -> ActionResult:
 if state.requests.has(request):return _duplicate(request,loan_id)
 var loan: Dictionary=state.loans.get(loan_id,{})
 if loan.is_empty() or request.is_empty():return _fail("loan_unavailable")
 var amount := int(loan.principal)-int(loan.paid)
 if amount<=0:return _fail("nothing_due")
 if wallet<amount:return ActionResult.failure(ActionResult.Code.INSUFFICIENT_FUNDS,&"insufficient_funds")
 var candidate := state.duplicate(true)
 candidate.loans[loan_id].paid=int(loan.principal)
 candidate.budget_minor=int(candidate.budget_minor)+amount
 var receipt := _receipt(candidate,request,loan_id,"loan_repaid",-amount,wallet,loan_id)
 return ActionResult.success({"state":candidate,"receipt":receipt,"cash_delta":-amount})
func _receipt(candidate: Dictionary, request: String, source: String, kind: String, delta: int, wallet: int, agreement: String) -> Dictionary:
 var id := "commit_receipt_%d" % int(candidate.next_receipt)
 candidate.next_receipt=int(candidate.next_receipt)+1
 var receipt := {"id":id,"source":source,"request_id":request,"kind":kind,"agreement":agreement,"cash_delta":delta,"wallet_before":wallet,"wallet_after":wallet+delta,"at":_session.clock.world_minutes,"creditor":"abdul_karim"}
 candidate.receipts[id]=receipt
 candidate.requests[request]=id
 return receipt
func _duplicate(request: String, source: String) -> ActionResult:
 var receipt: Dictionary=state.receipts[state.requests[request]]
 return ActionResult.success({"duplicate":true,"receipt":receipt.duplicate(true)}) if receipt.source==source else _fail("stale_financial_offer")
func snapshot() -> Dictionary:
 return state.duplicate(true)
func restore(data: Dictionary) -> ActionResult:
 var result := validate_state(data)
 if result.ok:state=data.duplicate(true)
 return result
func validate_state(data: Dictionary) -> ActionResult:
 for key in ["offers","loans","promises","moments","receipts","requests"]:
  if not data.get(key) is Dictionary:return _fail("invalid_commitments")
 for key in ["next_offer","next_loan","next_promise","next_receipt"]:
  if not ContentValidation.integer(data.get(key)) or data[key]<1:return _fail("invalid_commitment_counter")
 for key in ["initial_budget","budget_minor"]:
  if not ContentValidation.integer(data.get(key)) or data[key]<0 or data[key]>10000000:return _fail("invalid_lender_budget")
 var outstanding := 0
 var active := 0
 var accepted: Dictionary={}
 var repaid: Dictionary={}
 for id in data.offers:
  var offer_data: Variant=data.offers[id]
  if not _sequence(id,"commit_offer_",data.next_offer) or not offer_data is Dictionary or offer_data.get("id")!=id or not offer_data.get("kind") in ["loan","extension"] or offer_data.get("lender")!="abdul_karim" or not offer_data.get("terms_hash") is String or not ContentValidation.bounded(offer_data.get("at"),0,_session.clock.world_minutes+0.001) or not ContentValidation.number(offer_data.get("expires")) or offer_data.expires<=offer_data.at:return _fail("invalid_commitment_offer")
  if offer_data.kind=="loan":
   if not ContentValidation.integer(offer_data.get("principal")) or offer_data.principal<1 or offer_data.principal>data.initial_budget or not ContentValidation.bounded(offer_data.get("duration"),60,43200):return _fail("invalid_loan_offer")
  elif not offer_data.get("targets") is Array or offer_data.targets.is_empty() or not ContentValidation.bounded(offer_data.get("days"),1,7) or not ContentValidation.number(offer_data.get("deadline")) or offer_data.deadline<=offer_data.at:return _fail("invalid_extension_offer")
 for id in data.loans:
  var loan: Variant=data.loans[id]
  if not _sequence(id,"loan_",data.next_loan) or not loan is Dictionary or loan.get("id")!=id or loan.get("lender")!="abdul_karim" or not data.offers.has(loan.get("offer_id")) or not ContentValidation.integer(loan.get("principal")) or not ContentValidation.integer(loan.get("paid")) or loan.paid<0 or loan.paid>loan.principal:return _fail("invalid_loan")
  var offer_data: Dictionary=data.offers[loan.offer_id]
  if offer_data.kind!="loan" or loan.principal!=offer_data.principal or not ContentValidation.bounded(loan.get("accepted_at"),offer_data.at,minf(_session.clock.world_minutes+0.001,float(offer_data.expires))) or loan.get("due_at")!=float(loan.accepted_at)+float(offer_data.duration):return _fail("invalid_loan_terms")
  if not loan.get("repaired") is bool or not loan.get("status") in ["pending","fulfilled","broken"] or not ContentValidation.bounded(loan.get("assessed_at"),-1,_session.clock.world_minutes+0.001):return _fail("invalid_loan_assessment")
  if loan.status=="pending" and loan.assessed_at!=-1 or loan.status=="fulfilled" and (loan.paid!=loan.principal or loan.assessed_at<loan.accepted_at) or loan.status=="broken" and loan.assessed_at<loan.due_at:return _fail("invalid_loan_assessment")
  outstanding+=int(loan.principal)-int(loan.paid)
  if loan.principal>loan.paid:active+=1
 if active>1 or int(data.budget_minor)+outstanding!=int(data.initial_budget):return _fail("invalid_lender_budget")
 for id in data.promises:
  var p: Variant=data.promises[id]
  if not _sequence(id,"promise_",data.next_promise) or not p is Dictionary or p.get("id")!=id or p.get("kind")!="housing" or p.get("creditor")!="abdul_karim" or not data.offers.has(p.get("offer_id")) or not p.get("status") in ["pending","superseded","fulfilled","broken"] or not p.get("repaired") is bool:return _fail("invalid_promise")
  var offer_data: Dictionary=data.offers[p.offer_id]
  if offer_data.kind!="extension" or StableJson.stringify(p.get("targets"))!=StableJson.stringify(offer_data.targets) or p.get("deadline")!=offer_data.deadline or not ContentValidation.bounded(p.get("accepted_at"),offer_data.at,minf(float(offer_data.expires),_session.clock.world_minutes+0.001)):return _fail("invalid_promise_terms")
  for target in p.targets:
   if not _session.accounts.state.obligations.has(target):return _fail("orphan_promise")
  if not ContentValidation.bounded(p.get("assessed_at"),-1,_session.clock.world_minutes+0.001):return _fail("invalid_promise_assessment")
  if p.status in ["pending","superseded"] and p.assessed_at!=-1 or p.status in ["fulfilled","broken"] and p.assessed_at<p.accepted_at:return _fail("invalid_promise_assessment")
  if p.status=="broken" and p.assessed_at<p.deadline:return _fail("premature_promise_breach")
 for id in data.receipts:
  var receipt: Variant=data.receipts[id]
  if not _sequence(id,"commit_receipt_",data.next_receipt) or not receipt is Dictionary or receipt.get("id")!=id or not receipt.get("kind") in ["loan_accepted","loan_repaid","extension_accepted"] or not receipt.get("request_id") is String or data.requests.get(receipt.request_id)!=id or receipt.get("creditor")!="abdul_karim" or not ContentValidation.bounded(receipt.get("at"),0,_session.clock.world_minutes+0.001):return _fail("invalid_commitment_receipt")
  for key in ["cash_delta","wallet_before","wallet_after"]:
   if not ContentValidation.integer(receipt.get(key)):return _fail("invalid_commitment_cash")
  if receipt.wallet_before<0 or receipt.wallet_after<0 or receipt.wallet_after-receipt.wallet_before!=receipt.cash_delta:return _fail("invalid_commitment_cash")
  if receipt.kind=="extension_accepted":
   if receipt.cash_delta!=0 or not data.promises.has(receipt.get("agreement")) or receipt.get("source")!=data.promises[receipt.agreement].offer_id:return _fail("invalid_commitment_receipt")
  else:
   if receipt.kind=="loan_accepted":
    if accepted.has(receipt.agreement):return _fail("duplicate_loan_receipt")
    accepted[receipt.agreement]=true
   else:
    if repaid.has(receipt.agreement):return _fail("duplicate_loan_receipt")
    repaid[receipt.agreement]=true
   if not data.loans.has(receipt.get("agreement")):return _fail("orphan_loan_receipt")
   var loan: Dictionary=data.loans[receipt.agreement]
   if receipt.kind=="loan_accepted" and (receipt.source!=loan.offer_id or receipt.cash_delta!=loan.principal) or receipt.kind=="loan_repaid" and (receipt.source!=loan.id or receipt.cash_delta!=-int(loan.paid)):return _fail("invalid_loan_receipt")
 for id in data.loans:
  if not accepted.has(id) or (int(data.loans[id].paid)>0)!=repaid.has(id):return _fail("missing_loan_receipt")
 for id in data.moments:
  var moment: Variant=data.moments[id]
  if not id is String or not moment is Dictionary or not ContentValidation.bounded(moment.get("at"),0,_session.clock.world_minutes) or not moment.get("source") is String or not moment.get("repair") is bool:return _fail("invalid_personal_moment")
  if not moment.repair and id!="about:%d" % (floori(float(moment.at)/1440.0)+1):return _fail("invalid_personal_moment")
 if data.requests.size()!=data.receipts.size():return _fail("invalid_commitment_requests")
 return ActionResult.success()
func _sequence(id: String, prefix: String, limit: int) -> bool:
 var suffix := id.trim_prefix(prefix)
 return id.begins_with(prefix) and suffix.is_valid_int() and int(suffix)>0 and suffix==str(int(suffix)) and int(suffix)<limit
func _fail(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,StringName(key))
