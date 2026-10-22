class_name SaveCodec
extends Node
const SCHEMA_VERSION := 4
const SCHEMA_REVISION := 1
const COMPONENTS := ["clock","items","spaces","routine","wallet","needs","home","knowledge","relationships","effects","cooking","service","visitors","scheduler"]
func encode(session: GameSession) -> Dictionary:
 var state: Dictionary = {}
 for id in COMPONENTS: state[id] = session.get(id).snapshot()
 state["narrative"] = session.narrative.snapshot()
 state["player_pose"] = session.player_pose.snapshot()
 state["kiosk_open"] = session.kiosk_open
 var envelope := {"schema_version":SCHEMA_VERSION,"schema_revision":SCHEMA_REVISION,"content_fingerprint":session.config.fingerprint,"state":state}
 envelope["checksum"] = StableJson.stringify(envelope).sha256_text()
 return envelope
func validate(data: Dictionary, _config: SessionConfig) -> ActionResult:
 if not valid_digest(data): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"corrupt_save")
 if data.get("schema_version")!=SCHEMA_VERSION or data.get("schema_revision")!=SCHEMA_REVISION or not data.get("content_fingerprint") is String or not data.get("state") is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_save_envelope")
 for id in COMPONENTS+["narrative","player_pose"]:
  if not data.state.get(id) is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"missing_saved_component",{"component":id})
 if not data.state.get("kiosk_open") is bool: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_kiosk_state")
 return ActionResult.success()
func create_candidate(data: Dictionary, config: SessionConfig, destination: Node = null) -> ActionResult:
 var legacy := ActionResult.success({"data":data}) if data.get("schema_version")==SCHEMA_VERSION else SaveMigrations.upgrade(data)
 if not legacy.ok:return legacy
 var migration := LivingSpacesMigration.upgrade(legacy.details.data,config,SCHEMA_REVISION)
 if not migration.ok:return migration
 var restored_data: Dictionary = migration.details.data
 var result := validate(restored_data,config)
 if not result.ok: return result
 var candidate := GameSession.new()
 # Inkgd tears down runtime nodes on tree exit. Restore under the final owner
 # so installing a validated candidate never reparents a live Ink player.
 var owner_node: Node = destination if destination!=null else self
 owner_node.add_child(candidate)
 result = candidate.configure(config)
 if not result.ok:
  candidate.queue_free()
  return result
 for id in COMPONENTS:
  result = candidate.get(id).restore(restored_data.state[id])
  if not result.ok:
   candidate.queue_free()
   return ActionResult.failure(ActionResult.Code.INVALID_SAVE,result.message_key,{"component":id})
 result = candidate.player_pose.restore(restored_data.state.player_pose)
 if not result.ok or not config.section("locations").has(str(candidate.location_id)):
  candidate.queue_free()
  return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_player_pose")
 var location: Dictionary = config.section("locations")[str(candidate.location_id)]
 var bounds: Array = location.player_bounds
 var ground := candidate.player_ground
 if ground.x<float(bounds[0]) or ground.x>float(bounds[2]) or ground.y<float(bounds[1]) or ground.y>float(bounds[3]) or FootprintGeometry.blocked(ground,candidate.spaces.solids(candidate.location_id),0):
  candidate.queue_free()
  return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_player_position")
 candidate.kiosk_open = restored_data.state.kiosk_open
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
 for memories in candidate.visitors.history.snapshot().services.values():
  for memory in memories:
   var order := candidate.service.order(StringName(memory.order_id))
   if order==null or order.status!=&"delivered" or str(order.visit_id)!=memory.visit_id or str(order.food_id)!=memory.food_id:
    candidate.queue_free()
    return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_service_memory")
 result = LivingSpacesSaveValidation.validate(candidate,restored_data)
 if not result.ok:
  candidate.queue_free()
  return result
 result = await candidate.narrative.restore(restored_data.state.narrative)
 if not result.ok:
  candidate.queue_free()
  return result
 return ActionResult.success({"session":candidate})

static func valid_digest(data: Dictionary) -> bool:
 var candidate := data.duplicate(true)
 var checksum: Variant = candidate.get("checksum")
 candidate.erase("checksum")
 return checksum is String and (checksum==StableJson.stringify(candidate).sha256_text() or (data.get("schema_version")==1 and checksum==JSON.stringify(candidate,"",true).sha256_text()))

static func decode_text(raw: String) -> ActionResult:
 var parsed: Variant = JSON.parse_string(raw)
 if not parsed is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"save_unreadable")
 if valid_digest(parsed): return ActionResult.success({"data":parsed})
 # Verify the exact compact bytes first. Godot's JSON parser can round a
 # nonintegral value by one ULP, even when stringify used full_precision.
 # Only an authenticated original payload may be resealed in memory.
 if ContentValidation.integer(parsed.get("schema_version")) and int(parsed.schema_version) in [1,2,3,SCHEMA_VERSION] and parsed.get("checksum") is String:
  var prefix := '{"checksum":"%s",' % parsed.checksum
  if raw.begins_with(prefix):
   var original_payload := "{"+raw.substr(prefix.length())
   if original_payload.sha256_text()==parsed.checksum:
    parsed.erase("checksum")
    parsed["checksum"] = StableJson.stringify(parsed).sha256_text()
    return ActionResult.success({"data":parsed})
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"corrupt_save")
