class_name AvoidanceContentValidation
extends RefCounted
static func validate(bundle: Dictionary) -> ActionResult:
 var spatial: Dictionary=bundle.get("spatial",{})
 if not spatial.has("avoidance"):return ActionResult.success()
 var data: Variant=spatial.avoidance
 if not data is Dictionary or not data.get("enabled") is bool:return ContentValidation.fail("spatial.avoidance")
 var bounds: Dictionary={"radius":[0.12,0.45],"neighbor_distance":[0.6,5],"time_horizon_agents":[0.2,3],"sample_age_seconds":[0.05,1],"passing_margin":[0.02,0.3],"conflict_lookahead":[0.2,3],"path_skip_distance":[0.25,1.5],"max_wait_seconds":[2,30]}
 for key in bounds:
  if not ContentValidation.bounded(data.get(key),bounds[key][0],bounds[key][1]):return ContentValidation.fail("spatial.avoidance."+key)
 if not ContentValidation.integer(data.get("max_neighbors")) or data.max_neighbors<1 or data.max_neighbors>16:return ContentValidation.fail("spatial.avoidance.max_neighbors")
 if float(data.neighbor_distance)<=float(data.radius)*2 or float(data.sample_age_seconds)<float(bundle.get("time",{}).get("fixed_step",1.0/60))*2:return ContentValidation.fail("spatial.avoidance.bounds")
 if float(data.path_skip_distance)<float(data.radius)*2+float(data.passing_margin):return ContentValidation.fail("spatial.avoidance.path_skip_distance")
 if data.has("passages"):
  var passages: Variant=data.passages
  if not passages is Dictionary or not passages.get("enabled") is bool:return ContentValidation.fail("spatial.avoidance.passages")
  var limits: Dictionary={"delay_seconds":[0.25,5],"max_seconds":[2,20],"retry_seconds":[1,15],"detect_distance":[0.6,3],"retreat_distance":[1,4],"route_distance":[1,6],"pocket_margin":[0.05,0.5],"arrival_radius":[0.08,0.14],"progress_ratio":[0.01,0.3]}
  for key in limits:
   if not ContentValidation.bounded(passages.get(key),limits[key][0],limits[key][1]):return ContentValidation.fail("spatial.avoidance.passages."+key)
  if not ContentValidation.integer(passages.get("candidate_limit")) or passages.candidate_limit<2 or passages.candidate_limit>10:return ContentValidation.fail("spatial.avoidance.passages.candidate_limit")
  if float(passages.delay_seconds)>=float(passages.max_seconds) or float(passages.detect_distance)>float(data.neighbor_distance) or not is_equal_approx(float(passages.arrival_radius),float(spatial.get("navigation",{}).get("arrival_radius",0.12))):return ContentValidation.fail("spatial.avoidance.passages.bounds")
  if float(passages.route_distance)<float(passages.retreat_distance) or float(passages.retreat_distance)<=float(data.radius)*2.0+float(data.passing_margin)+float(passages.pocket_margin):return ContentValidation.fail("spatial.avoidance.passages.retreat_bounds")
 return ActionResult.success()
