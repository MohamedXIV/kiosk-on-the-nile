class_name LifeActions
extends RefCounted
signal sleep_started
signal travelled(destination: StringName)
var _session: GameSession
func _init(session: GameSession) -> void:
 _session = session
func snack() -> ActionResult:
 var paid := _session.wallet.try_spend(int(_session.config.section("balance").snack_price))
 if not paid.ok: return paid
 var effect: Dictionary = _session.config.section("needs").snack
 _session.needs.apply_delta(effect.hunger,0,effect.mood)
 return ActionResult.success({"cue":"coin"})
func consume_held() -> ActionResult:
 var item := _session.cooking.held_item()
 if item == null: return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"empty_hands")
 var age := _session.cooking.freshness(item)
 if not age.sellable:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"food_unservable")
 item.quality_score=int(age.grade)
 var effect: Dictionary = _session.foods.definition(item.food_id).get("nourishment",{})
 if effect.is_empty():return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"unknown_food")
 var taken := _session.inventory.consume_for_player(item.id,_session.clock.world_minutes)
 if not taken.ok:return taken
 _session.alertness.consume(item.food_id,str(item.id))
 _session.needs.apply_delta(effect.hunger,0,effect.base_mood+item.quality_score*effect.quality_mood)
 _session.cooking.held_changed.emit()
 return ActionResult.success({"cue":"chime"})
func sleep(hours: int) -> ActionResult:
 if _session.location_id != &"rooftop": return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"sleep_at_home")
 var result := _session.routine.preview(hours)
 if not result.ok: return result
 sleep_started.emit()
 _session.kiosk_open = false
 result = _session.routine.sleep(hours)
 _session.kiosk_open = false
 var spawn: Array = _session.config.section("locations").rooftop.spawn
 _session.player_ground = Vector2(spawn[0],spawn[1])
 if not _session.advance.last_result.ok:return _session.advance.last_result
 return result
func travel(destination: StringName) -> ActionResult:
 var result := _session.travel.depart(&"to_kiosk" if destination==&"kiosk" else &"to_rooftop")
 if result.ok:travelled.emit(destination)
 return result
func toggle_kiosk() -> ActionResult:
 if _session.location_id != &"kiosk": return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"kiosk_unavailable")
 _session.kiosk_open = not _session.kiosk_open
 return ActionResult.success({"kiosk_open":_session.kiosk_open,"cue":"chime"})
func look_at_river() -> ActionResult:
 _session.needs.apply_delta(0,0,float(_session.config.section("needs").river_mood))
 return ActionResult.success({"cue":"chime"})
func toggle_fan() -> ActionResult:
 var result := _session.home.toggle_fan()
 if result.ok: result.details["cue"]="chime"
 if result.ok and _session.home.fan_on: _session.needs.apply_delta(0,0,float(_session.config.section("needs").fan_on_mood))
 return result
