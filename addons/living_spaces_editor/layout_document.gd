@tool
class_name LayoutDocument
extends RefCounted
var bundle: Dictionary = {}
var root: String
func load_bundle(directory: String) -> ActionResult:
 var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("manifest.json")))
 if not manifest is Dictionary or not manifest.get("sections") is Dictionary: return _fail("invalid_manifest")
 var candidate: Dictionary = {}
 for id in ["items","containers","spaces","initial_layout"]:
  if not manifest.sections.get(id) is String: return _fail("missing_section")
  var relative: String = manifest.sections[id]
  if relative.is_absolute_path() or ".." in relative.split("/") or ":" in relative: return _fail("invalid_content_path")
  var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join(relative)))
  if not value is Dictionary: return _fail("invalid_section")
  candidate[id]=value
 var result := _validate(candidate)
 if not result.ok: return result
 bundle = candidate
 root = directory
 return ActionResult.success()
func apply_structure(edit: Dictionary) -> ActionResult:
 if bundle.is_empty(): return _fail("no_document")
 var location_id := str(edit.get("location_id",""))
 var kind := str(edit.get("kind",""))
 if not bundle.spaces.locations.has(location_id) or not kind in ["walls","doors","rooms","buildings"]: return _fail("invalid_structure_edit")
 var value: Variant = edit.get("value")
 if not value is Dictionary or not value.get("id") is String: return _fail("invalid_structure_edit")
 var candidate := bundle.duplicate(true)
 var entries: Array = candidate.spaces.locations[location_id][kind]
 for i in range(entries.size()-1,-1,-1):
  if entries[i].id==value.id: entries.remove_at(i)
 if not edit.get("remove",false): entries.append(value.duplicate(true))
 # Authoring may be incomplete between edits. Export validates connectivity and placement.
 var result := SpaceContentValidation.validate(candidate)
 if not result.ok: return result
 bundle = candidate
 return ActionResult.success()
func replace_bundle(data: Dictionary) -> void:
 bundle = data.duplicate(true)
func export_bundle(destination: String) -> ActionResult:
 var result := _validate(bundle)
 if not result.ok: return result
 var paths := ["spaces.json","initial_layout.json"]
 var sections := ["spaces","initial_layout"]
 var originals: Dictionary = {}
 for i in range(paths.size()):
  var path: String = destination.path_join(paths[i])
  if not FileAccess.file_exists(path): return _fail("missing_export_target")
  originals[path]=FileAccess.get_file_as_string(path)
  var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
  if file==null: return _fail("export_not_writable")
  file.store_string(JSON.stringify(bundle[sections[i]],"  ",true)+"\n")
  file.close()
 for name in paths:
  var path: String = destination.path_join(name)
  if DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))!=OK:
   for original in originals:
    var file := FileAccess.open(original,FileAccess.WRITE)
    if file!=null: file.store_string(originals[original]);file.close()
   return _fail("export_failed")
 return ActionResult.success()
func validate_placement(request: PlacementRequest) -> ActionResult:
 var instances: Dictionary = {}
 for instance in bundle.initial_layout.instances: instances[instance.id]=instance
 return GridPlacementRules.validate({"placements":bundle.initial_layout.placements,"door_states":bundle.initial_layout.door_states,"instances":instances},request,{"items":bundle.items,"spaces":bundle.spaces.locations,"base_solids":bundle.spaces.base_solids},[],true)
func _validate(candidate: Dictionary) -> ActionResult:
 var result := SpaceContentValidation.validate(candidate)
 if not result.ok: return result
 var instances: Dictionary = {}
 for instance in candidate.initial_layout.instances: instances[instance.id]=instance
 for record in candidate.initial_layout.placements.values():
  result = GridPlacementRules.validate({"placements":candidate.initial_layout.placements,"door_states":candidate.initial_layout.door_states,"instances":instances},PlacementRequest.from_dict(record),{"items":candidate.items,"spaces":candidate.spaces.locations,"base_solids":candidate.spaces.base_solids},[],true)
  if not result.ok: return result
 return ActionResult.success()
func _fail(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,StringName(key))
