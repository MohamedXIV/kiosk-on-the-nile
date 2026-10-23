class_name SaveCoordinator
extends Node
signal completed(result: ActionResult)
var store := SaveStore.new()
var codec := SaveCodec.new()
var transition_active: bool = false
var _pending: bool = false
func _ready() -> void:
 add_child(codec)
func save_at_boundary(session: GameSession) -> ActionResult:
 if transition_active or (not session.narrative.is_ready() or not session.tuning.ready()):
  _pending = true
  return ActionResult.success({"deferred":true})
 var result := store.write(codec.encode(session))
 completed.emit(result)
 return result
func boundary(session: GameSession) -> void:
 if _pending and not transition_active and session.narrative.is_ready() and session.tuning.ready():
  _pending = false
  save_at_boundary(session)
func load_candidate(config: SessionConfig) -> ActionResult:
 var result := store.read()
 if not result.ok: return result
 var candidate := await codec.create_candidate(result.details.data,config,get_parent())
 if candidate.ok:
  store.protect_previous = bool(result.details.get("backup",false))
  return candidate
 push_warning("Save candidate rejected: %s (%s); retaining previous save" % [candidate.message_key,candidate.details])
 store.protect_previous = true
 if not result.details.get("backup",false):
  var previous := store.read_previous()
  if previous.ok: return await codec.create_candidate(previous.details.data,config,get_parent())
 return candidate
