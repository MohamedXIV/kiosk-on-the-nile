class_name ActionPolicy
extends RefCounted
var business_allowed: Callable
var _session: GameSession
var _data: Dictionary
var _attempts: Dictionary={}
var _effort: Dictionary={}
var _activity_next: int=1
var _last_refusal: float=-1
var _daily: Dictionary={}
func configure(session: GameSession) -> void:
 _session=session
 _data=session.config.section("action_policy")
func preview(action_id: StringName, _context: Dictionary = {}) -> ActionResult:
 if not _data.classes.has(str(action_id)):return _deny("unknown_action_class")
 var rule: Dictionary=_data.classes[str(action_id)]
 if action_id==&"commercial_preparation" and business_allowed.is_valid() and not business_allowed.call():return _deny("business_suspended")
 if rule.focus and (_session.needs.rest<=_session.tuning.value("absolute_floor") or _session.alertness.effective_focus()<_session.tuning.value("focus_denial")):return _deny("fatigue_focus")
 if rule.hunger and _session.needs.hunger<_session.tuning.value("hunger_denial"):return _deny("hunger_action")
 return ActionResult.success()
func attempt(action_id: StringName, attempt_key: String, context: Dictionary = {}) -> ActionResult:
 var eligibility := preview(action_id,context)
 if not eligibility.ok:return eligibility
 if attempt_key.is_empty():return _deny("invalid_attempt")
 if _attempts.has(attempt_key):
  var saved: Dictionary=_attempts[attempt_key]
  if saved.action!=str(action_id):return _deny("invalid_attempt")
  return _deny("mood_refusal") if saved.refused else ActionResult.success()
 var now := _session.clock.world_minutes
 var day := str(_session.clock.day)
 var refused := false
 if _data.classes[str(action_id)].refusal and _session.needs.mood<_session.tuning.value("mood_threshold"):
  if _last_refusal>=0 and now-_last_refusal<_session.tuning.value("refusal_cooldown"):return _deny("mood_refusal")
  if int(_daily.get(day,0))<int(_session.tuning.value("refusal_daily_cap")):
   # The decision is stable for a work opportunity, not generated on each click.
   var sample := float((attempt_key+":"+day).sha256_text().substr(0,8).hex_to_int())/4294967295.0
   refused=sample<_session.tuning.value("refusal_probability")
 _attempts[attempt_key]={"action":str(action_id),"at":now,"day":_session.clock.day,"refused":refused}
 if refused:
  _last_refusal=now
  _daily[day]=int(_daily.get(day,0))+1
  return _deny("mood_refusal")
 return ActionResult.success()
func opportunity(action_id: StringName, target: String) -> String:
 # Refusals share one cooldown opportunity; successes are tied to actual state
 # revision by the caller. Waiting a full cooldown opens a new decision.
 return "%s:%s:%d" % [action_id,target,floori(_session.clock.world_minutes/_session.tuning.value("refusal_cooldown"))]
func record_effort(source_id: String, kind: StringName, amount: float = 1.0) -> ActionResult:
 if _effort.has(source_id):return ActionResult.success({"duplicate":true})
 if source_id.is_empty() or not _data.effort.has(str(kind)) or not ContentValidation.bounded(amount,0,100):return _deny("invalid_effort")
 var cost: Dictionary=_data.effort[str(kind)]
 _session.needs.apply_delta(0,-float(cost.rest)*amount,-float(cost.mood)*amount)
 _effort[source_id]={"kind":str(kind),"amount":amount,"at":_session.clock.world_minutes}
 return ActionResult.success()
func snapshot() -> Dictionary:
 return {"next_activity":_activity_next,"attempts":_attempts.duplicate(true),"effort":_effort.duplicate(true),"last_refusal":_last_refusal,"daily":_daily.duplicate()}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("attempts") is Dictionary or not data.get("effort") is Dictionary or not data.get("daily") is Dictionary or not ContentValidation.bounded(data.get("last_refusal"),-1,_session.clock.world_minutes):return _deny("invalid_action_policy")
 var activity_limit: Variant=data.get("next_activity",1)
 if not ContentValidation.integer(activity_limit) or activity_limit<1:return _deny("invalid_effort_sequence")
 var counts: Dictionary={}
 var last := -1.0
 for id in data.attempts:
  var a: Variant=data.attempts[id]
  if not id is String or id.is_empty() or not a is Dictionary or not _data.classes.has(a.get("action")) or not a.get("refused") is bool or not ContentValidation.bounded(a.get("at"),0,_session.clock.world_minutes) or not ContentValidation.integer(a.get("day")) or a.day!=floori(float(a.at)/1440.0)+1:return _deny("invalid_action_attempt")
  if a.refused:
   counts[str(int(a.day))]=int(counts.get(str(int(a.day)),0))+1
   last=maxf(last,float(a.at))
 if StableJson.stringify(counts)!=StableJson.stringify(data.daily) or absf(last-float(data.last_refusal))>0.001:return _deny("invalid_refusal_provenance")
 for id in data.effort:
  var e: Variant=data.effort[id]
  if not id is String or id.is_empty() or not e is Dictionary or not _data.effort.has(e.get("kind")) or not ContentValidation.bounded(e.get("amount"),0,100) or not ContentValidation.bounded(e.get("at"),0,_session.clock.world_minutes):return _deny("invalid_effort_history")
  if e.kind in ["cleaning","arranging"]:
   var suffix := str(id).trim_prefix("activity_")
   if not str(id).begins_with("activity_") or not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=int(activity_limit):return _deny("invalid_effort_sequence")
 _activity_next=int(activity_limit)
 _attempts=data.attempts.duplicate(true)
 _effort=data.effort.duplicate(true)
 _last_refusal=float(data.last_refusal)
 _daily=data.daily.duplicate()
 return ActionResult.success()
func _deny(key: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,StringName(key))

func record_activity(kind: StringName) -> ActionResult:
 var result := record_effort("activity_%d" % _activity_next,kind)
 if result.ok:_activity_next+=1
 return result
