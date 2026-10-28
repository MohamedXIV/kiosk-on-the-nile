class_name ResidentialController
extends Node
var session: GameSession
var room: LocationView
var _motor: ActorMotor
var _navigation: NpcNavigation
var _id: StringName
var avoidance: NpcAvoidanceWorld
var _speed: float=0
var _arrival_radius: float=0.12
func step(delta: float) -> void:
 var record := session.residential.current
 if record==null or record.id!=_id:
  if avoidance!=null and _id!=&"":avoidance.remove_actor(_id)
  if _motor!=null:_motor.queue_free();_motor=null
  _id=&""
 if record==null:return
 if _motor==null:
  _id=record.id
  _motor=ActorMotor.new();room.add_child(_motor);_motor.pose=record.pose
  var spatial := session.config.section("spatial")
  _speed=float(session.config.section("residential_visits").speed)
  _arrival_radius=float(spatial.get("navigation",{}).get("arrival_radius",0.12))
  _motor.configure(room.mapping,_speed,float(spatial.foot_radius))
  _navigation=NpcNavigation.new();_navigation.configure(room.navigation,spatial.get("navigation",{}))
  if avoidance!=null:avoidance.tune_motor(_motor,record.id)
  _motor.collision_mask=1;_motor.teleport(&"rooftop",record.pose.ground)
  var visual := CharacterView.new();visual.name="Visual";visual.configure(spatial.character);_motor.add_child(visual)
 var paused := record.phase==&"staying" and (session.narrative.speech_active(record.id) or session.personal.holds_visit(record.id))
 var destination: Vector2=record.destination
 var coordinated := false
 var route := PackedVector2Array()
 if avoidance!=null:
  avoidance.sync(record.id,record.pose.ground,paused or record.pose.ground.distance_to(record.destination)<=_arrival_radius,_speed,false,record.destination,paused)
  avoidance.prepare_passages(delta)
  destination=avoidance.movement_target(record.id,destination)
  route=avoidance.movement_path(record.id)
  paused=paused or avoidance.passage_waiting(record.id)
  coordinated=avoidance.passage_active(record.id)
 _navigation.step(_motor,destination,delta,paused,route)
 if _navigation.take_failure() and not coordinated and _navigation.claim_fallback() and session.residential.navigation_alternative(room.navigation):RuntimePerformance.observe("npc_route_fallback",0)
 record.pose=_motor.pose
 _motor.get_node("Visual").present(record.pose,Color(session.presence.profile(record.character_id).color),false)
