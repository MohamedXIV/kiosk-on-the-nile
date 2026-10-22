class_name SaveStore
extends RefCounted
var root: String
var protect_previous: bool = false
func _init(directory: String = "user://saves") -> void:
 root = directory
func has_save() -> bool:
 return FileAccess.file_exists(root.path_join("session.json")) or FileAccess.file_exists(root.path_join("previous.json"))
func read() -> ActionResult:
 for name in ["session.json","previous.json"]:
  var result := _read_path(root.path_join(name))
  if result.ok:
   result.details["backup"] = name=="previous.json"
   return result
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"save_unreadable")
func read_previous() -> ActionResult:
 var result := _read_path(root.path_join("previous.json"))
 if result.ok: result.details["backup"]=true
 return result
func _read_path(path: String) -> ActionResult:
 if not FileAccess.file_exists(path): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"save_unreadable")
 return SaveCodec.decode_text(FileAccess.get_file_as_string(path))
func write(data: Dictionary) -> ActionResult:
 if OS.has_feature("web") and not OS.is_userfs_persistent(): return ActionResult.failure(ActionResult.Code.IO_ERROR,&"storage_unavailable")
 var absolute := ProjectSettings.globalize_path(root)
 if DirAccess.make_dir_recursive_absolute(absolute)!=OK: return ActionResult.failure(ActionResult.Code.IO_ERROR,&"save_write_failed")
 var temporary := absolute.path_join("session.tmp")
 var primary := absolute.path_join("session.json")
 var previous := absolute.path_join("previous.json")
 var serialized := StableJson.stringify(data)
 var file := FileAccess.open(temporary,FileAccess.WRITE)
 if file==null: return ActionResult.failure(ActionResult.Code.IO_ERROR,&"save_write_failed")
 file.store_string(serialized)
 file.flush()
 var error := file.get_error()
 file.close()
 if error!=OK or FileAccess.get_file_as_string(temporary)!=serialized: return ActionResult.failure(ActionResult.Code.IO_ERROR,&"save_write_failed")
 var existing := _read_path(primary)
 if not protect_previous and existing.ok:
  # Keep the previous file intact until the replacement backup is complete.
  var backup_temp := absolute.path_join("previous.tmp")
  if DirAccess.copy_absolute(primary,backup_temp)!=OK or DirAccess.rename_absolute(backup_temp,previous)!=OK: return ActionResult.failure(ActionResult.Code.IO_ERROR,&"save_backup_failed")
 if DirAccess.rename_absolute(temporary,primary)!=OK: return ActionResult.failure(ActionResult.Code.IO_ERROR,&"save_write_failed")
 protect_previous = false
 if OS.has_feature("web"): JavaScriptBridge.force_fs_sync()
 return ActionResult.success({"sync_requested":OS.has_feature("web")})
