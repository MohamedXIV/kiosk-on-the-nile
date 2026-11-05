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
 check.case("knowledge_gate_exposes_used_fan_offer")
 var phone_rule: Dictionary={}
 for interaction in definitions.kiosk.interactions:
  if interaction.get("secondary_action")=="buy_fan":phone_rule=interaction.secondary_requires
 check.is_true(not phone_rule.is_empty())
 check.is_true(not session.conditions.permits(phone_rule))
 check.is_true(session.knowledge.learn(&"KNOWN_CHEAP_FAN","مصلحة مروحة","amgad"))
 check.is_true(session.conditions.permits(phone_rule))
 check.case("stored_fan_requires_placement_before_generated_equipment_interaction")
 check.is_true(not _has_fan_target(view,session))
 check.is_true(session.home.install_fan().ok)
 check.is_true(session.home.has_fan)
 view.refresh_layout()
 check.is_true(not _has_fan_target(view,session))
 var fan: Dictionary=session.items.instances(&"fan")[0]
 var request := PlacementRequest.from_dict({"instance_id":fan.id,"location_id":"rooftop","cell":[2,-3],"rotation":0,"host_id":"","slot_id":""})
 check.is_true(session.spaces.place(request).ok)
 view.refresh_layout()
 check.is_true(_has_fan_target(view,session))
 check.is_true(session.spaces.store(StringName(fan.id)).ok)
 view.refresh_layout()
 check.is_true(not _has_fan_target(view,session))
 # Ownership in storage still prevents buying a second used fan.
 check.is_true(not session.conditions.permits(phone_rule))
 check.case("actor_motion_respects_current_generated_solids_and_player_bounds")
 var motor := ActorMotor.new()
 view.add_child(motor)
 motor.configure(mapping,4.5)
 motor.teleport(&"rooftop",Vector2(0,-0.2))
 await tree.physics_frame
 motor.step_input(Vector2(-1,-1),1.0)
 check.is_true(not FootprintGeometry.blocked(motor.pose.ground,session.spaces.solids(&"rooftop"),0.0))
 var bounds: Array=view.definition.data.player_bounds
 check.is_true(motor.pose.ground.x>=float(bounds[0]) and motor.pose.ground.y>=float(bounds[1]))
 check.is_true(view.get_node("Solids").get_child_count()>0)
 check.is_true(view.y_sort_enabled)
 view.queue_free()
 session.queue_free()
 store.free()
 await tree.process_frame

func _has_fan_target(view: LocationView, session: GameSession) -> bool:
 for target in view.interaction_targets():
  for fan in session.items.instances(&"fan"):
   if str(target.id)=="equipment:"+str(fan.id):return true
 return false
