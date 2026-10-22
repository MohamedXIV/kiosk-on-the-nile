class_name TeaRules
extends RefCounted
func tick(job: CookingJob, delta: float) -> void:
 if job.stage == &"HEATING":
  job.heat_elapsed += delta
  if job.heat_elapsed >= float(job.recipe.data.timing.boil_seconds): job.stage = &"BOILED"
 elif job.stage == &"BREWING":
  job.brew_elapsed += delta
  if job.brew_elapsed >= float(job.recipe.data.timing.brew_seconds): job.stage = &"READY"
 elif job.stage == &"READY": job.brew_elapsed += delta
func act(job: CookingJob, has_stock: bool, hands_free: bool) -> ActionResult:
 match job.stage:
  &"EMPTY":
   if not has_stock: return ActionResult.failure(ActionResult.Code.OUT_OF_STOCK,&"out_of_stock")
   job.stage = &"HEATING"
   job.heat_elapsed = 0
   return ActionResult.success({"cue":"pour"})
  &"BOILED":
   if not has_stock: return ActionResult.failure(ActionResult.Code.OUT_OF_STOCK,&"out_of_stock")
   job.stage = &"BREWING"
   job.brew_elapsed = 0
   return ActionResult.success({"stock_debit":job.recipe.portion_cost,"cue":"chime"})
  &"READY":
   if not hands_free: return ActionResult.failure(ActionResult.Code.HANDS_BUSY,&"hands_busy")
   var score := 3
   if job.brew_elapsed > float(job.recipe.data.timing.okay_until): score = 1
   elif job.brew_elapsed > float(job.recipe.data.timing.good_until): score = 2
   return ActionResult.success({"completed":true,"score":score,"cue":"pour"})
 return ActionResult.failure(ActionResult.Code.INVALID_STAGE,&"wait_cooking")
