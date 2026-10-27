class_name TuningStore
extends RefCounted
signal applied
signal rejected
var _spec: Dictionary
var _actors: Array
var _values: Dictionary={}
var _names: Dictionary={}
var _pending: Dictionary={}
func configure(spec: Dictionary, actors: Array) -> ActionResult:
 _spec=spec.duplicate(true)
 _actors=actors.duplicate()
 for key in _spec.fields:_values[key]=_spec.fields[key].default
 return propose({})
func value(key: String) -> float:
 return float(_values[key])
func display_name(id: String, fallback: String) -> String:
 return str(_names.get(id,fallback))
func propose(overrides: Dictionary) -> ActionResult:
 var result := _candidate(overrides)
 if result.ok:_pending=result.details.state
 return result
func _candidate(data: Dictionary) -> ActionResult:
 for key in data:
  if key not in ["values","names"]:return _fail()
 if not data.get("values",{}) is Dictionary or not data.get("names",{}) is Dictionary:return _fail()
 var values: Dictionary={}
 for key in _spec.fields:values[key]=_spec.fields[key].default
 for key in data.get("values",{}):
  if not _spec.fields.has(key):return _fail()
  var field: Dictionary=_spec.fields[key]
  if not ContentValidation.bounded(data.values[key],field.minimum,field.maximum):return _fail()
  values[key]=data.values[key]
 if not TuningValidation.values_valid(values):return _fail()
 var names: Dictionary=data.get("names",{}).duplicate()
 for id in names:
  if not id in _actors or not names[id] is String or names[id].strip_edges().is_empty() or names[id].length()>80:return _fail()
 return ActionResult.success({"state":{"values":values,"names":names}})
func apply_at_boundary(persist: bool = true) -> ActionResult:
 if _pending.is_empty():return ActionResult.success()
 if persist:
  var file := FileAccess.open("user://tuning.pending.json",FileAccess.WRITE)
  if file==null:return _io_failure()
  file.store_string(JSON.stringify(_pending,"  "))
  file.flush()
  var error := file.get_error()
  file.close()
  if error!=OK or DirAccess.rename_absolute("user://tuning.pending.json","user://tuning.json")!=OK:return _io_failure()
 _values=_pending.values.duplicate()
 _names=_pending.names.duplicate()
 _pending={}
 applied.emit()
 return ActionResult.success()
func load_local() -> ActionResult:
 if not FileAccess.file_exists("user://tuning.json"):return ActionResult.success()
 var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string("user://tuning.json"))
 if not parsed is Dictionary:return _fail()
 return propose(parsed)
func ready() -> bool:
 return _pending.is_empty()
func snapshot() -> Dictionary:
 return {"values":_values.duplicate(),"names":_names.duplicate()}
func restore(data: Dictionary) -> ActionResult:
 var result := _candidate(data)
 if not result.ok:return result
 _pending=result.details.state
 return apply_at_boundary(false)
func _fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_tuning")

func _io_failure() -> ActionResult:
 _pending={}
 rejected.emit()
 return ActionResult.failure(ActionResult.Code.IO_ERROR,&"invalid_tuning")
