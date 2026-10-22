extends Control
var runtime: InkRuntime
var body: Label
var choices: VBoxContainer
var start: Button
var restored := false
var content: ContentStore
func _ready() -> void:
 if OS.has_feature("web") and JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('qa')") in ["kiosk","rooftop"]:
  add_child(load("res://tests/qualification/locations_boot.tscn").instantiate())
  return
 if OS.has_feature("web") and JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('qa')") == "spatial":
  add_child(load("res://tests/fixtures/spatial_room.tscn").instantiate())
  return
 content = ContentStore.new()
 add_child(content)
 var content_outcome: ActionResult
 if OS.has_feature("web"):
  var origin: String = JavaScriptBridge.eval("window.location.origin")
  content_outcome = await content.load_http(str(JavaScriptBridge.eval("new URL('content/', document.baseURI).href")))
 else:
  content_outcome = content.load_directory("res://content")
 if not content_outcome.ok:
  push_error("Invalid qualification content")
  return
 var theme_data := Theme.new()
 theme_data.default_font = load("res://assets/fonts/Cairo.ttf")
 theme_data.default_font_size = 26
 theme = theme_data
 var title := Label.new()
 title.text = "كشك ع النيل — E — 45 ج.م"
 title.position = Vector2(100,100)
 title.size = Vector2(1080,80)
 title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 add_child(title)
 body = Label.new()
 body.position = Vector2(100,220)
 body.size = Vector2(1080,90)
 body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 add_child(body)
 choices = VBoxContainer.new()
 choices.position = Vector2(350,350)
 choices.size.x = 580
 add_child(choices)
 start = Button.new()
 start.text = "ابدأ"
 start.position = Vector2(490,230)
 start.size = Vector2(300,70)
 start.pressed.connect(begin)
 add_child(start)
 if FileAccess.file_exists("user://ink-qualification.json"):
  restored = true
  await begin()
 else:
  publish("ready")
func begin() -> void:
 start.hide()
 runtime = InkRuntime.new()
 add_child(runtime)
 var definition := StoryDefinition.new()
 definition.id = &"qualification"
 definition.compiled_path = "res://tests/fixtures/qualification.ink.json"
 definition.sha256 = FileAccess.get_file_as_string(definition.compiled_path).sha256_text()
 var outcome := await runtime.open(definition,{"day":1})
 if not outcome.ok:
  publish("failed")
  return
 if restored:
  outcome = runtime.restore(JSON.parse_string(FileAccess.get_file_as_string("user://ink-qualification.json")))
  if not outcome.ok:
   publish("failed")
   return
  show_frame(runtime.frame())
 else:
  show_frame(runtime.advance())
func show_frame(frame: NarrativeTypes.Frame) -> void:
 body.text = frame.text
 for child in choices.get_children(): child.queue_free()
 for choice in frame.choices:
  var button := Button.new()
  button.text = choice.text
  button.custom_minimum_size.y = 60
  button.pressed.connect(func(): runtime.choose(int(choice.index)); show_frame(runtime.advance()))
  choices.add_child(button)
 var file := FileAccess.open("user://ink-qualification.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(runtime.snapshot()))
 file.close()
 if OS.has_feature("web"): JavaScriptBridge.force_fs_sync()
 publish("choice" if not frame.choices.is_empty() else "done")
func publish(phase: String) -> void:
 var data := {"phase":phase,"choices":runtime.frame().choices.size() if runtime else 0,"restored":restored,"text":body.text,"rate":content.section("time").minutes_per_second}
 if OS.has_feature("web"):
  JavaScriptBridge.eval("window.inkStatus="+JSON.stringify(data))
func _exit_tree() -> void:
 if runtime: runtime.close()
