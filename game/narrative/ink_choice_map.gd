class_name InkChoiceMap
extends RefCounted
## Resolve compiled relative choice targets in their owning container.
var choices: Dictionary={}
var valid: bool=true
static func compile(raw: Dictionary) -> ActionResult:
 var scanner:=InkChoiceMap.new()
 scanner._scan(raw.get("root"),[],0)
 return ActionResult.success({"choices":scanner.choices}) if scanner.valid else ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_policy_choice_map")
func _target(container: Array, raw: String) -> String:
 if not raw.begins_with("."):return raw
 var parts: Array=Array(raw.trim_prefix(".").split("."));var path:=container.duplicate()
 if parts.is_empty() or parts.pop_front()!="^":valid=false;return ""
 for part in parts:
  if part=="^":
   if path.is_empty():valid=false;return ""
   path.pop_back()
  elif str(part).is_empty():valid=false;return ""
  else:path.append(part)
 return ".".join(path)
func _scan(value: Variant, path: Array, depth: int) -> void:
 if depth>128 or not value is Array:valid=false;return
 var pending: String=""
 for i in range(value.size()):
  var part: Variant=value[i]
  if part is String and part.begins_with("^policy_choice:"):
   var id: String=part.trim_prefix("^policy_choice:").strip_edges()
   if not pending.is_empty() or not id.is_valid_identifier():valid=false
   pending=id
  elif part is Dictionary and part.has("*") and not pending.is_empty():
   if not part["*"] is String:valid=false;continue
   var target:=_target(path,part["*"])
   if target.is_empty() or (choices.has(target) and choices[target]!=pending):valid=false
   else:choices[target]=pending
   pending=""
  if part is Array:_scan(part,path+[str(i)],depth+1)
  elif part is Dictionary and i==value.size()-1:
   for key in part:
    if part[key] is Array:_scan(part[key],path+[str(key)],depth+1)
 if not pending.is_empty():valid=false
