class_name SeatUse
extends RefCounted
## Player and home guest claims over the same derived geometry as kiosk visitors.
var _session: GameSession
var _player: String=""
var _guest: String=""
var _guest_id: String=""
var _declined_guest: String=""
func configure(session: GameSession) -> void:_session=session
func external_owner(slot_id: String) -> StringName:
 if _player==slot_id:return &"player"
 if _guest==slot_id:return StringName(_guest_id)
 return &""
func available(slot: Dictionary) -> bool:
 return not slot.is_empty() and _clear_access(slot) and external_owner(str(slot.id))==&"" and _session.visitors.seating.owner(str(slot.id))==&"" and not _session.hygiene.is_cleaning(StringName(slot.item_id)) and (slot.table_id=="" or not _session.hygiene.is_cleaning(StringName(slot.table_id)))
func player_slot() -> Dictionary:return _session.visitors.seat_catalog.lookup(_player)
func guest_slot() -> Dictionary:return _session.visitors.seat_catalog.lookup(_guest)
func player_seated() -> bool:return not player_slot().is_empty()
func guest_seated(id: StringName) -> bool:
 var guest := _session.residential.current
 var slot := guest_slot()
 return guest!=null and str(id)==_guest_id and not slot.is_empty() and guest.pose.ground.distance_to(slot.access)<=0.15
func sit(slot_id: String) -> ActionResult:
 var slot := _session.visitors.seat_catalog.lookup(slot_id)
 if not available(slot) or slot.location_id!=str(_session.location_id) or _session.player_ground.distance_to(slot.access)>0.65:return _fail("seat_unavailable")
 if not _clear_access(slot):return _fail("seat_unavailable")
 var solids := _session.spaces.solids(_session.location_id)
 for i in range(1,14):
  if FootprintGeometry.blocked(_session.player_ground.lerp(slot.access,float(i)/13.0),solids,0.12):return _fail("seat_unavailable")
 if FootprintGeometry.blocked(_session.player_ground,_session.spaces.solids(_session.location_id),0.12):return _fail("seat_unavailable")
 for visit in _session.presence.at(_session.location_id):
  if visit.pose.ground.distance_to(_session.player_ground)<0.55:return _fail("seat_unavailable")
 _player=slot_id;_session.player_pose.facing=slot.facing;_session.player_pose.walk_phase=0
 return ActionResult.success()
func stand() -> void:_player=""
func release_guest() -> void:_guest="";_guest_id="";_declined_guest=""
func abandon_guest() -> void:
 var guest := _session.residential.current
 release_guest()
 if guest!=null and guest.phase==&"staying":
  _declined_guest=str(guest.id);guest.destination=guest.pose.ground
func _clear_access(slot: Dictionary) -> bool:
 return not slot.is_empty() and not FootprintGeometry.blocked(slot.access,_session.spaces.solids(StringName(slot.location_id)),0.12)
func tick() -> void:
 if not _player.is_empty():
  var slot := player_slot()
  if slot.is_empty() or not _clear_access(slot) or slot.location_id!=str(_session.location_id) or _session.player_ground.distance_to(slot.access)>0.65:stand()
 var guest := _session.residential.current
 if guest==null or guest.phase!=&"staying":release_guest();return
 if not _guest.is_empty():
  var slot := guest_slot()
  if slot.is_empty() or not _clear_access(slot) or slot.location_id!=str(guest.pose.location_id) or (reachable.is_valid() and not reachable.call(guest.pose.ground,slot.access)):abandon_guest()
  else:guest.destination=slot.access
  return
 if _declined_guest==str(guest.id):return
 if _session.narrative!=null and _session.narrative.speech_active(guest.id):return
 var slots := _session.visitors.seat_catalog.entries(&"rooftop")
 slots.sort_custom(func(a,b):return guest.pose.ground.distance_squared_to(a.access)<guest.pose.ground.distance_squared_to(b.access))
 for slot in slots:
  if not available(slot) or FootprintGeometry.blocked(slot.access,_session.spaces.solids(&"rooftop"),0.12):continue
  if _session.player_ground.distance_to(slot.access)<0.65:continue
  if reachable.is_valid() and not reachable.call(guest.pose.ground,slot.access):continue
  _guest=str(slot.id);_guest_id=str(guest.id);guest.destination=slot.access;break
var reachable: Callable
func busy_item(id: StringName) -> bool:
 for slot in [player_slot(),guest_slot()]:
  if not slot.is_empty() and (slot.item_id==str(id) or slot.table_id==str(id)):return true
 return false
func snapshot() -> Dictionary:return {"player":_player,"guest":_guest,"guest_id":_guest_id,"declined_guest":_declined_guest}
func restore(data: Dictionary) -> ActionResult:
 for key in ["player","guest","guest_id","declined_guest"]:
  if not data.get(key) is String:return _fail("invalid_seat_use")
 if data.player!="" and data.player==data.guest:return _fail("invalid_seat_use")
 for key in ["player","guest"]:
  if data[key]=="":continue
  var slot := _session.visitors.seat_catalog.lookup(data[key])
  if slot.is_empty() or not _clear_access(slot) or _session.visitors.seating.owner(data[key])!=&"":return _fail("invalid_seat_use")
  if key=="player":
   if slot.location_id!=str(_session.location_id) or _session.player_ground.distance_to(slot.access)>0.65:return _fail("invalid_seat_use")
  else:
   var guest := _session.residential.current
   if guest==null or data.guest_id!=str(guest.id) or guest.phase!=&"staying" or slot.location_id!=str(guest.pose.location_id) or guest.destination.distance_to(slot.access)>0.001:return _fail("invalid_seat_use")
 if (data.guest=="")!=(data.guest_id==""):return _fail("invalid_seat_use")
 if data.declined_guest!="":
  var current := _session.residential.current
  if current==null or current.phase!=&"staying" or data.declined_guest!=str(current.id) or data.guest!="":return _fail("invalid_seat_use")
 _player=data.player;_guest=data.guest;_guest_id=data.guest_id;_declined_guest=data.declined_guest
 return ActionResult.success()
static func _fail(key: String) -> ActionResult:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,StringName(key))

func validate_links() -> ActionResult:
 for slot in [player_slot(),guest_slot()]:
  if slot.is_empty():continue
  if _session.hygiene.is_cleaning(StringName(slot.item_id)) or (slot.table_id!="" and _session.hygiene.is_cleaning(StringName(slot.table_id))):return _fail("invalid_seat_use")
 if player_seated() and FootprintGeometry.blocked(_session.player_ground,_session.spaces.solids(_session.location_id),0.12):return _fail("invalid_seat_use")
 return _session.residential.validate_links()
