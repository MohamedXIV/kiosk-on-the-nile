class_name TuningPanel
extends PanelContainer
var _session: GameSession
var _editor := TextEdit.new()
var _feedback := Label.new()
var _upload: JavaScriptObject
func configure(session: GameSession) -> void:
 _session=session
 session.tuning.rejected.connect(func():_feedback.text="تعذّر حفظ الإعدادات؛ القيم السابقة ما اتغيرتش.")
 anchor_left=0.08;anchor_right=0.92;anchor_top=0.13;anchor_bottom=0.9
 var column := VBoxContainer.new()
 add_child(column)
 column.add_child(UiText.label("موازنة التطوير — قيم فقط؛ الحالة الحالية لا تتصفّر"))
 var units := PackedStringArray()
 for key in session.config.section("tuning").fields:
  var field: Dictionary=session.config.section("tuning").fields[key]
  units.append("%s: %s [%s..%s]" % [key,field.unit,field.minimum,field.maximum])
 var help := UiText.label("مرّر فوق النص لرؤية الوحدات والحدود. الصق JSON أو استورد ملفًا ثم طبّق.")
 help.tooltip_text="\n".join(units)
 column.add_child(help)
 _editor.size_flags_vertical=Control.SIZE_EXPAND_FILL
 _editor.custom_minimum_size.y=140
 _editor.text_direction=Control.TEXT_DIRECTION_LTR
 column.add_child(_editor)
 var buttons := HBoxContainer.new()
 column.add_child(buttons)
 buttons.add_child(UiText.button("طبّق",func():_apply_text()))
 buttons.add_child(UiText.button("الافتراضي",func():_editor.text="{}";_apply_text()))
 buttons.add_child(UiText.button("تصدير JSON",_export))
 buttons.add_child(UiText.button("استيراد JSON",_import))
 column.add_child(_feedback)
 column.add_child(UiText.button("اقفل",hide))
 hide()
func open() -> void:
 get_parent().move_child(self,get_parent().get_child_count()-1)
 _editor.text=JSON.stringify(_session.tuning.snapshot(),"  ")
 _feedback.text="التغيير يطبّق مع خطوة المحاكاة التالية. الأسماء تحت names بمُعرّف الشخصية."
 show()
func _apply_text() -> void:
 var parser := JSON.new()
 var error := parser.parse(_editor.text)
 var parsed: Variant=parser.data
 if error!=OK or not parsed is Dictionary:_feedback.text="JSON غير صالح؛ القيم السابقة محفوظة.";return
 var result := _session.tuning.propose(parsed)
 _feedback.text="تم قبول المرشح؛ يُطبّق في خطوة المحاكاة التالية." if result.ok else "الإعدادات مرفوضة؛ القيم السابقة لم تتغير."
func _export() -> void:
 if OS.has_feature("web"):JavaScriptBridge.download_buffer(_editor.text.to_utf8_buffer(),"kiosk-tuning.json","application/json")
 else:
  var file := FileAccess.open("user://kiosk-tuning-export.json",FileAccess.WRITE)
  if file:file.store_string(_editor.text)
func _import() -> void:
 if not OS.has_feature("web"):_feedback.text="الصق محتوى ملف JSON في المحرر ثم طبّق.";return
 _upload=JavaScriptBridge.create_callback(func(args):
  if not args.is_empty():_editor.text=str(args[0]);_feedback.text="الملف مقروء؛ راجعه ثم طبّق.")
 var window := JavaScriptBridge.get_interface("window")
 window.kioskTuningImport=_upload
 JavaScriptBridge.eval("(()=>{const input=document.createElement('input');input.type='file';input.accept='.json,application/json';input.onchange=()=>{const file=input.files[0];if(!file)return;const reader=new FileReader();reader.onload=()=>window.kioskTuningImport(String(reader.result));reader.readAsText(file)};input.click()})()")
