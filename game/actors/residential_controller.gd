class_name ResidentialController
extends Node
var session: GameSession
var room: LocationView
var _motor: ActorMotor
var _navigation: NpcNavigation
var _id: StringName
func step(delta: float) -> void:
 var record := session.residential.current
 if record==null or record.id!=_id:
  if _motor!=null:_motor.queue_free();_motor=null
  _id=&""
 if record==null:return
 if _motor==null:
  _id=record.id
  _motor=ActorMotor.new();room.add_child(_motor);_motor.pose=record.pose
  var spatial := session.config.section("spatial")
  _motor.configure(room.mapping,float(session.config.section("residential_visits").speed),float(spatial.foot_radius))
  _navigation=NpcNavigation.new();_navigation.configure(room.navigation,spatial.get("navigation",{}))
  _motor.collision_mask=1;_motor.teleport(&"rooftop",record.pose.ground)
  var visual := CharacterView.new();visual.name="Visual";visual.configure(spatial.character);_motor.add_child(visual)
 _navigation.step(_motor,record.destination,delta,record.phase==&"staying" and session.narrative.speech_active(record.id))
 if _navigation.take_failure() and _navigation.claim_fallback() and session.residential.navigation_alternative(room.navigation):RuntimePerformance.observe("npc_route_fallback",0)
 record.pose=_motor.pose
 _motor.get_node("Visual").present(record.pose,Color(session.presence.profile(record.character_id).color),false)
