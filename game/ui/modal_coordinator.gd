class_name ModalCoordinator
extends RefCounted
## One blocking sheet; domain state stays in services. Visibility is reconciled centrally.
var _entries: Dictionary={}
var _active: String=""
func register(id: String, panel: Control, close: Callable = Callable()) -> void:
 _entries[id]={"panel":panel,"close":close}
 panel.visibility_changed.connect(func():
  if panel.visible:activate(id)
  elif _active==id:_active="")
func activate(id: String) -> void:
 if not _entries.has(id):return
 if _active==id:return
 var previous := _active
 _active=id
 if previous!="" and _entries.has(previous):_close(previous)
 for key in _entries:
  if key!=id and _entries[key].panel.visible:_close(str(key))
func _close(id: String) -> void:
 var entry: Dictionary=_entries[id]
 if entry.close.is_valid():entry.close.call()
 else:entry.panel.hide()
func close_active() -> void:
 var id := _active
 _active=""
 if id!="" and _entries.has(id):_close(id)
func blocking() -> bool:
 return _active!="" and _entries.has(_active) and _entries[_active].panel.visible
func active_id() -> String:return _active
