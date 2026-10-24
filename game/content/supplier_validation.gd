class_name SupplierValidation
extends RefCounted
static func validate(bundle: Dictionary) -> ActionResult:
 var d: Variant=bundle.get("suppliers")
 if not d is Dictionary or not d.get("profiles") is Dictionary or not d.profiles.has("fathi") or not d.get("catalog") is Dictionary or d.catalog.is_empty() or not d.get("phone_hosts") is Array or d.phone_hosts.is_empty():return fail()
 var p: Variant=d.profiles.fathi
 if not p is Dictionary or not p.get("name") is String or not p.get("color") is String or not Color.html_is_valid(p.color):return fail()
 for key in ["phone_radius","quote_minutes","extra_delay_minutes","cash_wait_minutes"]:
  if not ContentValidation.bounded(d.get(key),0.1,1440):return fail()
 for key in ["fee_minor","credit_cap_minor","invoice_due_minutes","delivery_minute"]:
  if not ContentValidation.integer(d.get(key)) or d[key]<0:return fail()
 if d.delivery_minute>=1440 or d.credit_cap_minor>100000 or d.invoice_due_minutes<60 or d.invoice_due_minutes>43200:return fail()
 for id in d.catalog:
  var line: Variant=d.catalog[id]
  if not bundle.items.has(id) or bundle.items[id].kind!="ingredient" or not line is Dictionary:return fail()
  for key in ["price_minor","daily_stock"]:
   if not ContentValidation.integer(line.get(key)) or line[key]<1 or line[key]>100000:return fail()
 var e: Variant=d.get("emergency")
 if not e is Dictionary or not bundle.foods.has(e.get("food_id")) or not bundle.recipes.recipes.has(e.get("recipe_id")):return fail()
 for key in ["price_minor","cap_minor","daily_stock"]:
  if not ContentValidation.integer(e.get(key)) or e[key]<1 or e[key]>100000:return fail()
 return ActionResult.success()
static func fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_suppliers")
