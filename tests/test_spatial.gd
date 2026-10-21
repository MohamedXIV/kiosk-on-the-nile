extends RefCounted
func run(check, tree) -> void:
 check.case("projection_round_trip")
 var path := "res://game/world/spatial_mapping.gd"
 check.is_true(FileAccess.file_exists(path))
 if not FileAccess.file_exists(path): return
 var mapping = load(path).new({"x_scale":68,"depth_scale":54,"height_scale":48})
 check.equal(mapping.to_canvas(Vector2(1,2),1.0),Vector2(68,60))
 check.equal(mapping.to_ground(Vector2(68,108)),Vector2(1,2))
 check.case("native_collision_and_normalized_motion")
 var world := Node2D.new()
 tree.root.add_child(world)
 var solid := StaticBody2D.new()
 solid.position = Vector2(0,100)
 var shape := CollisionShape2D.new()
 var box := RectangleShape2D.new()
 box.size = Vector2(300,20)
 shape.shape = box
 solid.add_child(shape)
 world.add_child(solid)
 var motor = load("res://game/world/actor_motor.gd").new()
 world.add_child(motor)
 motor.configure(mapping,4.5)
 await tree.physics_frame
 motor.position = Vector2(500,0)
 motor.step_input(Vector2(1,1),1.0)
 check.near(mapping.to_ground(motor.position-Vector2(500,0)).length(),4.5)
 check.equal(motor.pose.ground,mapping.to_ground(motor.position))
 motor.position = Vector2.ZERO
 for i in range(120): motor.step_input(Vector2.DOWN,1.0/60.0)
 check.is_true(motor.position.y < 90)
 check.equal(motor.pose.ground,mapping.to_ground(motor.position))
 check.case("nearest_available_interaction")
 var Target = load("res://game/world/interaction_target.gd")
 var Selector = load("res://game/world/interaction_selector.gd")
 var a = Target.new(&"a",Vector2.ZERO,2.0)
 var b = Target.new(&"b",Vector2(1,0),2.0)
 var targets: Array[InteractionTarget] = [a,b]
 check.equal(Selector.nearest(Vector2(0.9,0),targets).id,&"b")
 b.available = false
 check.equal(Selector.nearest(Vector2(0.9,0),targets).id,&"a")
 check.equal(Selector.nearest(Vector2(10,0),targets),null)
 world.queue_free()
 await tree.process_frame
