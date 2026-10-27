class_name PeerContentValidation
extends RefCounted
static func validate(bundle: Dictionary) -> ActionResult:
 var visitors: Dictionary=bundle.get("visitors",{})
 if not visitors.has("peer_encounters"):return ActionResult.success()
 var data: Variant=visitors.peer_encounters
 if not data is Dictionary or not data.get("enabled") is bool:return _fail("enabled")
 if not ContentValidation.vector(data.get("delay_seconds"),2) or not ContentValidation.bounded(data.delay_seconds[0],1,120) or not ContentValidation.bounded(data.delay_seconds[1],data.delay_seconds[0],120):return _fail("delay_seconds")
 var bounds: Dictionary={"chance":[0,1],"max_seconds":[10,180],"cooldown_seconds":[1,300],"stop_distance":[0.6,2.5],"arrival_radius":[0.12,0.2],"target_tolerance":[0.2,2]}
 for key in bounds:
  if not ContentValidation.bounded(data.get(key),bounds[key][0],bounds[key][1]):return _fail(key)
 var nav_radius: float=float(bundle.get("spatial",{}).get("navigation",{}).get("arrival_radius",0.12))
 if float(data.arrival_radius)<nav_radius or float(data.arrival_radius)>=float(data.stop_distance):return _fail("arrival_radius")
 if not data.get("pairs") is Dictionary or data.pairs.is_empty() or data.pairs.size()>8:return _fail("pairs")
 var initiators: Array=[]
 for id in data.pairs:
  var pair: Variant=data.pairs[id]
  if not id is String or not id.is_valid_identifier() or not pair is Dictionary:return _fail("pair")
  for role in ["initiator","target"]:
   if not pair.get(role) is String or not visitors.get("characters",{}).has(pair[role]):return _fail("pair."+role)
  if pair.initiator==pair.target or pair.initiator in initiators:return _fail("pair.roles")
  initiators.append(pair.initiator)
  if not pair.get("encounter") is String or not bundle.get("encounters",{}).has(pair.encounter):return _fail("pair.encounter")
 return ActionResult.success()
static func _fail(key: String) -> ActionResult:
 return ContentValidation.fail("visitors.peer_encounters."+key)
