class_name BatchPreparation
extends RefCounted
## Candidate-only vessel and portion operations; ItemStore remains their owner.
static func create_vessel(job: Dictionary, change: ItemChangeSet) -> ActionResult:
 for item in change.state.items.values():
  if item.container_id=="player_hand":return ActionResult.failure(ActionResult.Code.HANDS_BUSY,&"hands_busy")
 var id := "item_%d" % int(change.state.next_id)
 change.state.next_id=int(change.state.next_id)+1
 change.state.items[id]={"id":id,"definition_id":job.definition.vessel_definition,"kind":"batch","quantity":1,"container_id":"player_hand","attributes":{"source_job_id":job.id,"portions_total":int(job.definition.portions),"portions_remaining":int(job.definition.portions),"state":"marinating","quality_evidence":job.step_results.duplicate(true)}}
 job["bowl_id"]=id
 return ActionResult.success()
static func load_vessel(job: Dictionary, change: ItemChangeSet, device_id: String) -> ActionResult:
 var id := str(job.get("bowl_id",""))
 if not change.state.items.has(id) or change.state.items[id].container_id!="player_hand":return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"carry_marinated_bowl")
 var slot_id := device_id+":batch"
 change.state.containers[slot_id]={"id":slot_id,"location_id":job.location_id,"kind":"appliance","capacity":1,"allowed_tags":["batch"],"host_id":device_id}
 change.state.items[id].container_id=slot_id
 change.state.items[id].attributes.state="roasting"
 job["heat_on"]=true
 return ActionResult.success()
static func slice_portion(job: Dictionary, change: ItemChangeSet, technique: int) -> ActionResult:
 var bowl_id := str(job.get("bowl_id",""))
 if not change.state.items.has(bowl_id):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"missing_batch")
 var batch: Dictionary=change.state.items[bowl_id]
 if int(batch.attributes.portions_remaining)<=0:return ActionResult.failure(ActionResult.Code.OUT_OF_STOCK,&"batch_empty")
 var id := "item_%d" % int(change.state.next_id)
 change.state.next_id=int(change.state.next_id)+1
 change.state.items[id]={"id":id,"definition_id":job.definition.filling_definition,"kind":"ingredient","quantity":1,"container_id":"player_hand","attributes":{"source_job_id":job.id,"technique_grade":technique,"mood_penalty":job.quality_penalty,"step_evidence":job.step_results.duplicate(true),"heat_elapsed":job.elapsed}}
 batch.attributes.portions_remaining=int(batch.attributes.portions_remaining)-1
 var empty: bool = batch.attributes.portions_remaining==0
 if empty:change.state.items.erase(bowl_id)
 return ActionResult.success({"item_id":id,"empty":empty})
