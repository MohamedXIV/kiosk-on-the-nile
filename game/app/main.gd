class_name Main
extends Node2D
var _content := ContentStore.new()
var _save := SaveCoordinator.new()
var _config: SessionConfig
var _text: UiText
var _session: GameSession
var _recipe_panel: RecipePanel
var _shop_panel: ShopPanel
var _journey_panel: JourneyPanel
var _inventory_panel: InventoryPanel
var _build_panel: BuildPanel
var _placement_preview: PlacementPreview
var _physical: PhysicalWorldController
var _world: Node2D
var _rooms: Dictionary = {}
var _motor: ActorMotor
var _character: CharacterView
var _camera: Camera2D
var _visitors: VisitorController
var _router: InteractionRouter
var _ui_layer: CanvasLayer
var _hud: Hud
var _title: TitleScreen
var _transition: LocationTransition
var _captions: SpatialCaptions
var _probe: QaProbe
var _focused: bool = true
var _busy: bool = false
var _sound: Soundscape
var _atmosphere: Atmosphere
func _ready() -> void:
 if OS.is_debug_build() and OS.has_feature("web"):
  var qa: Variant = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('qa')")
  if qa in ["ink","spatial","kiosk","rooftop"]:
   add_child(load("res://tests/qualification/ink_boot.tscn").instantiate())
   return
 _content.required_sections = SessionConfig.REQUIRED_SECTIONS.duplicate()
 add_child(_content)
 add_child(_save)
 var result: ActionResult
 if OS.has_feature("web"):
  result = await _content.load_http(str(JavaScriptBridge.eval("new URL('content/', document.baseURI).href")))
 else:
  var directory := "res://content"
  var arguments := OS.get_cmdline_user_args()
  var index := arguments.find("--content-dir")
  if index>=0 and index+1<arguments.size(): directory=arguments[index+1]
  result = _content.load_directory(directory)
 if not result.ok:
  push_error("Content rejected: "+str(result.details))
  var error := Label.new()
  error.text = "Content could not be loaded: "+str(result.details)
  add_child(error)
  return
 _config = SessionConfig.new(_content.bundle(),_content.fingerprint,_content.source_root)
 _text = UiText.new(_content.section("ui"))
 Engine.physics_ticks_per_second = roundi(1.0/float(_config.section("time").fixed_step))
 _configure_input()
 _sound = Soundscape.new()
 add_child(_sound)
 _sound.configure(_config.section("atmosphere").audio)
 _sound.set_muted(true)
 _atmosphere = Atmosphere.new()
 add_child(_atmosphere)
 _atmosphere.configure(_config.section("atmosphere"))
 _ui_layer = CanvasLayer.new()
 _ui_layer.layer = 5
 add_child(_ui_layer)
 _transition = LocationTransition.new()
 add_child(_transition)
 _transition.configure(_text.data.transition,_text.make_theme())
 _save.completed.connect(func(result):
  if _hud: _hud.toast.show_message(_save_message(result)))
 _title = TitleScreen.new()
 _ui_layer.add_child(_title)
 _title.configure(_text,_save.store.has_save())
 _title.new_requested.connect(begin_new_game)
 _title.continue_requested.connect(continue_game)
 if OS.is_debug_build():
  _probe = QaProbe.new()
  add_child(_probe)
func _configure_input() -> void:
 for action in _text.data.input:
  if not InputMap.has_action(action): InputMap.add_action(action)
  InputMap.action_erase_events(action)
  for key in _text.data.input[action]:
   var event := InputEventKey.new()
   event.physical_keycode = OS.find_keycode_from_string(key)
   InputMap.action_add_event(action,event)
func begin_new_game() -> void:
 if _busy: return
 _busy = true
 var candidate := GameSession.new()
 add_child(candidate)
 var result := candidate.configure(_config)
 if not result.ok:
  candidate.queue_free()
  push_error("Session rejected: "+str(result.details))
  _busy = false
  return
 _install(candidate)
 _busy = false
func continue_game() -> void:
 if _busy: return
 _busy = true
 var result := await _save.load_candidate(_config)
 if result.ok:
  var candidate: GameSession = result.details.session
  _install(candidate)
 else:
  push_warning("Save load rejected: %s (%s)" % [result.message_key,result.details])
  var error := UiText.label(_text.text("load_failed"))
  error.position = Vector2(30,30)
  _title.add_child(error)
 _busy = false
func _install(candidate: GameSession) -> void:
 if _world: _world.free()
 if _session: _session.queue_free()
 _session = candidate
 _world = Node2D.new()
 add_child(_world)
 _physical = PhysicalWorldController.new()
 var world_result := _physical.configure(_session,_world)
 if not world_result.ok: push_error(str(world_result.details));return
 _rooms = _physical.rooms
 _motor = _physical.motor
 _character = _physical.character
 _camera = _physical.camera
 _visitors = _physical.visitors
 _physical.input_provider = func():
  var locked := _transition.active or _hud==null or _hud.notebook.visible or _hud.sleep_panel.visible or _session.build.active or (_inventory_panel!=null and _inventory_panel.visible) or (_recipe_panel!=null and _recipe_panel.visible)
  return Vector2.ZERO if locked else Input.get_vector("move_left","move_right","move_up","move_down")
 _session.motion_step = _step_motion
 var room: LocationView = _rooms.get(str(_session.location_id))
 _router = InteractionRouter.new(_session,room,_text)
 if _hud: _hud.free()
 _hud = Hud.new()
 _ui_layer.add_child(_hud)
 _hud.configure(_text)
 _hud.bind(_session)
 _build_panel=BuildPanel.new()
 _hud.add_child(_build_panel)
 _build_panel.configure(_text,_session.build,_session)
 _inventory_panel=InventoryPanel.new()
 _hud.add_child(_inventory_panel)
 _inventory_panel.configure(_text,_session)
 _recipe_panel=RecipePanel.new()
 _hud.add_child(_recipe_panel)
 _recipe_panel.configure(_text,_session)
 _hud.inventory_requested.connect(func():_inventory_panel.open())
 _journey_panel=JourneyPanel.new()
 _hud.add_child(_journey_panel)
 _journey_panel.configure(_text,_session)
 _shop_panel=ShopPanel.new()
 _hud.add_child(_shop_panel)
 _shop_panel.configure(_text,_session)
 _session.travel.changed.connect(_travel_changed)
 _hud.travel_requested.connect(func(route_id):
  if _session.build.active or _hud.sleep_panel.visible:return
  var result := _session.travel.depart(route_id)
  if not result.ok:_hud.toast.show_message(_text.outcome(result)))
 _hud.arrange_requested.connect(_begin_arrange)
 _hud.clean_floor_requested.connect(func():
  var result := _session.hygiene.begin_clean(StringName("floor:"+str(_session.location_id)))
  _hud.toast.show_message(_text.outcome(result)))
 _hud.save_requested.connect(_request_save)
 _hud.notebook_requested.connect(_toggle_notebook)
 _hud.diagnostics_requested.connect(_diagnostics)
 _session.narrative.failed.connect(func(_result):_hud.toast.show_message(_text.text("narrative_failed")))
 _hud.dialogue.choice_selected.connect(_choose)
 _hud.sleep_panel.confirmed.connect(_begin_sleep)
 _captions = SpatialCaptions.new()
 _captions.theme = _text.make_theme()
 _captions.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _captions.mouse_filter = Control.MOUSE_FILTER_IGNORE
 _hud.add_child(_captions)
 _title.hide()
 _session.start_new()
 _sound.set_muted(false)
 if _probe: _probe.session = _session
func _physics_process(delta: float) -> void:
 if _session==null or not _focused: return
 _session.tick(delta)
 _sound.present(_session.location_id,_session.cooking,_session.home,_session.items,_session.spaces,_session.workflow)
 _atmosphere.present(_session.clock.minutes,_session.location_id)
 _character.present(_session.player_pose,Color(_config.section("spatial").character.player_color),true)
 _character.get_node("HeldItem").present_record(_session.items.get_item(_session.inventory.held_id()))
 _camera.global_position = _motor.global_position
 _camera.offset.y = -(float(_config.section("spatial").camera_vertical_anchor)-0.5)*get_viewport_rect().size.y
 _hud.present(_router.nearest())
 _captions.top_inset = _hud.top_occupied_height()
 _journey_panel.present()
 _shop_panel.present()
 if _shop_panel.visible:_journey_panel.hide()
 _captions.visible=_session.locations.is_physical(_session.location_id)
 if _captions.visible:_captions.present(_session,_rooms[str(_session.location_id)],_camera)
 _save.transition_active = _transition.active
 _save.boundary(_session)
func _unhandled_input(event: InputEvent) -> void:
 if _session==null or not _focused or _busy or _transition.active: return
 if event is InputEventKey and event.echo: return
 if _recipe_panel.visible:
  if event.is_action_pressed("cancel"):_recipe_panel.hide()
  return
 if _inventory_panel.visible:
  if event.is_action_pressed("cancel"):_inventory_panel.hide()
  return
 if _session.build.active:
  if event.is_action_pressed("cancel"):
   _session.build.cancel()
   _build_panel.hide()
  elif event is InputEventKey and event.pressed and event.keycode==KEY_R: _build_panel.rotate_selection()
  elif event is InputEventKey and event.pressed and event.keycode==KEY_ENTER: _session.build.confirm()
  elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
   var room: LocationView=_rooms[str(_session.location_id)]
   var ground := room.mapping.to_ground(room.get_local_mouse_position())
   _build_panel.move_cursor(Vector2i(floori(ground.x/0.25),floori(ground.y/0.25)))
  get_viewport().set_input_as_handled()
  return
 if _hud.sleep_panel.visible:
  if event.is_action_pressed("cancel"):
   _hud.sleep_panel.hide()
   get_viewport().set_input_as_handled()
  return
 if event.is_action_pressed("notebook"):
  _toggle_notebook()
  get_viewport().set_input_as_handled()
  return
 if _hud.notebook.visible: return
 if event.is_action_pressed("interact_primary") or event.is_action_pressed("interact_secondary"):
  get_viewport().set_input_as_handled()
  _busy = true
  var result := await _router.execute(event.is_action_pressed("interact_secondary"))
  if result.ok and result.details.has("show_recipes"):
   _recipe_panel.present(StringName(result.details.show_recipes))
   _busy=false
   return
  if result.ok and result.details.get("show_inventory",false):
   _inventory_panel.open()
   _busy=false
   return
  if result.ok and result.details.get("choose_sleep",false):
   _hud.sleep_panel.present(_session.routine)
   _busy = false
   return
  if result.ok and result.details.get("transition",false):
   _save.transition_active = true
   var message := _text.text("to_kiosk") if result.details.destination=="kiosk" else _text.text("back_home")
   result = await _transition.run(func():return _commit_transition(result.details),message)
   _save.transition_active = false
  _sound.play_action(result)
  _hud.toast.show_message(_text.text("craft_mood_penalty",{"quality":_session.cooking.quality_label(result.details.item)}) if result.ok and result.details.get("mood_penalty",0)>0 else _text.outcome(result))
  _busy = false
func _commit_transition(details: Dictionary) -> ActionResult:
 var result := _session.life.sleep(int(details.sleep_hours)) if details.has("sleep_hours") else _session.life.travel(StringName(details.destination))
 if not result.ok: return result
 _travel_changed()
 return result
func _request_save() -> void:
 if _session==null: return
 var result := _save.save_at_boundary(_session)
 if not result.details.get("deferred",false): _hud.toast.show_message(_save_message(result))
func _choose(session_id: StringName, choice_id: StringName) -> void:
 var result := _session.narrative.choose(session_id,choice_id)
 _sound.play_action(result)
 if not result.ok: _hud.toast.show_message(_text.outcome(result))
func _toggle_notebook() -> void:
 if _hud.sleep_panel.visible or _transition.active: return
 _session.hygiene.interrupt_clean()
 if _hud.notebook.visible: _hud.notebook.hide()
 else: _hud.notebook.present(_session.knowledge.notes())
func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  _focused = false
  if _sound: _sound.set_muted(true)
  if _text:
   for action in _text.data.input: Input.action_release(action)
 elif what==NOTIFICATION_APPLICATION_FOCUS_IN:
  _focused = true
  if _sound and _session: _sound.set_muted(false)

func _step_motion(delta: float) -> void:
 _physical.step(delta)

func _diagnostics() -> void:
 var diagnostics := Diagnostics.new()
 add_child(diagnostics)
 var result := await diagnostics.inspect(_config)
 diagnostics.queue_free()
 _hud.toast.show_message(_text.text("diagnostics_ok") if result.ok else _text.text("diagnostics_failed"))

func _save_message(result: ActionResult) -> String:
 if not result.ok: return _text.text("save_failed")
 return _text.text("saved_web") if result.details.get("sync_requested",false) else _text.text("saved")

func _begin_sleep(hours: int) -> void:
 if _busy or _transition.active or not _hud.sleep_panel.visible: return
 var preview := _session.routine.preview(hours)
 if not preview.ok:
  _hud.toast.show_message(_text.outcome(preview))
  return
 _busy = true
 _hud.sleep_panel.hide()
 # The fade is presentation only; keep the quoted time/condition stable.
 _session.running = false
 _save.transition_active = true
 var details := {"sleep_hours":hours,"destination":"rooftop"}
 var result := await _transition.run(func():return _commit_transition(details),_text.text("sleeping"))
 _save.transition_active = false
 _session.running = true
 if result.ok:
  var minute := int(_session.clock.minutes)
  _hud.toast.show_message(_text.text("sleep_completed",{"day":_session.clock.day,"hour":"%02d" % (minute/60),"minute":"%02d" % (minute%60)}))
 else: _hud.toast.show_message(_text.outcome(result))
 _sound.play_action(result)
 _busy = false

func _begin_arrange() -> void:
 if _busy or _transition.active or _hud.sleep_panel.visible: return
 _session.hygiene.interrupt_clean()
 var result := _session.build.begin(_session.location_id)
 if not result.ok:
  _hud.toast.show_message(_text.outcome(result))
  return
 if _placement_preview: _placement_preview.queue_free()
 var room: LocationView=_rooms[str(_session.location_id)]
 _placement_preview=PlacementPreview.new()
 room.add_child(_placement_preview)
 _placement_preview.configure(_session.build,_session.spaces,_session.items,room.mapping)
 _build_panel.open()

func _travel_changed() -> void:
 _physical.set_active_location(_session.location_id)
 _router=InteractionRouter.new(_session,_rooms.get(str(_session.location_id)),_text)
 if _session.build.active:
  _session.build.cancel()
  _build_panel.hide()
 _inventory_panel.hide()
 _recipe_panel.hide()
