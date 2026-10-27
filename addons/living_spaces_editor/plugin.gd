@tool
extends EditorPlugin
var _document := LayoutDocument.new()
var _dock: VBoxContainer
func _enter_tree() -> void:
 _dock = preload("layout_dock.gd").new()
 _dock.name="Living Spaces"
 _dock.document=_document
 add_control_to_dock(DOCK_SLOT_RIGHT_UL,_dock)
 _dock.reload_requested.connect(_reload)
 _dock.export_requested.connect(func():_dock.show_result(_document.export_bundle(_document.root)))
 _dock.edit_requested.connect(_apply)
 _reload()
func _exit_tree() -> void:
 remove_control_from_docks(_dock)
 _dock.queue_free()
func _reload() -> void:
 var result := _document.load_bundle("res://content")
 _dock.show_result(result)
 _dock.refresh()
func _apply(edit: Dictionary) -> void:
 var before := _document.bundle.duplicate(true)
 var result := _document.apply_structure(edit)
 if not result.ok:
  _dock.show_result(result)
  return
 var after := _document.bundle.duplicate(true)
 _document.replace_bundle(before)
 var undo := get_undo_redo()
 undo.create_action("Edit living-space structure",UndoRedo.MERGE_DISABLE,_dock)
 undo.add_do_method(_document,"replace_bundle",after)
 undo.add_undo_method(_document,"replace_bundle",before)
 undo.add_do_method(_dock,"refresh")
 undo.add_undo_method(_dock,"refresh")
 undo.commit_action()
 _dock.show_result(result)
