class_name LivingSpacesSaveValidation
extends RefCounted
static func validate(session: GameSession, envelope: Dictionary) -> ActionResult:
 if envelope.get("schema_revision")!=7: return _fail("schema_revision")
 var social_result := session.social_life.cross_validate()
 if not social_result.ok:return social_result
 var items := session.items.snapshot()
 var placements: Dictionary = session.spaces.snapshot().placements
 for id in items.items:
  var item: Dictionary = items.items[id]
  var container: Dictionary = items.containers[item.container_id]
  if container.kind=="placed" and not placements.has(id):return _fail("unplaced_world_item")
  if item.kind=="prepared":
   var raw: Dictionary=item.attributes
   var food := session.foods.definition(StringName(str(raw.get("food_id",""))))
   if raw.get("id")!=id or food.is_empty() or not ContentValidation.integer(raw.get("quality_score")) or int(raw.quality_score)<0 or int(raw.quality_score)>3 or not raw.get("sugar_id") is String or raw.get("quality_key")!=food.quality_keys[int(raw.quality_score)]:return _fail("food")
   if food.has("sugars"):
    if not food.sugars.has(raw.sugar_id):return _fail("food_sugar")
   elif raw.sugar_id!="":return _fail("food_sugar")
   if raw.has("source_job_id"):
    var job := session.workflow.job(StringName(raw.source_job_id))
    if job.get("result_item_id")!=id or job.get("result_quality")!=raw.quality_score:return _fail("food_source")
 for container in items.containers.values():
  if container.host_id!="" and not items.items.has(container.host_id):return _fail("container_host")
  if container.kind=="surface" and not session.items.items_in(StringName(container.id)).is_empty():
   if not placements.has(container.host_id):return _fail("food_on_stored_surface")
   for p in placements.values():
    if p.host_id==container.host_id:return _fail("food_on_occupied_surface")
 var workflows: Dictionary=session.workflow.snapshot().jobs
 for id in items.reservations:
  if not workflows.has(id) or workflows[id].status!="active":return _fail("orphan_ingredient_reservation")
 for id in workflows:
  var job: Dictionary=workflows[id]
  if job.status!="active":continue
  var step: Dictionary=job.definition.steps[int(job.step_index)]
  var resource_lines: Array=session.equipment.snapshot().reservations.get(id,[])
  if resource_lines.size()!=1 or resource_lines[0].instance_id!=job.devices[step.capability] or resource_lines[0].capability!=step.capability:return _fail("missing_workflow_resource")
  if not job.inputs_consumed and items.reservations.get(id,[]).is_empty():return _fail("missing_workflow_ingredients")
 for id in session.equipment.snapshot().reservations:
  if not workflows.has(id) or workflows[id].status!="active":return _fail("orphan_equipment_reservation")
 if session.home.snapshot()!=envelope.state.home:return _fail("home_projection")
 for actor in session._actor_snapshots():
  if session.locations.kind(StringName(actor.location_id))==&"":return _fail("actor_location")
  if not session.locations.is_physical(StringName(actor.location_id)):continue
  if FootprintGeometry.blocked(Vector2(actor.ground[0],actor.ground[1]),session.spaces.solids(StringName(actor.location_id)),0):return _fail("actor_in_furniture")
 var journey: Dictionary=session.travel.snapshot().journey
 if not journey.is_empty():
  var phase := str(journey.phase)
  var route := session.travel.route()
  var expected := "transit" if phase in ["outbound","returning"] else str(route.destination) if phase=="browsing" else str(session.location_id)
  if str(session.location_id)!=expected:return _fail("journey_pose")
  if route.kind=="shop":
   var bag := session.items.get_container(StringName(journey.purchase_container_id))
   if bag.get("kind")!="purchase_bag" or bag.location_id!=journey.return_location:return _fail("journey_bag")
 elif not session.locations.is_physical(session.location_id):return _fail("orphan_virtual_pose")
 for receipt in session.shops.snapshot().receipts.values():
  if session.items.get_container(StringName(receipt.bag_id)).get("kind")!="purchase_bag":return _fail("receipt_bag")
 for visit in session.visitors.visits.values():
  var pending := session.service.pending_for(visit.id)
  if (visit.shopping_state==&"pending")!=(pending!=null):return _fail("visit_pending_order")
  if pending!=null and (pending.food_id!=visit.food_id or pending.id!=visit.order_id or visit.served):return _fail("visit_order_projection")
  if visit.shopping_state==&"approaching" and (not visit.phase in [&"arriving",&"staying"] or visit.food_id.is_empty()):return _fail("visit_approach")
 var experiences := session.customer_experience.snapshot()
 for id in experiences.active:
  var record: Dictionary=experiences.active[id]
  var visit: VisitState=session.visitors.visits.get(id)
  if visit==null or visit.phase==&"leaving" or record.get("character_id")!=str(visit.character_id) or record.get("location_id")!=str(visit.pose.location_id):return _fail("orphan_visit_experience")
  if record.order_id!="":
   var order := session.service.order(StringName(record.order_id))
   if order==null or str(order.visit_id)!=id:return _fail("experience_order")
   if not record.food.is_empty() and (order.status!=&"delivered" or str(order.delivered_item_id)!=record.food.item_id or order.served_quality!=record.food.quality):return _fail("experience_food")
 for summaries in experiences.recent.values():
  for summary in summaries:
   if not summary.food.is_empty():
    var order := session.service.order(StringName(str(summary.food.get("order_id",""))))
    if order==null or order.status!=&"delivered" or str(order.visit_id)!=summary.visit_id or str(order.delivered_item_id)!=summary.food.item_id or order.served_quality!=summary.food.quality:return _fail("historical_experience_food")
 for id in experiences.closed:
  if not _counter_id(id,"visit_",int(session.visitors.snapshot().next_id)):return _fail("experience_visit_counter")
  if not session.hygiene.snapshot().applied.has("visit:"+str(id)):return _fail("experience_floor_event")
 var item_counter := int(items.next_id)
 for order in session.service.snapshot().orders.values():
  if order.delivered_item_id!="" and not _counter_id(order.delivered_item_id,"food_",item_counter):return _fail("delivered_food_counter")
 for receipt in session.shops.snapshot().receipts.values():
  if not _counter_id(receipt.journey_id,"journey_",int(session.travel.snapshot().next_id)):return _fail("purchase_journey_counter")
  for grant in receipt.get("granted",[]):
   if not _counter_id(str(grant.get("item_id","")),"item_",item_counter):return _fail("purchased_item_counter")
   if not journey.is_empty() and receipt.journey_id==journey.id and journey.phase in ["browsing","returning"]:
    var item := session.items.get_item(StringName(grant.item_id))
    if item.is_empty() or item.container_id!=receipt.bag_id or item.definition_id!=grant.definition_id or item.quantity!=grant.quantity:return _fail("missing_journey_purchase")
 return ActionResult.success()
static func _counter_id(value: String, prefix: String, next_id: int) -> bool:
 var suffix := value.trim_prefix(prefix)
 return value.begins_with(prefix) and suffix.is_valid_int() and int(suffix)>0 and int(suffix)<next_id
static func _fail(reason: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_living_spaces",{"reason":reason})
