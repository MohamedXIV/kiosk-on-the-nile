class_name ActorMotor
extends CharacterBody2D
signal pose_changed(pose: ActorPose)
var pose := ActorPose.new()
var _mapping: SpatialMapping
var _speed: float = 4.5
var _path := PackedVector2Array()
var _path_index: int = 0
var motion_filter: Callable
var motion_yielded: bool=false
var detour_skip_distance: float=0.75
var dynamic_wait_limit: float=6
func configure(mapping: SpatialMapping, speed: float, foot_radius: float = 8.0) -> void:
 _mapping = mapping
 position = _mapping.to_canvas(pose.ground)
 _speed = speed
 collision_layer = 2
 collision_mask = 1 | 4
 var foot := get_node_or_null("Foot") as CollisionShape2D
 if foot == null:
  foot = CollisionShape2D.new()
  foot.name = "Foot"
  add_child(foot)
 var shape := CircleShape2D.new()
 shape.radius = foot_radius
 foot.shape = shape
 commit_pose()
func teleport(location: StringName, ground: Vector2) -> void:
 pose.location_id = location
 position = _mapping.to_canvas(ground)
 velocity = Vector2.ZERO
 commit_pose()
func step_input(direction: Vector2, delta: float) -> void:
 if _mapping == null or delta < 0: return
 var normalized := direction.limit_length(1.0)
 var desired := normalized*_speed
 var filtered: Vector2=motion_filter.call(desired,delta) if motion_filter.is_valid() else desired
 motion_yielded=not desired.is_zero_approx() and filtered.distance_to(desired)>0.05
 velocity = _mapping.to_canvas(filtered.limit_length(_speed))
 var motion := velocity * delta
 var before := position
 if not motion.is_zero_approx():
  var collision := move_and_collide(motion)
  if collision:
   var remaining := collision.get_remainder().slide(collision.get_normal())
   if not remaining.is_zero_approx(): move_and_collide(remaining)
  pose.facing = filtered.normalized()
  pose.walk_phase = pose.walk_phase+delta*10.0 if position.distance_squared_to(before)>0.000001 else 0.0
 else:
  pose.walk_phase = 0
 commit_pose()
func step_path(path: PackedVector2Array, delta: float, waypoint_radius: float=0.08, clear_segment: Callable=Callable()) -> void:
 if path != _path:
  _path = path
  _path_index = 0
 while _path_index < _path.size() and pose.ground.distance_to(_path[_path_index]) < waypoint_radius:
  _path_index += 1
 if motion_filter.is_valid() and clear_segment.is_valid():
  for skipped in range(6):
   if _path_index>=_path.size()-1:break
   var current := _path[_path_index]
   var next := _path[_path_index+1]
   if (pose.ground-current).dot(next-current)<=0:break
   if pose.ground.distance_to(Geometry2D.get_closest_point_to_segment(pose.ground,current,next))>detour_skip_distance or not clear_segment.call(pose.ground,next):break
   _path_index+=1
   RuntimePerformance.observe("npc_detour_skip",0)
 if _path_index >= _path.size():
  step_input(Vector2.ZERO,delta)
  return
 var remaining := _path[_path_index] - pose.ground
 var limited_delta := minf(delta,remaining.length()/_speed)
 step_input(remaining.normalized(),limited_delta)
func commit_pose() -> void:
 if _mapping == null: return
 pose.ground = _mapping.to_ground(position)
 pose_changed.emit(pose)
func reset_path() -> void:
 _path=PackedVector2Array()
 _path_index=0
func path_cursor() -> int:
 return _path_index
func waypoint_distance() -> float:
 return pose.ground.distance_to(_path[_path_index]) if _path_index<_path.size() else 0.0
