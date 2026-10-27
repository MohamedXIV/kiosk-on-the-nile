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
 return ActionResult.success()
