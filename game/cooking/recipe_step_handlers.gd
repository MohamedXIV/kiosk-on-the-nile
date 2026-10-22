class_name RecipeStepHandlers
extends RefCounted
## Finite step operations. These return evidence; they never mutate owners.
static func apply(step: Dictionary, job: Dictionary, action_id: StringName, _evidence: Dictionary) -> ActionResult:
 if str(action_id)!=str(step.action):return ActionResult.failure(ActionResult.Code.INVALID_STAGE,&"invalid_cooking_stage")
 var elapsed := float(job.elapsed)
 if elapsed<float(step.get("duration",0)):return ActionResult.failure(ActionResult.Code.TOO_EARLY,&"too_early")
 var grade := 3
 if step.has("burnt_after") and elapsed>=float(step.burnt_after):grade=0
 elif step.has("okay_until") and elapsed>float(step.okay_until):grade=1
 elif step.has("good_until") and elapsed>float(step.good_until):grade=2
 return ActionResult.success({"advance":true,"grade":grade,"elapsed":elapsed})
static func technique(job: Dictionary) -> int:
 var definition: Dictionary=job.definition
 if definition.get("quality",{}).get("kind")=="two_sides":
  var timing: Dictionary=definition.quality
  var a := float(job.step_results[0].elapsed) if not job.step_results.is_empty() else 0.0
  var b := float(job.elapsed)
  if a+b>float(timing.burnt_after):return 0
  if a>=float(timing.excellent_a_min) and a<=float(timing.excellent_a_max) and b>=float(timing.excellent_b_min) and b<=float(timing.excellent_b_max):return 3
  if a+b>=float(timing.good_total_min) and a+b<=float(timing.good_total_max):return 2
  return 1
 var grade := 3
 for result in job.step_results:
  if result.get("assess",true):grade=mini(grade,int(result.grade))
 return grade
