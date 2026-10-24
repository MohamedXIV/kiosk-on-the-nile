class_name SupplierLedger
extends RefCounted
static func initial_state() -> Dictionary:return {"prepaid":0,"receipts":{},"invoices":{},"requests":{},"next_receipt":1}
static func remaining(data: Dictionary, emergency_only: bool = false) -> int:
 var total := 0
 for invoice in data.invoices.values():
  if not emergency_only or invoice.emergency:total+=int(invoice.total)-int(invoice.paid)
 return total
static func receipt(data: Dictionary, request: String, kind: String, at: float, wallet: int, delta: int, prepaid_delta: int, detail: Dictionary) -> Dictionary:
 var id := "supply_receipt_%d" % int(data.next_receipt);data.next_receipt=int(data.next_receipt)+1
 var r := {"id":id,"request":request,"kind":kind,"at":at,"wallet_before":wallet,"wallet_after":wallet+delta,"wallet_delta":delta,"prepaid_delta":prepaid_delta,"detail":detail.duplicate(true)}
 data.prepaid=int(data.prepaid)+prepaid_delta;data.receipts[id]=r;data.requests[request]=id
 return r
static func validate(data: Variant, now: float) -> ActionResult:
 if not data is Dictionary or not data.get("receipts") is Dictionary or not data.get("invoices") is Dictionary or not data.get("requests") is Dictionary or not ContentValidation.integer(data.get("prepaid")) or data.prepaid<0 or not ContentValidation.integer(data.get("next_receipt")) or data.next_receipt<1:return _fail()
 var prepaid := 0
 var paid: Dictionary={}
 var origins: Dictionary={}
 for id in data.receipts:
  var r: Variant=data.receipts[id]
  if not r is Dictionary or r.get("id")!=id or not str(id).begins_with("supply_receipt_") or not str(id).trim_prefix("supply_receipt_").is_valid_int() or int(str(id).trim_prefix("supply_receipt_"))>=data.next_receipt or not r.get("request") is String or data.requests.get(r.request)!=id or not r.get("kind") in ["deposit","settlement","delivery"] or not ContentValidation.bounded(r.get("at"),0,now+0.001) or not r.get("detail") is Dictionary or not r.get("journal_text") is String:return _fail()
  for key in ["wallet_before","wallet_after","wallet_delta","prepaid_delta"]:
   if not ContentValidation.integer(r.get(key)):return _fail()
  if r.wallet_before<0 or r.wallet_after<0 or r.wallet_after-r.wallet_before!=r.wallet_delta:return _fail()
  prepaid+=int(r.prepaid_delta)
  if r.kind=="deposit":
   if r.wallet_delta>=0 or r.prepaid_delta!=-int(r.wallet_delta):return _fail()
  elif r.kind=="settlement":
   if r.wallet_delta>=0 or r.prepaid_delta!=0 or not r.detail.get("payments") is Dictionary:return _fail()
   var total := 0
   for bill in r.detail.payments:
    var amount: Variant=r.detail.payments[bill]
    if not ContentValidation.integer(amount) or amount<1:return _fail()
    paid[bill]=int(paid.get(bill,0))+int(amount);total+=int(amount)
   if total!=-int(r.wallet_delta):return _fail()
  else:
   var d: Dictionary=r.detail
   if not d.get("occurrence") is String or origins.has(d.occurrence) or not d.get("mode") in ["prepaid","credit","cash"] or not d.get("name") is String:return _fail()
   origins[d.occurrence]=id
   for key in ["goods_minor","fee_minor","total_minor"]:
    if not ContentValidation.integer(d.get(key)) or d[key]<0:return _fail()
   if d.total_minor<=0 or d.total_minor!=d.goods_minor+d.fee_minor:return _fail()
   if d.mode=="prepaid" and (r.wallet_delta!=0 or r.prepaid_delta!=-int(d.total_minor)):return _fail()
   if d.mode=="cash" and (r.wallet_delta!=-int(d.total_minor) or r.prepaid_delta!=0):return _fail()
   if d.mode=="credit":
    if r.wallet_delta!=0 or r.prepaid_delta!=0 or not data.invoices.has(d.occurrence):return _fail()
   elif data.invoices.has(d.occurrence):return _fail()
 if prepaid!=int(data.prepaid) or data.requests.size()!=data.receipts.size():return _fail()
 for id in data.invoices:
  var bill: Variant=data.invoices[id]
  if not bill is Dictionary or bill.get("id")!=id or not origins.has(id) or not ContentValidation.integer(bill.get("total")) or not ContentValidation.integer(bill.get("paid")) or bill.paid<0 or bill.paid>bill.total or int(paid.get(id,0))!=int(bill.paid) or not bill.get("emergency") is bool or not bill.get("name") is String or not ContentValidation.number(bill.get("due_at")):return _fail()
  var r: Dictionary=data.receipts[origins[id]]
  if r.detail.mode!="credit" or bill.total!=r.detail.total_minor or bill.name!=r.detail.name or bill.get("at")!=r.at or bill.due_at<=r.at:return _fail()
 for id in paid:
  if not data.invoices.has(id):return _fail()
 return ActionResult.success()
static func _fail() -> ActionResult:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_supplier_ledger")
