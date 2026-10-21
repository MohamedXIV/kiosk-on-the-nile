extends RefCounted
func run(check, tree) -> void:
 check.case("source_location_markers")
 var path := "res://game/world/location_definition.gd"
 check.is_true(FileAccess.file_exists(path))
 if not FileAccess.file_exists(path): return
 var store := ContentStore.new()
 check.is_true(store.load_directory("res://content").ok)
 var definitions: Dictionary = store.section("locations")
 var Definition = load(path)
 var kiosk = Definition.new(&"kiosk",definitions.kiosk)
 var roof = Definition.new(&"rooftop",definitions.rooftop)
 check.equal(kiosk.marker(&"tea"),Vector2(-1.3,0.65))
 check.equal(roof.marker(&"exit"),Vector2(0,2.05))
 var mapping := SpatialMapping.new(store.section("spatial"))
 check.case("navigation_uses_shared_solids_and_external_arrival_lanes")
 var nav = load("res://game/world/kiosk_navigation.gd").new()
 nav.configure(kiosk,mapping)
 var route: PackedVector2Array = nav.path(Vector2(-14.5,3.6),Vector2(-1.3,1.75))
 check.is_true(route.size()>1)
 for point in route: check.is_true(not nav.blocked(point))
 var doorway_route: PackedVector2Array = nav.path(Vector2(3,2),Vector2(0,-0.2))
 check.is_true(doorway_route.size()>1)
 for point in doorway_route: check.is_true(not nav.blocked(point))
 check.case("actual_location_physics_and_rooftop_furniture")
 var config := SessionConfig.new(store.bundle(),store.fingerprint,store.source_root)
 var session := GameSession.new()
 tree.root.add_child(session)
 check.is_true(session.configure(config).ok)
 var view = load("res://game/world/location_view.gd").new()
 tree.root.add_child(view)
 view.configure(roof,session)
 check.case("owned_fan_and_knowledge_gate_actual_targets")
 var fan_visible := false
 for target in view.interaction_targets():
  if target.id == &"fan": fan_visible = true
 check.is_true(not fan_visible)
 session.home.install_fan()
 for target in view.interaction_targets():
  if target.id == &"fan": fan_visible = true
 check.is_true(fan_visible)
 var motor := ActorMotor.new()
 view.add_child(motor)
 motor.configure(mapping,4.5)
 motor.teleport(&"rooftop",Vector2(0,-0.2))
 await tree.physics_frame
 motor.step_input(Vector2(-1,-1),1.0)
 check.is_true(not load("res://game/world/footprint_geometry.gd").blocked(motor.pose.ground,roof.data.solids,0.0))
 check.is_true(motor.pose.ground.x>=-2.55 and motor.pose.ground.y>=-1.85)
 check.is_true(view.get_node("Solids").get_child_count()>0)
 check.is_true(view.y_sort_enabled)
 view.queue_free()
 session.queue_free()
 store.free()
 await tree.process_frame
