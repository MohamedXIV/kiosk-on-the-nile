class_name SessionAdvance
extends RefCounted
## Offscreen elapsed work: clock/recovery already applied, no synthetic speech/physics.
var _session: GameSession
var last_result := ActionResult.success()
func configure(session: GameSession) -> void:_session=session
func catch_up(frame: Dictionary) -> ActionResult:
 var failures: Dictionary={}
 _session.alertness.recover_sleep(float(frame.get("sleep_hours",0)))
 _session.fatigue.recover_sleep()
 _session.cooking.tick(float(frame.delta))
 _session.workflow.tick(frame)
 _session.hygiene.elapse(float(frame.world_delta))
 _session.shops.elapse(float(frame.world_delta))
 _session.hygiene.record_use(StringName("sleep:"+str(_session.clock.tick)),_session.routine.bed_id,&"sleep")
 var assessed := _session.accounts.tick(frame)
 if not assessed.ok:failures["accounts"]=str(assessed.message_key)
 var finance := _session.finance.tick(frame) if assessed.ok else assessed
 if not finance.ok:failures["finance"]=str(finance.message_key)
 var delivery_frame := frame.duplicate(true);delivery_frame["sleeping"]=true
 var supplied := _session.deliveries.tick(delivery_frame) if assessed.ok else assessed
 if not supplied.ok:failures["deliveries"]=str(supplied.message_key)
 _session.scheduler.tick(frame)
 var social := _session.social_life.tick(frame)
 if not social.ok:failures["social_life"]=str(social.message_key)
 last_result=ActionResult.success() if failures.is_empty() else ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"sleep_system_failed",{"failures":failures,"elapsed_committed":true})
 return last_result
