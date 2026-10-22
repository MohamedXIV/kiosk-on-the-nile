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
  var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(root.path_join(name))) if FileAccess.file_exists(root.path_join(name)) else null
  if data is Dictionary: return ActionResult.success({"data":data,"backup":name=="previous.json"})
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"save_unreadable")
func read_previous() -> ActionResult:
 var path := root.path_join("previous.json")
 if not FileAccess.file_exists(path): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"save_unreadable")
 var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
 return ActionResult.success({"data":data,"backup":true}) if data is Dictionary else ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"save_unreadable")
func write(data: Dictionary) -> ActionResult:
 if OS.has_feature("web") and not OS.is_userfs_persistent(): return ActionResult.failure(ActionResult.Code.IO_ERROR,&"storage_unavailable")
 var absolute := ProjectSettings.globalize_path(root)
 if DirAccess.make_dir_recursive_absolute(absolute)!=OK: return ActionResult.failure(ActionResult.Code.IO_ERROR,&"save_write_failed")
 var temporary := absolute.path_join("session.tmp")
 var primary := absolute.path_join("session.json")
 var previous := absolute.path_join("previous.json")
 var serialized := JSON.stringify(data,"",true)
 var file := FileAccess.open(temporary,FileAccess.WRITE)
 if file==null: return ActionResult.failure(ActionResult.Code.IO_ERROR,&"save_write_failed")
 file.store_string(serialized)
 file.flush()
 var error := file.get_error()
 file.close()
 if error!=OK or FileAccess.get_file_as_string(temporary)!=serialized: return ActionResult.failure(ActionResult.Code.IO_ERROR,&"save_write_failed")
 var existing: Variant = JSON.parse_string(FileAccess.get_file_as_string(primary)) if FileAccess.file_exists(primary) else null
 if not protect_previous and existing is Dictionary and SaveCodec.valid_digest(existing):
  # Keep the previous file intact until the replacement backup is complete.
  var backup_temp := absolute.path_join("previous.tmp")
  if DirAccess.copy_absolute(primary,backup_temp)!=OK or DirAccess.rename_absolute(backup_temp,previous)!=OK: return ActionResult.failure(ActionResult.Code.IO_ERROR,&"save_backup_failed")
 if DirAccess.rename_absolute(temporary,primary)!=OK: return ActionResult.failure(ActionResult.Code.IO_ERROR,&"save_write_failed")
 protect_previous = false
 if OS.has_feature("web"): JavaScriptBridge.force_fs_sync()
 return ActionResult.success({"sync_requested":OS.has_feature("web")})
