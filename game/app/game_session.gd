class_name GameSession
extends Node
signal _encounter_ready(kind: StringName, participants: PackedStringArray, extra: Dictionary)
signal system_failed(result: ActionResult)
signal changed
var tuning: TuningStore
var alertness: AlertnessService
var actions: ActionPolicy
var fatigue: FatigueService
var presence: ActorPresence
var seat_use: SeatUse
var residential: ResidentialVisits
var accounts: AccountBook
var commitments: CommitmentService
var finance: AccountTransactions
var contact: SupplierContact
var contracts: SupplierContracts
var deliveries: DeliveryService
var supply_transactions: SupplyTransactions
var district: DistrictOffice
var account_dialogue: FinancialDialogue
var advance: SessionAdvance
var _failure_signature: String=""
var config: SessionConfig
var clock: GameClock
var wallet: WalletService
var needs: NeedsService
var items: ItemStore
var locations: LocationRegistry
var shops: ShopService
var travel: TravelService
var equipment: EquipmentService
var build: BuildController
var spaces: SpaceService
var inventory: InventoryService
var home: HomeService
var knowledge: KnowledgeBook
var routine: DailyRoutine
var mood_policy: MoodPolicy
var customer_experience: CustomerExperience
var _pending_encounters: Array[Dictionary]=[]
var hygiene: HygieneService
var foods: FoodRegistry
var learning: RecipeLearning
var workflow: RecipeWorkflow
var cooking: CookingService
var supplies: SupplyService
var life: LifeActions
var service: ServiceSystem
var character_life: CharacterLife
var visitors: VisitorService
var social_life: SocialLife
var relationships: RelationshipStore
var semantic: SemanticNarrative
var conditions: ConditionEvaluator
var effects: NarrativeEffects
var inner: InnerMonologue
var personal: PersonalConversations
var journal: InteractionJournal
var ink_players: InkPlayerCache
var narrative: NarrativeDirector
var motion_step: Callable
var coordinator := SimulationCoordinator.new()
var scheduler := WorldScheduler.new()
var running: bool = false
var player_pose := ActorPose.new()
var location_id: StringName:
 get: return player_pose.location_id
 set(value): player_pose.location_id = value
var kiosk_open: bool = false
var player_ground: Vector2:
 get: return player_pose.ground
 set(value): player_pose.ground = value
var last_result := ActionResult.success()
func configure(source: SessionConfig) -> ActionResult:
 for key in SessionConfig.REQUIRED_SECTIONS:
  if not source.data.get(key) is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"missing_section",{"section":key})
 var validation := ContentValidation.validate(source.data)
 if not validation.ok: return validation
 config = source
 var spatial: Dictionary = source.section("spatial")
 location_id = StringName(spatial.get("initial_location","rooftop"))
 var initial_ground: Array = spatial.get("initial_ground",[0,0.5])
 player_ground = Vector2(initial_ground[0],initial_ground[1])
 var balance: Dictionary = source.section("balance")
 if not typeof(balance.get("starting_money")) in [TYPE_INT,TYPE_FLOAT] or balance.starting_money < 0:
  return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_starting_money")
 clock = GameClock.new(source.section("time"))
 wallet = WalletService.new(int(balance.starting_money))
 needs = NeedsService.new(source.section("needs"))
 tuning=TuningStore.new()
 var tuned := tuning.configure(source.section("tuning"),source.section("visitors").characters.keys()+source.section("residential_visits").profiles.keys()+source.section("suppliers").profiles.keys()+["player"])
 if not tuned.ok:return tuned
 tuning.apply_at_boundary(false)
 alertness=AlertnessService.new()
 alertness.configure(self)
 actions=ActionPolicy.new()
 actions.configure(self)
 fatigue=FatigueService.new()
 fatigue.configure(self)
 tuning.applied.connect(_apply_tuning)
 _apply_tuning()
 presence=ActorPresence.new();presence.configure(self)
 accounts=AccountBook.new();accounts.configure(self)
 commitments=CommitmentService.new();commitments.configure(self)
 finance=AccountTransactions.new();finance.configure(self)
 residential=ResidentialVisits.new();residential.configure(self)
 actions.business_allowed=accounts.business_allowed
 items = ItemStore.new()
 items.world_clock=clock
 items.food_definitions=source.section("foods")
 var item_result := items.configure(source.section("items"),source.section("containers"))
 if not item_result.ok: return item_result
 inventory = InventoryService.new(items,{"tea":"tea_portion","kebda":"kebda_portion"})
 item_result = inventory.restock_legacy(source.section("recipes").initial_stock,"starter")
 if not item_result.ok: return item_result
 home = HomeService.new(items)
 var initial_layout := source.section("initial_layout")
 var initial_grants: Array[Dictionary] = []
 initial_grants.assign(initial_layout.instances)
 for grant in initial_grants:
  var definition := items.definition(StringName(grant.definition_id))
  if definition.get("surface",false):
   var container_change := items.candidate()
   var slot_id := str(grant.id)+":top"
   container_change.state.containers[slot_id] = {"id":slot_id,"location_id":str(grant.container_id).trim_suffix("_world"),"kind":"surface","capacity":1,"allowed_tags":["prepared","batch","ingredient"],"host_id":grant.id}
   var slot_result := items.commit(container_change,false)
   if not slot_result.ok: return slot_result
 var furniture_result := items.prepare_grants(initial_grants)
 if not furniture_result.ok: return furniture_result
 furniture_result = items.commit(furniture_result.details.change,false)
 if not furniture_result.ok: return furniture_result
 var initial_home := home.restore(source.section("session").home,true)
 if not initial_home.ok: return initial_home
 var layout := {"placements":initial_layout.placements,"door_states":initial_layout.door_states,"starter_granted":true}
 for fan in items.instances(&"fan"):
  if fan.container_id=="rooftop_world": layout.placements[fan.id]={"instance_id":fan.id,"location_id":"rooftop","cell":[2,-3],"rotation":0,"host_id":"","slot_id":""}
 spaces = SpaceService.new()
 var space_result := spaces.configure(source.section("spaces"),layout,items,_actor_snapshots,_equipment_busy)
 if not space_result.ok: return space_result
 inventory.player_pose=player_pose
 inventory.spaces=spaces
 equipment=EquipmentService.new()
 var equipment_result := equipment.configure(source.section("equipment"),items,spaces)
 if not equipment_result.ok:return equipment_result
 equipment.external_busy=func(id):return cooking!=null and cooking.legacy_busy(id)
 inventory.equipment=equipment
 locations=LocationRegistry.new()
 var travel_config := source.section("travel")
 locations.configure(source.section("locations"),travel_config.routes)
 travel_config["physical_spawns"]=source.section("locations")
 travel=TravelService.new()
 var travel_result := travel.configure(travel_config,clock,player_pose,inventory,locations)
 if not travel_result.ok:return travel_result
 build=BuildController.new(spaces,items,player_pose)
 build.policy=actions
 kiosk_open = source.section("session").kiosk_open
 var social_data := source.section("social")
 var amounts: Dictionary = {}
 for key in balance:
  if key.ends_with("_price") or key=="daily_rent": amounts[key] = str(float(balance[key])/100.0)
 for i in range(social_data.initial_notes.size()): social_data.initial_notes[i] = str(social_data.initial_notes[i]).format(amounts)
 knowledge = KnowledgeBook.new(social_data)
 shops=ShopService.new()
 shops.eligibility_provider=func(fact):return knowledge.has(fact)
 var shops_result := shops.configure(source.section("shops"),wallet,items,travel,clock)
 if not shops_result.ok:return shops_result
 mood_policy = MoodPolicy.new(source.section("wellbeing"))
 routine = DailyRoutine.new(clock,wallet,needs,home,int(balance.daily_rent),mood_policy)
 foods=FoodRegistry.new()
 var food_result := foods.configure(source.section("foods"))
 if not food_result.ok:return food_result
 character_life=CharacterLife.new()
 var character_result := character_life.configure(source.section("character_life"),foods,clock)
 if not character_result.ok:return character_result
 cooking = CookingService.new()
 var kitchen := cooking.configure(source.section("recipes"),inventory)
 if not kitchen.ok: return kitchen
 cooking.set_quality_provider(func():return mood_policy.quality_penalty(needs.mood))
 workflow=RecipeWorkflow.new()
 items.cold_active=func(id):return equipment.enabled(id) and not spaces.placement(id).is_empty()
 var workflow_result := workflow.configure(source.section("recipe_workflows"),inventory,equipment,clock,knowledge)
 if not workflow_result.ok:return workflow_result
 workflow.policy=actions
 workflow.quality_provider=func():return mood_policy.quality_penalty(needs.mood)
 cooking.foods=foods
 hygiene=HygieneService.new()
 hygiene.policy=actions
 var hygiene_result := hygiene.configure(source.section("hygiene"),items,spaces,clock,func():return player_pose,func(id):return cooking.legacy_busy(id) or equipment.is_busy(id) or (visitors!=null and visitors.seating.busy_item(id)) or (seat_use!=null and seat_use.busy_item(id)))
 if not hygiene_result.ok:return hygiene_result
 cooking.set_hygiene_provider(hygiene.food_contact_evidence,func(id):hygiene.record_use(StringName("legacy:"+str(id)),id,&"batch"))
 workflow.hygiene_provider=hygiene.food_contact_evidence
 workflow.use_provider=_record_cooking_use
 routine.sleep_rest_provider=func():return hygiene.sleep_rest_multiplier(routine.bed_id)
 travel.departed.connect(hygiene.interrupt_clean)
 cooking.set_workflow(workflow)
 learning=RecipeLearning.new()
 learning.configure(workflow,items,source.section("learning").families)
 workflow.attempt_started.connect(func(id,recipe,evidence):learning.record_attempt(id,recipe,evidence))
 workflow.item_completed.connect(func(id,item,quality):learning.record_result(id,item,quality))
 supplies = SupplyService.new(travel,home,knowledge)
 life = LifeActions.new(self)
 service = ServiceSystem.new()
 service.policy=actions
 service.gift_allowed=can_offer_hospitality
 service.receipt_recipes=source.section("recipe_workflows")
 service.recipient_for=func(id):
  var visit: VisitState=visitors.visits.get(str(id))
  return visit.character_id if visit!=null else &""
 service.personal_item=func(id):return items.get_item(id).get("attributes",{}).get("personal_use",false)
 visitors = VisitorService.new()
 visitors.seat_catalog=SeatCatalog.new()
 visitors.seat_catalog.configure(spaces,items)
 visitors.seat_unavailable=func(id):return hygiene!=null and hygiene.is_cleaning(id)
 visitors.tuning=tuning
 visitors.foods=foods
 visitors.character_life=character_life
 visitors.food_selector=_choose_food
 service.configure(wallet,cooking,visitors.is_available,balance,foods,clock)
 visitors.configure(source.section("visitors"),source.section("locations").kiosk.markers,clock,service,func():return kiosk_open)
 seat_use=SeatUse.new();seat_use.configure(self)
 visitors.seating.external_owner=seat_use.external_owner
 customer_experience=CustomerExperience.new()
 var experience_result := customer_experience.configure(source.section("customer_experience"),hygiene,spaces,clock)
 if not experience_result.ok:return experience_result
 customer_experience.visit_provider=func(id):return visitors.visits.get(str(id))
 visitors.service_presence=func():return location_id==&"kiosk"
 visitors.service_busy=func():return personal!=null and personal.active() or narrative!=null and narrative.focused_session()!=null
 visitors.demand_provider=func():return customer_experience.demand_factor(&"kiosk")
 visitors.purchase_blocked=func(id):return service.decision_visit()==StringName(id) or (narrative!=null and narrative.speech_active(StringName(id))) or (personal!=null and personal.holds_visit(StringName(id)))
 visitors.meeting_available=func(id):return social_life!=null and social_life.can_invite(id)
 visitors.departed.connect(_close_experience)
 service.handed_over.connect(func(order_id,visit_id,item):visitors.record_service(order_id,visit_id,item,0))
 service.settled.connect(visitors.record_settlement)
 service.handed_over.connect(func(order_id,visit_id,_item):_sync_experience(visit_id,order_id))
 service.handed_over.connect(func(_order,_visit,item):
  if item.quality_score>=2: needs.apply_delta(0,0,float(config.section("needs").good_service_mood)))
 life.sleep_started.connect(hygiene.interrupt_clean)
 life.sleep_started.connect(visitors.clear_visits)
 clock.day_changed.connect(func(_previous,_current):visitors.begin_day())
 var actors: Array = presence.actor_ids()
 actors.append("player")
 journal=InteractionJournal.new()
 journal.configure(actors,clock)
 journal.append_once({"id":"accounts:activation","chapter":"accounts","actor":"system","name":UiText.localized("records.activation.name",{},"دفتر المستحقات"),"text":UiText.localized("records.activation.text",{},"إيجار السكن والحي أسبوعيًا، بمواعيد مستقبلية واضحة في دفتر المستحقات ومن غير خصم تلقائي."),"channel":"system","at":clock.world_minutes})
 relationships = RelationshipStore.new(source.section("social"),actors)
 var initial_relationships := relationships.restore({"values":source.section("social").get("initial_relationships",{})})
 if not initial_relationships.ok: return initial_relationships
 social_life=SocialLife.new()
 social_life.configure(self)
 visitors.availability_provider=func(actor):return not social_life.reserved(actor) and not residential.reserved(actor)
 life.sleep_started.connect(social_life.before_time_jump)
 conditions = ConditionEvaluator.new(knowledge,relationships,clock,visitors,home,player_pose,source.section("social").facts,actors,locations.ids())
 conditions.presence=presence
 conditions.social_life=social_life
 conditions.social_actions=source.section("social_life").actions.keys()
 conditions.social_topics=source.section("social_life").topics.keys()
 conditions.customer_experience=customer_experience
 conditions.learning=learning
 conditions.recipe_ids=source.section("recipe_workflows").keys()+source.section("learning").families.values()
 effects = NarrativeEffects.new(knowledge,needs,source.section("social").facts)
 effects.relationships=relationships
 effects.social_life=social_life
 effects.home_provider=residential.action
 effects.home_domain=residential
 effects.service_provider=_service_effect
 effects.finance_provider=financial_effect
 ink_players=InkPlayerCache.new()
 add_child(ink_players)
 narrative = NarrativeDirector.new()
 add_child(narrative)
 var stories: Dictionary = {}
 for id in source.section("encounters").values().map(func(encounter):return str(encounter.story)):
  if stories.has(id): continue
  var story := StoryDefinition.new()
  story.id = StringName(id)
  if not source.data.get("story_"+id) is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"missing_story")
  story.raw_json = JSON.stringify(source.section("story_"+id),"",true)
  story.sha256 = story.raw_json.sha256_text()
  stories[id] = story
 semantic=SemanticNarrative.new()
 var semantic_result := semantic.configure(self)
 if not semantic_result.ok:return semantic_result
 conditions.semantic=semantic
 var narrative_result := narrative.configure(self,source.section("encounters"),stories)
 if not narrative_result.ok: return narrative_result
 visitors.peer_available=func(id,own):
  var visit: VisitState=visitors.visits.get(str(id))
  if visit==null or social_life.reserved(str(visit.character_id)) or (personal!=null and personal.holds_visit(StringName(id))):return false
  for conversation: ConversationSession in narrative.sessions.values():
   if str(conversation.id)!=str(own) and str(id) in conversation.participants:return false
  return true
 visitors.peer_cancel=func(id):narrative.cancel(StringName(id))
 visitors.peer_manual=func(id):return narrative.sessions.has(id) and narrative.manual(narrative.sessions[id])
 narrative.chapter_finished.connect(func(id,_reason):visitors.peers.conversation_ended(str(id)))
 personal=PersonalConversations.new()
 personal.configure(self)
 inner=InnerMonologue.new()
 add_child(inner)
 inner.configure(self)
 visitors.encounter_requested.connect(_encounter_requested)
 _encounter_ready.connect(_start_encounter)
 life.sleep_started.connect(personal.leave)
 life.sleep_started.connect(narrative.cancel_all)
 advance=SessionAdvance.new();advance.configure(self)
 routine.slept.connect(_sleep_elapsed)
 life.travelled.connect(func(destination):
  if destination!=&"kiosk":
   personal.leave()
   narrative.leave_location())
 contact=SupplierContact.new();contact.configure(self)
 contracts=SupplierContracts.new();contracts.configure(self)
 deliveries=DeliveryService.new();deliveries.configure(self)
 supply_transactions=SupplyTransactions.new();supply_transactions.configure(self)
 account_dialogue=FinancialDialogue.new();account_dialogue.configure(self)
 effects.supply_provider=supplier_effect
 district=DistrictOffice.new();district.configure(self)
 travel.departed.connect(func():
  residential.clear()
  contact.close()
  personal.leave()
  narrative.leave_location())
 life.sleep_started.connect(seat_use.stand)
 life.sleep_started.connect(residential.clear)
 life.sleep_started.connect(contact.close)
 scheduler.configure({})
 return rebuild_order()
func rebuild_order() -> ActionResult:
 var handlers := {"needs":func(frame):needs.tick(frame.world_delta,kiosk_open),"scheduler":func(frame):scheduler.tick(frame),"cooking":func(frame):
  cooking.tick(frame.delta)
  workflow.tick(frame),"visitors":func(frame):visitors.tick(frame.delta,frame.world_delta),"narrative":_step_narrative,"motion":func(frame):
  if motion_step.is_valid(): motion_step.call(frame.delta)}
 handlers["accounts"]=func(frame):
  accounts.tick(frame)
  return finance.tick(frame)
 handlers["deliveries"]=func(frame):
  contact.tick(frame)
  return deliveries.tick(frame)
 handlers["residential"]=func(frame):residential.tick(frame);seat_use.tick()
 handlers["body"]=func(frame):alertness.tick(frame);fatigue.tick(frame)
 handlers["travel"]=func(frame):travel.tick(frame)
 handlers["shops"]=func(frame):shops.tick(frame)
 handlers["hygiene"]=func(frame):hygiene.tick(frame)
 handlers["customer_experience"]=_step_experiences
 handlers["social_life"]=func(frame):return social_life.tick(frame)
 return coordinator.prepare(clock,handlers,config.section("time").system_dependencies)
func start_new() -> void:
 running = true
func tick(delta: float) -> void:
 if not running: return
 var tuned := tuning.apply_at_boundary()
 if not tuned.ok:last_result=tuned;return
 last_result = coordinator.step(delta)
 var signature := "" if last_result.ok else JSON.stringify(last_result.details)
 if signature!="" and signature!=_failure_signature:system_failed.emit(last_result)
 _failure_signature=signature
 changed.emit()

func _encounter_requested(kind: StringName, participants: PackedStringArray, extra: Dictionary) -> void:
 _pending_encounters.append({"kind":kind,"participants":participants.duplicate(),"extra":extra.duplicate(true)})
func _step_narrative(frame: Dictionary) -> void:
 social_life.step_companionship(float(frame.delta))
 var pending := _pending_encounters.duplicate()
 _pending_encounters.clear()
 for event in pending:_encounter_ready.emit(event.kind,event.participants,event.extra)
 personal.tick()
 narrative.tick(float(frame.delta))
 inner.tick(frame)
func _start_encounter(kind: StringName, participants: PackedStringArray, extra: Dictionary) -> void:
 if kind==&"peer":
  var peer_id: String=str(extra.peer_id)
  if not visitors.peers.pending(peer_id,participants):return
  var context := extra.duplicate(true)
  var definition: Dictionary=config.section("encounters")[str(extra.encounter_id)]
  var variants: int=int(definition.topics[0].variants) if definition.has("topics") and not definition.topics.is_empty() else 1
  context["line_variant"]=int((peer_id+":variant").sha256_text().substr(0,8).hex_to_int())%variants
  var result := await narrative.start(StringName(extra.encounter_id),participants,context)
  if result.ok:
   var conversation_id: String=str(result.details.session_id)
   if not visitors.peers.link(peer_id,conversation_id):narrative.cancel(StringName(conversation_id))
  elif visitors.peers.pending(peer_id,participants):visitors.finish_peer()
  return
 if kind==&"service_request":
  var result := await narrative.start(&"service_availability",participants,{"manual_read":true,"line_variant":visitors.random_index(3)})
  var conversation: ConversationSession=narrative.sessions.get(result.details.get("session_id","")) if result.ok else null
  if conversation!=null:personal.adopt(conversation)
  elif not participants.is_empty():visitors.reset_request(StringName(participants[0]))
  return
 if kind in [&"reminder",&"ambient",&"served"]:
  for conversation: ConversationSession in narrative.sessions.values():
   if conversation.elapsed>=conversation.current.duration and conversation.current.choices.is_empty(): continue
   for participant in participants:
    if participant in conversation.participants: return
 if kind in [&"order",&"reminder"]:
  if participants.is_empty() or service.pending_for(StringName(participants[0]))==null:return
  var order_context := extra.duplicate(true)
  order_context.merge({"mode":5 if kind==&"order" else 7,"line_variant":visitors.random_index(3)},true)
  await narrative.start(&"orders",participants,order_context)
  return
 var id: StringName = &"visitors"
 var context_data := extra.duplicate(true)
 if kind==&"football": id=&"football"
 elif extra.get("character_id")=="amgad" and kind==&"served":id=&"amgad_served"
 elif kind==&"served": id=&"visitors_served"
 context_data["mode"] = 4 if kind==&"arrival" else 2 if kind==&"served" else 3 if kind==&"reminder" else 4 if kind==&"ambient" else 0
 if kind in [&"arrival",&"ambient"] and narrative.has_topics(&"venue_comments",participants,context_data):id=&"venue_comments"
 await narrative.start(id,participants,context_data)
func person_interaction(visit_id: StringName) -> ActionResult:
 if not presence.is_available(visit_id):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"visitor_unavailable")
 return await personal.open_for(visit_id)
func recall_order(visit_id: StringName) -> ActionResult:
 if not visitors.is_available(visit_id) or service.pending_for(visit_id)==null:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"order_unavailable")
 var visit: VisitState=visitors.visits[str(visit_id)]
 if location_id!=visit.pose.location_id or player_ground.distance_to(visit.pose.ground)>float(config.section("visitors").interaction_radius):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"visitor_unavailable")
 if narrative.speech_active(visit_id):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"conversation_in_progress")
 var next := visitors.random_index(3 if visit.recall_variant<0 else 2)
 if visit.recall_variant>=0 and next>=visit.recall_variant:next+=1
 var result := await narrative.start(&"orders",PackedStringArray([str(visit_id)]),{"mode":6,"line_variant":next})
 if result.ok:visit.recall_variant=next
 return result
func talk(visit_id: StringName) -> ActionResult:
 return await personal.open_for(visit_id)
func _legacy_talk(visit_id: StringName) -> ActionResult:
 if not narrative.can_talk(visit_id):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"nothing_new_to_say")
 if not visitors.is_available(visit_id): return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"visitor_unavailable")
 var visit: VisitState = visitors.visits[str(visit_id)]
 var encounter := narrative.talk_encounter(visit_id)
 if encounter.is_empty():return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"nothing_new_to_say")
 return await narrative.start(encounter,PackedStringArray([str(visit_id)]))

func _sleep_elapsed(frame: Dictionary) -> void:
 last_result=advance.catch_up(frame)
 if not last_result.ok:system_failed.emit(last_result)
 changed.emit()

func _actor_snapshots() -> Array[Dictionary]:
 var result: Array[Dictionary] = [player_pose.snapshot()]
 if residential!=null and residential.current!=null:result.append(residential.current.pose.snapshot())
 if visitors!=null:
  for visit in visitors.visits.values(): result.append(visit.pose.snapshot())
 return result

func _equipment_busy(id: StringName) -> bool:
 return (cooking!=null and cooking.legacy_busy(id)) or (equipment!=null and equipment.is_busy(id)) or (hygiene!=null and hygiene.is_cleaning(id)) or (visitors!=null and visitors.seating.busy_item(id)) or (seat_use!=null and seat_use.busy_item(id))

func _choose_food(character_id: StringName, visit_id: StringName) -> StringName:
 var offers: Array[Dictionary]=[]
 for id in workflow.available_foods(&"kiosk"):
  var food := foods.definition(StringName(id))
  offers.append({"food_id":str(id),"price_minor":int(food.price_minor)})
 var decision := character_life.consider(character_id,visit_id,offers)
 return StringName(str(decision.get("food_id","")))

func _record_cooking_use(job_id: StringName, step_index: int, instance_id: StringName, kind: StringName) -> void:
 var use_id: StringName=&"prep" if kind==&"prepare" else &"assembly" if kind==&"assemble" else &"batch"
 var source := str(job_id)+"/step/"+str(step_index) if use_id!=&"batch" else str(job_id)+"/appliance/"+str(instance_id)
 hygiene.record_use(StringName(source),instance_id,use_id)
 actions.record_effort("%s/step/%d" % [job_id,step_index],&"preparation")

func _sync_experience(visit_id: StringName, order_id: StringName = &"") -> ActionResult:
 var visit: VisitState=visitors.visits.get(str(visit_id))
 if visit==null:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"visitor_unavailable")
 var observed := customer_experience.observe(visit_id,visit.pose)
 if not observed.ok:return observed
 var order := service.order(order_id)
 if order==null:return ActionResult.success()
 var patience := float(config.section("visitors").max_wait_seconds)*float(config.section("time").minutes_per_second)
 customer_experience.record_order(visit_id,order.id,order.created_at if order.timing_known else -1.0,patience)
 if order.status==&"delivered" and order.served_quality>=0:
  return customer_experience.record_service(visit_id,{"order_id":str(order.id),"item_id":str(order.delivered_item_id),"food_id":str(order.food_id),"quality":order.served_quality,"served_at":order.served_at})
 return ActionResult.success()
func _close_experience(visit_id: StringName) -> void:
 var visit: VisitState=visitors.visits.get(str(visit_id))
 if visit==null:return
 _sync_experience(visit_id,visit.order_id)
 var order := service.order(visit.order_id)
 customer_experience.close_visit(visit_id,&"departed",order.closed_at if order!=null and order.status==&"cancelled" and order.closed_at>=0 else clock.world_minutes)

func _step_experiences(_frame: Dictionary) -> ActionResult:
 for visit in visitors.visits.values():
  if visit.phase==&"leaving":continue
  var result := _sync_experience(visit.id,visit.order_id)
  if not result.ok:return result
 return ActionResult.success()

func request_can_prepare(food_id: StringName) -> bool:
 return str(food_id) in workflow.available_foods(&"kiosk")
func _service_effect(action: String, participants: PackedStringArray) -> ActionResult:
 if action in ["accept","accept_gift"] and not accounts.business_allowed():return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"business_suspended")
 if participants.size()!=1 or not visitors.is_available(StringName(participants[0])):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"visitor_unavailable")
 var visit: VisitState=visitors.visits[participants[0]]
 if location_id!=visit.pose.location_id or player_ground.distance_to(visit.pose.ground)>float(config.section("spatial").hearing_radius):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"visitor_unavailable")
 if action=="decline":return visitors.decline_request(visit.id)
 if not request_can_prepare(visit.food_id):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"missing_ingredients")
 return visitors.accept_request(visit.id,action=="accept_gift")

func can_offer_hospitality(visit_id: StringName) -> bool:
 var visit: VisitState=visitors.visits.get(str(visit_id))
 if visit==null:return false
 return visit.needs_hospitality or relationships.value(&"player",visit.character_id,&"familiarity")>=float(config.section("social").conversation_familiarity_threshold)
func complete_service(order_id: StringName, mode: StringName, expected_item: StringName=&"") -> ActionResult:
 var order := service.order(order_id)
 if order==null or not visitors.is_available(order.visit_id):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"order_unavailable")
 var visit: VisitState=visitors.visits[str(order.visit_id)]
 if location_id!=visit.pose.location_id or player_ground.distance_to(visit.pose.ground)>float(config.section("visitors").interaction_radius):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"visitor_unavailable")
 if order.status==&"pending" and expected_item!=&"":
  var item := cooking.held_item()
  if item==null or item.id!=expected_item:return ActionResult.failure(ActionResult.Code.WRONG_ORDER,&"wrong_order")
 return service.complete(order_id,mode)
func _apply_tuning() -> void:
 clock.set_speed(tuning.value("clock_speed"))
 needs.apply_tuning(tuning)

func financial_context(chapter: String) -> Dictionary:return account_dialogue.context(chapter,"abdul_karim")
func pending_financial_offer(chapter: String) -> Dictionary:return account_dialogue.pending_financial_offer(chapter)
func financial_effect(action: String, source: String, participants: PackedStringArray) -> ActionResult:return account_dialogue.financial_effect(action,source,participants)
func notebook_people() -> Array[Dictionary]:
 var people := social_life.people()
 if journal.has_actor("abdul_karim") and not people.any(func(person):return person.actor_id=="abdul_karim"):people.append({"actor_id":"abdul_karim","name":presence.profile(&"abdul_karim").name,"score":relationships.value(&"player",&"abdul_karim",&"familiarity"),"stage":"صاحب السكن — معرفة وعلاقة مستقلة عن الحساب","connection":""})
 return people

func validate_financial_chapters() -> ActionResult:
 for chapter in contracts.state.emergency_quotes:
  if not narrative.valid_sequence(str(chapter),"conversation_",int(narrative.snapshot().next_id)):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_supplier_chapter")
 for id in accounts.state.chapters:
  var record: Variant=accounts.state.chapters[id]
  if not narrative.valid_sequence(str(id),"conversation_",int(narrative.snapshot().next_id)) or not record is Dictionary or record.get("id")!=id:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_financial_chapter")
  if not record.get("extension_targets") is Array:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_financial_targets")
  for target in record.extension_targets:
   var p := accounts.resolve_period(str(target))
   if p.is_empty() or p.lease!="housing_lease":return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_financial_targets")
  for key in ["pay_quote","partial_quote"]:
   if not record.get(key) is String:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_financial_chapter")
   if record[key].is_empty():continue
   var quote: Dictionary=accounts.state.quotes.get(record[key],{})
   if quote.is_empty() or quote.lease!="housing_lease" or quote.get("chapter")!=id:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_financial_chapter")
  if not record.get("loan_id") is String or (not record.loan_id.is_empty() and not commitments.state.loans.has(record.loan_id)):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_financial_chapter")
 for offer in commitments.state.offers.values():
  if not offer.get("chapter") is String or not accounts.state.chapters.has(offer.chapter):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_financial_offer_source")
 return ActionResult.success()

func supplier_context(chapter: String) -> Dictionary:return account_dialogue.context(chapter,"fathi")
func supplier_effect(action: String, source: String, participants: PackedStringArray) -> ActionResult:return account_dialogue.supplier_effect(action,source,participants)
