class_name LivingSpacesMigration
extends RefCounted
static func upgrade(envelope: Dictionary, config: SessionConfig, target_revision: int) -> ActionResult:
 if not SaveCodec.valid_digest(envelope): return _fail("checksum")
 var candidate: Dictionary
 if envelope.get("schema_version")==4:
  if not ContentValidation.integer(envelope.get("schema_revision")) or envelope.schema_revision<1 or envelope.schema_revision>target_revision:return _fail("unsupported_revision")
  candidate=envelope.duplicate(true)
 elif envelope.get("schema_version")==3:
  var result := _convert(envelope,config)
  if not result.ok:return result
  candidate=result.details.data
  candidate.schema_version=4
  candidate["schema_revision"]=1
  candidate["migrated_from"]=envelope.get("migrated_from",3)
 else:return _fail("schema")
 if candidate.schema_revision==1 and target_revision>=2:
  var result := _add_shopping(candidate,config)
  if not result.ok:return result
  candidate.schema_revision=2
 candidate.erase("checksum")
 candidate["checksum"]=StableJson.stringify(candidate).sha256_text()
 return ActionResult.success({"data":candidate})
static func _add_shopping(candidate: Dictionary, config: SessionConfig) -> ActionResult:
 if not candidate.get("state") is Dictionary or not candidate.state.get("items") is Dictionary or not candidate.state.items.get("items") is Dictionary or not candidate.state.items.get("containers") is Dictionary or not candidate.state.get("clock") is Dictionary:return _fail("shopping_components")
 var state: Dictionary=candidate.state
 var containers: Dictionary=state.items.containers
 if not containers.has("player_bag"):containers.player_bag=config.section("containers").player_bag
 for item in state.items.items.values():
  if not item is Dictionary or not config.section("items").has(str(item.get("definition_id",""))) or not containers.has(str(item.get("container_id",""))):return _fail("shopping_item")
  var definition: Dictionary=config.section("items")[item.definition_id]
  var spec: Dictionary=definition.get("container",{})
  if spec.is_empty():continue
  var id := str(item.id)+":"+str(spec.kind)
  if not containers.has(id):containers[id]={"id":id,"location_id":containers[item.container_id].location_id,"kind":spec.kind,"capacity":spec.capacity,"allowed_tags":spec.allowed_tags.duplicate(),"host_id":item.id}
 state["travel"]={"journey":{},"next_id":1}
 state["equipment"]={}
 var stock: Dictionary={}
 for shop_id in config.section("shops").shops:stock[shop_id]=config.section("shops").shops[shop_id].stock.duplicate(true)
 if not ContentValidation.integer(state.clock.get("day")) or state.clock.day<1:return _fail("shopping_clock")
 state["shops"]={"stock":stock,"receipts":{},"delivered":{},"revision":1,"next_quote":1,"next_receipt":1,"next_restock_at":float(state.clock.day)*1440+float(config.section("shops").restock_minutes)}
 return ActionResult.success()
static func _convert(envelope: Dictionary, config: SessionConfig) -> ActionResult:
 var candidate := envelope.duplicate(true)
 var state: Variant = candidate.get("state")
 if not state is Dictionary or not state.get("cooking") is Dictionary or not state.get("home") is Dictionary or not state.get("player_pose") is Dictionary or not state.get("visitors") is Dictionary or not state.visitors.get("visits") is Dictionary: return _fail("components")
 var kitchen: Dictionary = state.cooking
 if not kitchen.get("stock") is Dictionary or not kitchen.get("jobs") is Dictionary or not ContentValidation.integer(kitchen.get("next_item")) or kitchen.next_item<1: return _fail("kitchen")
 var recipes := config.section("recipes")
 if kitchen.stock.size()!=recipes.initial_stock.size(): return _fail("stock")
 for id in recipes.initial_stock:
  if not ContentValidation.integer(kitchen.stock.get(id)) or kitchen.stock[id]<0: return _fail("stock")
 if not state.home.get("has_fan") is bool or not state.home.get("fan_on") is bool or (state.home.fan_on and not state.home.has_fan): return _fail("home")
 var items := ItemStore.new()
 var containers := config.section("containers")
 var initial := config.section("initial_layout")
 for grant in initial.instances:
  if config.section("items")[grant.definition_id].get("surface",false):
   var slot_id := str(grant.id)+":top"
   containers[slot_id]={"id":slot_id,"location_id":str(grant.container_id).trim_suffix("_world"),"kind":"surface","capacity":1,"allowed_tags":["prepared","batch"],"host_id":grant.id}
 var result := items.configure(config.section("items"),containers)
 if not result.ok: return result
 var grants: Array[Dictionary] = []
 grants.assign(initial.instances)
 result=items.prepare_grants(grants)
 if not result.ok: return result
 result=items.commit(result.details.change,false)
 if not result.ok: return result
 var inventory := InventoryService.new(items,{"tea":"tea_portion","kebda":"kebda_portion"})
 var stock_grants: Array[Dictionary] = []
 var dry_capacity := int(items.get_container(&"kiosk_dry").capacity)
 var overflow := 0
 for id in kitchen.stock:overflow+=int(kitchen.stock[id])
 if overflow>dry_capacity:
  var overflow_change := items.candidate()
  overflow_change.state.containers["legacy_purchase_bag"]={"id":"legacy_purchase_bag","location_id":"kiosk","kind":"purchase_bag","capacity":overflow,"allowed_tags":["ingredient"],"host_id":""}
  result=items.commit(overflow_change,false)
  if not result.ok:return result
 for id in kitchen.stock:
  var quantity := int(kitchen.stock[id])
  var fitted := mini(dry_capacity,quantity)
  var definition_id := "tea_portion" if id=="tea" else "kebda_portion"
  if fitted>0:stock_grants.append({"definition_id":definition_id,"quantity":fitted,"container_id":"kiosk_dry","attributes":{}})
  if quantity>fitted:stock_grants.append({"definition_id":definition_id,"quantity":quantity-fitted,"container_id":"legacy_purchase_bag","attributes":{}})
  dry_capacity-=fitted
 if not stock_grants.is_empty():
  result=items.prepare_grants(stock_grants)
  if not result.ok:return result
  result=items.commit(result.details.change,false)
  if not result.ok:return result
 var layout := {"placements":initial.placements.duplicate(true),"door_states":initial.door_states.duplicate(true),"starter_granted":true}
 if state.home.has_fan:
  result=items.prepare_grants([{"id":"legacy_fan","definition_id":"fan","quantity":1,"container_id":"rooftop_world","attributes":{"enabled":state.home.fan_on}}])
  if not result.ok: return result
  result=items.commit(result.details.change,false)
  if not result.ok: return result
  layout.placements.legacy_fan={"instance_id":"legacy_fan","location_id":"rooftop","cell":[2,-3],"rotation":0,"host_id":"","slot_id":""}
 var counter := items.candidate()
 counter.state.next_id=maxi(int(counter.state.next_id),int(kitchen.next_item))
 result=items.commit(counter,false)
 if not result.ok: return result
 if kitchen.get("held")!=null:
  var raw: Variant = kitchen.held
  if not raw is Dictionary or not raw.get("id") is String or not recipes.recipes.has(str(raw.get("recipe_id",""))) or not ContentValidation.integer(raw.get("quality_score")) or not raw.quality_score in [0,1,2,3] or not raw.get("sugar_id") is String: return _fail("held_food")
  var recipe: Dictionary = recipes.recipes[raw.recipe_id]
  if raw.get("food_id")!=recipe.food_id or raw.get("quality_key")!=recipe.quality_keys[int(raw.quality_score)]: return _fail("held_food")
  var suffix: String = raw.id.trim_prefix("food_")
  if not raw.id.begins_with("food_") or not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=int(kitchen.next_item): return _fail("food_identity")
  if recipe.get("rules_id")=="tea":
   var known := false
   for sugar in recipe.sugars:
    if sugar.id==raw.sugar_id:known=true
   if not known:return _fail("food_sugar")
  elif raw.sugar_id!="":return _fail("food_sugar")
  result=inventory.receive_prepared(PreparedItem.from_dict(raw))
  if not result.ok:return result
 var spaces := SpaceService.new()
 result=spaces.configure(config.section("spaces"),layout,items,Callable(),Callable())
 if not result.ok:return result
 state["items"]=items.snapshot()
 state["spaces"]=layout
 state.cooking={"jobs":kitchen.jobs.duplicate(true)}
 result=_repair_pose(state.player_pose,config,spaces,true)
 if not result.ok:return result
 for visit in state.visitors.visits.values():
  if not visit is Dictionary or not visit.get("pose") is Dictionary: return _fail("visitor_pose")
  result=_repair_pose(visit.pose,config,spaces,false)
  if not result.ok:return result
 return ActionResult.success({"data":candidate})
static func _repair_pose(pose: Dictionary, config: SessionConfig, spaces: SpaceService, player: bool) -> ActionResult:
 var actor := ActorPose.new()
 var result := actor.restore(pose)
 if not result.ok:return result
 var locations := config.section("locations")
 if not locations.has(str(actor.location_id)):return _fail("pose_location")
 var location: Dictionary = locations[str(actor.location_id)]
 var bounds: Array = location.player_bounds if player else location.navigation_bounds
 var area := Rect2(Vector2(bounds[0],bounds[1]),Vector2(bounds[2]-bounds[0],bounds[3]-bounds[1]))
 if not area.grow(0.001).has_point(actor.ground):return _fail("pose_bounds")
 var solids := spaces.solids(actor.location_id)
 if not FootprintGeometry.blocked(actor.ground,solids,0.16):return ActionResult.success()
 var choices: Array[Vector2] = []
 var scale := 0.25
 for x in range(ceili(bounds[0]/scale),floori(bounds[2]/scale)+1):
  for y in range(ceili(bounds[1]/scale),floori(bounds[3]/scale)+1):
   var point := Vector2(x,y)*scale
   if not FootprintGeometry.blocked(point,solids,0.2):choices.append(point)
 var origin := actor.ground
 choices.sort_custom(func(a,b):
  var da: float=a.distance_squared_to(origin)
  var db: float=b.distance_squared_to(origin)
  return da<db if not is_equal_approx(da,db) else a.x<b.x if a.x!=b.x else a.y<b.y)
 var adjusted := location.duplicate(true)
 adjusted.solids=solids
 var navigation := KioskNavigation.new()
 navigation.configure(LocationDefinition.new(actor.location_id,adjusted),SpatialMapping.new(config.section("spatial")))
 var spawn := Vector2(location.spawn[0],location.spawn[1])
 for point in choices:
  if not navigation.path(point,spawn).is_empty():pose.ground=[point.x,point.y];return ActionResult.success()
 return _fail("no_migration_position")
static func _fail(reason: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"incompatible_save",{"reason":reason})
