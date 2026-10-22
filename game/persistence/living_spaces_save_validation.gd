class_name LivingSpacesSaveValidation
extends RefCounted
static func validate(session: GameSession, envelope: Dictionary) -> ActionResult:
 if envelope.get("schema_revision")!=1: return _fail("schema_revision")
 var items := session.items.snapshot()
 var placements: Dictionary = session.spaces.snapshot().placements
 for id in items.items:
  var item: Dictionary = items.items[id]
  var container: Dictionary = items.containers[item.container_id]
  if container.kind=="placed" and not placements.has(id):return _fail("unplaced_world_item")
  if item.kind=="prepared":
   var raw: Dictionary=item.attributes
   var recipes: Dictionary=session.config.section("recipes").recipes
   if raw.get("id")!=id or not recipes.has(str(raw.get("recipe_id",""))) or not ContentValidation.integer(raw.get("quality_score")) or not raw.quality_score in [0,1,2,3] or not raw.get("sugar_id") is String:return _fail("food")
   var recipe: Dictionary=recipes[raw.recipe_id]
   if raw.get("food_id")!=recipe.food_id or raw.get("quality_key")!=recipe.quality_keys[int(raw.quality_score)]:return _fail("food")
   if recipe.get("rules_id")=="tea":
    var known:=false
    for sugar in recipe.sugars:
     if sugar.id==raw.sugar_id:known=true
    if not known:return _fail("food_sugar")
   elif raw.sugar_id!="":return _fail("food_sugar")
 for container in items.containers.values():
  if container.host_id!="" and not items.items.has(container.host_id):return _fail("container_host")
  if container.kind=="surface" and not session.items.items_in(StringName(container.id)).is_empty():
   if not placements.has(container.host_id):return _fail("food_on_stored_surface")
   for p in placements.values():
    if p.host_id==container.host_id:return _fail("food_on_occupied_surface")
 if not items.reservations.is_empty():return _fail("unknown_live_reservation")
 if session.home.snapshot()!=envelope.state.home:return _fail("home_projection")
 for actor in session._actor_snapshots():
  if not session.config.section("locations").has(actor.location_id):return _fail("actor_location")
  if FootprintGeometry.blocked(Vector2(actor.ground[0],actor.ground[1]),session.spaces.solids(StringName(actor.location_id)),0):return _fail("actor_in_furniture")
 return ActionResult.success()
static func _fail(reason: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_living_spaces",{"reason":reason})
