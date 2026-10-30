class_name RecipeWorkflow
extends RefCounted
signal changed
signal attempt_started(job_id: StringName, recipe_id: StringName, evidence: Dictionary)
signal item_completed(job_id: StringName, item_id: StringName, quality: int)
var policy: ActionPolicy
var quality_provider: Callable
var sugar_provider: Callable
var serving_provider: Callable
var use_provider: Callable
var hygiene_provider: Callable
var _recipes: Dictionary
var _inventory: InventoryService
var _equipment: EquipmentService
var _clock: GameClock
var _knowledge: KnowledgeBook
var _jobs: Dictionary={}
var _active_jobs: Dictionary={}
var _next_id: int=1
func configure(recipes: Dictionary, inventory: InventoryService, equipment: EquipmentService, clock: GameClock, knowledge: KnowledgeBook) -> ActionResult:
 var result := CookingWorkflowValidation.validate_recipes(recipes,inventory.items)
 if not result.ok:return result
 _recipes=recipes.duplicate(true)
 _inventory=inventory
 _equipment=equipment
 _clock=clock
 _knowledge=knowledge
 _jobs.clear();_active_jobs.clear();_next_id=1
 return ActionResult.success()
func available_recipes(location_id: StringName, instance_id: StringName, selections: Dictionary={}) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 var item := _inventory.items.get_item(instance_id)
 if item.is_empty():return result
 for id in _recipes:
  var chosen := _selected_definition(_recipes[id],selections.get(id,{}))
  if not chosen.ok:continue
  var definition: Dictionary=chosen.details.definition
  if not _station_eligible(definition,location_id,instance_id).ok:continue
  var capability := StringName(definition.steps[0].capability)
  if not _equipment.is_usable(instance_id,location_id,capability):continue
  var eligibility := _requirements(definition,location_id,[str(instance_id)])
  result.append({"id":id,"definition":definition.duplicate(true),"available":eligibility.ok,"missing":eligibility.message_key,"details":eligibility.details})
 return result
func start(recipe_id: StringName, location_id: StringName, instance_ids: PackedStringArray, for_self: bool = false, selected_inputs: Dictionary={}) -> ActionResult:
 if not _recipes.has(str(recipe_id)):return _fail("unknown_recipe")
 var chosen := _selected_definition(_recipes[str(recipe_id)],selected_inputs)
 if not chosen.ok:return chosen
 var definition: Dictionary=chosen.details.definition
 if instance_ids.is_empty():return _fail("recipe_station_mismatch")
 var eligibility := _station_eligible(definition,location_id,StringName(instance_ids[0]))
 if not eligibility.ok:return eligibility
 var requirements := _requirements(definition,location_id,instance_ids)
 if not requirements.ok:return requirements
 var devices: Dictionary=requirements.details.devices
 devices[str(definition.steps[0].capability)]=str(instance_ids[0])
 var first: Dictionary=definition.steps[0]
 if not _near(StringName(devices[first.capability]),location_id):return _fail("equipment_out_of_reach")
 var action_class: StringName=&"cooking_for_self" if for_self else &"commercial_preparation"
 if policy!=null:
  var permitted := policy.attempt(action_class,policy.opportunity(action_class,str(recipe_id)+":"+str(_next_id)))
  if not permitted.ok:return permitted
 var id := "cook_%d" % _next_id
 var change := _inventory.items.candidate()
 var inputs: Array[Dictionary]=[]
 inputs.assign(definition.inputs)
 var available := _inventory.available(location_id,inputs)
 if not available.ok:return available
 change.state.reservations[id]=available.details.sources.duplicate(true)
 var evidence: Array=[]
 for source in available.details.sources:
  var input: Dictionary=change.state.items[source.item_id].duplicate(true)
  input["consumed_quantity"]=int(source.quantity)
  input["requirement_index"]=int(source.requirement_index)
  evidence.append(input)
 var job := {"id":id,"recipe_id":str(recipe_id),"recipe_version":int(definition.version),"definition":definition,"time_domain":"world_minutes","location_id":str(location_id),"step_index":0,"elapsed":0.0,"last_world_minutes":_clock.world_minutes,"started_at":_clock.world_minutes,"step_results":[],"devices":devices,"input_evidence":evidence,"quality_penalty":int(quality_provider.call()) if quality_provider.is_valid() else 0,"sugar_id":str(sugar_provider.call(StringName(instance_ids[0]))) if sugar_provider.is_valid() and not instance_ids.is_empty() else "","status":"active","inputs_consumed":false}
 if RecipeProcesses.supports(definition):RecipeProcesses.initialise(job)
 job["personal_use"]=for_self
 job["reaction_time_domain"]="simulation_seconds"
 job["current_hygiene_evidence"]=_hygiene_evidence(job,first)
 if definition.get("consume_on_start",true):_consume_all(change,job)
 var resources: Array[Dictionary]=[{"instance_id":devices[first.capability],"capability":first.capability,"units":1}]
 var equipment := _equipment.prepare_reservations(StringName(id),resources,true)
 if not equipment.ok:return equipment
 var result := _commit(change,equipment.details.state,job)
 if not result.ok:return result
 attempt_started.emit(StringName(id),recipe_id,{"location_id":str(location_id),"at":_clock.world_minutes})
 return ActionResult.success({"job_id":id,"cue":"chime"})
func act(job_id: StringName, action_id: StringName, options: Dictionary={}) -> ActionResult:
 if not _jobs.has(str(job_id)) or _jobs[str(job_id)].status!="active":return _fail("unknown_job")
 var candidate: Dictionary=_jobs[str(job_id)].duplicate(true)
 if action_id==&"cancel":return _cancel(candidate)
 if RecipeProcesses.supports(candidate.definition):
  var synced := _publish_process(RecipeProcesses.prepare_tick(self,_jobs[str(job_id)],_clock.frame(0)))
  if not synced.ok:return synced
  candidate=_jobs[str(job_id)].duplicate(true)
 var step: Dictionary=candidate.definition.steps[int(candidate.step_index)]
 if RecipeProcesses.supports(candidate.definition):return _publish_process(RecipeProcesses.prepare_action(self,candidate,action_id,options))
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
  var prepared_output := _prepared_output(candidate,change,options)
  if not prepared_output.ok:return prepared_output
  output=prepared_output.details.item
  candidate.status="completed"
  candidate["result_item_id"]=str(output.id)
  candidate["result_quality"]=output.quality_score
  candidate["result_snapshot"]=change.state.items[str(output.id)].attributes.duplicate(true)
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
 for id in _active_jobs.keys():
  var job: Dictionary=_jobs[id]
  if RecipeProcesses.supports(job.definition):
   _publish_process(RecipeProcesses.prepare_tick(self,job,frame))
   continue
  var world_delta := maxf(0,float(frame.world_minutes)-float(job.last_world_minutes))
  var elapsed_before := float(job.elapsed)
  var delta := world_delta
  job.last_world_minutes=float(frame.world_minutes)
  var step: Dictionary=job.definition.steps[int(job.step_index)]
  if job.get("reaction_time_domain","")=="simulation_seconds" and step.kind not in ["cold_wait","batch_heat"]:
   delta=float(frame.delta)*float(job.definition.get("presentation_minutes_per_second",1))
  if step.kind=="cold_wait":
   var bowl := _inventory.items.get_item(StringName(str(job.get("bowl_id",""))))
   if not bowl.is_empty():
    var container := _inventory.items.get_container(StringName(bowl.container_id))
    if _inventory._usable_storage(container,StringName(job.location_id),"cold"):job.elapsed=float(job.elapsed)+delta
  elif step.kind=="batch_heat":
   if job.get("heat_on",true):job.elapsed=float(job.elapsed)+delta
   var slice_delta := float(frame.delta)*float(job.definition.get("presentation_minutes_per_second",1)) if job.get("reaction_time_domain","")=="simulation_seconds" else delta
   _progress_slice(job,slice_delta)
  elif step.kind in ["heat","brew","wait"] or _near(StringName(job.devices[step.capability]),StringName(job.location_id)):job.elapsed=float(job.elapsed)+delta
  if step.kind in ["brew","batch_heat"] and float(job.elapsed)>=float(step.duration) and not job.has("ready_at"):
   var progress := float(job.elapsed)-elapsed_before
   job["ready_at"]=float(frame.world_minutes)-world_delta*clampf((float(job.elapsed)-float(step.duration))/maxf(progress,0.001),0,1)
   job["freshness"]=FoodFreshness.begin(float(job.ready_at),"warm" if step.kind=="brew" else "ambient")
   if step.kind=="batch_heat":job.elapsed=float(step.duration);job["heat_on"]=false
func job(id: StringName) -> Dictionary:
 return _jobs.get(str(id),{}).duplicate(true)
func progress_view(id: StringName) -> Dictionary:
 # Narrow observation for UI; frozen definitions and command state stay owned here.
 var record: Dictionary=_jobs.get(str(id),{})
 if record.is_empty() or record.status!="active":return {}
 var step: Dictionary=record.definition.steps[int(record.step_index)]
 var portions := 0
 if step.kind in ["batch_heat","batch_hold"]:portions=int(_inventory.items.get_item(StringName(str(record.get("bowl_id","")))).get("attributes",{}).get("portions_remaining",0))
 var freshness_stage := ""
 if step.kind=="batch_hold":
  var batch := _inventory.items.get_item(StringName(str(record.get("bowl_id",""))))
  if not batch.is_empty():freshness_stage=str(FoodFreshness.view(batch.attributes,_clock.world_minutes,_inventory.items.food_definitions).stage)
 return {"freshness_stage":freshness_stage,"step_id":str(step.id),"kind":str(step.kind),"elapsed":float(record.elapsed),"duration":float(step.duration),"portions":portions,"heat_on":bool(record.get("heat_on",true)),"slicing":record.has("pending_slice"),"heat":str(record.get("heat","medium")),"process":RecipeProcesses.supports(record.definition)}
func active_at(instance_id: StringName) -> Dictionary:
 for id in _active_jobs:
  var record: Dictionary=_jobs[id]
  if str(record.devices[record.definition.steps[int(record.step_index)].capability])==str(instance_id):return record.duplicate(true)
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
func _prepared_output(job: Dictionary, change: ItemChangeSet, options: Dictionary={}) -> ActionResult:
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
 item.initial_quality=RecipeProcesses.initial_quality(job,technique)
 item.prepared_at=float(job.get("ready_at",_clock.world_minutes))
 item.freshness=FoodFreshness.transition(job.get("freshness",FoodFreshness.begin(item.prepared_at)),"ambient",_clock.world_minutes)
 for input in job.input_evidence:
  if not input.attributes.has("freshness"):continue
  item.prepared_at=minf(item.prepared_at,float(input.attributes.prepared_at))
  item.freshness.exposure=maxf(float(item.freshness.exposure),FoodFreshness.exposure(input.attributes.freshness,_clock.world_minutes))
 item.method=StringName(str(job.definition.get("method","mix")))
 item.heat=&"medium"
 item.serving_format=StringName(str(job.definition.get("serving_format","cup" if job.recipe_id=="tea" else "plate" if str(job.recipe_id).begins_with("potato") else "sandwich")))
 item.quality_score=RecipeProcesses.grade_for(item.initial_quality)
 item.quality_key=StringName(job.definition.quality_keys[item.quality_score])
 var plan: ActionResult = serving_provider.call(item.food_id,options) if serving_provider.is_valid() else ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"incompatible_serving")
 if not plan.ok:return plan
 var serving := MenuService.consume_inputs(_inventory,change,StringName(job.location_id),plan.details.plan)
 if not serving.ok:return serving
 item.variant_id=StringName(plan.details.plan.variant_id);item.serving_format=StringName(plan.details.plan.serving_format);item.consumption_mode=StringName(plan.details.plan.consumption_mode);item.additions=PackedStringArray(plan.details.plan.additions)
 var attributes := item.snapshot()
 attributes["portioned_at"]=_clock.world_minutes
 attributes["serving_plan"]=plan.details.plan.duplicate(true);attributes["serving_evidence"]=serving.details.evidence
 attributes.merge({"personal_use":bool(job.get("personal_use",false)) or job.input_evidence.any(func(input):return input.attributes.get("personal_use",false)),"source_job_id":job.id,"technique_grade":technique,"mood_penalty":job.quality_penalty,"hygiene_penalty":hygiene_penalty,"step_evidence":job.step_results.duplicate(true)})
 change.state.items[str(item.id)]={"id":str(item.id),"definition_id":"prepared_food","kind":"prepared","quantity":1,"container_id":"player_hand","attributes":attributes}
 return ActionResult.success({"item":item})
func _hygiene_evidence(job: Dictionary, step: Dictionary) -> Dictionary:
 return hygiene_provider.call(PackedStringArray([str(job.devices[step.capability])])) if hygiene_provider.is_valid() else {}
func _commit(change: ItemChangeSet, equipment_state: Dictionary, job: Dictionary, record_use: bool=true) -> ActionResult:
 var validation := _inventory.items.validate_change(change)
 if not validation.ok:return validation
 if not _equipment.can_commit_reservations(equipment_state):return _fail("stale_equipment_change")
 var committed := _inventory.items.commit(change,false)
 if not committed.ok:return committed
 _equipment.commit_reservations(equipment_state)
 _jobs[job.id]=job.duplicate(true)
 if job.status=="active":_active_jobs[job.id]=true
 else:_active_jobs.erase(job.id)
 if str(job.id)=="cook_%d" % _next_id:_next_id+=1
 if record_use and job.status!="cancelled" and use_provider.is_valid() and int(job.get("use_recorded_step",-1))!=int(job.step_index):
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
  if not ContentValidation.integer(job.get("quality_penalty")) or not ContentValidation.bounded(job.quality_penalty,0,2) or not job.get("sugar_id") is String or not job.get("personal_use") is bool or job.get("reaction_time_domain")!="simulation_seconds":return _fail("invalid_workflow_state")
  if not job.get("recipe_id") is String:return _fail("invalid_recipe_version")
  var result := CookingWorkflowValidation.validate_recipes({str(job.recipe_id):job.definition},_inventory.items)
  if not result.ok or job.step_index<0 or job.step_index>=job.definition.steps.size():return _fail("invalid_workflow_definition")
  if job.get("recipe_version")!=job.definition.version:return _fail("invalid_recipe_version")
  if not job.get("input_evidence") is Array or not ContentValidation.bounded(job.get("started_at"),0,float(job.last_world_minutes)):return _fail("invalid_workflow_inputs")
  var consumed := {}
  for input in job.input_evidence:
   if not input is Dictionary or not input.get("id") is String or not input.get("definition_id") is String or not input.get("attributes") is Dictionary or input.get("kind")!="ingredient" or not ContentValidation.integer(input.get("consumed_quantity")) or input.consumed_quantity<1 or not ContentValidation.integer(input.get("quantity")) or input.quantity<input.consumed_quantity or not ContentValidation.integer(input.get("requirement_index")) or input.requirement_index<0 or input.requirement_index>=job.definition.inputs.size():return _fail("invalid_workflow_input")
   var index := int(input.requirement_index)
   var requirement: Dictionary=job.definition.inputs[index]
   if not _inventory.items.ingredient_matches(str(input.definition_id),str(requirement.definition_id)):return _fail("invalid_workflow_input_material")
   if requirement.has("grade") and requirement.grade!=input.attributes.get("lot",{}).get("grade"):return _fail("invalid_workflow_input_grade")
   var lot_result := IngredientLots.validate(input,_inventory.items._definitions,float(job.started_at))
   if not lot_result.ok:return lot_result
   consumed[index]=int(consumed.get(index,0))+int(input.consumed_quantity)
  for index in range(job.definition.inputs.size()):
   if int(consumed.get(index,0))!=int(job.definition.inputs[index].quantity):return _fail("invalid_workflow_input_quantity")
  for step in job.definition.steps:
   if not job.devices.get(step.capability) is String:return _fail("missing_workflow_device")
  for evidence in job.step_results:
   if not evidence is Dictionary or not evidence.get("step_id") is String or not ContentValidation.integer(evidence.get("grade")) or evidence.grade<0 or evidence.grade>3 or not ContentValidation.number(evidence.get("elapsed")) or evidence.elapsed<0:return _fail("invalid_step_evidence")
  if not ContentValidation.integer(job.get("quality_penalty")) or job.quality_penalty<0 or job.quality_penalty>2 or not job.get("sugar_id") is String:return _fail("invalid_workflow_quality")
  if RecipeProcesses.supports(job.definition):
   var process_result := RecipeProcesses.validate_saved(job,_inventory.items,_clock.world_minutes)
   if not process_result.ok:return process_result
  if job.status=="completed" and not RecipeProcesses.supports(job.definition) and not job.definition.has("vessel_definition"):
   if not job.get("result_snapshot") is Dictionary:return _fail("invalid_result_snapshot")
   var serving_check := RecipeProcesses.validate_serving(job.result_snapshot,_inventory.items,_clock.world_minutes)
   if not serving_check.ok:return serving_check
  if job.status=="active" and job.definition.has("vessel_definition") and job.step_index>=1:
   var bowl := _inventory.items.get_item(StringName(str(job.get("bowl_id",""))))
   if bowl.get("kind")!="batch" or bowl.attributes.get("source_job_id")!=id or not ContentValidation.integer(bowl.attributes.get("portions_remaining")) or bowl.attributes.portions_remaining<1 or bowl.attributes.portions_remaining>int(job.definition.portions):return _fail("invalid_batch")
   if job.definition.steps[int(job.step_index)].kind=="batch_heat" and bowl.container_id!=str(job.devices[job.definition.steps[int(job.step_index)].capability])+":batch":return _fail("batch_device")
  if not RecipeProcesses.supports(job.definition) and job.has("ready_at"):
   if not ContentValidation.bounded(job.ready_at,float(job.started_at),_clock.world_minutes) or not FoodFreshness.valid(job.get("freshness"),float(job.ready_at),_clock.world_minutes):return _fail("invalid_workflow_freshness")
  if job.has("pending_slice"):
   if not job.pending_slice is Dictionary or not ContentValidation.number(job.pending_slice.get("elapsed")) or job.pending_slice.elapsed<0 or job.pending_slice.get("duration")!=job.definition.get("slice_minutes"):return _fail("invalid_slice")
  for instance_id in job.devices.values():
   if _inventory.items.get_item(StringName(instance_id)).is_empty():return _fail("orphan_workflow_device")
   var step: Dictionary=job.definition.steps[int(job.step_index)]
   if job.status=="active" and str(job.devices[step.capability])==str(instance_id) and _inventory.spaces.placement(StringName(instance_id)).get("location_id")!=job.get("location_id"):return _fail("orphan_workflow_device")
 _jobs=data.jobs.duplicate(true)
 _active_jobs.clear()
 for id in _jobs:
  if _jobs[id].status=="active":_active_jobs[id]=true
 _next_id=int(data.next_id)
 return ActionResult.success()
func _fail(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,StringName(key))

func jobs_at(instance_id: StringName) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for id in _active_jobs:
  var job: Dictionary=_jobs[id]
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
  if float(job.elapsed)<float(step.duration):return ActionResult.failure(ActionResult.Code.TOO_EARLY,&"too_early")
  job["heat_on"]=false
  if job.has("freshness"):job.freshness=FoodFreshness.transition(job.freshness,"ambient",_clock.world_minutes)
  _jobs[job.id]=job
  changed.emit()
  return ActionResult.success()
 if action_id!=&"slice":return _fail("invalid_cooking_stage")
 if float(job.elapsed)<float(step.duration):return ActionResult.failure(ActionResult.Code.TOO_EARLY,&"too_early")
 if job.has("freshness"):
  var current := {"food_id":str(job.definition.get("freshness_food_id","")),"prepared_at":float(job.ready_at),"initial_quality":100.0,"freshness":job.freshness}
  if not FoodFreshness.view(current,_clock.world_minutes,_inventory.items.food_definitions).sellable:return _fail("food_unservable")
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
 var sliced := BatchPreparation.slice_portion(candidate,change,technique,_clock.world_minutes,_inventory.items.food_definitions)
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

func available_foods(location_id: StringName, include_prepared: bool=true) -> PackedStringArray:
 var result := PackedStringArray()
 # Finished portions remain sellable after their last raw inputs were consumed.
 for item in _inventory.items.snapshot().items.values():
  if not include_prepared or item.kind!="prepared":continue
  var container := _inventory.items.get_container(StringName(item.container_id))
  var local: bool = container.location_id==str(location_id) and container.kind!="purchase_bag"
  var carried: bool = container.id=="player_hand" and _inventory.player_pose!=null and _inventory.player_pose.location_id==location_id
  var food_id := str(item.attributes.get("food_id",""))
  if (local or carried) and food_id!="" and FoodFreshness.view(item.attributes,_clock.world_minutes,_inventory.items.food_definitions).sellable and not food_id in result:result.append(food_id)
 for recipe_id in _recipes:
  var definition: Dictionary=_recipes[recipe_id]
  if RecipeProcesses.supports(definition):
   for id in _active_jobs:
    var job: Dictionary=_jobs[id]
    if job.recipe_id!=recipe_id or job.location_id!=str(location_id) or job.definition.steps[int(job.step_index)].kind!="batch_hold":continue
    var bowl := _inventory.items.get_item(StringName(str(job.get("bowl_id",""))))
    if not bowl.is_empty() and FoodFreshness.view(bowl.attributes,_clock.world_minutes,_inventory.items.food_definitions).sellable and not str(definition.output.food_id) in result:result.append(str(definition.output.food_id))
   continue
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

func _publish_process(prepared: ActionResult) -> ActionResult:
 if not prepared.ok or not prepared.details.get("publish",false):return prepared
 var data: Dictionary=prepared.details
 var result := _commit(data.change,data.equipment,data.job,not data.get("automatic",false) and not data.get("skip_use",false))
 if not result.ok:return result
 if data.has("item"):
  var item: PreparedItem=data.item
  item_completed.emit(StringName(data.job.id),item.id,item.quality_score)
  return ActionResult.success({"completed":true,"item":item,"score":item.quality_score,"cue":"chime"})
 return ActionResult.success({"cue":"chime"})
func station_status(instance_id: StringName) -> Dictionary:
 for id in _active_jobs:
  var record: Dictionary=_jobs[id]
  var step: Dictionary=record.definition.steps[int(record.step_index)]
  if str(record.devices[step.capability])!=str(instance_id):continue
  return {"id":id,"process":RecipeProcesses.supports(record.definition),"recipe_id":record.recipe_id,"label":str(record.definition.label),"step":{"id":str(step.id),"label":str(step.label),"kind":str(step.kind),"duration":float(step.duration),"action":str(step.action)},"elapsed":float(record.elapsed),"heat":str(record.get("heat","medium"))}
 return {}
func heating_states(location_id: StringName) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for id in _active_jobs:
  var job: Dictionary=_jobs[id]
  if job.location_id!=str(location_id):continue
  var step: Dictionary=job.definition.steps[int(job.step_index)]
  if step.kind in ["heat","brew","batch_heat","passive_heat","batch_hold"] and job.get("heat_on",true) and job.get("heat","medium")!="off":result.append({"capability":str(step.capability),"method":str(job.definition.get("method","brew" if step.capability=="heat_water" else "")),"heat":str(job.get("heat","medium"))})
 return result
func result_for(job_id: StringName, item_id: StringName) -> Dictionary:
 var record: Dictionary=_jobs.get(str(job_id),{})
 if record.get("portion_results",{}).has(str(item_id)):return record.portion_results[str(item_id)].duplicate(true)
 if record.get("result_item_id")==str(item_id):return record.get("result_snapshot",{"id":str(item_id),"quality_score":record.get("result_quality",-1)}).duplicate(true)
 return {}

func _selected_definition(definition: Dictionary, selections: Dictionary) -> ActionResult:
 var candidate := definition.duplicate(true)
 for id in selections:
  if not selections[id] is String:return _fail("out_of_stock")
  var found := false
  for input in candidate.inputs:
   if input.definition_id!=id:continue
   if input.has("grade") and input.grade!=selections[id]:return _fail("out_of_stock")
   var known := false
   for value in _inventory.items._definitions.values():
    var material: Dictionary=value.get("material",{})
    if material.get("family")==_inventory.items.ingredient_family(str(id)) and material.get("grade")==selections[id]:known=true;break
   if not known:return _fail("out_of_stock")
   input["grade"]=selections[id];found=true
  if not found:return _fail("out_of_stock")
 return ActionResult.success({"definition":candidate})
func grade_options(required: StringName, location_id: StringName) -> PackedStringArray:
 var result := PackedStringArray()
 for item in _inventory.material_instances(required):
  var container := _inventory.items.get_container(StringName(item.container_id))
  var storage := str(_inventory.items.definition(StringName(item.definition_id)).get("required_storage","dry"))
  if not _inventory._usable_storage(container,location_id,storage):continue
  var grade := str(item.attributes.get("lot",{}).get("grade",""))
  if not grade.is_empty() and not grade in result:result.append(grade)
 return result
