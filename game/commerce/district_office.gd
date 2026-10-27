class_name DistrictOffice
extends RefCounted
var _session: GameSession
var state: Dictionary={"journey_id":"","quote_id":"","request_id":"","last_receipt":""}
func configure(session: GameSession) -> void:
 _session=session
func available() -> bool:
 return _session.location_id==&"district" and _session.travel.journey.data.get("route_id")=="district" and _session.travel.journey.data.get("phase")=="browsing"
func open() -> ActionResult:
 if not available():return _fail()
 var id := str(_session.travel.journey.data.id)
 if state.journey_id!=id:state={"journey_id":id,"quote_id":"","request_id":"","last_receipt":""}
 return ActionResult.success()
func journey_context() -> ActionResult:
 return open()
func quote(offer: String) -> ActionResult:
 if not open().ok:return _fail()
 var result := _session.accounts.quote("kiosk_lease",offer,_session.clock.world_minutes)
 state.quote_id="";state.request_id=""
 if result.ok:
  state.quote_id=str(result.details.quote.id)
  state.request_id="district:"+str(state.journey_id)+":"+str(state.quote_id)
 return result
func pay() -> ActionResult:
 if not available() or state.quote_id.is_empty():return _fail()
 var result := _session.finance.pay(state.quote_id,state.request_id)
 if result.ok:state.last_receipt=str(result.details.receipt.id)
 return result
func snapshot() -> Dictionary:
 return state.duplicate(true)
func restore(data: Dictionary) -> ActionResult:
 for key in ["journey_id","quote_id","request_id","last_receipt"]:
  if not data.get(key) is String:return _fail()
 if not data.quote_id.is_empty():
  var q: Dictionary=_session.accounts.state.quotes.get(data.quote_id,{})
  if q.is_empty() or q.lease!="kiosk_lease" or data.request_id!="district:"+str(data.journey_id)+":"+str(data.quote_id):return _fail()
 if not data.last_receipt.is_empty() and not _session.accounts.state.receipts.has(data.last_receipt):return _fail()
 state=data.duplicate()
 return ActionResult.success()
func _fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"district_unavailable")
