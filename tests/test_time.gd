extends RefCounted
func run(check, _tree) -> void:
 check.case("shared_time_order_and_missing_dependencies")
 var path := "res://game/time/simulation_coordinator.gd"
 check.is_true(FileAccess.file_exists(path))
 if not FileAccess.file_exists(path): return
 var Clock = load("res://game/time/game_clock.gd")
 var Coordinator = load(path)
 var clock = Clock.new({"minutes_per_second":2.5,"start_day":1,"start_minutes":930,"wake_minutes":900})
 var coordinator = Coordinator.new()
 var observed: Array = []
 var handlers := {"needs":func(frame):observed.append(["needs",frame.minutes]),"actors":func(frame):observed.append(["actors",frame.minutes])}
 check.is_true(coordinator.prepare(clock,handlers,{"clock":[],"needs":["clock"],"actors":["needs"]}).ok)
 check.is_true(coordinator.step(1.0).ok)
 check.equal(observed, [["needs",932.5],["actors",932.5]])
 check.case("dependency_cycles_and_missing_ids_are_rejected")
 check.is_true(not coordinator.prepare(clock,handlers,{"clock":[],"needs":["actors"],"actors":["needs"]}).ok)
 check.is_true(not coordinator.prepare(clock,handlers,{"clock":[],"needs":["missing"],"actors":[]}).ok)
 check.case("blocked_scheduled_job_never_blocks_clock_or_runs_early")
 var scheduler = load("res://game/time/world_scheduler.gd").new()
 var calls: Array = []
 var permitted := {"ready":false}
 scheduler.configure({"a":func(_payload):calls.append("a");return ActionResult.success(),"b":func(_payload):calls.append("b");return ActionResult.success()},func(_condition):return permitted.ready)
 check.is_true(scheduler.schedule_many([
  {"id":"b","action":"b","domain":"simulation","due":1.0,"deadline":10.0,"depends_on":["a"]},
  {"id":"a","action":"a","domain":"simulation","due":1.0,"deadline":10.0,"requires":{"fact_known":"X"}}
 ]).ok)
 clock.advance(1.0)
 scheduler.tick(clock.frame(1.0))
 check.equal(calls, [])
 check.is_true(clock.simulation_seconds > 1.0)
 permitted.ready = true
 scheduler.tick(clock.frame(0.0))
 check.equal(calls, ["a","b"])
 scheduler.tick(clock.frame(0.0))
 check.equal(calls, ["a","b"])
 check.case("expired_prerequisite_cancels_dependents_without_hang")
 var late = load("res://game/time/world_scheduler.gd").new()
 late.configure({"a":func(_payload):return ActionResult.success()},func(_condition):return false)
 check.is_true(late.schedule_many([{"id":"a","action":"a","due":0,"deadline":1,"requires":{}},{"id":"b","action":"a","due":0,"deadline":100,"depends_on":["a"]}]).ok)
 clock.advance(5.0)
 late.tick(clock.frame(5.0))
 check.equal(late.status("a"),"expired")
 check.equal(late.status("b"),"cancelled")
