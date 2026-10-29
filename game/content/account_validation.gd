class_name AccountValidation
extends RefCounted
static func validate(bundle: Dictionary) -> ActionResult:
 var data: Variant=bundle.get("accounts")
 if not data is Dictionary or not data.get("creditors") is Dictionary or not data.get("leases") is Dictionary or not data.get("advance_offers") is Dictionary:return fail()
 for id in ["abdul_karim","district"]:
  var c: Variant=data.creditors.get(id)
  if not c is Dictionary or not c.get("name") is String or c.name.is_empty() or c.get("kind")!=("person" if id=="abdul_karim" else "institution"):return fail()
 for id in ["housing_lease","kiosk_lease"]:
  if not lease_valid(data.leases.get(id),data.creditors):return fail()
 if data.leases.housing_lease.creditor!="abdul_karim" or data.leases.housing_lease.suspends_business or data.leases.kiosk_lease.creditor!="district" or not data.leases.kiosk_lease.suspends_business:return fail()
 for offer in data.advance_offers.values():
  if not offer is Dictionary or not ContentValidation.integer(offer.get("periods")) or not ContentValidation.bounded(offer.periods,1,12) or not ContentValidation.integer(offer.get("discount_percent")) or not ContentValidation.bounded(offer.discount_percent,0,50):return fail()
 if not ContentValidation.bounded(data.get("quote_minutes"),1,1440) or not ContentValidation.integer(data.get("partial_minor")) or data.partial_minor<1 or not data.get("extensions") is Array:return fail()
 for rule in data.extensions:
  if not rule is Dictionary or not ContentValidation.integer(rule.get("days")) or not ContentValidation.bounded(rule.days,1,7):return fail()
  for key in ["familiarity","trust"]:
   if not ContentValidation.bounded(rule.get(key),0,100):return fail()
 var loan: Variant=data.get("loan")
 if not loan is Dictionary or loan.get("lender")!="abdul_karim" or not ContentValidation.integer(loan.get("budget_minor")) or loan.budget_minor<1 or not loan.get("amounts") is Array or loan.amounts.is_empty() or not ContentValidation.bounded(loan.get("duration_minutes"),60,43200):return fail()
 for amount in loan.amounts:
  if not ContentValidation.integer(amount) or amount<1 or amount>loan.budget_minor:return fail()
 for key in ["familiarity","trust"]:
  if not ContentValidation.bounded(loan.get(key),0,100):return fail()
 for key in ["promise_fulfilled","promise_broken","promise_repair","personal_moment"]:
  if not data.get(key) is Dictionary:return fail()
  for axis in ["familiarity","trust"]:
   if not ContentValidation.bounded(data[key].get(axis),-10,10):return fail()
 var visits: Variant=bundle.get("residential_visits")
 if not visits is Dictionary or not visits.get("profiles") is Dictionary or not visits.profiles.has("abdul_karim") or not ContentValidation.vector(visits.get("window"),2) or visits.window[0]<0 or visits.window[0]>=visits.window[1] or visits.window[1]>1440 or not ContentValidation.vector(visits.get("arrival_delay_minutes"),2) or visits.arrival_delay_minutes[0]<=0 or visits.arrival_delay_minutes[0]>visits.arrival_delay_minutes[1] or not ContentValidation.vector(visits.get("entrance"),2) or not ContentValidation.vector(visits.get("standing"),2):return fail()
 for key in ["stay_minutes","return_minutes","speed","pre_due_minutes","greet_delay_minutes"]:
  if not ContentValidation.bounded(visits.get(key),0.1,10080):return fail()
 if not visits.get("social_guests") is Array or visits.social_guests.size()>2 or not ContentValidation.vector(visits.get("guest_window"),2) or visits.guest_window[0]<0 or visits.guest_window[0]>=visits.guest_window[1] or visits.guest_window[1]>1440:return fail()
 var known_guests: Array=[]
 for actor in visits.social_guests:
  if not actor in bundle.visitors.characters or actor in known_guests:return fail()
  known_guests.append(actor)
 for profile in visits.profiles.values():
  if not profile is Dictionary or not profile.get("name") is String or not profile.get("color") is String or not Color.html_is_valid(profile.color):return fail()
 return ActionResult.success()
static func lease_valid(lease: Variant, creditors: Dictionary) -> bool:
 if not lease is Dictionary or not creditors.has(lease.get("creditor")) or not lease.get("label") is String or not lease.get("allow_partial") is bool or not lease.get("suspends_business") is bool:return false
 for key in ["nominal_minor","period_minutes","due_minute","grace_minutes","version"]:
  if not ContentValidation.integer(lease.get(key)):return false
 return lease.nominal_minor>0 and lease.period_minutes>=1440 and lease.period_minutes<=43200 and lease.due_minute>=0 and lease.due_minute<1440 and lease.grace_minutes>=0 and lease.grace_minutes<=43200 and lease.version>0
static func fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_accounts")
