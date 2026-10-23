class_name InteractionRouter
extends RefCounted
var _session: GameSession
var _room: LocationView
var _text: UiText
func _init(session: GameSession, room: LocationView, text: UiText) -> void:
 _session = session
 _room = room
 _text = text
func nearest() -> InteractionTarget:
 if _room==null or not _session.locations.is_physical(_session.location_id):return null
 var targets := _room.interaction_targets()
 var balance: Dictionary = _session.config.section("balance")
 var format: Dictionary = {}
 for key in balance:
  if key.ends_with("_price") or key=="daily_rent": format[key] = str(float(balance[key])/100.0)
  elif key in ["supply_tea","supply_kebda"]: format[key] = balance[key]
 for target in targets:
  target.primary = target.primary.format(format)
  target.secondary = target.secondary.format(format)
  if _session.cooking.job(target.id):
   target.primary = StationController.new(_session.cooking,str(_text.data.input.interact_primary[0])).status_label(target.id)
   if _session.cooking.job(target.id).stage!=&"EMPTY": target.secondary=""
   elif _session.cooking.job(target.id).recipe.rules_id==&"tea":target.secondary=_text.text("station_options")
  if target.id==&"sign": target.primary=_text.text("close_kiosk") if _session.kiosk_open else _text.text("open_kiosk")
 if _session.location_id==&"kiosk":
  for visit: VisitState in _session.visitors.visits.values():
   if not _session.visitors.is_available(visit.id): continue
   var target := InteractionTarget.new(visit.id,visit.pose.ground,float(_session.config.section("visitors").interaction_radius))
   target.visit_id = visit.id
   var character := _session.visitors.character(visit.character_id)
   var item := _session.cooking.held_item()
   var order := _session.service.pending_for(visit.id)
   if not (item and order and order.food_id==item.food_id) and order==null and not _session.narrative.can_talk(visit.id) and _session.social_life.topics_for(visit.id).is_empty(): continue
   target.primary = _text.text("serve",{"item":_session.cooking.item_label(item),"name":character.name}) if item and order and order.food_id==item.food_id else _text.text("talk",{"name":character.name})
   targets.append(target)
 var selected := InteractionSelector.nearest(_session.player_ground,targets)
 var people: Array[InteractionTarget]=[]
 for target in targets:
  if not target.visit_id.is_empty():people.append(target)
 var person := InteractionSelector.nearest(_session.player_ground,people)
 if person!=null and selected!=null and selected.visit_id.is_empty():
  var item := _session.cooking.held_item()
  var order := _session.service.pending_for(person.visit_id)
  if item and order and item.food_id==order.food_id:return person
  selected.secondary=person.primary
  selected.secondary_visit_id=person.visit_id
 return selected
func execute(secondary: bool) -> ActionResult:
 var target := nearest()
 if secondary and target!=null and not target.secondary_visit_id.is_empty():
  _session.hygiene.interrupt_clean()
  return await _session.person_interaction(target.secondary_visit_id)
 if secondary and _session.cooking.held_item() and (target==null or target.secondary.is_empty()): return _session.life.consume_held()
 if target==null: return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"no_target")
 if not target.visit_id.is_empty():
  if secondary: return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"no_secondary")
  var item := _session.cooking.held_item()
  var order := _session.service.pending_for(target.visit_id)
  if item and order and item.food_id==order.food_id: return _session.service.deliver(order.id)
  return await _session.person_interaction(target.visit_id)
 var record: Dictionary = {}
 for data in _room.definition.data.interactions:
  if data.id==str(target.id): record=data;break
 var action: String = record.get("secondary_action","") if secondary and not target.secondary.is_empty() else record.get("action","") if not secondary else ""
 if action!="clean":_session.hygiene.interrupt_clean()
 match action:
  "clean":return _session.hygiene.begin_clean(StringName(record.instance_id))
  "recipes":return ActionResult.success({"show_recipes":str(record.instance_id)})
  "inventory":
   if _session.items.get_item(_session.inventory.held_id()).get("kind")=="batch":return _session.inventory.store_held(StringName(record.container_id))
   return ActionResult.success({"show_inventory":true})
  "toggle_equipment":
   var id := StringName(record.instance_id)
   return _session.equipment.set_enabled(id,not _session.equipment.enabled(id))
  "surface":
   var result := _session.inventory.put_down(StringName(record.slot_id)) if not _session.inventory.held_id().is_empty() else _session.inventory.pick_up(StringName(record.slot_id))
   if result.ok: _session.cooking.held_changed.emit()
   return result
  "door": return _session.spaces.set_door_open(StringName(record.door_id),not bool(record.opened))
  "cook": return _session.cooking.act(StringName(record.station_id))
  "sugar": return ActionResult.success({"show_recipes":str(record.station_id)})
  "buy_stock": return _session.supplies.buy_stock()
  "buy_fan": return _session.supplies.buy_fan()
  "snack": return _session.life.snack()
  "toggle_fan": return _session.life.toggle_fan()
  "toggle_kiosk": return _session.life.toggle_kiosk()
  "river": return _session.life.look_at_river()
  "travel": return ActionResult.success({"transition":true,"destination":record.destination})
  "sleep":
   _session.routine.bed_id=StringName(str(record.get("instance_id","bed")))
   return ActionResult.success({"choose_sleep":true})
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"no_secondary")
