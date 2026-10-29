class_name NotebookView
extends RefCounted
## Pure notebook projections. No command, quote preparation or historical rewrite.
static func t(key: String, args: Dictionary = {}) -> String:
 return UiText.localized("notebook."+key,args,key)
static func source(id: String, value: String) -> String:
 return LocaleService.current.source_text(id,value) if LocaleService.current else value
static func name(actor: String, value: String) -> String:
 return source("actor."+actor,value)
static func notes(session: GameSession) -> Array[Dictionary]:
 var state := session.knowledge.snapshot()
 var refs: Dictionary=session.config.section("ui").get("notebook_layout",{}).get("note_refs",{})
 var initial: Array=session.config.section("social").initial_notes
 var result: Array[Dictionary]=[]
 for original in state.notes:
  var display := str(original)
  var chapter := ""
  var candidates: Array[Dictionary]=[]
  for fact in state.facts:
   var record: Dictionary=state.facts[fact]
   var linked: bool=record.get("note","")==original or (fact=="START_ROUTINE" and record.source=="initial" and original in initial)
   if not linked:continue
   candidates.append({"fact":fact,"source":str(record.source)})
  # Flat legacy note arrays do not identify their fact. Ambiguity is not provenance.
  if candidates.size()==1:
   display=source(str(refs.get(candidates[0].fact,"")),display)
   if str(candidates[0].source).begins_with("conversation_"):chapter=str(candidates[0].source).get_slice("/",0)
  result.append({"text":display,"chapter":chapter})
 # Compatibility IDs only select presentation; assertions remain the sole fact owner.
 for fact in session.knowledge.aliases:
  if not refs.has(fact):continue
  var record:=session.knowledge.record(StringName(fact))
  if record.is_empty():continue
  var ref: String=str(refs[fact])
  var canonical: String=str(session.config.data.get("locale_ar",{}).get("messages",{}).get(ref,""))
  if canonical.is_empty():continue
  result.append({"text":source(ref,canonical),"chapter":str(record.source).get_slice("/",0) if str(record.source).begins_with("conversation_") else ""})
 return result
static func people(session: GameSession) -> Array[Dictionary]:
 var result := session.notebook_people()
 for person in result:
  var actor := str(person.get("actor_id",""))
  person.name=name(actor,str(person.name))
  if actor=="abdul_karim":person.stage=t("landlord")
  else:person.stage=source(str(person.get("stage_ref","")),str(person.stage))
  if not str(person.connection).is_empty() and actor in ["farid","youssef"]:
   var other := "youssef" if actor=="farid" else "farid"
   person.connection=t("connection.result" if session.knowledge.has(&"WORK_TRIAL_RESULT") else "connection.trial",{"name":name(other,str(session.visitors.character(StringName(other)).name))})
 return result
static func reputation(session: GameSession) -> String:
 var rep := session.customer_experience.reputation(&"kiosk")
 var data := session.config.section("customer_experience")
 var category := "unrated" if not rep.rated else "good" if float(rep.score)>=float(data.good_above) else "poor" if float(rep.score)<float(data.poor_below) else "okay"
 return t("reputation",{"label":t("rep."+category)})
static func paragraph(label: RichTextLabel, value: String, direction: int=-1) -> void:
 # Paragraph formatting is native, not parsed BBCode: heard brackets stay literal.
 var rtl := direction==1
 if direction<0:
  rtl=LocaleService.current.rtl()
  for i in range(value.length()):
   var code := value.unicode_at(i)
   if code>=0x0590 and code<=0x08ff:rtl=true;break
   if (code>=65 and code<=90) or (code>=97 and code<=122):rtl=false;break
 label.push_paragraph(HORIZONTAL_ALIGNMENT_LEFT,Control.TEXT_DIRECTION_RTL if rtl else Control.TEXT_DIRECTION_LTR)
 label.add_text(value+"\n")
 label.pop()
static func readable_text(label: RichTextLabel, value: String) -> void:
 label.clear()
 for line in value.split("\n"):paragraph(label,line)
static func money(minor: int) -> String:return "%.2f" % (float(minor)/100.0)
static func accounts(session: GameSession) -> String:
 var now := session.clock.world_minutes
 var week := floorf(now/10080.0)*10080.0
 var report := session.accounts.summary(week,week+20160,false)
 var lines := PackedStringArray([t("business_open" if report.business_allowed else "business_suspended")])
 for row in report.rows:
  var remaining := int(row.gross)-int(row.paid)
  lines.append(t("obligation",{"label":source("notebook.lease."+str(row.lease),str(row.label)),"name":str(row.creditor_name),"status":t("covered" if remaining==0 else "overdue" if now>=float(row.due_at) else "upcoming"),"amount":money(remaining),"date":SupplierText.date(float(row.due_at))}))
  if row.creditor=="district" and remaining>0:lines.append(t("enforce",{"date":SupplierText.date(float(row.enforce_at))}))
 for promise in session.commitments.state.promises.values():
  if promise.status in ["pending","broken"]:lines.append(t("promise",{"status":t("status."+str(promise.status)),"date":SupplierText.date(float(promise.deadline))}))
 for loan in session.commitments.state.loans.values():
  if int(loan.principal)<=int(loan.paid):continue
  lines.append(t("loan",{"name":str(loan.creditor_name),"principal":money(int(loan.principal)),"amount":money(int(loan.principal)-int(loan.paid)),"date":SupplierText.date(float(loan.due_at))}))
 var ledger: Dictionary=session.accounts.state.supplier
 lines.append(t("supply_balance",{"prepaid":money(int(ledger.prepaid)),"owed":money(SupplierLedger.remaining(ledger))}))
 if session.contracts.state.active!="":
  var version: Dictionary=session.contracts.state.versions[session.contracts.state.active]
  lines.append(t("supply_next",{"date":SupplierText.date(SupplierContracts.next_time(version,now))}))
 for invoice in ledger.invoices.values():
  var remaining := int(invoice.total)-int(invoice.paid)
  if remaining>0:lines.append(t("supply_invoice",{"name":str(invoice.name),"amount":money(remaining),"date":SupplierText.date(float(invoice.due_at))}))
 return "\n\n".join(lines)
static func receipts(session: GameSession) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for receipt in session.accounts.state.receipts.values():
  var lines := PackedStringArray([t("receipt",{"id":str(receipt.id),"name":str(receipt.creditor_name),"date":SupplierText.date(float(receipt.at)),"amount":money(int(receipt.net))})])
  for line in receipt.lines:lines.append(t("receipt_line",{"start":SupplierText.date(float(line.start)),"end":SupplierText.date(float(line.end)),"gross":money(int(line.gross)),"discount":money(int(line.discount)),"net":money(int(line.net))}))
  result.append({"at":float(receipt.at),"id":"account:"+str(receipt.id),"text":"\n".join(lines)})
 for receipt in session.commitments.state.receipts.values():
  result.append({"at":float(receipt.at),"id":"commitment:"+str(receipt.id),"text":str(receipt.id)+" · "+SupplierText.date(float(receipt.at))+"\n"+str(receipt.get("journal_text",""))})
 for receipt in session.accounts.state.supplier.receipts.values():
  result.append({"at":float(receipt.at),"id":"supply:"+str(receipt.id),"text":str(receipt.id)+" · "+SupplierText.date(float(receipt.at))+"\n"+str(receipt.journal_text)})
 result.sort_custom(func(a,b):return a.id>b.id if a.at==b.at else a.at>b.at)
 return result
static func validate_layout(bundle: Dictionary) -> ActionResult:
 var ui: Dictionary=bundle.get("ui",{})
 if not ui.has("notebook_layout"):return ActionResult.success()
 var rules: Variant=ui.notebook_layout
 if not rules is Dictionary or not ContentValidation.integer(rules.get("history_page_size")) or not ContentValidation.bounded(rules.history_page_size,10,100) or not rules.get("note_refs") is Dictionary:return ContentValidation.fail("ui.notebook_layout")
 for fact in rules.note_refs:
  var ref: Variant=rules.note_refs[fact]
  if not fact in bundle.get("social",{}).get("facts",[]) or not ref is String:return ContentValidation.fail("ui.notebook_layout.note_refs")
  for catalog in ["locale_ar","locale_en"]:
   if not bundle.get(catalog,{}).get("messages",{}).has(ref):return ContentValidation.fail("ui.notebook_layout.note_refs")
 for stage in bundle.get("social_life",{}).get("relationships",{}).get("stages",[]):
  if not stage is Dictionary:return ContentValidation.fail("social_life.relationships.stages")
  if not stage.has("text_ref"):continue
  if not stage.text_ref is String:return ContentValidation.fail("social_life.relationships.stages.text_ref")
  for catalog in ["locale_ar","locale_en"]:
   if not bundle.get(catalog,{}).get("messages",{}).has(stage.text_ref):return ContentValidation.fail("social_life.relationships.stages.text_ref")
 return ActionResult.success()
