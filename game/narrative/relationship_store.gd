class_name RelationshipStore
extends RefCounted
## Directional, hidden social state. No presentation or progression rules here.
var _defaults: Dictionary
var _bounds: Array
var _actors: Array
var _values: Dictionary = {}
func _init(social: Dictionary, actor_ids: Array) -> void:
 _defaults = social.relationship_defaults.duplicate(true)
 _bounds = social.relationship_bounds.duplicate()
 _actors = actor_ids.duplicate()
func value(from: StringName, to: StringName, axis: StringName) -> float:
 return float(_values.get(str(from),{}).get(str(to),{}).get(str(axis),_defaults.get(str(axis),0)))
func adjust(from: StringName, to: StringName, axis: StringName, amount: float) -> ActionResult:
 if not str(from) in _actors or not str(to) in _actors or not _defaults.has(str(axis)) or not is_finite(amount): return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_relationship")
 if not _values.has(str(from)): _values[str(from)] = {}
 if not _values[str(from)].has(str(to)): _values[str(from)][str(to)] = {}
 _values[str(from)][str(to)][str(axis)] = clampf(value(from,to,axis)+amount,float(_bounds[0]),float(_bounds[1]))
 return ActionResult.success()
func snapshot() -> Dictionary:
 return {"values":_values.duplicate(true)}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("values") is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_relationships")
 for from in data.values:
  if not from in _actors or not data.values[from] is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"unknown_actor")
  for to in data.values[from]:
   if not to in _actors or not data.values[from][to] is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"unknown_actor")
   for axis in data.values[from][to]:
    if not _defaults.has(axis) or not ContentValidation.bounded(data.values[from][to][axis],_bounds[0],_bounds[1]): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_relationship")
 _values = data.values.duplicate(true)
 return ActionResult.success()

func threshold_valid(axis: StringName, threshold: Variant) -> bool:
 return _defaults.has(str(axis)) and ContentValidation.bounded(threshold,_bounds[0],_bounds[1])
