class_name ContentStore
extends Node
## Plain external JSON is validated before replacing the active immutable bundle.
var _sections: Dictionary = {}
var fingerprint: String = ""
var source_root: String = "res://content"
func section(id: String) -> Dictionary:
 return _sections.get(id, {}).duplicate(true)
func bundle() -> Dictionary:
 return _sections.duplicate(true)
func load_directory(directory: String) -> ActionResult:
 var manifest: Variant = _read_json(directory.path_join("manifest.json"))
 if not _valid_manifest(manifest):
  return ActionResult.failure(ActionResult.Code.INVALID_CONTENT, &"invalid_manifest")
 var candidate: Dictionary = {}
 for key in manifest.sections:
  var relative: String = manifest.sections[key]
  if not _safe_path(relative): return ActionResult.failure(ActionResult.Code.INVALID_CONTENT, &"invalid_content_path")
  var value: Variant = _read_json(directory.path_join(relative))
  if not value is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_CONTENT, &"invalid_section", {"section":key})
  candidate[key] = value
 var outcome := validate(candidate)
 if not outcome.ok: return outcome
 _sections = candidate
 fingerprint = JSON.stringify(candidate, "", true).sha256_text()
 source_root = directory
 return ActionResult.success()
func load_http(base_url: String) -> ActionResult:
 var manifest: Variant = await _fetch_json(base_url.path_join("manifest.json"))
 if not _valid_manifest(manifest): return ActionResult.failure(ActionResult.Code.INVALID_CONTENT, &"invalid_manifest")
 var candidate: Dictionary = {}
 for key in manifest.sections:
  var relative: String = manifest.sections[key]
  if not _safe_path(relative): return ActionResult.failure(ActionResult.Code.INVALID_CONTENT, &"invalid_content_path")
  var value: Variant = await _fetch_json(base_url.path_join(relative))
  if not value is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_CONTENT, &"invalid_section")
  candidate[key] = value
 var outcome := validate(candidate)
 if not outcome.ok: return outcome
 _sections = candidate
 fingerprint = JSON.stringify(candidate, "", true).sha256_text()
 source_root = base_url
 return ActionResult.success()
func validate(candidate: Dictionary) -> ActionResult:
 return ContentValidation.validate(candidate)
func _valid_manifest(value: Variant) -> bool:
 return value is Dictionary and value.get("schema_version") == 1 and value.get("sections") is Dictionary and value.sections.has("time")
func _safe_path(path: String) -> bool:
 return not path.is_absolute_path() and not ":" in path and not ".." in path.split("/")
func _read_json(path: String) -> Variant:
 if not FileAccess.file_exists(path): return null
 return JSON.parse_string(FileAccess.get_file_as_string(path))
func _fetch_json(url: String) -> Variant:
 var request := HTTPRequest.new()
 add_child(request)
 if request.request(url) != OK:
  request.queue_free()
  return null
 var response: Array = await request.request_completed
 request.queue_free()
 if response[1] != 200: return null
 return JSON.parse_string(response[3].get_string_from_utf8())
