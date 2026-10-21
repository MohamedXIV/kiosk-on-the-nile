extends Node2D
var session: GameSession
var motor: ActorMotor
var character: CharacterView
var camera: Camera2D
func _ready() -> void:
 var store := ContentStore.new()
 add_child(store)
 var selected: String = "rooftop"
 var result: ActionResult
 if OS.has_feature("web"):
  selected = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('qa')")
  result = await store.load_http(str(JavaScriptBridge.eval("window.location.origin"))+"/content")
 else:
  result = store.load_directory("res://content")
 if not result.ok:
  push_error("Qualification content rejected: "+str(result.details))
  return
 session = GameSession.new()
 add_child(session)
 result = session.configure(SessionConfig.new(store.bundle(),store.fingerprint,store.source_root))
 if not result.ok:
  push_error("Qualification session rejected")
  return
 session.location_id = StringName(selected)
 var rooms: Dictionary = {}
 for id in store.section("locations"):
  var definition := LocationDefinition.new(StringName(id),store.section("locations")[id])
  var room := LocationView.new()
  add_child(room)
  room.configure(definition,session)
  rooms[id] = room
 var active: LocationView = rooms[selected]
 motor = ActorMotor.new()
 active.add_child(motor)
 motor.pose = session.player_pose
 var spatial: Dictionary = store.section("spatial")
 motor.configure(active.mapping,float(spatial.player_speed),float(spatial.foot_radius))
 motor.teleport(StringName(selected),Vector2(active.definition.data.spawn[0],active.definition.data.spawn[1]))
 character = preload("res://game/presentation/character_view.tscn").instantiate()
 motor.add_child(character)
 character.configure(spatial.character)
 character.present(motor.pose,Color("3d7a8a"),true)
 camera = Camera2D.new()
 add_child(camera)
 camera.global_position = motor.global_position
 camera.offset.y = -(float(spatial.camera_vertical_anchor)-0.5)*get_viewport_rect().size.y
 camera.enabled = true
 await get_tree().process_frame
 await get_tree().process_frame
 if OS.has_feature("web"): JavaScriptBridge.eval("window.locationStatus="+JSON.stringify({"ready":true,"id":selected}))
func _physics_process(delta: float) -> void:
 if motor == null or camera == null: return
 var direction := Vector2(float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A)),float(Input.is_key_pressed(KEY_S))-float(Input.is_key_pressed(KEY_W)))
 motor.step_input(direction,delta)
 character.present(motor.pose,Color("3d7a8a"),true)
 camera.global_position = motor.global_position
