class_name RecipeProcesses
extends RefCounted
## Finite process operations prepared for RecipeWorkflow; no separate state owner.
const HEATS := ["off","low","medium","high"]
const METHODS := ["saute","fry","grill","boil","simmer","roast","brew","mix"]
static func supports(definition: Dictionary) -> bool:return definition.get("process_version",1)==2
static func validate(definition: Dictionary, items: ItemStore) -> ActionResult:
 if not supports(definition):return ActionResult.success()
 if not ContentValidation.integer(definition.get("portions")) or not ContentValidation.bounded(definition.portions,1,12) or items.definition(StringName(str(definition.get("vessel_definition","")))).get("kind")!="batch":return _fail("batch")
 if not definition.get("method") in METHODS or not definition.get("default_heat") in HEATS.slice(1) or not definition.get("ideal_heat") in HEATS.slice(1) or not definition.get("hold_heat") in ["off","low"]:return _fail("method")
 var cooking := 0;var holding := 0
 for step in definition.steps:
  if step.kind=="passive_heat":cooking+=1
  if step.kind=="batch_hold":holding+=1
  if step.has("allow_early") and not step.allow_early is bool:return _fail("allow_early")
  if step.has("vessel_after") and not step.vessel_after in ["hand","device"]:return _fail("vessel_after")
 if cooking!=1 or holding!=1 or definition.steps[-1].kind!="batch_hold" or definition.steps[0].kind!="prepare":return _fail("phases")
 return ActionResult.success()
static func initialise(job: Dictionary) -> void:
 job["heat"]=str(job.definition.default_heat)
 job["heat_error"]=0.0;job["heat_history"]=[]
 job["portion_results"]={};job["portions_served"]=0
 job["ready_at"]=-1.0;job["initial_quality"]=-1.0
static func prepare_action(owner: RecipeWorkflow, original: Dictionary, action: StringName, options: Dictionary={}) -> ActionResult:
 var job := original.duplicate(true)
 var step: Dictionary=job.definition.steps[int(job.step_index)]
 var device := str(job.devices[step.capability])
 if not owner._near(StringName(device),StringName(job.location_id)):return owner._fail("equipment_out_of_reach")
 var change := owner._inventory.items.candidate()
 if str(action).begins_with("heat:"):
  var heat := str(action).trim_prefix("heat:")
  if not heat in HEATS or not step.kind in ["passive_heat","batch_hold"]:return owner._fail("invalid_cooking_stage")
  job.heat=heat
  if step.kind=="batch_hold" and change.state.items.has(str(job.bowl_id)):
   var attributes: Dictionary=change.state.items[str(job.bowl_id)].attributes
   attributes.freshness=FoodFreshness.transition(attributes.freshness,"ambient" if heat=="off" else "warm",owner._clock.world_minutes)
  var record := {"at":owner._clock.world_minutes,"heat":heat}
  if job.heat_history.size()>=32:job.heat_history.remove_at(1)
  job.heat_history.append(record)
  if job.has("bowl_id") and change.state.items.has(job.bowl_id):change.state.items[job.bowl_id].attributes.heat=heat
  return _prepared(owner,job,change)
 if str(action)!=str(step.action):return owner._fail("invalid_cooking_stage")
 if step.kind=="passive_heat":return ActionResult.failure(ActionResult.Code.TOO_EARLY,&"too_early")
 if step.kind=="batch_hold":
  if not owner._inventory.held_id().is_empty():return ActionResult.failure(ActionResult.Code.HANDS_BUSY,&"hands_busy")
  return _serve(owner,job,change,options)
 var elapsed := float(job.elapsed)
 if elapsed<float(step.duration) and not step.get("allow_early",false):return ActionResult.failure(ActionResult.Code.TOO_EARLY,&"too_early")
 var grade := 3 if elapsed>=float(step.duration) else 1
 if step.kind=="prepare":
  if step.get("consume_inputs",true):owner._consume_all(change,job)
  var created := _vessel(owner,job,change,device,str(step.get("vessel_after","hand")))
  if not created.ok:return created
 elif step.kind=="soak":
  var taken := _move_vessel(job,change,"player_hand")
  if not taken.ok:return taken
 elif step.kind=="transfer":
  if change.state.items.get(str(job.get("bowl_id","")),{}).get("container_id")!="player_hand":return owner._fail("carry_prepared_vessel")
  _slot(change,device,str(job.location_id))
  var moved := _move_vessel(job,change,device+":batch")
  if not moved.ok:return moved
 else:return owner._fail("invalid_cooking_stage")
 job.step_results.append({"step_id":step.id,"grade":grade,"elapsed":elapsed,"assess":step.get("assess",true),"hygiene_evidence":job.get("current_hygiene_evidence",{})})
 job.step_index=int(job.step_index)+1;job.elapsed=0.0;job.last_world_minutes=owner._clock.world_minutes
 var next: Dictionary=job.definition.steps[int(job.step_index)]
 job["current_hygiene_evidence"]=owner._hygiene_evidence(job,next)
 if change.state.items.has(str(job.get("bowl_id",""))):
  change.state.items[job.bowl_id].attributes.state="soaking" if next.kind=="soak" else "cooking" if next.kind=="passive_heat" else "prepared"
 var prepared := _prepared(owner,job,change)
 if prepared.ok:prepared.details["skip_use"]=next.kind=="transfer"
 return prepared
static func prepare_tick(owner: RecipeWorkflow, job: Dictionary, frame: Dictionary) -> ActionResult:
 var step: Dictionary=job.definition.steps[int(job.step_index)]
 var now := float(frame.world_minutes)
 var delta := maxf(0,now-float(job.last_world_minutes))
 if step.kind=="prepare":
  if owner._near(StringName(job.devices[step.capability]),StringName(job.location_id)):job.elapsed=float(job.elapsed)+float(frame.delta)*float(job.definition.get("presentation_minutes_per_second",1))
 elif step.kind=="soak" or step.kind=="batch_hold":job.elapsed=float(job.elapsed)+delta
 elif step.kind=="passive_heat":
  var rate := _rate(str(job.heat),str(job.definition.ideal_heat))
  var progress := float(job.elapsed)+delta*rate
  var difference := absf(float(HEATS.find(str(job.heat))-HEATS.find(str(job.definition.ideal_heat))))
  if rate>0 and progress>=float(step.duration):
   var candidate := job.duplicate(true)
   var needed := maxf(0,float(step.duration)-float(job.elapsed))/rate
   candidate.heat_error=float(job.heat_error)+needed*difference
   candidate.ready_at=float(job.last_world_minutes)+needed
   var grade := 3-clampi(floori(float(candidate.heat_error)/maxf(1,float(step.duration))*2.0),0,3)
   for result in candidate.step_results:
    if result.get("assess",true):grade=mini(grade,int(result.grade))
   candidate.step_results.append({"step_id":step.id,"grade":grade,"elapsed":float(step.duration),"assess":true,"hygiene_evidence":candidate.get("current_hygiene_evidence",{})})
   candidate.initial_quality=initial_quality(candidate,grade)
   candidate.step_index=int(candidate.step_index)+1
   candidate.elapsed=maxf(0,now-float(candidate.ready_at));candidate.last_world_minutes=now
   candidate.heat=str(candidate.definition.hold_heat)
   var next: Dictionary=candidate.definition.steps[int(candidate.step_index)]
   candidate["current_hygiene_evidence"]=owner._hygiene_evidence(candidate,next)
   var change := owner._inventory.items.candidate()
   var bowl: Dictionary=change.state.items.get(str(candidate.get("bowl_id","")),{})
   if bowl.is_empty():return owner._fail("missing_batch")
   bowl.attributes.merge({"state":"ready","ready_at":candidate.ready_at,"initial_quality":candidate.initial_quality,"heat":candidate.heat,"food_id":str(candidate.definition.output.food_id),"prepared_at":candidate.ready_at,"freshness":FoodFreshness.begin(float(candidate.ready_at),"ambient" if candidate.heat=="off" else "warm")},true)
   var prepared := _prepared(owner,candidate,change)
   if prepared.ok:prepared.details["automatic"]=true
   return prepared
  job.elapsed=progress
  if rate>0:job.heat_error=float(job.heat_error)+delta*difference
 job.last_world_minutes=now
 return ActionResult.success({"publish":false})
static func _serve(owner: RecipeWorkflow, job: Dictionary, change: ItemChangeSet, options: Dictionary) -> ActionResult:
 var batch: Dictionary=change.state.items.get(str(job.get("bowl_id","")),{})
 if batch.is_empty() or int(batch.attributes.portions_remaining)<1:return owner._fail("batch_empty")
 var age := FoodFreshness.view(batch.attributes,owner._clock.world_minutes,owner._inventory.items.food_definitions)
 if not age.sellable:return owner._fail("food_unservable")
 var plan: ActionResult = owner.serving_provider.call(StringName(str(job.definition.output.food_id)),options) if owner.serving_provider.is_valid() else ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"incompatible_serving")
 if not plan.ok:return plan
 var consumed := MenuService.consume_inputs(owner._inventory,change,StringName(job.location_id),plan.details.plan)
 if not consumed.ok:return consumed
 var serving: Array=consumed.details.evidence
 var output := PreparedItem.new()
 output.id=StringName("food_%d" % int(change.state.next_id));change.state.next_id=int(change.state.next_id)+1
 output.recipe_id=StringName(job.recipe_id);output.food_id=StringName(job.definition.output.food_id)
 output.initial_quality=float(job.initial_quality);output.prepared_at=float(job.ready_at)
 output.freshness=FoodFreshness.transition(batch.attributes.freshness,"ambient",owner._clock.world_minutes)
 output.batch_id=StringName(job.bowl_id);output.method=StringName(job.definition.method)
 output.heat=StringName(job.heat);output.serving_format=StringName(job.definition.get("serving_format","sandwich"))
 output.quality_score=grade_for(output.initial_quality)
 output.quality_key=StringName(job.definition.quality_keys[output.quality_score])
 var attributes := output.snapshot()
 job.portions_served=int(job.portions_served)+1
 attributes.merge({"source_job_id":job.id,"portion_index":job.portions_served,"personal_use":bool(job.get("personal_use",false)),"serving_plan":plan.details.plan.duplicate(true),"serving_evidence":serving,"portioned_at":owner._clock.world_minutes})
 change.state.items[str(output.id)]={"id":str(output.id),"definition_id":"prepared_food","kind":"prepared","quantity":1,"container_id":"player_hand","attributes":attributes}
 batch.attributes.portions_remaining=int(batch.attributes.portions_remaining)-1
 job.portion_results[str(output.id)]=attributes.duplicate(true)
 job["result_item_id"]=str(output.id);job["result_quality"]=output.quality_score
 if int(batch.attributes.portions_remaining)==0:
  change.state.items.erase(str(job.bowl_id));change.state.reservations.erase(str(job.id));job.status="completed"
 var result := _prepared(owner,job,change)
 if result.ok:result.details["item"]=output
 return result
static func _vessel(owner: RecipeWorkflow, job: Dictionary, change: ItemChangeSet, device: String, where: String) -> ActionResult:
 if where=="hand" and not owner._inventory.held_id().is_empty():return ActionResult.failure(ActionResult.Code.HANDS_BUSY,&"hands_busy")
 var container := "player_hand"
 if where=="device":_slot(change,device,str(job.location_id));container=device+":batch"
 var id := "item_%d" % int(change.state.next_id);change.state.next_id=int(change.state.next_id)+1
 change.state.items[id]={"id":id,"definition_id":job.definition.vessel_definition,"kind":"batch","quantity":1,"container_id":container,"attributes":{"source_job_id":job.id,"portions_total":int(job.definition.portions),"portions_remaining":int(job.definition.portions),"state":"prepared","ready_at":-1.0,"initial_quality":-1.0,"method":job.definition.method,"heat":job.heat,"personal_use":bool(job.get("personal_use",false))}}
 job["bowl_id"]=id
 return ActionResult.success()
static func _slot(change: ItemChangeSet, device: String, location: String) -> void:
 change.state.containers[device+":batch"]={"id":device+":batch","location_id":location,"kind":"appliance","capacity":1,"allowed_tags":["batch"],"host_id":device}
static func _move_vessel(job: Dictionary, change: ItemChangeSet, destination: String) -> ActionResult:
 var id := str(job.get("bowl_id",""))
 if not change.state.items.has(id):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"missing_batch")
 if destination=="player_hand":
  for item in change.state.items.values():
   if item.container_id=="player_hand":return ActionResult.failure(ActionResult.Code.HANDS_BUSY,&"hands_busy")
 change.state.items[id].container_id=destination
 return ActionResult.success()
static func _prepared(owner: RecipeWorkflow, job: Dictionary, change: ItemChangeSet) -> ActionResult:
 var lines: Array[Dictionary]=[]
 if job.status=="active":
  var step: Dictionary=job.definition.steps[int(job.step_index)]
  lines.append({"instance_id":job.devices[step.capability],"capability":step.capability,"units":1})
 var equipment := owner._equipment.prepare_reservations(StringName(job.id),lines,true)
 if not equipment.ok:return equipment
 return ActionResult.success({"publish":true,"job":job,"change":change,"equipment":equipment.details.state})
static func initial_quality(job: Dictionary, technique: int) -> float:
 if technique==0:return 0
 var hygiene := 0
 for record in job.step_results:hygiene=maxi(hygiene,int(record.get("hygiene_evidence",{}).get("penalty",0)))
 for input in job.input_evidence:hygiene=maxi(hygiene,int(input.attributes.get("hygiene_penalty",0)))
 return clampf(technique*25.0+IngredientLots.quality(job.input_evidence)*25.0-int(job.quality_penalty)*25.0-hygiene*25.0,25,100)
static func grade_for(score: float) -> int:return 3 if score>=85 else 2 if score>=60 else 1 if score>=25 else 0
static func _rate(heat: String, ideal: String) -> float:
 if heat=="off":return 0
 if heat==ideal:return 1
 return 1.0+0.3*float(HEATS.find(heat)-HEATS.find(ideal))
static func validate_saved(job: Dictionary, items: ItemStore, now: float) -> ActionResult:
 if not job.get("heat") in HEATS or not ContentValidation.bounded(job.get("heat_error"),0,maxf(1,(now-float(job.started_at))*3.0)) or not job.get("heat_history") is Array or job.heat_history.size()>32 or not job.get("portion_results") is Dictionary or not ContentValidation.integer(job.get("portions_served")) or job.portions_served!=job.portion_results.size() or job.portions_served<0 or job.portions_served>int(job.definition.portions):return _fail("saved_shape")
 var previous := float(job.started_at)
 for event in job.heat_history:
  if not event is Dictionary or not CharacterLifeValidation.keys(event,["at","heat"]) or not ContentValidation.bounded(event.at,previous,now) or not event.heat in HEATS:return _fail("saved_heat")
  previous=float(event.at)
 var step: Dictionary=job.definition.steps[int(job.step_index)]
 if not ContentValidation.bounded(job.get("ready_at"),-1,now) or not ContentValidation.bounded(job.get("initial_quality"),-1,100):return _fail("saved_quality")
 if step.kind=="batch_hold":
  if float(job.ready_at)<float(job.started_at) or float(job.initial_quality)<0:return _fail("saved_ready")
 elif job.portions_served!=0 or float(job.ready_at)!=-1 or float(job.initial_quality)!=-1:return _fail("saved_early_result")
 var seen := {}
 for id in job.portion_results:
  var r: Variant=job.portion_results[id]
  if not r is Dictionary or r.get("id")!=id or r.get("recipe_id")!=job.recipe_id or r.get("food_id")!=job.definition.output.food_id or r.get("batch_id")!=job.get("bowl_id") or not ContentValidation.bounded(r.get("initial_quality"),0,100) or not is_equal_approx(float(r.initial_quality),float(job.initial_quality)) or not ContentValidation.bounded(r.get("prepared_at"),float(job.started_at),now) or not is_equal_approx(float(r.prepared_at),float(job.ready_at)) or not ContentValidation.integer(r.get("quality_score")) or r.quality_score!=grade_for(float(r.initial_quality)) or r.get("quality_key")!=job.definition.quality_keys[int(r.quality_score)]:return _fail("saved_portion")
  if not ContentValidation.integer(r.get("portion_index")) or r.portion_index<1 or r.portion_index>job.portions_served or seen.has(int(r.portion_index)) or not ContentValidation.bounded(r.get("portioned_at"),float(job.ready_at),now) or not r.get("serving_evidence") is Array:return _fail("saved_portion_source")
  if r.get("method")!=job.definition.method or not r.get("heat") in HEATS or r.get("sugar_id")!="" or r.get("source_job_id")!=job.id or r.get("personal_use")!=job.personal_use:return _fail("saved_portion_recipe")
  seen[int(r.portion_index)]=true
  if not FoodFreshness.valid(r.get("freshness"),float(job.ready_at),float(r.portioned_at)):return _fail("saved_portion_freshness")
  var serving_check := validate_serving(r,items,now)
  if not serving_check.ok:return serving_check
 if job.status=="active" and int(job.step_index)>0:
  var batch := items.get_item(StringName(str(job.get("bowl_id",""))))
  if batch.get("kind")!="batch" or batch.get("definition_id")!=job.definition.vessel_definition or batch.attributes.get("source_job_id")!=job.id or batch.attributes.get("portions_total")!=job.definition.portions or batch.attributes.get("portions_remaining")!=int(job.definition.portions)-int(job.portions_served):return _fail("saved_batch")
  if step.kind in ["passive_heat","batch_hold","soak"] and batch.container_id!=str(job.devices[step.capability])+":batch":return _fail("saved_batch_device")
  if step.kind=="batch_hold" and not FoodFreshness.valid(batch.attributes.get("freshness"),float(job.ready_at),now):return _fail("saved_batch_freshness")
  if step.kind=="batch_hold" and (not is_equal_approx(float(batch.attributes.get("ready_at",-1)),float(job.ready_at)) or not is_equal_approx(float(batch.attributes.get("initial_quality",-1)),float(job.initial_quality))):return _fail("saved_batch_quality")
 if job.status=="completed" and job.portions_served!=int(job.definition.portions):return _fail("saved_yield")
 return ActionResult.success()
static func validate_serving(record: Dictionary, items: ItemStore, now: float) -> ActionResult:
 if not MenuService.validate_plan(record.get("serving_plan"),items.serving_catalog) or not record.get("serving_evidence") is Array or not ContentValidation.bounded(record.get("portioned_at"),0,now):return _fail("saved_serving_plan")
 for key in ["variant_id","food_id","serving_format","consumption_mode","additions"]:
  if record.get(key)!=record.serving_plan.get(key):return _fail("saved_serving_identity")
 var counts := {}
 for input in record.serving_evidence:
  if not input is Dictionary or not input.get("attributes") is Dictionary or not input.get("definition_id") is String or not ContentValidation.integer(input.get("consumed_quantity")) or input.consumed_quantity<1 or not ContentValidation.integer(input.get("requirement_index")) or input.requirement_index<0 or input.requirement_index>=record.serving_plan.inputs.size():return _fail("saved_serving_input")
  var index := int(input.requirement_index)
  if not items.ingredient_matches(str(input.definition_id),str(record.serving_plan.inputs[index].definition_id)):return _fail("saved_serving_material")
  var checked := IngredientLots.validate(input,items._definitions,float(record.portioned_at))
  if not checked.ok:return checked
  counts[index]=int(counts.get(index,0))+int(input.consumed_quantity)
 for index in range(record.serving_plan.inputs.size()):
  if int(counts.get(index,0))!=int(record.serving_plan.inputs[index].quantity):return _fail("saved_serving_quantity")
 return ActionResult.success()
static func preparation_matches(item: Dictionary, proof: Dictionary) -> bool:
 for key in ["id","food_id","recipe_id","batch_id","method","variant_id","serving_format","consumption_mode","additions"]:
  if not item.has(key) or not proof.has(key) or item[key]!=proof[key]:return false
 if not item.get("freshness") is Dictionary or not proof.get("freshness") is Dictionary:return false
 var time: Variant = item.freshness.get("at",-1)
 if not ContentValidation.number(time) or not ContentValidation.number(proof.freshness.get("at")) or float(time)<float(proof.freshness.at):return false
 if not ContentValidation.bounded(item.freshness.get("exposure"),float(proof.freshness.exposure)+maxf(0,float(time)-float(proof.freshness.at))*0.25-0.001,float(proof.freshness.exposure)+maxf(0,float(time)-float(proof.freshness.at))+0.001):return false
 for key in ["initial_quality","prepared_at"]:
  if not ContentValidation.number(item.get(key)) or not ContentValidation.number(proof.get(key)) or not is_equal_approx(float(item[key]),float(proof[key])):return false
 return true
static func _fail(reason: String) -> ActionResult:return ContentValidation.fail("recipe_workflows.process."+reason)
