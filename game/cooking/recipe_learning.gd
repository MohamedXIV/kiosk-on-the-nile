class_name RecipeLearning
extends RefCounted
## Evidence is accepted only after the canonical cooking transaction exists.
var _workflow: RecipeWorkflow
var _items: ItemStore
var _attempts: Dictionary={}
var _results: Dictionary={}
var _families: Dictionary={}
func configure(workflow: RecipeWorkflow, items: ItemStore, families: Dictionary) -> void:
 _workflow=workflow
 _items=items
 _families=families.duplicate(true)
func record_attempt(job_id: StringName, recipe_id: StringName, evidence: Dictionary) -> ActionResult:
 var job := _workflow.job(job_id)
 if job.is_empty() or job.recipe_id!=str(recipe_id) or job.status!="active":return _fail("unverified_recipe_attempt")
 if _attempts.has(str(job_id)):return ActionResult.success({"duplicate":true})
 _attempts[str(job_id)]={"job_id":str(job_id),"recipe_id":str(recipe_id),"family":_family(str(recipe_id)),"at":job.last_world_minutes,"location_id":job.location_id,"evidence":evidence.duplicate(true)}
 return ActionResult.success()
func record_result(job_id: StringName, item_id: StringName, quality: int) -> ActionResult:
 var job := _workflow.job(job_id)
 var item := _items.get_item(item_id)
 if job.get("status")!="completed" or job.get("result_item_id")!=str(item_id) or job.get("result_quality")!=quality or item.is_empty() or item.attributes.get("source_job_id")!=str(job_id) or item.attributes.get("quality_score")!=quality:return _fail("unverified_recipe_result")
 if _results.has(str(item_id)):return ActionResult.success({"duplicate":true})
 _results[str(item_id)]={"job_id":str(job_id),"item_id":str(item_id),"recipe_id":job.recipe_id,"family":_family(job.recipe_id),"quality":quality,"at":job.last_world_minutes}
 return ActionResult.success()
func context(recipe_id: StringName) -> Dictionary:
 var family := _family(str(recipe_id))
 var attempts: Array=[]
 var results: Array=[]
 for attempt in _attempts.values():
  if attempt.family==family:attempts.append(attempt)
 for result in _results.values():
  if result.family==family:results.append(result)
 results.sort_custom(func(a,b):return a.at>b.at if a.at!=b.at else a.item_id>b.item_id)
 return {"attempted":not attempts.is_empty(),"completed":not results.is_empty(),"attempt_count":attempts.size(),"last_quality":int(results[0].quality) if not results.is_empty() else -1,"last_item_id":str(results[0].item_id) if not results.is_empty() else ""}
func snapshot() -> Dictionary:
 return {"attempts":_attempts.duplicate(true),"results":_results.duplicate(true)}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("attempts") is Dictionary or not data.get("results") is Dictionary:return _fail("invalid_learning")
 for id in data.attempts:
  var record: Variant=data.attempts[id]
  var job := _workflow.job(StringName(id))
  if not record is Dictionary or record.get("job_id")!=id or job.is_empty() or record.get("recipe_id")!=job.recipe_id or record.get("family")!=_family(job.recipe_id):return _fail("invalid_attempt_evidence")
 for id in data.results:
  var record: Variant=data.results[id]
  if not record is Dictionary or record.get("item_id")!=id or not ContentValidation.integer(record.get("quality")) or record.quality<0 or record.quality>3:return _fail("invalid_result_evidence")
  var job := _workflow.job(StringName(str(record.get("job_id",""))))
  if job.get("status")!="completed" or job.get("result_item_id")!=id or job.get("result_quality")!=record.quality or record.get("family")!=_family(str(job.recipe_id)):return _fail("orphan_result_evidence")
 _attempts=data.attempts.duplicate(true)
 _results=data.results.duplicate(true)
 return ActionResult.success()
func _family(recipe_id: String) -> String:
 return str(_families.get(recipe_id,recipe_id))
func _fail(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,StringName(key))

func result_evidence(item_id: StringName) -> Dictionary:
 return _results.get(str(item_id),{}).duplicate(true)
