class_name RecipeWorkflow
extends RefCounted
signal changed
signal attempt_started(job_id: StringName, recipe_id: StringName, evidence: Dictionary)
signal item_completed(job_id: StringName, item_id: StringName, quality: int)
var quality_provider: Callable
var sugar_provider: Callable
var use_provider: Callable
var hygiene_provider: Callable
var _recipes: Dictionary
var _inventory: InventoryService
var _equipment: EquipmentService
var _clock: GameClock
var _knowledge: KnowledgeBook
var _jobs: Dictionary={}
var _next_id: int=1
func configure(recipes: Dictionary, inventory: InventoryService, equipment: EquipmentService, clock: GameClock, knowledge: KnowledgeBook) -> ActionResult:
 var result := CookingWorkflowValidation.validate_recipes(recipes,inventory.items)
 if not result.ok:return result
 _recipes=recipes.duplicate(true)
 _inventory=inventory
 _equipment=equipment
 _clock=clock
 _knowledge=knowledge
 return ActionResult.success()
func available_recipes(location_id: StringName, instance_id: StringName) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 var item := _inventory.items.get_item(instance_id)
 if item.is_empty():return result
 for id in _recipes:
  var definition: Dictionary=_recipes[id]
  if not _station_eligible(definition,location_id,instance_id).ok:continue
  var capability := StringName(definition.steps[0].capability)
  if not _equipment.is_usable(instance_id,location_id,capability):continue
  var eligibility := _requirements(definition,location_id,[str(instance_id)])
  result.append({"id":id,"definition":definition.duplicate(true),"available":eligibility.ok,"missing":eligibility.message_key,"details":eligibility.details})
 return result
func start(recipe_id: StringName, location_id: StringName, instance_ids: PackedStringArray) -> ActionResult:
 if not _recipes.has(str(recipe_id)):return _fail("unknown_recipe")
 var definition: Dictionary=_recipes[str(recipe_id)].duplicate(true)
 if instance_ids.is_empty():return _fail("recipe_station_mismatch")
 var eligibility := _station_eligible(definition,location_id,StringName(instance_ids[0]))
 if not eligibility.ok:return eligibility
 var requirements := _requirements(definition,location_id,instance_ids)
 if not requirements.ok:return requirements
 var devices: Dictionary=requirements.details.devices
 devices[str(definition.steps[0].capability)]=str(instance_ids[0])
 var first: Dictionary=definition.steps[0]
 if not _near(StringName(devices[first.capability]),location_id):return _fail("equipment_out_of_reach")
 var id := "cook_%d" % _next_id
 var change := _inventory.items.candidate()
 var inputs: Array[Dictionary]=[]
 inputs.assign(definition.inputs)
 var available := _inventory.available(location_id,inputs)
 if not available.ok:return available
 change.state.reservations[id]=available.details.sources.duplicate(true)
 var evidence: Array=[]
 for source in available.details.sources:evidence.append(change.state.items[source.item_id].duplicate(true))
 var job := {"id":id,"recipe_id":str(recipe_id),"recipe_version":int(definition.version),"definition":definition,"time_domain":"world_minutes","location_id":str(location_id),"step_index":0,"elapsed":0.0,"last_world_minutes":_clock.world_minutes,"step_results":[],"devices":devices,"input_evidence":evidence,"quality_penalty":int(quality_provider.call()) if quality_provider.is_valid() else 0,"sugar_id":str(sugar_provider.call(StringName(instance_ids[0]))) if sugar_provider.is_valid() and not instance_ids.is_empty() else "","status":"active","inputs_consumed":false}
 job["current_hygiene_evidence"]=_hygiene_evidence(job,first)
 if definition.get("consume_on_start",true):_consume_all(change,job)
 var resources: Array[Dictionary]=[{"instance_id":devices[first.capability],"capability":first.capability,"units":1}]
 var equipment := _equipment.prepare_reservations(StringName(id),resources,true)
 if not equipment.ok:return equipment
 var result := _commit(change,equipment.details.state,job)
 if not result.ok:return result
 attempt_started.emit(StringName(id),recipe_id,{"location_id":str(location_id),"at":_clock.world_minutes})
 return ActionResult.success({"job_id":id,"cue":"chime"})
func act(job_id: StringName, action_id: StringName) -> ActionResult:
 if not _jobs.has(str(job_id)) or _jobs[str(job_id)].status!="active":return _fail("unknown_job")
 var candidate: Dictionary=_jobs[str(job_id)].duplicate(true)
 if action_id==&"cancel":return _cancel(candidate)
 var step: Dictionary=candidate.definition.steps[int(candidate.step_index)]
 if step.kind=="batch_heat":return _batch_action(candidate,action_id)
 var action_device := str(candidate.devices[step.capability])
 if step.kind=="cold_wait":
  var next_step: Dictionary=candidate.definition.steps[int(candidate.step_index)+1]
  action_device=str(candidate.devices[next_step.capability])
 if not _near(StringName(action_device),StringName(candidate.location_id)):return _fail("equipment_out_of_reach")
 var result := RecipeStepHandlers.apply(step,candidate,action_id,{})
 if not result.ok:return result
 var change := _inventory.items.candidate()
 if step.kind=="prepare" and candidate.definition.get("vessel_definition","")!="":
  var vessel := BatchPreparation.create_vessel(candidate,change)
  if not vessel.ok:return vessel
 if step.kind=="cold_wait":
  var loaded := BatchPreparation.load_vessel(candidate,change,action_device)
  if not loaded.ok:return loaded
 if step.get("consume_inputs",false):_consume_all(change,candidate)
 candidate.step_results.append({"step_id":step.id,"grade":int(result.details.grade),"elapsed":candidate.elapsed,"assess":step.get("assess",true),"hygiene_evidence":candidate.get("current_hygiene_evidence",{})})
 var output: PreparedItem
 var resource_lines: Array[Dictionary]=[]
 if int(candidate.step_index)+1>=candidate.definition.steps.size():
  if not _inventory.held_id().is_empty():return ActionResult.failure(ActionResult.Code.HANDS_BUSY,&"hands_busy")
  output=_prepared_output(candidate,change)
  candidate.status="completed"
  candidate["result_item_id"]=str(output.id)
  candidate["result_quality"]=output.quality_score
  change.state.reservations.erase(str(job_id))
 else:
  candidate.step_index=int(candidate.step_index)+1
  var next: Dictionary=candidate.definition.steps[int(candidate.step_index)]
  if not _equipment.is_usable(StringName(candidate.devices[next.capability]),StringName(candidate.location_id),StringName(next.capability),job_id):return _fail("equipment_out_of_reach")
  if not next.get("inherit_elapsed",false):candidate.elapsed=0.0
  candidate.last_world_minutes=_clock.world_minutes
  candidate["current_hygiene_evidence"]=_hygiene_evidence(candidate,next)
  resource_lines.append({"instance_id":candidate.devices[next.capability],"capability":next.capability,"units":1})
 var equipment := _equipment.prepare_reservations(job_id,resource_lines,true)
 if not equipment.ok:return equipment
 result=_commit(change,equipment.details.state,candidate)
 if not result.ok:return result
 if output!=null:
  item_completed.emit(job_id,output.id,output.quality_score)
  return ActionResult.success({"completed":true,"item":output,"score":output.quality_score,"mood_penalty":candidate.quality_penalty,"cue":"chime"})
 return ActionResult.success({"cue":"chime"})
func tick(frame: Dictionary) -> void:
 for id in _jobs:
  var job: Dictionary=_jobs[id]
  if job.status!="active":continue
  var delta := maxf(0,float(frame.world_minutes)-float(job.last_world_minutes))
  job.last_world_minutes=float(frame.world_minutes)
  var step: Dictionary=job.definition.steps[int(job.step_index)]
  if step.kind=="cold_wait":
   var bowl := _inventory.items.get_item(StringName(str(job.get("bowl_id",""))))
   if not bowl.is_empty():
    var container := _inventory.items.get_container(StringName(bowl.container_id))
    if _inventory._usable_storage(container,StringName(job.location_id),"cold"):job.elapsed=float(job.elapsed)+delta
  elif step.kind=="batch_heat":
   if job.get("heat_on",true):job.elapsed=float(job.elapsed)+delta
   _progress_slice(job,delta)
  elif step.kind in ["heat","brew","wait"] or _near(StringName(job.devices[step.capability]),StringName(job.location_id)):job.elapsed=float(job.elapsed)+delta
func job(id: StringName) -> Dictionary:
 return _jobs.get(str(id),{}).duplicate(true)
func active_at(instance_id: StringName) -> Dictionary:
 for record in _jobs.values():
  if record.status=="active" and str(record.devices[record.definition.steps[int(record.step_index)].capability])==str(instance_id):return record.duplicate(true)
 return {}
func recipes() -> Dictionary:
 return _recipes.duplicate(true)
func _station_eligible(definition: Dictionary, location_id: StringName, instance_id: StringName) -> ActionResult:
 var fact := StringName(str(definition.get("learning_fact","")))
 if not fact.is_empty() and not _knowledge.has(fact):return _fail("recipe_unknown")
 var locations: Array=definition.get("allowed_locations",[])
 if not locations.is_empty() and not str(location_id) in locations:return _fail("recipe_wrong_location")
 if not _equipment.is_usable(instance_id,location_id,StringName(definition.steps[0].capability)):return _fail("recipe_station_mismatch")
 for step in definition.steps:
  if _equipment.candidates(location_id,StringName(step.capability)).is_empty():return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"missing_equipment",{"capability":str(step.capability)})
 return ActionResult.success()
func _requirements(definition: Dictionary, location_id: StringName, preferred: PackedStringArray) -> ActionResult:
 var fact := StringName(str(definition.get("learning_fact","")))
 if not fact.is_empty() and not _knowledge.has(fact):return _fail("recipe_unknown")
 var devices: Dictionary={}
 for step in definition.steps:
  var capability := StringName(str(step.capability))
  if devices.has(str(capability)):continue
  var choices := _equipment.candidates(location_id,capability)
  var selected := ""
  for id in preferred:
   if id in choices and not _equipment.is_busy(StringName(id)):selected=id;break
  if selected.is_empty():
   for id in choices:
    if not _equipment.is_busy(StringName(id)):selected=id;break
  if selected.is_empty():return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"missing_equipment",{"capability":str(capability)})
  devices[str(capability)]=selected
 var inputs: Array[Dictionary]=[]
 inputs.assign(definition.inputs)
 var result := _inventory.available(location_id,inputs)
 if not result.ok:return result
 return ActionResult.success({"devices":devices})
func _consume_all(change: ItemChangeSet, job: Dictionary) -> void:
 if job.inputs_consumed:return
 for line in change.state.reservations.get(job.id,[]):
  change.state.items[line.item_id].quantity-=int(line.quantity)
  if change.state.items[line.item_id].quantity==0:change.state.items.erase(line.item_id)
 change.state.reservations[job.id]=[]
 job.inputs_consumed=true
func _prepared_output(job: Dictionary, change: ItemChangeSet) -> PreparedItem:
 var item := PreparedItem.new()
 item.id=StringName("food_%d" % int(change.state.next_id))
 change.state.next_id=int(change.state.next_id)+1
 item.recipe_id=StringName(job.recipe_id)
 item.food_id=StringName(job.definition.output.food_id)
 item.sugar_id=StringName(job.sugar_id)
 var technique := RecipeStepHandlers.technique(job)
 for input in job.input_evidence:
  if input.attributes.has("technique_grade"):technique=mini(technique,int(input.attributes.technique_grade))
  job.quality_penalty=maxi(int(job.quality_penalty),int(input.attributes.get("mood_penalty",0)))
 var hygiene_penalty := 0
 for evidence in job.step_results:hygiene_penalty=maxi(hygiene_penalty,int(evidence.get("hygiene_evidence",{}).get("penalty",0)))
 for input in job.input_evidence:hygiene_penalty=maxi(hygiene_penalty,int(input.attributes.get("hygiene_penalty",0)))
 item.quality_score=maxi(1,technique-int(job.quality_penalty)-hygiene_penalty) if technique>0 else 0
 item.quality_key=StringName(job.definition.quality_keys[item.quality_score])
 var attributes := item.snapshot()
 attributes.merge({"source_job_id":job.id,"technique_grade":technique,"mood_penalty":job.quality_penalty,"hygiene_penalty":hygiene_penalty,"step_evidence":job.step_results.duplicate(true)})
 change.state.items[str(item.id)]={"id":str(item.id),"definition_id":"prepared_food","kind":"prepared","quantity":1,"container_id":"player_hand","attributes":attributes}
 return item
func _hygiene_evidence(job: Dictionary, step: Dictionary) -> Dictionary:
 return hygiene_provider.call(PackedStringArray([str(job.devices[step.capability])])) if hygiene_provider.is_valid() else {}
func _commit(change: ItemChangeSet, equipment_state: Dictionary, job: Dictionary) -> ActionResult:
 var validation := _inventory.items.validate_change(change)
 if not validation.ok:return validation
 var committed := _inventory.items.commit(change,false)
 if not committed.ok:return committed
 _equipment.commit_reservations(equipment_state)
 _jobs[job.id]=job.duplicate(true)
 if str(job.id)=="cook_%d" % _next_id:_next_id+=1
 if job.status=="active" and use_provider.is_valid() and int(job.get("use_recorded_step",-1))!=int(job.step_index):
  _jobs[job.id]["use_recorded_step"]=int(job.step_index)
  var step: Dictionary=job.definition.steps[int(job.step_index)]
  use_provider.call(StringName(job.id),int(job.step_index),StringName(job.devices[step.capability]),StringName(step.kind))
 _inventory.items.changed.emit(_inventory.items.revision)
 changed.emit()
 return ActionResult.success()
func _cancel(job: Dictionary) -> ActionResult:
 var change := _inventory.items.candidate()
 change.state.reservations.erase(job.id)
 if job.has("bowl_id"):change.state.items.erase(str(job.bowl_id))
 var equipment := _equipment.prepare_reservations(StringName(job.id),[],true)
 if not equipment.ok:return equipment
 job.status="cancelled"
 return _commit(change,equipment.details.state,job)
func _near(id: StringName, location_id: StringName) -> bool:
 return _inventory.player_pose!=null and _inventory.player_pose.location_id==location_id and _inventory.spaces.placement(id).get("location_id")==str(location_id) and _inventory.spaces.ground(id).distance_to(_inventory.player_pose.ground)<=1.6
func snapshot() -> Dictionary:
 return {"jobs":_jobs.duplicate(true),"next_id":_next_id}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("jobs") is Dictionary or not ContentValidation.integer(data.get("next_id")) or data.next_id<1:return _fail("invalid_workflows")
 for id in data.jobs:
  var suffix := str(id).trim_prefix("cook_")
  if not str(id).begins_with("cook_") or not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=int(data.next_id):return _fail("invalid_workflow_counter")
  var job: Variant=data.jobs[id]
  if not job is Dictionary or job.get("id")!=id or not job.get("definition") is Dictionary or not job.get("status") in ["active","completed","cancelled"] or job.get("time_domain")!="world_minutes" or not ContentValidation.integer(job.get("step_index")) or not ContentValidation.number(job.get("elapsed")) or job.elapsed<0 or not ContentValidation.number(job.get("last_world_minutes")) or (job.last_world_minutes<0 or job.last_world_minutes>_clock.world_minutes+0.001) or not job.get("devices") is Dictionary or not job.get("step_results") is Array or not job.get("inputs_consumed") is bool:return _fail("invalid_workflow")
  var result := CookingWorkflowValidation.validate_recipes({str(job.recipe_id):job.definition},_inventory.items)
  if not result.ok or job.step_index<0 or job.step_index>=job.definition.steps.size():return _fail("invalid_workflow_definition")
  if not job.get("recipe_id") is String or job.get("recipe_version")!=job.definition.version:return _fail("invalid_recipe_version")
  for step in job.definition.steps:
   if not job.devices.get(step.capability) is String:return _fail("missing_workflow_device")
  for evidence in job.step_results:
   if not evidence is Dictionary or not evidence.get("step_id") is String or not ContentValidation.integer(evidence.get("grade")) or evidence.grade<0 or evidence.grade>3 or not ContentValidation.number(evidence.get("elapsed")) or evidence.elapsed<0:return _fail("invalid_step_evidence")
  if not ContentValidation.integer(job.get("quality_penalty")) or job.quality_penalty<0 or job.quality_penalty>2 or not job.get("sugar_id") is String:return _fail("invalid_workflow_quality")
  if job.status=="active" and job.definition.has("vessel_definition") and job.step_index>=1:
   var bowl := _inventory.items.get_item(StringName(str(job.get("bowl_id",""))))
   if bowl.get("kind")!="batch" or bowl.attributes.get("source_job_id")!=id or not ContentValidation.integer(bowl.attributes.get("portions_remaining")) or bowl.attributes.portions_remaining<1 or bowl.attributes.portions_remaining>int(job.definition.portions):return _fail("invalid_batch")
   if job.definition.steps[int(job.step_index)].kind=="batch_heat" and bowl.container_id!=str(job.devices[job.definition.steps[int(job.step_index)].capability])+":batch":return _fail("batch_device")
  if job.has("pending_slice"):
   if not job.pending_slice is Dictionary or not ContentValidation.number(job.pending_slice.get("elapsed")) or job.pending_slice.elapsed<0 or job.pending_slice.get("duration")!=job.definition.get("slice_minutes"):return _fail("invalid_slice")
  for instance_id in job.devices.values():
   if _inventory.items.get_item(StringName(instance_id)).is_empty():return _fail("orphan_workflow_device")
   var step: Dictionary=job.definition.steps[int(job.step_index)]
   if job.status=="active" and str(job.devices[step.capability])==str(instance_id) and _inventory.spaces.placement(StringName(instance_id)).get("location_id")!=job.get("location_id"):return _fail("orphan_workflow_device")
 _jobs=data.jobs.duplicate(true)
 _next_id=int(data.next_id)
 return ActionResult.success()
func _fail(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,StringName(key))

func jobs_at(instance_id: StringName) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for job in _jobs.values():
  if job.status!="active":continue
  var step: Dictionary=job.definition.steps[int(job.step_index)]
  if str(job.devices[step.capability])==str(instance_id):result.append(job.duplicate(true));continue
  if step.kind=="cold_wait" and job.get("bowl_id","")==str(_inventory.held_id()):
   var next: Dictionary=job.definition.steps[int(job.step_index)+1]
   if str(job.devices[next.capability])==str(instance_id):result.append(job.duplicate(true))
 return result
func _batch_action(job: Dictionary, action_id: StringName) -> ActionResult:
 var step: Dictionary=job.definition.steps[int(job.step_index)]
 if not _near(StringName(job.devices[step.capability]),StringName(job.location_id)):return _fail("equipment_out_of_reach")
 if action_id==&"stop_heat":
  job["heat_on"]=false
  _jobs[job.id]=job
  changed.emit()
  return ActionResult.success()
 if action_id!=&"slice":return _fail("invalid_cooking_stage")
 if float(job.elapsed)<float(step.duration):return ActionResult.failure(ActionResult.Code.TOO_EARLY,&"too_early")
 if job.has("pending_slice"):return _fail("slice_in_progress")
 if not _inventory.held_id().is_empty():return ActionResult.failure(ActionResult.Code.HANDS_BUSY,&"hands_busy")
 job["pending_slice"]={"elapsed":0.0,"duration":float(job.definition.slice_minutes)}
 _jobs[job.id]=job
 changed.emit()
 return ActionResult.success()
func _progress_slice(job: Dictionary, delta: float) -> void:
 if not job.has("pending_slice"):return
 var step: Dictionary=job.definition.steps[int(job.step_index)]
 if not _near(StringName(job.devices[step.capability]),StringName(job.location_id)):
  job.erase("pending_slice")
  changed.emit()
  return
 job.pending_slice.elapsed=float(job.pending_slice.elapsed)+delta
 if job.pending_slice.elapsed<float(job.pending_slice.duration) or not _inventory.held_id().is_empty():return
 var candidate := job.duplicate(true)
 var evidence := RecipeStepHandlers.apply(step,candidate,&"slice",{})
 if not evidence.ok:return
 var technique := int(evidence.details.grade)
 for result in candidate.step_results:
  if result.get("assess",true):technique=mini(technique,int(result.grade))
 var change := _inventory.items.candidate()
 var sliced := BatchPreparation.slice_portion(candidate,change,technique)
 if not sliced.ok:return
 candidate.erase("pending_slice")
 var lines: Array[Dictionary]=[]
 if sliced.details.empty:
  candidate.status="completed"
  change.state.reservations.erase(candidate.id)
 else:lines.append({"instance_id":candidate.devices[step.capability],"capability":step.capability,"units":1})
 var resources := _equipment.prepare_reservations(StringName(candidate.id),lines,true)
 if not resources.ok:return
 _commit(change,resources.details.state,candidate)

func available_foods(location_id: StringName) -> PackedStringArray:
 var result := PackedStringArray()
 # Finished portions remain sellable after their last raw inputs were consumed.
 for item in _inventory.items.snapshot().items.values():
  if item.kind!="prepared":continue
  var container := _inventory.items.get_container(StringName(item.container_id))
  var local: bool = container.location_id==str(location_id) and container.kind!="purchase_bag"
  var carried: bool = container.id=="player_hand" and _inventory.player_pose!=null and _inventory.player_pose.location_id==location_id
  var food_id := str(item.attributes.get("food_id",""))
  if (local or carried) and food_id!="" and not food_id in result:result.append(food_id)
 for recipe_id in _recipes:
  var definition: Dictionary=_recipes[recipe_id]
  if definition.has("vessel_definition"):continue
  if not definition.get("allowed_locations",[]).is_empty() and not str(location_id) in definition.allowed_locations:continue
  var fact := StringName(str(definition.get("learning_fact","")))
  if not fact.is_empty() and not _knowledge.has(fact):continue
  var usable := true
  for step in definition.steps:
   if _equipment.candidates(location_id,StringName(step.capability)).is_empty():usable=false
  if not usable:continue
  var active := false
  for job in _jobs.values():
   if job.status=="active" and job.location_id==str(location_id) and job.recipe_id==recipe_id:active=true
  var inputs: Array[Dictionary]=[]
  for input in definition.inputs:
   if input.get("required_storage")!="hand":inputs.append(input);continue
   var intermediate := false
   for item in _inventory.items.instances(StringName(input.definition_id)):
    var container := _inventory.items.get_container(StringName(item.container_id))
    if (container.location_id==str(location_id) and container.kind!="purchase_bag") or (container.id=="player_hand" and _inventory.player_pose.location_id==location_id):intermediate=true
   for precursor_id in _recipes:
    var precursor: Dictionary=_recipes[precursor_id]
    if precursor.get("filling_definition")!=input.definition_id:continue
    var precursor_inputs: Array[Dictionary]=[]
    precursor_inputs.assign(precursor.inputs)
    var capable := true
    for step in precursor.steps:
     if _equipment.candidates(location_id,StringName(step.capability)).is_empty():capable=false
    if capable and _inventory.available(location_id,precursor_inputs).ok:intermediate=true
    for job in _jobs.values():
     if job.status=="active" and job.location_id==str(location_id) and job.recipe_id==precursor_id:intermediate=true
   if not intermediate:usable=false
  if usable and (active or _inventory.available(location_id,inputs).ok) and not str(definition.output.food_id) in result:result.append(str(definition.output.food_id))
 return result
