class_name IngredientLots
extends RefCounted
## Immutable acquisition evidence; ItemStore remains the stock and reservation owner.
static func matches(definitions: Dictionary, actual: String, required: String) -> bool:
 if actual==required:return definitions.has(actual)
 var a: Dictionary=definitions.get(actual,{}).get("material",{})
 var r: Dictionary=definitions.get(required,{}).get("material",{})
 return not a.is_empty() and not r.is_empty() and a.get("family")==r.get("family")
static func stamp(definition: Dictionary, source_id: String, at: float, cost_minor: int) -> Dictionary:
 var material: Dictionary=definition.material
 return {"origin":source_id,"acquired_at":at,"grade":material.grade,"quality":int(material.quality),"cost_minor":cost_minor,"cost_units":1,"cost_known":false,"source_kind":"grant","source_ref":source_id}
static func validate_definitions(definitions: Dictionary) -> ActionResult:
 for id in definitions:
  var d: Dictionary=definitions[id]
  if not d.has("material"):continue
  var m: Variant=d.material
  if d.get("kind")!="ingredient" or not m is Dictionary or not CharacterLifeValidation.keys(m,["family","grade","quality"]) or not m.family is String or not definitions.has(m.family) or not m.grade is String or m.grade.is_empty() or not ContentValidation.integer(m.quality) or not ContentValidation.bounded(m.quality,0,100):return _fail("definition")
  var base: Variant=definitions[m.family].get("material")
  if not base is Dictionary or base.get("family")!=m.family or definitions[m.family].get("required_storage")!=d.get("required_storage"):return _fail("family")
 return ActionResult.success()
static func validate(item: Dictionary, definitions: Dictionary, now: float) -> ActionResult:
 var definition: Dictionary=definitions.get(str(item.get("definition_id","")),{})
 var attributes: Dictionary=item.get("attributes",{})
 if not definition.has("material"):return _fail("unexpected") if attributes.has("lot") else ActionResult.success()
 var lot: Variant=attributes.get("lot")
 if not lot is Dictionary or not CharacterLifeValidation.keys(lot,["origin","acquired_at","grade","quality","cost_minor","cost_units","cost_known","source_kind","source_ref"]):return _fail("shape")
 if not lot.origin is String or lot.origin.is_empty() or not lot.source_ref is String or lot.source_ref.is_empty() or not lot.source_kind in ["starter","grant","shop","supplier"] or not ContentValidation.bounded(lot.acquired_at,0,now):return _fail("source")
 if lot.grade!=definition.material.grade or lot.quality!=definition.material.quality or not ContentValidation.integer(lot.quality) or not ContentValidation.integer(lot.cost_minor) or not ContentValidation.bounded(lot.cost_minor,0,1000000000) or not ContentValidation.integer(lot.cost_units) or not ContentValidation.bounded(lot.cost_units,1,1000000) or not lot.cost_known is bool:return _fail("grade_or_cost")
 return ActionResult.success()
static func quality(evidence: Array) -> float:
 var total := 0.0;var units := 0
 for item in evidence:
  if not item is Dictionary:continue
  var lot: Dictionary=item.get("attributes",{}).get("lot",{})
  var derived: Variant=item.get("attributes",{}).get("material_quality")
  if lot.is_empty() and not ContentValidation.bounded(derived,0,1):continue
  var quantity := int(item.get("consumed_quantity",item.get("quantity",0)))
  total+=(float(lot.quality) if not lot.is_empty() else float(derived)*100.0)*quantity;units+=quantity
 return total/(100.0*units) if units>0 else 0.6
static func sources(items: Dictionary, shops: Dictionary, deliveries: Dictionary, versions: Dictionary, catalog: Dictionary) -> ActionResult:
 var totals := {}
 for item in items.values():
  var lot: Dictionary=item.attributes.get("lot",{})
  if lot.is_empty():continue
  if lot.source_kind=="shop":
   var receipt: Dictionary=shops.get(lot.source_ref,{})
   if receipt.is_empty() or not is_equal_approx(float(receipt.at),float(lot.acquired_at)):return _fail("shop_receipt")
   var found := false
   for grant in receipt.get("granted",[]):
    if grant.item_id==lot.origin and grant.definition_id==item.definition_id:
     var expected: Dictionary=grant.get("lot",{})
     var cost_found := false
     for line in receipt.quote.lines:
      var offer: Dictionary=catalog.get(str(receipt.quote.shop_id),{}).get("offers",{}).get(str(line.get("offer_id","")),{})
      var cost_units := 0;var contains := false
      for part in offer.get("contents",[]):
       cost_units+=int(part.quantity)
       if part.definition_id==item.definition_id:contains=true
      if contains and lot.cost_known and int(lot.cost_minor)==int(line.unit_price_minor) and int(lot.cost_units)==cost_units:cost_found=true
     if not cost_found:return _fail("shop_cost")
     var key := "shop/"+str(lot.source_ref)+"/"+str(lot.origin)
     totals[key]=int(totals.get(key,0))+int(item.quantity)
     if int(totals[key])>int(grant.quantity):return _fail("shop_conservation")
     if not _same_lot(lot,expected) or int(item.quantity)>int(grant.quantity):return _fail("shop_lot")
     found=true;break
   if not found:return _fail("shop_grant")
  elif lot.source_kind=="supplier":
   var occurrence: Dictionary=deliveries.get(lot.source_ref,{})
   var terms: Dictionary=versions.get(str(occurrence.get("version_id","")),{})
   if occurrence.get("status")!="delivered" or not is_equal_approx(float(occurrence.get("evaluated_at",-1)),float(lot.acquired_at)) or item.attributes.get("supply_occurrence")!=lot.source_ref or item.attributes.get("supply_grant_id",item.id)!=lot.origin:return _fail("supplier_receipt")
   var expected := false
   for line in terms.get("lines",[]):
    if line.definition_id==item.definition_id and int(line.unit_minor)==int(lot.cost_minor) and int(lot.cost_units)==1 and lot.cost_known:expected=true
   if not expected:return _fail("supplier_cost")
   var bound := 0
   for grant in occurrence.get("grants",[]):
    if grant.id==lot.origin and grant.definition_id==item.definition_id:bound=int(grant.quantity)
   var key := "supplier/"+str(lot.source_ref)+"/"+str(lot.origin)
   totals[key]=int(totals.get(key,0))+int(item.quantity)
   if int(totals[key])>bound:return _fail("supplier_conservation")
 return ActionResult.success()
static func validate_session(session: GameSession) -> ActionResult:
 var records: Dictionary=session.items.snapshot().items
 var jobs: Dictionary=session.workflow.snapshot().jobs
 for id in jobs:
  var job := session.workflow.job(StringName(id))
  if not job.inputs_consumed:continue
  for index in range(job.input_evidence.size()):
   var input: Dictionary=job.input_evidence[index]
   if not input.attributes.has("lot"):continue
   var copy := input.duplicate(true)
   copy.quantity=int(input.consumed_quantity)
   records["consumed/"+id+"/"+str(index)]=copy
  for output_id in job.get("portion_results",{}):
   var output: Dictionary=job.portion_results[output_id]
   var serving: Array=output.get("serving_evidence",[])
   for index in range(serving.size()):
    var input: Dictionary=serving[index]
    if not input.attributes.has("lot"):continue
    var copy := input.duplicate(true);copy.quantity=int(input.consumed_quantity)
    records["serving/"+str(output_id)+"/"+str(index)]=copy
 return sources(records,session.shops.snapshot().receipts,session.deliveries.snapshot().occurrences,session.contracts.snapshot().versions,session.config.section("shops").shops)
static func _same_lot(a: Dictionary, b: Dictionary) -> bool:
 if a.size()!=b.size():return false
 for key in a:
  if key=="acquired_at":
   if not ContentValidation.number(b.get(key)) or not is_equal_approx(float(a[key]),float(b[key])):return false
  elif not b.has(key) or a[key]!=b[key]:return false
 return true
static func _fail(reason: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,StringName("invalid_ingredient_lot_"+reason))
