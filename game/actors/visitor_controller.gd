class_name VisitorController
extends Node
var _service: VisitorService
var _room: LocationView
var _motors: Dictionary = {}
var _followers: Dictionary = {}
var _spatial: Dictionary={}
func configure(service: VisitorService, room: LocationView) -> void:
 _service = service
 _room = room
 _spatial=room.session.config.section("spatial")
 var navigation_settings: Dictionary=_spatial.get("navigation",{}).duplicate(true)
 if not navigation_settings.has("arrival_radius"):navigation_settings["arrival_radius"]=float(room.session.config.section("visitors").arrival_radius)*0.8
 _spatial["navigation"]=navigation_settings
 _service.route_reachable=func(from: Vector2,to: Vector2):return _room.navigation.reachable(from,to,float(_spatial.get("navigation",{}).get("arrival_radius",0.12)))
func step(delta: float) -> void:
 for id in _motors.keys():
  if not _service.visits.has(id):
   _motors[id].queue_free()
   _motors.erase(id)
   _followers.erase(id)
 for id in _service.visits:
  var visit: VisitState = _service.visits[id]
  if not _motors.has(id):
   var perf := RuntimePerformance.begin()
   var motor := ActorMotor.new()
   _room.add_child(motor)
   motor.pose = visit.pose
   var spatial: Dictionary = _spatial
   motor.configure(_room.mapping,float(spatial.npc_speed),float(spatial.foot_radius))
   motor.collision_mask = 1
   motor.teleport(&"kiosk",visit.pose.ground)
   var visual := CharacterView.new()
   visual.name = "Visual"
   visual.configure(spatial.character)
   motor.add_child(visual)
   _motors[id] = motor
   var follower := NpcNavigation.new()
   follower.configure(_room.navigation,_spatial.get("navigation",{}))
   _followers[id]=follower
   RuntimePerformance.finish("visitor_node_spawn",perf)
  var motor: ActorMotor = _motors[id]
  var follower: NpcNavigation=_followers[id]
  var sitting := _service.seating.seated(visit.id)
  var paused := sitting or (visit.phase!=&"leaving" and _service.busy_in_conversation(visit.id))
  follower.step(motor,_service.meetings.goal(visit),delta,paused)
  if follower.take_failure():
   if _service.meetings.active(visit.id):_service.meetings.finish(visit.id)
   elif _service.seating.reserved(visit.id):_service.seating.release(visit.id)
   elif follower.claim_fallback() and _service.navigation_alternative(visit.id):RuntimePerformance.observe("npc_route_fallback",0)
  _service.commit_pose(visit.id,motor.pose)
  var visual: CharacterView=motor.get_node("Visual")
  visual.present(motor.pose,Color(_service.character(visit.character_id).color),false)
  var slot := _service.seating.slot_for(visit.id) if sitting else {}
  if sitting:motor.pose.facing=slot.facing
  var hip_offset := _room.mapping.to_canvas(slot.anchor,float(slot.height))-_room.mapping.to_canvas(motor.pose.ground)+Vector2(0,14) if sitting else Vector2.ZERO
  visual.present_seat(sitting,hip_offset)

func invalidate_paths() -> void:
 for follower: NpcNavigation in _followers.values():follower.invalidate()
