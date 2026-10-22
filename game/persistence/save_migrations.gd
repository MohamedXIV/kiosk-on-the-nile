class_name SaveMigrations
extends RefCounted
const CURRENT := 3
static func upgrade(original: Dictionary) -> ActionResult:
 if not SaveCodec.valid_digest(original): return _invalid("checksum")
 var version: Variant = original.get("schema_version")
 if not ContentValidation.integer(version) or not int(version) in [1,2,CURRENT]: return _invalid("schema")
 if int(version)==CURRENT: return ActionResult.success({"data":original.duplicate(true)})
 var candidate := original.duplicate(true)
 if not candidate.get("state") is Dictionary or not candidate.state.get("clock") is Dictionary or not candidate.state.get("cooking") is Dictionary or not candidate.state.cooking.get("jobs") is Dictionary: return _invalid("components")
 if int(version)==1:
  var clock: Dictionary = candidate.state.clock
  for field in ["world_minutes","minutes","day"]:
   if not ContentValidation.number(clock.get(field)) or clock[field]<0: return _invalid("clock_field")
  if not ContentValidation.integer(clock.day) or clock.day<1: return _invalid("clock_day")
  if absf(fposmod(float(clock.world_minutes),1440)-fposmod(float(clock.minutes),1440))>0.001: return _invalid("clock_alignment")
  # Keep the original monotonic timeline, pending jobs, story hashes and money.
  # Legacy work-day labels become actual calendar dates; never charge on load.
  clock.day = floori(float(clock.world_minutes)/1440.0)+1
  clock.minutes = fposmod(float(clock.world_minutes),1440.0)
  candidate.state["routine"] = {"last_rent_day":clock.day}
  for job in candidate.state.cooking.jobs.values():
   if not job is Dictionary: return _invalid("cooking_job")
   job["quality_penalty"] = 0
 # Older versions have no topic consumption or per-person visit reservations.
 var state: Dictionary = candidate.state
 if not state.get("visitors") is Dictionary or not state.get("narrative") is Dictionary or not state.visitors.get("visits") is Dictionary or not state.narrative.get("sessions") is Dictionary: return _invalid("social_components")
 if not ContentValidation.integer(state.clock.get("day")) or state.clock.day<1 or not ContentValidation.number(state.clock.get("world_minutes")) or state.clock.world_minutes<0: return _invalid("clock_history")
 var reservations: Dictionary = {}
 for visit in state.visitors.visits.values():
  if not visit is Dictionary or not visit.get("character_id") is String: return _invalid("visit")
  reservations[visit.character_id] = {"day":state.clock.day,"count":1,"world_minutes":state.clock.world_minutes}
 state.visitors["history"] = {"visits":reservations,"services":{}}
 state.narrative["history"] = {}
 for conversation in state.narrative.sessions.values():
  if not conversation is Dictionary: return _invalid("conversation")
  conversation["topic_selection"] = {}
 candidate.schema_version = CURRENT
 candidate["migrated_from"] = int(version)
 candidate.erase("checksum")
 candidate["checksum"] = StableJson.stringify(candidate).sha256_text()
 return ActionResult.success({"data":candidate})
static func _invalid(reason: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"incompatible_save",{"reason":reason})
