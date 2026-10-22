class_name SaveCodec
extends Node
const SCHEMA_VERSION := 1
const COMPONENTS := ["clock","wallet","needs","home","knowledge","relationships","effects","cooking","service","visitors","scheduler"]
func encode(session: GameSession) -> Dictionary:
 var state: Dictionary = {}
 for id in COMPONENTS: state[id] = session.get(id).snapshot()
 state["narrative"] = session.narrative.snapshot()
 state["player_pose"] = session.player_pose.snapshot()
 state["kiosk_open"] = session.kiosk_open
 var envelope := {"schema_version":SCHEMA_VERSION,"content_fingerprint":session.config.fingerprint,"state":state}
 envelope["checksum"] = JSON.stringify(envelope,"",true).sha256_text()
 return envelope
func validate(data: Dictionary, _config: SessionConfig) -> ActionResult:
 if not valid_digest(data): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"corrupt_save")
 if data.get("schema_version")!=SCHEMA_VERSION or not data.get("content_fingerprint") is String or not data.get("state") is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_save_envelope")
 for id in COMPONENTS+["narrative","player_pose"]:
  if not data.state.get(id) is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"missing_saved_component",{"component":id})
 if not data.state.get("kiosk_open") is bool: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_kiosk_state")
 return ActionResult.success()
func create_candidate(data: Dictionary, config: SessionConfig) -> ActionResult:
 var result := validate(data,config)
 if not result.ok: return result
 var candidate := GameSession.new()
 add_child(candidate)
 result = candidate.configure(config)
 if not result.ok:
  candidate.queue_free()
  return result
 for id in COMPONENTS:
  result = candidate.get(id).restore(data.state[id])
  if not result.ok:
   candidate.queue_free()
   return ActionResult.failure(ActionResult.Code.INVALID_SAVE,result.message_key,{"component":id})
 result = candidate.player_pose.restore(data.state.player_pose)
 if not result.ok or not config.section("locations").has(str(candidate.location_id)):
  candidate.queue_free()
  return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_player_pose")
 var location: Dictionary = config.section("locations")[str(candidate.location_id)]
 var bounds: Array = location.player_bounds
 var ground := candidate.player_ground
 if ground.x<float(bounds[0]) or ground.x>float(bounds[2]) or ground.y<float(bounds[1]) or ground.y>float(bounds[3]) or FootprintGeometry.blocked(ground,location.solids,0):
  candidate.queue_free()
  return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_player_position")
 candidate.kiosk_open = data.state.kiosk_open
 for order in candidate.service.snapshot().orders.values():
  if order.status=="pending" and not candidate.visitors.is_available(StringName(order.visit_id)):
   candidate.queue_free()
   return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"orphan_pending_order")
 for visit in candidate.visitors.visits.values():
  if not visit.order_id.is_empty():
   var order := candidate.service.order(visit.order_id)
   if order==null or order.visit_id!=visit.id:
    candidate.queue_free()
    return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_visit_order")
 result = await candidate.narrative.restore(data.state.narrative)
 if not result.ok:
  candidate.queue_free()
  return result
 return ActionResult.success({"session":candidate})

static func valid_digest(data: Dictionary) -> bool:
 var candidate := data.duplicate(true)
 var checksum: Variant = candidate.get("checksum")
 candidate.erase("checksum")
 return checksum is String and checksum==JSON.stringify(candidate,"",true).sha256_text()
