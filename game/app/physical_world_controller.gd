class_name PhysicalWorldController
extends RefCounted
var rooms: Dictionary = {}
var motor: ActorMotor
var character: CharacterView
var camera: Camera2D
var residential: ResidentialController
var visitors: VisitorController
var input_provider: Callable
var _session: GameSession
func configure(session: GameSession, parent: Node2D) -> ActionResult:
 _session = session
 for id in session.config.section("locations"):
  var room := LocationView.new()
  parent.add_child(room)
  room.configure(LocationDefinition.new(StringName(id),session.config.section("locations")[id]),session)
  rooms[id]=room
 var room_id := session.location_id if session.locations.is_physical(session.location_id) else StringName(session.travel.snapshot().journey.origin_pose.location_id)
 var room: LocationView = rooms[str(room_id)]
 motor = ActorMotor.new()
 room.add_child(motor)
 motor.pose = session.player_pose
 var spatial := session.config.section("spatial")
 motor.configure(room.mapping,float(spatial.player_speed),float(spatial.foot_radius))
 if session.locations.is_physical(session.location_id):motor.teleport(session.location_id,session.player_ground)
 character = preload("res://game/presentation/character_view.tscn").instantiate()
 motor.add_child(character)
 character.configure(spatial.character)
 camera = Camera2D.new()
 parent.add_child(camera)
 camera.enabled = true
 camera.position_smoothing_enabled = true
 camera.position_smoothing_speed = float(spatial.camera_smoothing)
 camera.global_position = motor.global_position
 camera.reset_smoothing()
 visitors = VisitorController.new()
 parent.add_child(visitors)
 session.visitors.update_markers(rooms.kiosk.definition.data.markers)
 visitors.configure(session.visitors,rooms.kiosk)
 session.visitors.observed_actors=func():
  var actors: Dictionary={}
  if session.locations.is_physical(session.location_id):actors["player"]=session.player_pose
  for visit: VisitState in session.visitors.visits.values():actors[str(visit.character_id)]=visit.pose
  return actors
 session.visitors.sight_clear=func(from: Vector2,to: Vector2):return rooms.kiosk.navigation.sight_clear(from,to)
 residential=ResidentialController.new()
 parent.add_child(residential)
 residential.session=session;residential.room=rooms.rooftop
 session.spaces.set_adapter(_refresh)
 return ActionResult.success()
func step(delta: float) -> void:
 var direction := Vector2.ZERO
 if input_provider.is_valid(): direction = input_provider.call()
 if _session.locations.is_physical(_session.location_id):motor.step_input(direction,delta)
 visitors.step(delta)
 residential.step(delta)
func set_active_location(id: StringName) -> void:
 if not _session.locations.is_physical(id):return
 var room: LocationView = rooms[str(id)]
 if motor.get_parent()!=room: motor.reparent(room,false)
 motor.teleport(id,_session.player_ground)
 camera.global_position = motor.global_position
 camera.reset_smoothing()
func _refresh(id: StringName) -> void:
 if not rooms.has(str(id)): return
 var room: LocationView = rooms[str(id)]
 room.refresh_layout()
 if id==&"kiosk":
  _session.visitors.update_markers(room.definition.data.markers)
  visitors.invalidate_paths()
