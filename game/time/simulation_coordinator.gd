class_name SimulationCoordinator
extends RefCounted
var clock: GameClock
var order: Array[String] = []
var _handlers: Dictionary = {}
var _graph: Dictionary = {}
var last_failures: Dictionary = {}
func prepare(source: GameClock, handlers: Dictionary, graph: Dictionary) -> ActionResult:
 if not graph.has("clock") or not graph.clock is Array or not graph.clock.is_empty():
  return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_clock_phase")
 if graph.size() != handlers.size() + 1:
  return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"missing_system")
 for id in graph:
  if not graph[id] is Array or (id != "clock" and (not handlers.has(id) or not handlers[id] is Callable)):
   return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_system")
  for dependency in graph[id]:
   if not graph.has(dependency): return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"missing_dependency")
 var candidate: Array[String] = ["clock"]
 var remaining: Array = graph.keys()
 remaining.erase("clock")
 remaining.sort()
 while not remaining.is_empty():
  var available: Array = []
  for id in remaining:
   var ready := true
   for dependency in graph[id]:
    if not dependency in candidate: ready = false
   if ready: available.append(id)
  if available.is_empty(): return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"dependency_cycle")
  for id in available:
   candidate.append(str(id))
   remaining.erase(id)
 clock = source
 order = candidate
 _handlers = handlers.duplicate()
 _graph = graph.duplicate(true)
 return ActionResult.success()
func step(delta: float) -> ActionResult:
 if clock == null or delta < 0 or not is_finite(delta):
  return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"simulation_not_ready")
 clock.advance(delta)
 last_failures.clear()
 var shared_frame := clock.frame(delta)
 for id in order:
  if id == "clock": continue
  var blocked := false
  for dependency in _graph[id]:
   if last_failures.has(dependency): blocked = true
  if blocked:
   last_failures[id] = "dependency_failed"
   continue
  var outcome: Variant = _handlers[id].call(shared_frame.duplicate(true))
  if outcome is ActionResult and not outcome.ok: last_failures[id] = str(outcome.message_key)
 if not last_failures.is_empty(): return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"system_blocked",last_failures.duplicate())
 return ActionResult.success()
