class_name WorldScheduler
extends RefCounted
## Durable data-only jobs; blocked prerequisites never block the simulation loop.
var _jobs: Dictionary = {}
var _handlers: Dictionary = {}
var _condition: Callable
func configure(handlers: Dictionary, condition: Callable = Callable()) -> void:
 _handlers = handlers.duplicate()
 _condition = condition
func schedule_many(definitions: Array) -> ActionResult:
 var candidate := _jobs.duplicate(true)
 for definition in definitions:
  if not definition is Dictionary: return _invalid()
  var id: String = definition.get("id", "")
  var action: String = definition.get("action", "")
  if id.is_empty() or candidate.has(id) or not _handlers.has(action): return _invalid()
  var job: Dictionary = definition.duplicate(true)
  job["domain"] = job.get("domain","simulation")
  job["due"] = job.get("due",0.0)
  job["deadline"] = job.get("deadline",1.0e12)
  job["depends_on"] = job.get("depends_on",[])
  if not job.domain in ["simulation","world"] or not job.depends_on is Array: return _invalid()
  for field in ["due","deadline"]:
   if not typeof(job[field]) in [TYPE_FLOAT,TYPE_INT] or not is_finite(float(job[field])): return _invalid()
  if float(job.deadline) < float(job.due): return _invalid()
  job["status"] = "pending"
  job["reason"] = ""
  candidate[id] = job
 var visited: Array = []
 var remaining := candidate.keys()
 while not remaining.is_empty():
  var ready: Array = []
  for id in remaining:
   var dependencies_ready := true
   for dependency in candidate[id].depends_on:
    if not candidate.has(dependency): return _invalid()
    if not dependency in visited: dependencies_ready = false
   if dependencies_ready: ready.append(id)
  if ready.is_empty(): return _invalid()
  for id in ready:
   visited.append(id)
   remaining.erase(id)
 _jobs = candidate
 return ActionResult.success()
func tick(frame: Dictionary) -> void:
 var ids: Array = _jobs.keys()
 ids.sort()
 for _pass in range(ids.size() + 1):
  var changed := false
  for id in ids:
   var job: Dictionary = _jobs[id]
   if job.status in ["completed","expired","cancelled"]: continue
   var now := float(frame.simulation_seconds if job.domain == "simulation" else frame.world_minutes)
   if now > float(job.deadline):
    job.status = "expired"
    job.reason = "deadline"
    changed = true
    continue
   if now < float(job.due): continue
   var blocked := false
   for dependency in job.depends_on:
    if _jobs[dependency].status in ["expired","cancelled"]:
     job.status = "cancelled"
     job.reason = "prerequisite_expired"
     changed = true
     blocked = true
     break
    if _jobs[dependency].status != "completed": blocked = true
   if blocked:
    if job.status != "cancelled": job.status = "blocked"; job.reason = "prerequisite"
    continue
   if job.has("requires") and (not _condition.is_valid() or not _condition.call(job.requires)):
    job.status = "blocked"
    job.reason = "condition"
    continue
   var result: Variant = _handlers[job.action].call(job.get("payload",{}))
   if result is ActionResult and result.ok:
    job.status = "completed"
    job.reason = ""
    changed = true
   else:
    job.status = "blocked"
    job.reason = "action_unavailable"
  if not changed: break
func status(id: String) -> String:
 return _jobs.get(id,{}).get("status","")
func snapshot() -> Dictionary:
 return _jobs.duplicate(true)
func restore(data: Dictionary) -> ActionResult:
 var definitions: Array = []
 for id in data:
  if not data[id] is Dictionary or data[id].get("id") != id or not data[id].get("status","") in ["pending","blocked","completed","expired","cancelled"]: return _invalid()
  definitions.append(data[id])
 var old := _jobs
 _jobs = {}
 var result := schedule_many(definitions)
 if not result.ok:
  _jobs = old
  return result
 for id in data: _jobs[id] = data[id].duplicate(true)
 return ActionResult.success()
func _invalid() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_schedule")
