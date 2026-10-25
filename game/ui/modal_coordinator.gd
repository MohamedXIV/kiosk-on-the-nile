class_name ModalCoordinator
extends RefCounted
## One blocking sheet and a weak return-focus target; no domain state is duplicated.
var _entries: Dictionary={}
var _active: String=""
func register(id: String, panel: Control, close: Callable = Callable()) -> void:
 _entries[id]={"panel":panel,"close":close,"return_focus":null}
 panel.focus_mode=Control.FOCUS_ALL
 panel.visibility_changed.connect(func():
  if panel.visible:activate(id)
  elif _active==id:
   _active=""
   _restore_focus(id))
func activate(id: String) -> void:
 if not _entries.has(id) or _active==id:return
 var entry: Dictionary=_entries[id]
 var owner: Control=entry.panel.get_viewport().gui_get_focus_owner()
 var previous := _active
 if previous!="" and _entries.has(previous) and owner!=null and (_entries[previous].panel==owner or _entries[previous].panel.is_ancestor_of(owner)):
  var saved: Variant=_entries[previous].return_focus
  owner=saved.get_ref() if saved is WeakRef else null
 entry.return_focus=weakref(owner) if owner!=null else null
 _active=id
 if previous!="" and _entries.has(previous):_close(previous)
 for key in _entries:
  if key!=id and _entries[key].panel.visible:_close(str(key))
 entry.panel.call_deferred("grab_focus")
func _close(id: String) -> void:
 var entry: Dictionary=_entries[id]
 if entry.close.is_valid():entry.close.call()
 else:entry.panel.hide()
func _restore_focus(id: String) -> void:
 var saved: Variant=_entries[id].return_focus
 var target: Control=saved.get_ref() if saved is WeakRef else null
 if is_instance_valid(target) and target.is_visible_in_tree():target.grab_focus()
func close_active() -> void:
 if _active!="" and _entries.has(_active):_close(_active)
func blocking() -> bool:
 return _active!="" and _entries.has(_active) and _entries[_active].panel.visible
func active_id() -> String:return _active
