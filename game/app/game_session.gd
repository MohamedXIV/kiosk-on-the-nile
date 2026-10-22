class_name GameSession
extends Node
signal changed
var config: SessionConfig
var clock: GameClock
var wallet: WalletService
var needs: NeedsService
var items: ItemStore
var locations: LocationRegistry
var travel: TravelService
var equipment: EquipmentService
var build: BuildController
var spaces: SpaceService
var inventory: InventoryService
var home: HomeService
var knowledge: KnowledgeBook
var routine: DailyRoutine
var mood_policy: MoodPolicy
var cooking: CookingService
var supplies: SupplyService
var life: LifeActions
var service: ServiceSystem
var visitors: VisitorService
var relationships: RelationshipStore
var conditions: ConditionEvaluator
var effects: NarrativeEffects
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
 items = ItemStore.new()
 var item_result := items.configure(source.section("items"),source.section("containers"))
 if not item_result.ok: return item_result
 inventory = InventoryService.new(items,{"tea":"tea_portion","kebda":"kebda_portion"})
 item_result = inventory.restock_legacy(source.section("recipes").initial_stock)
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
   container_change.state.containers[slot_id] = {"id":slot_id,"location_id":str(grant.container_id).trim_suffix("_world"),"kind":"surface","capacity":1,"allowed_tags":["prepared","batch"],"host_id":grant.id}
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
 var space_result := spaces.configure(source.section("spaces"),layout,items,_actor_snapshots,func(id):return cooking!=null and cooking.job(id)!=null and cooking.job(id).stage!=&"EMPTY")
 if not space_result.ok: return space_result
 inventory.player_pose=player_pose
 inventory.spaces=spaces
 equipment=EquipmentService.new()
 var equipment_result := equipment.configure(source.section("equipment"),items,spaces)
 if not equipment_result.ok:return equipment_result
 inventory.equipment=equipment
 locations=LocationRegistry.new()
 var travel_config := source.section("travel")
 locations.configure(source.section("locations"),travel_config.routes)
 travel_config["physical_spawns"]=source.section("locations")
 travel=TravelService.new()
 var travel_result := travel.configure(travel_config,clock,player_pose,inventory,locations)
 if not travel_result.ok:return travel_result
 build=BuildController.new(spaces,items,player_pose)
 kiosk_open = source.section("session").kiosk_open
 var social_data := source.section("social")
 var amounts: Dictionary = {}
 for key in balance:
  if key.ends_with("_price") or key=="daily_rent": amounts[key] = str(float(balance[key])/100.0)
 for i in range(social_data.initial_notes.size()): social_data.initial_notes[i] = str(social_data.initial_notes[i]).format(amounts)
 knowledge = KnowledgeBook.new(social_data)
 mood_policy = MoodPolicy.new(source.section("wellbeing"))
 routine = DailyRoutine.new(clock,wallet,needs,home,int(balance.daily_rent),mood_policy)
 cooking = CookingService.new()
 var kitchen := cooking.configure(source.section("recipes"),inventory)
 if not kitchen.ok: return kitchen
 cooking.set_quality_provider(func():return mood_policy.quality_penalty(needs.mood))
 supplies = SupplyService.new(wallet,cooking,home,knowledge,balance,items)
 life = LifeActions.new(self)
 service = ServiceSystem.new()
 visitors = VisitorService.new()
 service.configure(wallet,cooking,visitors.is_available,balance)
 visitors.configure(source.section("visitors"),source.section("locations").kiosk.markers,clock,service,func():return kiosk_open)
 service.settled.connect(visitors.record_service)
 service.settled.connect(func(_order,_visit,item,_payment):
  if item.quality_score>=2: needs.apply_delta(0,0,float(config.section("needs").good_service_mood)))
 life.sleep_started.connect(visitors.clear_visits)
 clock.day_changed.connect(func(_previous,_current):visitors.begin_day())
 var actors: Array = source.section("visitors").characters.keys()
 actors.append("player")
 relationships = RelationshipStore.new(source.section("social"),actors)
 var initial_relationships := relationships.restore({"values":source.section("social").get("initial_relationships",{})})
 if not initial_relationships.ok: return initial_relationships
 conditions = ConditionEvaluator.new(knowledge,relationships,clock,visitors,home,player_pose,source.section("social").facts,actors,locations.ids())
 effects = NarrativeEffects.new(knowledge,needs,source.section("social").facts)
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
 var narrative_result := narrative.configure(self,source.section("encounters"),stories)
 if not narrative_result.ok: return narrative_result
 visitors.encounter_requested.connect(_encounter_requested)
 life.sleep_started.connect(narrative.cancel_all)
 routine.slept.connect(_sleep_elapsed)
 life.travelled.connect(func(destination):
  if destination!=&"kiosk": narrative.cancel_all())
 scheduler.configure({})
 return rebuild_order()
func rebuild_order() -> ActionResult:
 var handlers := {"needs":func(frame):needs.tick(frame.delta,kiosk_open),"scheduler":func(frame):scheduler.tick(frame),"cooking":func(frame):cooking.tick(frame.delta),"visitors":func(frame):visitors.tick(frame.delta),"narrative":func(frame):narrative.tick(frame.delta),"motion":func(frame):
  if motion_step.is_valid(): motion_step.call(frame.delta)}
 handlers["travel"]=func(frame):travel.tick(frame)
 return coordinator.prepare(clock,handlers,config.section("time").system_dependencies)
func start_new() -> void:
 running = true
func tick(delta: float) -> void:
 if not running: return
 last_result = coordinator.step(delta)
 changed.emit()

func _encounter_requested(kind: StringName, participants: PackedStringArray, extra: Dictionary) -> void:
 if kind in [&"reminder",&"ambient",&"served"]:
  for conversation: ConversationSession in narrative.sessions.values():
   if conversation.elapsed>=conversation.current.duration and conversation.current.choices.is_empty(): continue
   for participant in participants:
    if participant in conversation.participants: return
 var id: StringName = &"visitors"
 var context_data := extra.duplicate(true)
 if kind==&"football": id=&"football"
 elif extra.get("character_id")=="amgad" and kind in [&"arrival",&"served"]: id=&"amgad_arrival" if kind==&"arrival" else &"amgad_served"
 elif kind==&"served": id=&"visitors_served"
 context_data["mode"] = 1 if kind==&"arrival" else 2 if kind==&"served" else 3 if kind==&"reminder" else 4 if kind==&"ambient" else 0
 await narrative.start(id,participants,context_data)
func talk(visit_id: StringName) -> ActionResult:
 if not visitors.is_available(visit_id): return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"visitor_unavailable")
 var visit: VisitState = visitors.visits[str(visit_id)]
 return await narrative.start(&"amgad" if visit.character_id==&"amgad" else &"visitors",PackedStringArray([str(visit_id)]))

func _sleep_elapsed(frame: Dictionary) -> void:
 # Sleep skips travel/social scenes, while unattended stations and due jobs
 # consume the same elapsed clock frame. Recovery has already been applied.
 cooking.tick(float(frame.delta))
 scheduler.tick(frame)
 changed.emit()

func _actor_snapshots() -> Array[Dictionary]:
 var result: Array[Dictionary] = [player_pose.snapshot()]
 if visitors!=null:
  for visit in visitors.visits.values(): result.append(visit.pose.snapshot())
 return result
