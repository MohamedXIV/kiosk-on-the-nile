class_name LocaleService
extends RefCounted
signal changed
static var current: LocaleService
var locale: String="ar_EG"
var revision: int=0
var _catalogs: Dictionary={}
var _translations: Array[Translation]=[]
const SETTINGS := "user://language.cfg"
func configure(bundle: Dictionary) -> ActionResult:
 var valid := validate_bundle(bundle)
 if not valid.ok:return valid
 for translation in _translations:TranslationServer.remove_translation(translation)
 _translations.clear();_catalogs.clear()
 for id in ["locale_ar","locale_en"]:
  var d: Dictionary=bundle[id]
  _catalogs[str(d.locale)]=d.messages.duplicate(true)
  var translation := Translation.new();translation.set_locale(str(d.locale))
  for key in d.messages:translation.add_message(StringName(key),StringName(d.messages[key]))
  TranslationServer.add_translation(translation);_translations.append(translation)
 current=self
 var settings := ConfigFile.new()
 if settings.load(SETTINGS)==OK:
  var saved := str(settings.get_value("display","locale","ar_EG"))
  if _catalogs.has(saved):locale=saved
 TranslationServer.set_locale(locale)
 return ActionResult.success()
func set_locale(value: String) -> ActionResult:
 if not _catalogs.has(value):return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"unsupported_locale")
 if locale==value:return ActionResult.success()
 locale=value;revision+=1;TranslationServer.set_locale(locale)
 var settings := ConfigFile.new();settings.set_value("display","locale",locale);settings.save(SETTINGS)
 if OS.has_feature("web"):JavaScriptBridge.force_fs_sync()
 changed.emit()
 return ActionResult.success()
func text(id: String, args: Dictionary = {}, fallback: String = "") -> String:
 return _resolve(id,args,fallback,0)
func _resolve(id: String, args: Dictionary, fallback: String, depth: int) -> String:
 if depth>8:return fallback
 var value := str(_catalogs.get(locale,{}).get(id,_catalogs.get("ar_EG",{}).get(id,fallback)))
 if value=="":return fallback
 var parameters := args.duplicate(true)
 for key in parameters:
  var parameter: Variant=parameters[key]
  if parameter is Dictionary and parameter.get("text_ref") is String:
   var nested := str(_catalogs.get(locale,{}).get(parameter.text_ref,_catalogs.get("ar_EG",{}).get(parameter.text_ref,"")))
   if nested=="":return fallback
   parameters[key]=_resolve(str(parameter.text_ref),parameter.get("parameters",{}),nested,depth+1)
 var expression := RegEx.new();expression.compile("\\{([A-Za-z_][A-Za-z0-9_]*)\\}")
 for match_value in expression.search_all(value):
  if not parameters.has(match_value.get_string(1)):return fallback
 return value.format(parameters)
func rtl() -> bool:return locale=="ar_EG"
func source_text(id: String, source: String, args: Dictionary = {}) -> String:
 # A stable identity plus an exact source guard; custom/historic wording survives.
 var fallback := source.format(args)
 return text(id,args,fallback) if _catalogs.get("ar_EG",{}).get(id)!=null and _catalogs.ar_EG[id]==source else fallback
func source_variants(id: String, source: String) -> PackedStringArray:
 var values := PackedStringArray([source])
 if _catalogs.get("ar_EG",{}).get(id)!=source:return values
 for supported in ["ar_EG","en"]:
  var value := str(_catalogs.get(supported,{}).get(id,source))
  if not value in values:values.append(value)
 return values
func picker() -> OptionButton:
 var select := OptionButton.new()
 select.add_item("العربية");select.add_item("English")
 select.select(0 if rtl() else 1)
 select.item_selected.connect(func(index):set_locale("ar_EG" if index==0 else "en"))
 select.set_meta("locale_picker",true)
 return select
static func validate_bundle(bundle: Dictionary) -> ActionResult:
 for key in ["locale_ar","locale_en"]:
  var d: Variant=bundle.get(key)
  if not d is Dictionary or d.get("locale")!=("ar_EG" if key=="locale_ar" else "en") or d.get("direction")!=("rtl" if key=="locale_ar" else "ltr") or not d.get("messages") is Dictionary:return _fail()
  for id in d.messages:
   if not id is String or id=="" or not d.messages[id] is String or d.messages[id]=="":return _fail()
 var expression := RegEx.new();expression.compile("\\{([A-Za-z_][A-Za-z0-9_]*)\\}")
 for id in bundle.locale_en.messages:
  if not bundle.locale_ar.messages.has(id):return _fail()
  var names: Array=[];var other: Array=[]
  for m in expression.search_all(str(bundle.locale_ar.messages[id])):names.append(m.get_string(1))
  for m in expression.search_all(str(bundle.locale_en.messages[id])):other.append(m.get_string(1))
  names.sort();other.sort()
  if names!=other:return _fail()
 return ActionResult.success()
static func _fail() -> ActionResult:return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_locale_catalog")

func captured_reference(id: String, source: String) -> Variant:
 return {"text_ref":id} if _catalogs.get("ar_EG",{}).get(id)==source else source
