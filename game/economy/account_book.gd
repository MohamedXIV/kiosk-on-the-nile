class_name AccountBook
extends RefCounted
signal changed
var _session: GameSession
var _data: Dictionary
var state: Dictionary={}
func configure(session: GameSession) -> void:
 _session=session
 _data=session.config.section("accounts")
 state=initial_state(_data,session.clock.world_minutes)
static func initial_state(data: Dictionary, now: float) -> Dictionary:
 var result := {"activated_at":now,"chapters":{},"leases":{},"obligations":{},"coverage":{},"receipts":{},"requests":{},"quotes":{},"next_quote":1,"next_receipt":1}
 for id in data.leases:
  var lease: Dictionary=data.leases[id].duplicate(true)
  lease["creditor_name"]=str(data.creditors[lease.creditor].name)
  lease["first_start"]=ceil((now-float(lease.due_minute))/1440.0)*1440.0+float(lease.due_minute)
  result.leases[id]=lease
 return result
func period(lease_id: String, index: int, source: Dictionary = {}) -> Dictionary:
 var data: Dictionary=state if source.is_empty() else source
 var lease: Dictionary=data.leases.get(lease_id,{})
 if lease.is_empty() or index<0:return {}
 var start := float(lease.first_start)+index*float(lease.period_minutes)
 return {"id":"%s/%d" % [lease_id,index],"lease":lease_id,"period":index,"start":start,"end":start+float(lease.period_minutes)}
func tick(_frame: Dictionary) -> ActionResult:
 for id in state.leases:
  var lease: Dictionary=state.leases[id]
  var count := maxi(0,floori((_session.clock.world_minutes-float(lease.first_start))/float(lease.period_minutes)))
  for index in range(count):
   var p := period(id,index)
   if state.obligations.has(p.id):continue
   p.merge({"creditor":lease.creditor,"creditor_name":lease.creditor_name,"label":lease.label,"gross":int(lease.nominal_minor),"paid":int(lease.nominal_minor) if state.coverage.has(p.id) else 0,"due_at":p.end,"enforce_at":float(p.end)+float(lease.grace_minutes)})
   state.obligations[p.id]=p
 return ActionResult.success()
func business_allowed() -> bool:
 for bill in state.obligations.values():
  if state.leases[bill.lease].suspends_business and int(bill.paid)<int(bill.gross) and _session.clock.world_minutes>=float(bill.enforce_at):return false
 return true
func outstanding(creditor: String) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for bill in state.obligations.values():
  if bill.creditor==creditor and int(bill.paid)<int(bill.gross):result.append(bill.duplicate(true))
 result.sort_custom(func(a,b):return float(a.due_at)<float(b.due_at))
 return result
func remaining(id: String) -> int:
 var bill: Dictionary=state.obligations.get(id,{})
 if not bill.is_empty():return int(bill.gross)-int(bill.paid)
 var p := resolve_period(id)
 if p.is_empty() or state.coverage.has(id):return 0
 return int(state.leases[p.lease].nominal_minor)
func quote(lease_id: String, offer_id: String, at: float, amount: int = 0) -> ActionResult:
 tick({})
 if not state.leases.has(lease_id) or absf(at-_session.clock.world_minutes)>0.01:return _fail("account_unavailable")
 var lease: Dictionary=state.leases[lease_id]
 var lines: Array=[]
 if offer_id in ["settle","partial"]:
  var budget := amount if offer_id=="partial" else 9223372036854775807
  if offer_id=="partial" and (not lease.allow_partial or amount<1):return _fail("partial_unavailable")
  for bill in outstanding(str(lease.creditor)):
   if bill.lease!=lease_id:continue
   var credit := mini(int(bill.gross)-int(bill.paid),budget)
   if credit<=0:break
   var p := period(lease_id,int(bill.period))
   p.merge({"gross":credit,"discount":0,"net":credit,"credit":credit,"prepaid":false,"remaining_at_quote":int(bill.gross)-int(bill.paid)})
   lines.append(p)
   budget-=credit
 else:
  if lease_id!="kiosk_lease" or not _data.advance_offers.has(offer_id):return _fail("account_offer_unavailable")
  var offer: Dictionary=_data.advance_offers[offer_id]
  var index := maxi(0,floori((at-float(lease.first_start))/float(lease.period_minutes))+1)
  while state.coverage.has(period(lease_id,index).id):index+=1
  for offset in range(int(offer.periods)):
   var p := period(lease_id,index+offset)
   if state.coverage.has(p.id) or state.obligations.has(p.id) or float(p.start)<=at:return _fail("coverage_overlap")
   var gross := int(lease.nominal_minor)
   var discount := gross*int(offer.discount_percent)/100
   p.merge({"gross":gross,"discount":discount,"net":gross-discount,"credit":gross,"prepaid":true,"remaining_at_quote":0})
   lines.append(p)
 if lines.is_empty():return _fail("nothing_due")
 var id := "account_quote_%d" % int(state.next_quote)
 state.next_quote=int(state.next_quote)+1
 var total := 0
 for line in lines:total+=int(line.net)
 var terms: Dictionary=_data.advance_offers.get(offer_id,{"periods":0,"discount_percent":0}).duplicate(true)
 terms["mode"]="advance" if offer_id not in ["settle","partial"] else offer_id
 terms["amount"]=amount if offer_id=="partial" else 0
 var quote_data := {"terms":terms,"id":id,"lease":lease_id,"creditor":lease.creditor,"creditor_name":lease.creditor_name,"version":lease.version,"offer":offer_id,"offer_hash":StableJson.stringify(_data.advance_offers).sha256_text(),"at":at,"expires":at+float(_data.quote_minutes),"lines":lines,"net":total}
 state.quotes[id]=quote_data
 return ActionResult.success({"quote":quote_data.duplicate(true)})
func prepare_payment(quote_id: String, request_id: String, wallet_before: int) -> ActionResult:
 if state.requests.has(request_id):
  var old: Dictionary=state.receipts[state.requests[request_id]]
  return ActionResult.success({"duplicate":true,"receipt":old.duplicate(true)}) if old.quote_id==quote_id else _fail("stale_account_quote")
 var q: Dictionary=state.quotes.get(quote_id,{})
 if request_id.is_empty() or q.is_empty() or _session.clock.world_minutes>float(q.expires) or q.version!=state.leases[q.lease].version or q.offer_hash!=StableJson.stringify(_data.advance_offers).sha256_text():return _fail("stale_account_quote")
 if wallet_before<int(q.net):return ActionResult.failure(ActionResult.Code.INSUFFICIENT_FUNDS,&"insufficient_funds")
 var candidate := state.duplicate(true)
 var receipt_id := "account_receipt_%d" % int(candidate.next_receipt)
 for line in q.lines:
  if line.prepaid:
   if candidate.coverage.has(line.id) or candidate.obligations.has(line.id) or _session.clock.world_minutes>=float(line.start):return _fail("coverage_overlap")
   candidate.coverage[line.id]=receipt_id
  else:
   if not candidate.obligations.has(line.id) or remaining(line.id)!=int(line.remaining_at_quote) or int(line.credit)>remaining(line.id):return _fail("stale_account_quote")
   candidate.obligations[line.id].paid=int(candidate.obligations[line.id].paid)+int(line.credit)
 var receipt := {"id":receipt_id,"quote_id":quote_id,"request_id":request_id,"creditor":q.creditor,"creditor_name":q.creditor_name,"lease":q.lease,"lines":q.lines.duplicate(true),"net":int(q.net),"at":_session.clock.world_minutes,"wallet_before":wallet_before,"wallet_after":wallet_before-int(q.net)}
 candidate.receipts[receipt_id]=receipt
 candidate.requests[request_id]=receipt_id
 candidate.next_receipt=int(candidate.next_receipt)+1
 return ActionResult.success({"state":candidate,"receipt":receipt})
func summary(from_at: float, to_at: float) -> Dictionary:
 var rows: Array=[]
 for bill in state.obligations.values():
  if remaining(bill.id)>0:rows.append(bill.duplicate(true))
 for id in state.leases:
  var lease: Dictionary=state.leases[id]
  var first := maxi(0,floori((from_at-float(lease.first_start))/float(lease.period_minutes)))
  for i in range(first,first+3):
   var p := period(id,i)
   if float(p.end)>to_at or state.obligations.has(p.id):continue
   p.merge({"creditor":lease.creditor,"creditor_name":lease.creditor_name,"label":lease.label,"gross":int(lease.nominal_minor),"paid":int(lease.nominal_minor) if state.coverage.has(p.id) else 0,"due_at":p.end,"enforce_at":float(p.end)+float(lease.grace_minutes)})
   rows.append(p)
 rows.sort_custom(func(a,b):return float(a.due_at)<float(b.due_at))
 return {"rows":rows,"receipts":state.receipts.values().duplicate(true),"business_allowed":business_allowed()}
func snapshot() -> Dictionary:
 return state.duplicate(true)
func restore(data: Dictionary) -> ActionResult:
 var result := validate_state(data)
 if result.ok:state=data.duplicate(true)
 return result
func validate_state(data: Dictionary) -> ActionResult:
 for key in ["chapters","leases","obligations","coverage","receipts","requests","quotes"]:
  if not data.get(key) is Dictionary:return _fail("invalid_account_state")
 for key in ["next_quote","next_receipt"]:
  if not ContentValidation.integer(data.get(key)) or data[key]<1:return _fail("invalid_account_counter")
 if data.leases.keys().size()!=_data.leases.size():return _fail("invalid_leases")
 for id in data.leases:
  var lease: Variant=data.leases[id]
  if not _data.leases.has(id) or not AccountValidation.lease_valid(lease,_data.creditors) or not ContentValidation.number(lease.get("first_start")) or lease.first_start<0 or not lease.get("creditor_name") is String:return _fail("invalid_lease")
 if not ContentValidation.bounded(data.get("activated_at"),0,_session.clock.world_minutes+0.001):return _fail("invalid_account_activation")
 for id in data.leases:
  var lease: Dictionary=data.leases[id]
  var expected_start: float=ceilf((float(data.activated_at)-float(lease.due_minute))/1440.0)*1440.0+float(lease.due_minute)
  if lease.first_start!=expected_start or lease.creditor!=("abdul_karim" if id=="housing_lease" else "district") or lease.suspends_business!=(id=="kiosk_lease"):return _fail("invalid_lease_identity")
  var count := maxi(0,floori((_session.clock.world_minutes-float(lease.first_start))/float(lease.period_minutes)))
  if count>100000:return _fail("invalid_account_calendar")
  for index in range(count):
   if not data.obligations.has(period(id,index,data).id):return _fail("missing_obligation")
 var credits: Dictionary={}
 var prepaid: Dictionary={}
 for id in data.quotes:
  var q: Variant=data.quotes[id]
  if not _sequence(id,"account_quote_",int(data.next_quote)) or not q is Dictionary or q.get("id")!=id or not data.leases.has(q.get("lease")) or q.get("creditor")!=data.leases[q.lease].creditor or not q.get("creditor_name") is String or q.get("version")!=data.leases[q.lease].version or not q.get("lines") is Array or q.lines.is_empty() or not ContentValidation.bounded(q.get("at"),0,_session.clock.world_minutes+0.001) or not ContentValidation.number(q.get("expires")) or q.expires<=q.at or not q.get("offer_hash") is String or not q.get("offer") is String:return _fail("invalid_account_quote")
  if not q.get("terms") is Dictionary or not q.terms.get("mode") in ["advance","settle","partial"] or not ContentValidation.integer(q.terms.get("periods")) or not ContentValidation.bounded(q.terms.get("periods"),0,12) or not ContentValidation.integer(q.terms.get("discount_percent")) or not ContentValidation.bounded(q.terms.discount_percent,0,50):return _fail("invalid_account_terms")
  if q.terms.mode=="advance":
   if q.lease!="kiosk_lease" or q.terms.periods<1 or q.lines.size()!=int(q.terms.periods):return _fail("invalid_advance_terms")
  elif q.offer!=q.terms.mode or q.terms.periods!=0 or q.terms.discount_percent!=0 or (q.offer=="partial" and not data.leases[q.lease].allow_partial):return _fail("invalid_settlement_terms")
  var total := 0
  var seen: Dictionary={}
  for line in q.lines:
   if not _line_valid(line,q.lease,data) or seen.has(line.id):return _fail("invalid_account_line")
   if line.prepaid!=(q.terms.mode=="advance") or int(line.discount)!=int(line.gross)*int(q.terms.discount_percent)/100:return _fail("invalid_account_discount")
   if q.offer=="settle" and line.credit!=line.remaining_at_quote:return _fail("invalid_settlement_terms")
   if line.prepaid and (line.start<=q.at or int(line.period)!=int(q.lines[0].period)+seen.size()):return _fail("invalid_advance_periods")
   seen[line.id]=true
   total+=int(line.net)
  if not ContentValidation.integer(q.get("net")) or total!=int(q.net):return _fail("invalid_account_total")
 for id in data.chapters:
  var chapter: Variant=data.chapters[id]
  if not id is String or not str(id).begins_with("conversation_") or not str(id).trim_prefix("conversation_").is_valid_int() or not chapter is Dictionary or chapter.get("id")!=id or not chapter.get("extension_targets") is Array:return _fail("invalid_financial_chapter")
  for key in ["pay_quote","partial_quote","loan_id"]:
   if not chapter.get(key) is String:return _fail("invalid_financial_chapter")
  for key in ["pay_quote","partial_quote"]:
   if chapter[key].is_empty():continue
   var q: Dictionary=data.quotes.get(chapter[key],{})
   if q.is_empty() or q.lease!="housing_lease" or q.get("chapter")!=id:return _fail("invalid_financial_chapter")
  for target in chapter.extension_targets:
   if not target is String or not target.begins_with("housing_lease/") or not target.get_slice("/",1).is_valid_int():return _fail("invalid_financial_target")
 for id in data.receipts:
  var receipt: Variant=data.receipts[id]
  if not _sequence(id,"account_receipt_",int(data.next_receipt)) or not receipt is Dictionary or receipt.get("id")!=id or not data.quotes.has(receipt.get("quote_id")) or not receipt.get("request_id") is String or data.requests.get(receipt.request_id)!=id:return _fail("invalid_account_receipt")
  var q: Dictionary=data.quotes[receipt.quote_id]
  if receipt.get("creditor")!=q.creditor or receipt.get("lease")!=q.lease or receipt.get("creditor_name")!=q.creditor_name or receipt.get("net")!=q.net or StableJson.stringify(receipt.get("lines"))!=StableJson.stringify(q.lines) or not ContentValidation.bounded(receipt.get("at"),q.at,minf(_session.clock.world_minutes+0.001,float(q.expires))):return _fail("invalid_account_receipt")
  if not ContentValidation.integer(receipt.get("wallet_before")) or not ContentValidation.integer(receipt.get("wallet_after")) or receipt.wallet_after<0 or receipt.wallet_before-receipt.wallet_after!=receipt.net:return _fail("invalid_account_cash")
  for line in receipt.lines:
   if line.prepaid:
    if prepaid.has(line.id) or receipt.at>=line.start:return _fail("duplicate_coverage")
    prepaid[line.id]=id
   else:credits[line.id]=int(credits.get(line.id,0))+int(line.credit)
 if StableJson.stringify(prepaid)!=StableJson.stringify(data.coverage) or data.requests.size()!=data.receipts.size():return _fail("invalid_coverage_receipts")
 for id in data.obligations:
  var bill: Variant=data.obligations[id]
  if not bill is Dictionary or bill.get("id")!=id or not data.leases.has(bill.get("lease")) or not ContentValidation.integer(bill.get("period")):return _fail("invalid_obligation")
  var p := period(bill.lease,int(bill.period),data)
  var lease: Dictionary=data.leases[bill.lease]
  if p.is_empty() or p.id!=id or bill.get("start")!=p.start or bill.get("end")!=p.end or bill.get("due_at")!=p.end or p.end>_session.clock.world_minutes+0.001 or bill.get("enforce_at")!=float(p.end)+float(lease.grace_minutes) or bill.get("gross")!=lease.nominal_minor or bill.get("creditor")!=lease.creditor or not ContentValidation.integer(bill.get("paid")) or bill.paid<0 or bill.paid>bill.gross:return _fail("invalid_obligation")
  var paid := int(lease.nominal_minor) if prepaid.has(id) else int(credits.get(id,0))
  if bill.paid!=paid:return _fail("invalid_obligation_receipts")
 for id in credits:
  if not data.obligations.has(id):return _fail("orphan_payment")
 return ActionResult.success()
func _line_valid(line: Variant, lease_id: String, data: Dictionary) -> bool:
 if not line is Dictionary or not ContentValidation.integer(line.get("period")) or line.period<0 or not line.get("prepaid") is bool:return false
 var p := period(lease_id,int(line.period),data)
 if line.get("id")!=p.id or line.get("lease")!=lease_id or line.get("start")!=p.start or line.get("end")!=p.end:return false
 for key in ["gross","discount","net","credit","remaining_at_quote"]:
  if not ContentValidation.integer(line.get(key)) or line[key]<0:return false
 return line.gross>0 and line.net==line.gross-line.discount and line.net>0 and line.credit==line.gross and (line.prepaid and line.gross==data.leases[lease_id].nominal_minor or not line.prepaid and line.discount==0 and line.credit<=line.remaining_at_quote)
func _sequence(id: String, prefix: String, limit: int) -> bool:
 var suffix := id.trim_prefix(prefix)
 return id.begins_with(prefix) and suffix.is_valid_int() and int(suffix)>0 and suffix==str(int(suffix)) and int(suffix)<limit
func _fail(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,StringName(key))

func resolve_period(id: String) -> Dictionary:
 var parts := id.split("/")
 if parts.size()!=2 or not state.leases.has(parts[0]) or not parts[1].is_valid_int() or int(parts[1])<0 or parts[1]!=str(int(parts[1])):return {}
 return period(parts[0],int(parts[1]))
func housing_targets() -> Array:
 var targets: Array=[]
 for bill in outstanding("abdul_karim"):targets.append(str(bill.id))
 if not targets.is_empty():return targets
 var lease: Dictionary=state.leases.housing_lease
 var index := maxi(0,floori((_session.clock.world_minutes-float(lease.first_start))/float(lease.period_minutes)))
 var p := period("housing_lease",index)
 if remaining(p.id)>0:targets.append(p.id)
 return targets
