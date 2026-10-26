class_name SeatingContentValidation
extends RefCounted
static func validate(bundle: Dictionary) -> ActionResult:
 for id in bundle.get("items",{}):
  var item: Dictionary=bundle.items[id]
  if item.has("gathering_surface") and not item.gathering_surface is bool:return ContentValidation.fail("items.gathering_surface")
  if not item.has("seats"):continue
  if item.get("kind")!="furniture" or not item.seats is Array or item.seats.is_empty() or item.seats.size()>8:return ContentValidation.fail("items.seats")
  var known: Dictionary={}
  for seat in item.seats:
   if not seat is Dictionary or not seat.get("id") is String or not seat.id.is_valid_identifier() or known.has(seat.id):return ContentValidation.fail("items.seats.id")
   known[seat.id]=true
   for key in ["access","anchor","facing"]:
    if not ContentValidation.vector(seat.get(key),2):return ContentValidation.fail("items.seats."+key)
   var access := Vector2(seat.access[0],seat.access[1])
   var anchor := Vector2(seat.anchor[0],seat.anchor[1])
   if access.length()<0.3 or access.length()>3 or absf(anchor.x)>float(item.footprint[0])*0.125 or absf(anchor.y)>float(item.footprint[1])*0.125 or not is_equal_approx(Vector2(seat.facing[0],seat.facing[1]).length(),1):return ContentValidation.fail("items.seats.geometry")
   if not ContentValidation.bounded(seat.get("height"),0.05,1.5) or not ContentValidation.bounded(seat.get("table_radius"),0,4):return ContentValidation.fail("items.seats.height")
 var visitors: Dictionary=bundle.get("visitors",{})
 for character in visitors.get("characters",{}).values():
  if character.has("seating_chance") and not ContentValidation.bounded(character.seating_chance,0,1):return ContentValidation.fail("visitors.seating_chance")
 if visitors.has("seating"):
  var policy: Variant=visitors.seating
  if not policy is Dictionary or not policy.get("enabled") is bool or not CharacterMotionValidation._interval(policy.get("delay_seconds"),0.5,60):return ContentValidation.fail("visitors.seating")
  if not ContentValidation.bounded(policy.get("retry_seconds"),1,120) or not ContentValidation.bounded(policy.get("search_radius"),1,20) or not ContentValidation.bounded(policy.get("arrival_radius"),0.005,0.15):return ContentValidation.fail("visitors.seating.timing")
  var stopping_radius := float(bundle.get("spatial",{}).get("navigation",{}).get("arrival_radius",float(visitors.get("arrival_radius",0.15))*0.8))
  if float(policy.arrival_radius)<stopping_radius or float(policy.arrival_radius)>float(visitors.get("arrival_radius",0.15)):return ContentValidation.fail("visitors.seating.arrival_radius")
  for key in ["max_searches","max_candidates"]:
   if not ContentValidation.integer(policy.get(key)) or policy[key]<1 or policy[key]>8:return ContentValidation.fail("visitors.seating."+key)
 var style: Dictionary=bundle.get("spatial",{}).get("character",{})
 if style.has("sit_transition_seconds") and not ContentValidation.bounded(style.sit_transition_seconds,0.05,2):return ContentValidation.fail("character.sit_transition_seconds")
 return ActionResult.success()
