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
  if target.id==&"sign": target.primary=_text.text("close_kiosk") if _session.kiosk_open else _text.text("open_kiosk")
 if _session.location_id==&"kiosk":
  for visit: VisitState in _session.visitors.visits.values():
   if not _session.visitors.is_available(visit.id): continue
   var target := InteractionTarget.new(visit.id,visit.pose.ground,float(_session.config.section("visitors").interaction_radius))
   target.visit_id = visit.id
   var character := _session.visitors.character(visit.character_id)
   var item := _session.cooking.held_item()
   var order := _session.service.pending_for(visit.id)
   target.primary = _text.text("serve",{"item":_session.cooking.item_label(item),"name":character.name}) if item and order and order.food_id==item.food_id else _text.text("talk",{"name":character.name})
   targets.append(target)
 return InteractionSelector.nearest(_session.player_ground,targets)
func execute(secondary: bool) -> ActionResult:
 var target := nearest()
 if secondary and _session.cooking.held_item() and (target==null or target.secondary.is_empty()): return _session.life.consume_held()
 if target==null: return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"no_target")
 if not target.visit_id.is_empty():
  if secondary: return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"no_secondary")
  var item := _session.cooking.held_item()
  var order := _session.service.pending_for(target.visit_id)
  if item and order and item.food_id==order.food_id: return _session.service.deliver(order.id)
  return await _session.talk(target.visit_id)
 var record: Dictionary = {}
 for data in _room.definition.data.interactions:
  if data.id==str(target.id): record=data;break
 var action: String = record.get("secondary_action","") if secondary and not target.secondary.is_empty() else record.get("action","") if not secondary else ""
 match action:
  "cook": return _session.cooking.act(StringName(record.station_id))
  "sugar": return _session.cooking.cycle_sugar(StringName(record.station_id))
  "buy_stock": return _session.supplies.buy_stock()
  "buy_fan": return _session.supplies.buy_fan()
  "snack": return _session.life.snack()
  "toggle_fan": return _session.life.toggle_fan()
  "toggle_kiosk": return _session.life.toggle_kiosk()
  "river": return _session.life.look_at_river()
  "travel": return ActionResult.success({"transition":true,"destination":record.destination})
  "sleep": return ActionResult.success({"choose_sleep":true})
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"no_secondary")
