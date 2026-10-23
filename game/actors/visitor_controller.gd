class_name VisitorController
extends Node
var _service: VisitorService
var _room: LocationView
var _motors: Dictionary = {}
var _paths: Dictionary = {}
var _destinations: Dictionary = {}
func configure(service: VisitorService, room: LocationView) -> void:
 _service = service
 _room = room
func step(delta: float) -> void:
 for id in _motors.keys():
  if not _service.visits.has(id):
   _motors[id].queue_free()
   _motors.erase(id)
   _paths.erase(id)
   _destinations.erase(id)
 for id in _service.visits:
  var visit: VisitState = _service.visits[id]
  if not _motors.has(id):
   var motor := ActorMotor.new()
   _room.add_child(motor)
   motor.pose = visit.pose
   var spatial: Dictionary = _room.session.config.section("spatial")
   motor.configure(_room.mapping,float(spatial.npc_speed),float(spatial.foot_radius))
   motor.collision_mask = 1
   motor.teleport(&"kiosk",visit.pose.ground)
   var visual := CharacterView.new()
   visual.name = "Visual"
   visual.configure(spatial.character)
   motor.add_child(visual)
   _motors[id] = motor
  var motor: ActorMotor = _motors[id]
  if _destinations.get(id) != visit.destination:
   _destinations[id] = visit.destination
   _paths[id] = _room.navigation.path(visit.pose.ground,visit.destination)
  if visit.phase!=&"leaving" and _service.busy_in_conversation(visit.id):motor.step_input(Vector2.ZERO,delta)
  elif visit.phase in [&"arriving",&"leaving"] or visit.pose.ground.distance_to(visit.destination)>float(_room.session.config.section("visitors").arrival_radius): motor.step_path(_paths[id],delta)
  else: motor.step_input(Vector2.ZERO,delta)
  _service.commit_pose(visit.id,motor.pose)
  motor.get_node("Visual").present(motor.pose,Color(_service.character(visit.character_id).color),false)

func invalidate_paths() -> void:
 _paths.clear()
 _destinations.clear()
