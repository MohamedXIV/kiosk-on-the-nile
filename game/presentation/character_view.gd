class_name CharacterView
extends Node2D
var _pose := ActorPose.new()
var _color := Color("3d7a8a")
var _is_player: bool = false
var _style: Dictionary = {}
var _idle := CharacterIdle.new()
var _torso := StyleBoxFlat.new()
var _seated_target: bool=false
var _seat_offset := Vector2.ZERO
var _body_offset := Vector2.ZERO
var _posture_from := Vector2.ZERO
var _posture_elapsed: float=0
var _sit_amount: float=0
var _sit_from: float=0
var _seat_elevation: float=0
func configure(style: Dictionary) -> void:
 _style = style.duplicate(true)
 _idle.configure(_style.get("idle",{}))
func present(pose: ActorPose, color: Color, is_player: bool) -> void:
 _pose = pose
 _color = color
 _is_player = is_player
func present_seat(seated: bool, hip_offset: Vector2 = Vector2.ZERO, elevation: float = 0) -> void:
 var target := hip_offset if seated else Vector2.ZERO
 if _seated_target!=seated or not _seat_offset.is_equal_approx(target):
  _posture_from=_body_offset;_posture_elapsed=0
  _sit_from=_sit_amount
 _seated_target=seated
 _seat_offset=target
 if seated:_seat_elevation=elevation
func _process(delta: float) -> void:
 if not is_visible_in_tree() or _style.is_empty():return
 _idle.advance(delta,_pose.walk_phase!=0,_is_player)
 var duration := float(_style.get("sit_transition_seconds",0.35))
 _posture_elapsed=minf(duration,_posture_elapsed+delta)
 _body_offset=_posture_from.lerp(_seat_offset,smoothstep(0,1,_posture_elapsed/duration))
 _sit_amount=lerpf(_sit_from,1.0 if _seated_target else 0.0,smoothstep(0,1,_posture_elapsed/duration))
 var held := get_node_or_null("HeldItem") as HeldItemView
 if held:
  held.facing = _pose.facing
  held.position.y = -absf(sin(_pose.walk_phase))*float(_style.get("bob_pixels",3.84))-_idle.breathing
  held.queue_redraw()
 queue_redraw()
func _draw() -> void:
 var bob := absf(sin(_pose.walk_phase))*float(_style.get("bob_pixels",3.84))
 var body_bob := bob+_idle.breathing
 var swing := sin(_pose.walk_phase)*float(_style.get("leg_swing",5))
 var forward := _pose.facing*Vector2(14,10)
 var seated_feet := _body_offset+Vector2(0,-14)+forward+Vector2(0,_seat_elevation)
 ellipse(Vector2.ZERO.lerp(seated_feet,_sit_amount),Vector2(16,8),Color(0,0,0,0.38))
 var legs := Color(_style.get("legs","#262320"))
 if _sit_amount>0.001:
  for side in [-5,5]:
   var hip := _body_offset+Vector2(float(side),-14)
   var foot := Vector2(float(side),-2).lerp(seated_feet+Vector2(float(side),0),_sit_amount)
   var knee := hip.lerp(foot,0.5).lerp(hip+forward,_sit_amount)
   draw_polyline(PackedVector2Array([hip,knee,foot]),legs,6,true)
 else:
  draw_rect(Rect2(-8,-16+swing-bob,6,14),legs)
  draw_rect(Rect2(2,-16-swing-bob,6,14),legs)
 draw_set_transform(_body_offset)
 _torso.bg_color = _color
 _torso.border_color = Color(0,0,0,0.45)
 _torso.set_border_width_all(1)
 _torso.set_corner_radius_all(8)
 draw_style_box(_torso,Rect2(-14,-46-body_bob,28,32))
 if _is_player: draw_rect(Rect2(-9,-36-body_bob,18,20),Color(_style.get("apron","#dfd5c6")))
 draw_circle(Vector2(0,-56-body_bob),12.5,Color(_style.get("skin","#d9a17c")))
 draw_arc(Vector2(0,-56-body_bob),12.5,0,TAU,32,Color(0,0,0,0.45),1.5,true)
 var hair := PackedVector2Array([Vector2(0,-59-body_bob)])
 for i in range(17):
  var angle := PI + PI*i/16.0
  hair.append(Vector2(cos(angle)*12.5,-59-body_bob+sin(angle)*12.5))
 draw_colored_polygon(hair,Color(_style.get("hair","#2b241f")))
 if _pose.facing.y >= -0.3:
  var offset := _pose.facing.x*4
  for x in [-4,4]:
   var eye := Vector2(float(x)+offset,-55-body_bob)+_idle.gaze
   if _idle.blinking:draw_line(eye-Vector2(1.8,0),eye+Vector2(1.8,0),Color("1a1614"),1.4,true)
   else:draw_circle(eye,1.8,Color("1a1614"))
 draw_set_transform(Vector2.ZERO)
func ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
 draw_set_transform(center,0,radius)
 draw_circle(Vector2.ZERO,1,color)
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
