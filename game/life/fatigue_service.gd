class_name FatigueService
extends RefCounted
var _session: GameSession
var _next_at: float=0
var _pulse_end: float=0
var _sequence: int=1
var _severity: float=0
var visual_scale: float=1
func configure(session: GameSession) -> void:
 _session=session
 _next_at=session.clock.simulation_seconds+5
func tick(_frame: Dictionary) -> void:
 var now := _session.clock.simulation_seconds
 if _session.needs.rest>=_session.tuning.value("fatigue_warning"):
  _severity=0
  _pulse_end=now
  _next_at=maxf(_next_at,now+_session.tuning.value("blur_warning_min"))
  return
 if now<_next_at:return
 var severe := _session.needs.rest<_session.tuning.value("focus_denial")
 var minimum := _session.tuning.value("blur_severe_min" if severe else "blur_warning_min")
 var maximum := _session.tuning.value("blur_severe_max" if severe else "blur_warning_max")
 var sample := float(("fatigue:%d" % _sequence).sha256_text().substr(0,8).hex_to_int())/4294967295.0
 _sequence+=1
 _severity=1.0 if severe else clampf(1.0-_session.needs.rest/_session.tuning.value("fatigue_warning"),0.12,0.7)
 _pulse_end=now+_session.tuning.value("blur_duration")
 _next_at=now+lerpf(minimum,maximum,sample)
func recover_sleep() -> void:
 _severity=0
 _pulse_end=_session.clock.simulation_seconds
 _next_at=_pulse_end+_session.tuning.value("blur_warning_min")
func view() -> Dictionary:
 var remaining := maxf(0,_pulse_end-_session.clock.simulation_seconds)
 var duration := _session.tuning.value("blur_duration")
 var envelope := sin(clampf(remaining/duration,0,1)*PI)
 return {"strength":_severity*envelope*visual_scale*_session.tuning.value("blur_strength")}
func snapshot() -> Dictionary:
 return {"next_at":_next_at,"pulse_end":_pulse_end,"sequence":_sequence,"severity":_severity,"visual_scale":visual_scale}
func restore(data: Dictionary) -> ActionResult:
 var now := _session.clock.simulation_seconds
 if not ContentValidation.bounded(data.get("next_at"),0,now+30.001) or not ContentValidation.bounded(data.get("pulse_end"),0,now+1.501) or not ContentValidation.integer(data.get("sequence")) or data.sequence<1 or not ContentValidation.bounded(data.get("severity"),0,1) or not ContentValidation.bounded(data.get("visual_scale"),0,1):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_fatigue_pulse")
 _next_at=float(data.next_at)
 _pulse_end=float(data.pulse_end)
 _sequence=int(data.sequence)
 _severity=float(data.severity)
 visual_scale=float(data.visual_scale)
 return ActionResult.success()
