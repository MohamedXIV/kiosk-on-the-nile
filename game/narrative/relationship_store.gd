class_name RelationshipStore
extends RefCounted
## Directional, hidden social state. No presentation or progression rules here.
var _defaults: Dictionary
var _bounds: Array
var _actors: Array
var _values: Dictionary = {}
var _semantic_gains: Dictionary = {}
var revision: int = 0
func fork() -> RelationshipStore:
 var result:=RelationshipStore.new({"relationship_defaults":_defaults,"relationship_bounds":_bounds},_actors)
 result._values=_values.duplicate(true);result._semantic_gains=_semantic_gains.duplicate(true);result.revision=revision
 return result
func _init(social: Dictionary, actor_ids: Array) -> void:
 _defaults = social.relationship_defaults.duplicate(true)
 _bounds = social.relationship_bounds.duplicate()
 _actors = actor_ids.duplicate()
func value(from: StringName, to: StringName, axis: StringName) -> float:
 return float(_values.get(str(from),{}).get(str(to),{}).get(str(axis),_defaults.get(str(axis),0)))
func can_adjust(from: StringName, to: StringName, axis: StringName, amount: float) -> bool:
 return str(from) in _actors and str(to) in _actors and _defaults.has(str(axis)) and is_finite(amount)
func adjust(from: StringName, to: StringName, axis: StringName, amount: float) -> ActionResult:
 if not can_adjust(from,to,axis,amount): return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_relationship")
 if not _values.has(str(from)): _values[str(from)] = {}
 if not _values[str(from)].has(str(to)): _values[str(from)][str(to)] = {}
 _values[str(from)][str(to)][str(axis)] = clampf(value(from,to,axis)+amount,float(_bounds[0]),float(_bounds[1]))
 revision+=1
 return ActionResult.success()
func snapshot() -> Dictionary:
 var result: Dictionary={"values":_values.duplicate(true)}
 if not _semantic_gains.is_empty():result["semantic_gains"]=_semantic_gains.duplicate(true)
 return result
func restore(data: Dictionary) -> ActionResult:
 if not data.get("values") is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_relationships")
 for from in data.values:
  if not from in _actors or not data.values[from] is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"unknown_actor")
  for to in data.values[from]:
   if not to in _actors or not data.values[from][to] is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"unknown_actor")
   for axis in data.values[from][to]:
    if not _defaults.has(axis) or not ContentValidation.bounded(data.values[from][to][axis],_bounds[0],_bounds[1]): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_relationship")
 var gains: Variant=data.get("semantic_gains",{})
 if not gains is Dictionary:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_semantic_relationships")
 for id in gains:
  if not _valid_gain(gains[id]) or gains[id].id!=id:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_semantic_relationships")
 _values = data.values.duplicate(true);_semantic_gains=gains.duplicate(true);revision+=1
 return ActionResult.success()

func threshold_valid(axis: StringName, threshold: Variant) -> bool:
 return _defaults.has(str(axis)) and ContentValidation.bounded(threshold,_bounds[0],_bounds[1])
func semantic_gain(id: String) -> Dictionary:return _semantic_gains.get(id,{}).duplicate(true)
func semantic_gain_ids() -> Array:return _semantic_gains.keys()
func _valid_gain(gain: Variant) -> bool:
 return NarrativePolicyValidation.fields(gain,["id","source","from","to","axis","amount"]) and gain.id is String and gain.source is String and gain.from is String and gain.to is String and gain.axis is String and ContentValidation.bounded(gain.amount,-10,10) and can_adjust(StringName(gain.from),StringName(gain.to),StringName(gain.axis),float(gain.amount))
func prepare_gains(gains: Array) -> ActionResult:
 var candidate:=fork()
 for gain in gains:
  if not _valid_gain(gain):return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_semantic_relationships")
  if candidate._semantic_gains.has(gain.id):
   if candidate._semantic_gains[gain.id]!=gain:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_semantic_relationships")
   continue
  candidate.adjust(StringName(gain.from),StringName(gain.to),StringName(gain.axis),float(gain.amount));candidate._semantic_gains[gain.id]=gain.duplicate(true)
 return ActionResult.success({"revision":revision,"state":candidate.snapshot()})
func can_commit(ticket: Dictionary) -> ActionResult:
 if ticket.get("revision")!=revision or not ticket.get("state") is Dictionary or not ticket.state.get("semantic_gains",{}) is Dictionary:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"stale_relationship_transaction")
 for id in _semantic_gains:
  if ticket.state.get("semantic_gains",{}).get(id)!=_semantic_gains[id]:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_semantic_relationships")
 return fork().restore(ticket.state)
func publish(ticket: Dictionary) -> void:
 _values=ticket.state.values.duplicate(true);_semantic_gains=ticket.state.get("semantic_gains",{}).duplicate(true);revision+=1
