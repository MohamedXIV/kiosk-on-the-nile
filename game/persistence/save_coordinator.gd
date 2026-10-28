class_name SaveCoordinator
extends Node
signal completed(result: ActionResult)
signal started
var store := SaveStore.new()
var codec := SaveCodec.new()
var transition_active: bool = false
var unconfirmed: bool = false
var _pending: bool = false
var _saving: bool = false
var _feedback: Dictionary = {}
var _web_ack := WebSaveAck.new()
func _ready() -> void:
 add_child(codec)
 add_child(_web_ack)
 _web_ack.completed.connect(_durable_result)
func configure_feedback(settings: Dictionary) -> void:
 _feedback=settings.duplicate(true)
func save_at_boundary(session: GameSession) -> ActionResult:
 if OS.has_feature("web"):
  unconfirmed=true
  _web_ack.arm()
 if _saving or transition_active or (not session.narrative.is_ready() or not session.personal.is_ready() or not session.tuning.ready()):
  if not _pending and not _saving:started.emit()
  _pending = true
  return ActionResult.success({"deferred":true})
 _pending=false
 started.emit()
 var snapshot := codec.encode(session)
 var result := store.write(snapshot)
 if result.ok and OS.has_feature("web"):
  _saving=true
  _web_ack.begin(ProjectSettings.globalize_path(store.root.path_join("session.json")),StableJson.stringify(snapshot),_feedback)
  return ActionResult.success({"pending":true})
 completed.emit(result)
 return result
func _durable_result(result: ActionResult) -> void:
 _saving=false
 if result.ok and _pending:
  _web_ack.arm()
  return
 unconfirmed=not result.ok
 completed.emit(result)
func boundary(session: GameSession) -> void:
 if _pending and not _saving and not transition_active and session.narrative.is_ready() and session.personal.is_ready() and session.tuning.ready():
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
