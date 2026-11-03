extends Node2D
## Debug-only deterministic previews of production UI. Never reads or writes saves.
## Run this scene with -- --area history --lang ar_EG [--capture-dir /tmp/cozy].
var session: GameSession
var hud: Hud
var _store := ContentStore.new()
var _locale := LocaleService.new()
var _text: UiText
var _physical := PhysicalWorldController.new()
var _area: String="hud"
var _limitations: Array[String]=[]
var _visit: VisitState
var _capture_dir: String=""
var _prepared: bool=false
func _ready() -> void:
 # InkGD installs its runtime singleton at root; wait until scene attachment ends.
 await get_tree().process_frame
 _area=_parameter("area","hud")
 _capture_dir=_parameter("capture-dir","")
 var extent := get_window().size
 if OS.has_feature("web"):
  extent=Vector2i(int(JavaScriptBridge.eval("window.innerWidth")),int(JavaScriptBridge.eval("window.innerHeight")))
 extent=Vector2i(int(_parameter("width",str(extent.x))),int(_parameter("height",str(extent.y))))
 # Exercise responsive logical layout instead of scaling a fixed 1280 px canvas.
 get_window().content_scale_size=extent
 if not OS.has_feature("web"):get_window().size=extent
 add_child(_store)
 var result: ActionResult
 if OS.has_feature("web"):
  result=await _store.load_http(str(JavaScriptBridge.eval("new URL('content/',document.baseURI).href")))
 else:result=_store.load_directory("res://content")
 if not _require(result,"content"):return
 if not _require(_locale.configure(_store.bundle()),"locale"):return
 var language := _parameter("lang","ar_EG")
 if language=="ar":language="ar_EG"
 if not _require(_locale.set_locale(language),"language"):return
 _text=UiText.new(_store.section("ui"))
 var fixture := _store.bundle()
 fixture.visitors.seed=1703
 session=GameSession.new();add_child(session)
 if not _require(session.configure(SessionConfig.new(fixture,_store.fingerprint,_store.source_root)),"session"):return
 session.start_new()
 if _area not in ["title","sleep","supplier","tuning"]:
  if not _require(session.travel.depart(&"to_kiosk"),"kiosk journey"):return
  _finish_journey()
 if _area in ["dialogue","visitor","payment","notes","people","history","notebook","accounts","receipts"]:
  _spawn_social_fixture()
  if _area not in ["visitor","payment"]:await _hear_authored_conversation()
 if _area in ["shop","district","journey"]:
  if not _require(session.travel.depart(&"district" if _area=="district" else &"market"),"outing"):return
  if _area!="journey":_finish_journey()
 # The simulation stays at its prepared domain state after these finite commands.
 session.running=false
 var world := Node2D.new();add_child(world)
 if not _require(_physical.configure(session,world),"physical world"):return
 _physical.character.present(session.player_pose,Color(session.config.section("spatial").character.player_color),true)
 _physical.camera.position_smoothing_enabled=false
 _physical.camera.offset.y=-(float(session.config.section("spatial").camera_vertical_anchor)-0.5)*get_viewport_rect().size.y
 var layer := CanvasLayer.new();layer.layer=5;add_child(layer)
 hud=Hud.new();layer.add_child(hud);hud.configure(_text);hud.bind(session)
 _locale.changed.connect(func():UiText.refresh_tree(self))
 hud.present(null)
 await _open_area(layer)
 UiText.refresh_tree(hud)
 if _area!="hud":hud.suppress_prompts()
 for index in range(10):await get_tree().process_frame
 _prepared=true
 # Reapply compact dialogue sizing after fonts and wrapping have settled.
 if _area=="dialogue":hud.present(null)
 var status := {"ready":true,"area":_area,"locale":_locale.locale,"limitations":_limitations,"world_minutes":session.clock.world_minutes}
 print("COZY_UI_STATUS ",JSON.stringify(status))
 if OS.has_feature("web"):JavaScriptBridge.eval("window.cozyStatus="+JSON.stringify(status))
 if not _capture_dir.is_empty():await _capture()
func _process(_delta: float) -> void:
 if not _prepared or not is_instance_valid(hud) or _area=="title":return
 hud.present(null)
 if _area!="hud":hud.suppress_prompts()
func _parameter(key: String, fallback: String) -> String:
 if OS.has_feature("web"):
  var value: Variant=JavaScriptBridge.eval("new URLSearchParams(window.location.search).get("+JSON.stringify(key)+")")
  return str(value) if value!=null else fallback
 var args := OS.get_cmdline_user_args()
 var position := args.find("--"+key)
 return args[position+1] if position>=0 and position+1<args.size() else fallback
func _require(result: ActionResult, stage: String) -> bool:
 if result.ok:return true
 var message := stage+": "+str(result.message_key)+" "+str(result.details)
 push_error("Cozy UI preview rejected: "+message)
 if OS.has_feature("web"):JavaScriptBridge.eval("window.cozyStatus="+JSON.stringify({"ready":false,"area":_area,"error":message}))
 return false
func _finish_journey() -> void:
 var remaining := float(session.travel.journey.data.due_at)-session.clock.world_minutes
 var seconds := (remaining+0.02)/float(session.config.section("time").minutes_per_second)
 # The coordinator owns clock, travel arrival, accounts and the rest of the world.
 while seconds>0:
  var step := minf(0.25,seconds)
  session.tick(step)
  seconds-=step
func _spawn_social_fixture() -> void:
 # Arrival pose is an explicit test fixture, not a saved or shipping game mutation.
 _visit=session.visitors.spawn(&"amgad")
 if _visit==null:
  for value: VisitState in session.visitors.visits.values():
   if value.character_id==&"amgad":_visit=value;break
 if _visit==null:_limitations.append("Amgad was unavailable in this fixture.");return
 _visit.phase=&"staying";_visit.pose.ground=Vector2(-0.7,1.8);_visit.destination=_visit.pose.ground
 session.player_ground=Vector2(0.2,1.8)
func _hear_authored_conversation() -> void:
 if _visit==null:return
 var opened := await session.personal.open_for(_visit.id)
 if not opened.ok:_limitations.append("Personal conversation unavailable: "+str(opened.message_key));return
 var selected := false
 for topic in session.narrative.manual_topics_for(_visit.id):
  if str(topic.encounter)=="amgad":
   var result := await session.personal.select_topic(str(topic.key))
   selected=result.ok
   break
 if not selected:_limitations.append("No authored Amgad topic was available; showing the real topic list.");return
 if _area=="dialogue":return
 # Advance actual authored speech into the journal without inventing history text.
 for index in range(8):
  var view := session.personal.view()
  var conversation: ConversationSession=view.get("conversation")
  if conversation==null:break
  var choices := session.narrative.choices(conversation)
  if not choices.is_empty():
   if not _require(session.narrative.choose(conversation.id,StringName(choices[0].id)),"authored choice"):break
  elif not session.personal.advance().ok:break
 session.personal.leave()
func _open_area(layer: CanvasLayer) -> void:
 match _area:
  "title":
   hud.hide()
   var title := TitleScreen.new();layer.add_child(title);title.configure(_text,false);UiText.refresh_tree(title)
  "hud":pass
  "shop":
   var panel := ShopPanel.new();hud.add_child(panel);panel.configure(_text,session);panel.present()
  "inventory":
   var panel := InventoryPanel.new();hud.add_child(panel);panel.configure(_text,session);panel.open()
  "recipe","recipe_v2":
   var target: StringName=&"kebda" if _area=="recipe_v2" else &"tea"
   session.player_ground=session.spaces.ground(target)+Vector2(0,0.8)
   if _area=="recipe":
    var started := session.workflow.start(&"tea",&"kiosk",PackedStringArray(["tea"]))
    if not started.ok:_limitations.append("Tea active job unavailable: "+str(started.message_key))
   else:_limitations.append("V2 liver recipe shows genuine initial ingredient availability; no unearned stock or progress is injected.")
   var panel := RecipePanel.new();hud.add_child(panel);panel.configure(_text,session);panel.present(target)
  "dialogue":
   hud.dialogue.choice_selected.connect(func(id,choice):session.narrative.choose(id,choice);hud.present(null))
   hud.dialogue.advance_requested.connect(func():session.personal.advance();hud.present(null))
   hud.dialogue.leave_requested.connect(func():session.personal.leave();hud.present(null))
   hud.dialogue.topic_selected.connect(func(key):await session.personal.select_topic(key);hud.present(null))
   hud.present(null)
  "notebook","notes","people","history","accounts","receipts":
   hud.notebook.open()
   hud.notebook._tabs.current_tab={"people":1,"history":2,"accounts":3,"receipts":3}.get(_area,0)
   if _area=="receipts":
    hud.notebook._accounts._mode.select(1)
    _limitations.append("Receipts show the actual empty initial ledger; no fabricated signed records.")
   hud.notebook.refresh()
  "visitor":
   if _visit!=null:
    var panel := VisitorPanel.new();hud.add_child(panel);panel.configure(_text,session);panel.present(_visit.id)
  "payment":
   if _visit!=null:
    # Genuine accepted quote; payment is left pending and never automatically settled.
    var order := session.service.place_order(_visit.id,&"tea")
    if order!=null:
     var panel := PaymentPanel.new();hud.add_child(panel);panel.configure(_text,session);panel.present(order.id)
    else:_limitations.append("Initial tea order unavailable.")
  "supplier":
   var points := session.contact.points()
   if not points.is_empty():
    var point: Dictionary=points[0]
    for value in points:
     if value.location_id==str(session.location_id):point=value;break
    session.location_id=StringName(point.location_id);session.player_ground=point.ground
    var connected := await session.contact.begin(str(point.host_id))
    if connected.ok:
     # The real phone/contact gate is open; show the production contract editor.
     session.contact.panel_requested=true
     var panel := SupplierPanel.new();hud.add_child(panel);panel.configure(_text,session);panel.present()
    else:_limitations.append("Supplier phone unavailable: "+str(connected.message_key))
   else:_limitations.append("No placed phone host in the initial layout.")
  "district":
   var panel := DistrictPanel.new();hud.add_child(panel);panel.configure(_text,session);panel.present();panel._quote("settle")
  "sleep":hud.sleep_panel.present(session.routine)
  "journey":
   var panel := JourneyPanel.new();hud.add_child(panel);panel.configure(_text,session);panel.present()
  "build":
   if _require(session.build.begin(session.location_id),"arrangement"):
    var panel := BuildPanel.new();hud.add_child(panel);panel.configure(_text,session.build,session);panel.open()
  "menu":
   var panel := MenuPanel.new();hud.add_child(panel);panel.configure(_text,session);panel.open()
  "tuning":
   var panel := TuningPanel.new();hud.add_child(panel);panel.configure(session);panel.open()
  _:_limitations.append("Unknown area; showing the real HUD.")
 if session.locations.is_physical(session.location_id):_physical.set_active_location(session.location_id)
 _physical.character.present(session.player_pose,Color(session.config.section("spatial").character.player_color),true)
func _capture() -> void:
 if DisplayServer.get_name()=="headless":
  print("COZY_UI_CAPTURE skipped: headless display has no rendered image")
 else:
  await RenderingServer.frame_post_draw
  DirAccess.make_dir_recursive_absolute(_capture_dir)
  var path := _capture_dir.path_join(_area+"-"+_locale.locale+".png")
  var error := get_viewport().get_texture().get_image().save_png(path)
  print("COZY_UI_CAPTURE ",path," status=",error)
 # Let InkGD finish its deferred runtime-removal callbacks before native exit.
 session.personal.leave()
 for id in session.narrative.sessions.keys():session.narrative.cancel(StringName(id))
 await get_tree().process_frame
 for player in session.ink_players.get_children():
  player.destroy()
  player.queue_free()
 for index in range(3):await get_tree().process_frame
 get_tree().quit()
