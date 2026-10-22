class_name KebdaRules
extends RefCounted
func tick(job: CookingJob, delta: float) -> void:
 if job.stage == &"SIDE_A": job.side_a_elapsed += delta
 elif job.stage in [&"SIDE_B",&"SEASONED"]: job.side_b_elapsed += delta
func act(job: CookingJob, has_stock: bool, hands_free: bool) -> ActionResult:
 match job.stage:
  &"EMPTY":
   if not has_stock: return ActionResult.failure(ActionResult.Code.OUT_OF_STOCK,&"out_of_stock")
   job.stage = &"SIDE_A"
   job.side_a_elapsed = 0
   job.side_b_elapsed = 0
   job.seasoned = false
   return ActionResult.success({"stock_debit":job.recipe.portion_cost,"cue":"chime"})
  &"SIDE_A":
   if job.side_a_elapsed < float(job.recipe.data.timing.minimum_flip): return ActionResult.failure(ActionResult.Code.TOO_EARLY,&"too_early")
   job.stage = &"SIDE_B"
   return ActionResult.success({"cue":"chime"})
  &"SIDE_B":
   job.stage = &"SEASONED"
   job.seasoned = true
   return ActionResult.success({"cue":"chime"})
  &"SEASONED":
   if not hands_free: return ActionResult.failure(ActionResult.Code.HANDS_BUSY,&"hands_busy")
   return ActionResult.success({"completed":true,"score":score(job),"cue":"chime"})
 return ActionResult.failure(ActionResult.Code.INVALID_STAGE,&"invalid_cooking_stage")
func score(job: CookingJob) -> int:
 var timing: Dictionary = job.recipe.data.timing
 var total := job.side_a_elapsed+job.side_b_elapsed
 if total > float(timing.burnt_after): return 0
 if job.side_a_elapsed >= float(timing.excellent_a_min) and job.side_a_elapsed <= float(timing.excellent_a_max) and job.side_b_elapsed >= float(timing.excellent_b_min) and job.side_b_elapsed <= float(timing.excellent_b_max) and job.seasoned: return 3
 if total >= float(timing.good_total_min) and total <= float(timing.good_total_max): return 2
 return 1
