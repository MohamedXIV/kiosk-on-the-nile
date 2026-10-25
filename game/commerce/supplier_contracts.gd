class_name SupplierContracts
extends RefCounted
var _session: GameSession
var state: Dictionary={}
var revision: int=0
static func initial_state() -> Dictionary:return {"emergency_quotes":{},"quotes":{},"versions":{},"requests":{},"active":"","next_quote":1,"next_contract":1}
func configure(session: GameSession) -> void:_session=session;state=initial_state()
func quote(terms: Dictionary) -> ActionResult:
 if not _session.contact.available():return _fail("supplier_contact_required")
 var data := _session.config.section("suppliers")
 var lines: Array=[]
 var total := 0
 for id in terms.get("basket",{}):
  var qty: Variant=terms.basket[id]
  if not data.catalog.has(id) or not ContentValidation.integer(qty) or qty<1 or qty>int(data.catalog[id].daily_stock):return _fail("invalid_supplier_basket")
  var price := int(data.catalog[id].price_minor)
  lines.append({"definition_id":id,"quantity":int(qty),"unit_minor":price});total+=int(qty)*price
 if lines.is_empty():return _fail("invalid_supplier_basket")
 lines.sort_custom(func(a,b):return str(a.definition_id)<str(b.definition_id))
 var destination := destination_snapshot(str(terms.get("destination","")))
 if destination.is_empty() or not basket_fits(lines,destination,false):return _fail("supplier_storage_invalid")
 var days: Array=[]
 for value in terms.get("weekdays",[]):
  if not ContentValidation.integer(value) or value<0 or value>6 or days.has(int(value)):return _fail("invalid_supplier_schedule")
  days.append(int(value))
 days.sort()
 if days.is_empty() or not ContentValidation.integer(terms.get("minute")) or terms.minute<0 or terms.minute>=1440 or not terms.get("leave_goods") is bool or not terms.get("mode") in ["prepaid","credit","cash"] or not terms.get("once",false) is bool:return _fail("invalid_supplier_schedule")
 var id := "supply_quote_%d" % int(state.next_quote)
 var q := {"id":id,"at":_session.clock.world_minutes,"expires":_session.clock.world_minutes+float(data.quote_minutes),"supplier":"fathi","name":str(_session.presence.profile(&"fathi").name),"lines":lines,"goods_minor":total,"fee_minor":int(data.fee_minor),"total_minor":total+int(data.fee_minor),"destination":destination,"weekdays":days,"minute":int(terms.minute),"leave_goods":bool(terms.leave_goods),"mode":str(terms.mode),"credit_cap":int(data.credit_cap_minor),"due_minutes":float(data.invoice_due_minutes),"once":bool(terms.get("once",false)),"extra_delay":float(data.extra_delay_minutes),"cash_wait":float(data.cash_wait_minutes),"content_hash":StableJson.stringify(data).sha256_text()}
 state.next_quote=int(state.next_quote)+1;state.quotes[id]=q
 return ActionResult.success({"quote":q.duplicate(true)})
func destination_snapshot(id: String) -> Dictionary:
 var c := _session.items.get_container(StringName(id))
 if c.is_empty() or not c.kind in ["dry","cold"] or not _session.locations.is_physical(StringName(c.location_id)):return {}
 var host := str(c.host_id)
 var ground: Array=[]
 if not host.is_empty():
  var p := _session.spaces.placement(StringName(host))
  if p.is_empty() or p.location_id!=c.location_id or _session.items.get_item(StringName(host)).get("container_id")!=str(c.location_id)+"_world":return {}
  var g := _session.spaces.ground(StringName(host));ground=[g.x,g.y]
 return {"id":id,"host_id":host,"location_id":str(c.location_id),"kind":str(c.kind),"ground":ground}
func destination_valid(d: Dictionary) -> bool:return not d.is_empty() and StableJson.stringify(destination_snapshot(str(d.get("id",""))))==StableJson.stringify(d)
func basket_fits(lines: Array, destination: Dictionary, current: bool = true) -> bool:
 var c := _session.items.get_container(StringName(str(destination.get("id",""))))
 if c.is_empty():return false
 var needed := 0
 for line in lines:
  var d := _session.items.definition(StringName(str(line.definition_id)))
  if d.get("required_storage","dry")!=c.kind or not str(d.get("kind","")) in c.allowed_tags:return false
  needed+=int(line.quantity)
 if current:
  for item in _session.items.items_in(StringName(c.id)):needed+=int(item.quantity)
 return needed<=int(c.capacity)
func accept(quote_id: String, request_id: String) -> ActionResult:return _sign(quote_id,request_id,"")
func amend(contract_id: String, quote_id: String, request_id: String) -> ActionResult:
 if state.active=="" or not state.versions.has(state.active) or state.versions[state.active].contract_id!=contract_id:return _fail("stale_supplier_quote")
 return _sign(quote_id,request_id,contract_id)
func _sign(quote_id: String, request_id: String, existing: String) -> ActionResult:
 if state.requests.has(request_id):return ActionResult.success({"duplicate":true}) if state.requests[request_id].source==quote_id else _fail("stale_supplier_quote")
 var q: Dictionary=state.quotes.get(quote_id,{})
 if not _session.contact.available() or request_id.is_empty() or q.is_empty() or _session.clock.world_minutes>float(q.expires) or q.content_hash!=StableJson.stringify(_session.config.section("suppliers")).sha256_text() or not destination_valid(q.destination) or not basket_fits(q.lines,q.destination,false):return _fail("stale_supplier_quote")
 # Process everything due under the old signed version before closing its window.
 var caught := _session.deliveries.tick({})
 if not caught.ok:return caught
 var candidate := state.duplicate(true)
 var now := _session.clock.world_minutes
 var contract_id := existing
 var version := 1
 if not q.once:
  if existing=="" and candidate.active!="":return _fail("supplier_contract_exists")
  if existing!="":
   var old: Dictionary=candidate.versions[candidate.active];old.closed_at=now;version=int(old.version)+1
 if contract_id=="":contract_id="supply_contract_%d" % int(candidate.next_contract);candidate.next_contract=int(candidate.next_contract)+1
 var id := contract_id+":v"+str(version)
 var signed: Dictionary=q.duplicate(true)
 signed.merge({"id":id,"quote_id":q.id,"contract_id":contract_id,"version":version,"accepted_at":now,"closed_at":-1.0,"first_at":now+float(q.extra_delay) if q.once else next_time(q,now)},true)
 candidate.versions[id]=signed
 if not q.once:candidate.active=id
 candidate.requests[request_id]={"source":quote_id,"version_id":id,"at":now,"kind":"sign"}
 var valid := validate_state(candidate)
 if not valid.ok:return valid
 state=candidate;revision+=1
 _session.journal.append_once({"id":"supply:agreement:"+request_id,"chapter":"supply","actor":"system","name":UiText.localized("records.supply.name",{},"دفتر التوريد".format({})),"text":UiText.localized("records.supply.agreement",{"creditor":q.name,"date":SupplierText.date(float(signed.first_at)),"goods":"%.2f" % (float(q.goods_minor)/100),"fee":"%.2f" % (float(q.fee_minor)/100)},"وافقت على اتفاق توريد مع {creditor}؛ أول موعد {date}. السلة {goods} + توصيل {fee} ج.م.".format({"creditor":q.name,"date":SupplierText.date(float(signed.first_at)),"goods":"%.2f" % (float(q.goods_minor)/100),"fee":"%.2f" % (float(q.fee_minor)/100)})),"channel":"system","at":now})
 return ActionResult.success({"version":signed.duplicate(true)})
func pause(contract_id: String, request_id: String) -> ActionResult:
 if state.requests.has(request_id):return ActionResult.success({"duplicate":true}) if state.requests[request_id].source==contract_id else _fail("stale_supplier_quote")
 if not _session.contact.available() or request_id.is_empty() or state.active=="" or state.versions[state.active].contract_id!=contract_id:return _fail("supplier_contact_required")
 var result := _session.deliveries.tick({})
 if not result.ok:return result
 var id := str(state.active)
 revision+=1
 state.versions[id].closed_at=_session.clock.world_minutes;state.active=""
 state.requests[request_id]={"source":contract_id,"version_id":id,"at":_session.clock.world_minutes,"kind":"pause"}
 _session.journal.append_once({"id":"supply:agreement:"+request_id,"chapter":"supply","actor":"system","name":UiText.localized("records.supply.name",{},"دفتر التوريد".format({})),"text":UiText.localized("records.supply.paused",{},"أوقفت الاتفاق للمواعيد التالية؛ الرصيد المقدم والإيصالات محفوظة.".format({})),"channel":"system","at":_session.clock.world_minutes})
 return ActionResult.success()
static func next_time(terms: Dictionary, after: float) -> float:
 var day := floori(after/1440.0)
 for offset in range(8):
  var d := day+offset
  var at := d*1440.0+int(terms.minute)
  if at>after+0.000001 and terms.weekdays.any(func(value):return int(value)==d%7):return at
 return -1
func snapshot() -> Dictionary:return state.duplicate(true)
func restore(data: Dictionary) -> ActionResult:
 var result := validate_state(data)
 if result.ok:state=data.duplicate(true);revision+=1
 return result
func validate_state(data: Dictionary) -> ActionResult:
 for key in ["quotes","versions","requests","emergency_quotes"]:
  if not data.get(key) is Dictionary:return _fail("invalid_supplier_contracts")
 for key in ["next_quote","next_contract"]:
  if not ContentValidation.integer(data.get(key)) or data[key]<1:return _fail("invalid_supplier_contracts")
 if not data.get("active") is String or (data.active!="" and not data.versions.has(data.active)):return _fail("invalid_supplier_contracts")
 for chapter in data.emergency_quotes:
  var e: Variant=data.emergency_quotes[chapter]
  if not str(chapter).begins_with("conversation_") or not e is Dictionary or e.get("mode")!="credit" or e.get("fee_minor")!=0 or _session.foods.definition(StringName(str(e.get("food_id","")))).is_empty() or not _session.config.section("recipes").recipes.has(e.get("recipe_id")) or not e.get("name") is String:return _fail("invalid_emergency_quote")
  for key in ["goods_minor","total_minor","emergency_cap"]:
   if not ContentValidation.integer(e.get(key)) or e[key]<1:return _fail("invalid_emergency_quote")
  if e.goods_minor!=e.total_minor or e.total_minor>e.emergency_cap or not ContentValidation.bounded(e.get("due_minutes"),60,43200):return _fail("invalid_emergency_quote")
 for id in data.quotes:
  var q: Variant=data.quotes[id]
  if not q is Dictionary or q.get("id")!=id or not str(id).begins_with("supply_quote_") or not str(id).trim_prefix("supply_quote_").is_valid_int() or int(str(id).trim_prefix("supply_quote_"))>=int(data.next_quote) or not _valid_terms(q):return _fail("invalid_supplier_quote")
 for id in data.versions:
  var v: Variant=data.versions[id]
  if not v is Dictionary or v.get("id")!=id or not data.quotes.has(v.get("quote_id")) or not ContentValidation.integer(v.get("version")) or v.version<1 or not ContentValidation.bounded(v.get("accepted_at"),data.quotes[v.quote_id].at,minf(float(data.quotes[v.quote_id].expires),_session.clock.world_minutes+0.001)) or not ContentValidation.number(v.get("first_at")) or v.first_at<=v.accepted_at or not ContentValidation.bounded(v.get("closed_at"),-1,_session.clock.world_minutes+0.001):return _fail("invalid_supplier_version")
  var q: Dictionary=data.quotes[v.quote_id]
  for key in q:
   if key=="id":continue
   if StableJson.stringify(v.get(key))!=StableJson.stringify(q[key]):return _fail("changed_supplier_terms")
  if id!=str(v.get("contract_id",""))+":v"+str(int(v.version)) or (v.closed_at>=0 and v.closed_at<v.accepted_at) or (data.active==id and (v.once or v.closed_at!=-1)):return _fail("invalid_supplier_version")
  var expected: float=float(v.accepted_at)+float(v.extra_delay) if v.once else next_time(v,float(v.accepted_at))
  if absf(float(v.first_at)-expected)>0.001:return _fail("invalid_supplier_schedule")
  if int(v.version)>1 and not data.versions.has(str(v.contract_id)+":v"+str(int(v.version)-1)):return _fail("invalid_supplier_version")
 for request in data.requests.values():
  if not request is Dictionary or not request.get("kind") in ["sign","pause"] or not data.versions.has(request.get("version_id")) or not ContentValidation.bounded(request.get("at"),0,_session.clock.world_minutes+0.001):return _fail("invalid_supplier_request")
 return ActionResult.success()
func _valid_terms(q: Dictionary) -> bool:
 if q.get("supplier")!="fathi" or not q.get("name") is String or not q.get("lines") is Array or q.lines.is_empty() or not q.get("destination") is Dictionary or not q.get("weekdays") is Array or q.weekdays.is_empty() or not q.get("mode") in ["prepaid","credit","cash"] or not q.get("leave_goods") is bool or not q.get("once") is bool:return false
 if not ContentValidation.bounded(q.get("at"),0,_session.clock.world_minutes+0.001) or not ContentValidation.number(q.get("expires")) or q.expires<=q.at or not ContentValidation.integer(q.get("minute")) or q.minute<0 or q.minute>=1440:return false
 for key in ["goods_minor","fee_minor","total_minor","credit_cap"]:
  if not ContentValidation.integer(q.get(key)) or q[key]<0:return false
 for key in ["due_minutes","extra_delay","cash_wait"]:
  if not ContentValidation.bounded(q.get(key),0.1,43200):return false
 var total := 0
 var seen: Dictionary={}
 for line in q.lines:
  if not line is Dictionary or not _session.items.definition(StringName(str(line.get("definition_id","")))).get("kind")=="ingredient" or seen.has(line.definition_id) or not ContentValidation.integer(line.get("quantity")) or not ContentValidation.bounded(line.quantity,1,100000) or not ContentValidation.integer(line.get("unit_minor")) or line.unit_minor<1:return false
  seen[line.definition_id]=true;total+=int(line.quantity)*int(line.unit_minor)
 var days: Dictionary={}
 for day in q.weekdays:
  if not ContentValidation.integer(day) or day<0 or day>6 or days.has(str(int(day))):return false
  days[str(int(day))]=true
 return total==int(q.goods_minor) and int(q.total_minor)==total+int(q.fee_minor) and q.destination.get("id") is String and q.destination.get("host_id") is String and q.destination.get("location_id") in ["kiosk","rooftop"] and q.destination.get("kind") in ["cold","dry"] and q.destination.get("ground") is Array and q.get("content_hash") is String
func _fail(key: String) -> ActionResult:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,StringName(key))
