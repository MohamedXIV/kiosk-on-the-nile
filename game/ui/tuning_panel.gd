class_name TuningPanel
extends PanelContainer
var _session: GameSession
var _editor := TextEdit.new()
var _feedback := Label.new()
var _upload: JavaScriptObject
var _feedback_key: String=""
func configure(session: GameSession) -> void:
 _session=session
 session.tuning.rejected.connect(func():_set_feedback("tuning.rejected"))
 anchor_left=0.08;anchor_right=0.92;anchor_top=0.13;anchor_bottom=0.9
 var column := VBoxContainer.new()
 add_child(SheetControls.scroll(column))
 column.add_child(_label("tuning.title"))
 var units := PackedStringArray()
 for key in session.config.section("tuning").fields:
  var field: Dictionary=session.config.section("tuning").fields[key]
  units.append("%s: %s [%s..%s]" % [key,field.unit,field.minimum,field.maximum])
 var help := _label("tuning.help")
 help.tooltip_text="\n".join(units)
 column.add_child(help)
 _editor.size_flags_vertical=Control.SIZE_EXPAND_FILL
 _editor.custom_minimum_size.y=140
 _editor.text_direction=Control.TEXT_DIRECTION_LTR
 column.add_child(_editor)
 var buttons := HFlowContainer.new()
 column.add_child(buttons)
 buttons.add_child(_button("tuning.apply",func():_apply_text()))
 buttons.add_child(_button("tuning.default",func():_editor.text="{}";_apply_text()))
 buttons.add_child(_button("tuning.export",_export))
 buttons.add_child(_button("tuning.import",_import))
 _feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 column.add_child(_feedback)
 column.add_child(_button("tuning.close",hide))
 if LocaleService.current:LocaleService.current.changed.connect(_refresh_language)
 hide()
func open() -> void:
 get_parent().move_child(self,get_parent().get_child_count()-1)
 _editor.text=JSON.stringify(_session.tuning.snapshot(),"  ")
 _set_feedback("tuning.open")
 show()
func _apply_text() -> void:
 var parser := JSON.new()
 var error := parser.parse(_editor.text)
 var parsed: Variant=parser.data
 if error!=OK or not parsed is Dictionary:_set_feedback("tuning.invalid");return
 var result := _session.tuning.propose(parsed)
 _set_feedback("tuning.accepted" if result.ok else "tuning.denied")
func _export() -> void:
 if OS.has_feature("web"):JavaScriptBridge.download_buffer(_editor.text.to_utf8_buffer(),"kiosk-tuning.json","application/json")
 else:
  var file := FileAccess.open("user://kiosk-tuning-export.json",FileAccess.WRITE)
  if file:file.store_string(_editor.text)
func _import() -> void:
 if not OS.has_feature("web"):_set_feedback("tuning.paste");return
 _upload=JavaScriptBridge.create_callback(func(args):
  if not args.is_empty():_editor.text=str(args[0]);_set_feedback("tuning.loaded"))
 var window := JavaScriptBridge.get_interface("window")
 window.kioskTuningImport=_upload
 JavaScriptBridge.eval("(()=>{const input=document.createElement('input');input.type='file';input.accept='.json,application/json';input.onchange=()=>{const file=input.files[0];if(!file)return;const reader=new FileReader();reader.onload=()=>window.kioskTuningImport(String(reader.result));reader.readAsText(file)};input.click()})()")

func _label(id: String) -> Label:
 var control := SheetControls.label(UiText.localized(id));UiText.bind_control(control,id)
 return control
func _button(id: String, action: Callable) -> Button:
 var control := SheetControls.button(UiText.localized(id),action);UiText.bind_control(control,id)
 return control
func _set_feedback(id: String) -> void:
 _feedback_key=id;_feedback.text=UiText.localized(id)
func _refresh_language() -> void:
 UiText.refresh_tree(self)
 _editor.text_direction=Control.TEXT_DIRECTION_LTR
 if not _feedback_key.is_empty():_feedback.text=UiText.localized(_feedback_key)
