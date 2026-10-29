class_name PolicyDecision
extends RefCounted
var status: String = "invalid"
var allowed: bool = false
var reasons: Array[Dictionary] = []
var evidence: Array = []
static func make(state: String, reason: String = "", at: String = "", sources: Array = []) -> PolicyDecision:
 var value := PolicyDecision.new()
 value.status=state;value.allowed=state=="allowed";value.evidence=sources
 if not reason.is_empty():value.reasons.append({"id":reason,"path":at})
 return value
func snapshot() -> Dictionary:
 return {"status":status,"allowed":allowed,"reasons":reasons.duplicate(true),"evidence":evidence.duplicate(true)}
