class_name StableJson
extends RefCounted
## JSON parsing changes integers into floats. Hash the same numeric value alike.
static func stringify(value: Variant) -> String:
 return JSON.stringify(_normalize(value),"",true,true)
static func _normalize(value: Variant) -> Variant:
 if value is Dictionary:
  var result: Dictionary = {}
  for key in value: result[key]=_normalize(value[key])
  return result
 if value is Array:
  var result: Array = []
  for item in value: result.append(_normalize(item))
  return result
 if typeof(value)==TYPE_FLOAT and ContentValidation.integer(value): return int(value)
 return value
