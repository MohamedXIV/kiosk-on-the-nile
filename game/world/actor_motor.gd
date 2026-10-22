class_name ActorMotor
extends CharacterBody2D
signal pose_changed(pose: ActorPose)
var pose := ActorPose.new()
var _mapping: SpatialMapping
var _speed: float = 4.5
var _path := PackedVector2Array()
var _path_index: int = 0
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
 velocity = _mapping.to_canvas(normalized*_speed)
 var motion := velocity * delta
 if not motion.is_zero_approx():
  var collision := move_and_collide(motion)
  if collision:
   var remaining := collision.get_remainder().slide(collision.get_normal())
   if not remaining.is_zero_approx(): move_and_collide(remaining)
  pose.facing = normalized
  pose.walk_phase += delta*10.0
 else:
  pose.walk_phase = 0
 commit_pose()
func step_path(path: PackedVector2Array, delta: float) -> void:
 if path != _path:
  _path = path
  _path_index = 0
 while _path_index < _path.size() and pose.ground.distance_to(_path[_path_index]) < 0.08:
  _path_index += 1
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
