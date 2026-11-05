extends RefCounted
func run(check, tree) -> void:
 var store := ContentStore.new()
 check.is_true(store.load_directory("res://content").ok)
 var config := SessionConfig.new(store.bundle(),store.fingerprint,store.source_root)
 var sessions: Array[GameSession]=[]
 var session := _session(config,tree,check);sessions.append(session)
 var tea: Dictionary=store.section("recipe_workflows").tea
 var speed := float(tea.presentation_minutes_per_second)
 check.case("inventory_backed_tea_reserves_then_consumes_exact_input")
 _approach(session,&"tea")
 var initial := session.cooking.stock_count(&"tea")
 check.equal(initial,int(store.section("recipes").initial_stock.tea))
 check.is_true(session.cooking.cycle_sugar(&"tea").ok)
 check.is_true(session.cooking.act(&"tea").ok)
 check.equal(_quantity(session,&"tea_portion"),initial)
 check.equal(session.cooking.stock_count(&"tea"),initial-1)
 var before := _snapshot(session)
 check.equal(session.cooking.act(&"tea").code,ActionResult.Code.TOO_EARLY)
 check.equal(_snapshot(session),before)
 check.is_true(not session.cooking.cycle_sugar(&"tea").ok)
 check.equal(_snapshot(session),before)
 _advance(session,float(tea.steps[0].duration)/speed)
 check.is_true(session.cooking.act(&"tea").ok)
 check.equal(_quantity(session,&"tea_portion"),initial-1)
 _advance(session,float(tea.steps[1].duration)/speed)
 check.is_true(session.cooking.act(&"tea").ok)
 var item := session.cooking.held_item()
 check.is_true(item!=null)
 if item!=null:
  check.equal(item.quality_score,3)
  check.equal(item.sugar_id,&"extra")
  check.is_true(session.cooking.take_held(item.id)!=null)
 check.case("overbrewed_tea_uses_current_workflow_quality_windows")
 for fixture in [[float(tea.steps[1].good_until)+1,2],[float(tea.steps[1].okay_until)+1,1]]:
  var late := _session(config,tree,check);sessions.append(late);_approach(late,&"tea")
  check.is_true(late.cooking.act(&"tea").ok)
  _advance(late,float(tea.steps[0].duration)/speed)
  check.is_true(late.cooking.act(&"tea").ok)
  _advance(late,float(fixture[0])/speed)
  check.is_true(late.cooking.act(&"tea").ok)
  check.equal(late.cooking.held_item().quality_score,int(fixture[1]))
 check.case("occupied_hands_reject_serving_without_stock_or_workflow_mutation")
 check.is_true(session.cooking.act(&"tea").ok)
 _advance(session,float(tea.steps[0].duration)/speed);check.is_true(session.cooking.act(&"tea").ok)
 _advance(session,float(tea.steps[1].duration)/speed);check.is_true(session.cooking.act(&"tea").ok)
 check.is_true(session.cooking.act(&"tea").ok)
 _advance(session,float(tea.steps[0].duration)/speed);check.is_true(session.cooking.act(&"tea").ok)
 _advance(session,float(tea.steps[1].duration)/speed)
 before=_snapshot(session)
 check.equal(session.cooking.act(&"tea").code,ActionResult.Code.HANDS_BUSY)
 check.equal(_snapshot(session),before)
 check.case("current_kebda_batch_preparation_heat_and_portion_lifecycle")
 var batch := _session(config,tree,check);sessions.append(batch);_approach(batch,&"kebda")
 var kebda: Dictionary=store.section("recipe_workflows").kebda
 var additions: Dictionary={}
 for input in kebda.inputs:
  var missing := maxi(0,int(input.quantity)-batch.inventory.stock_count(&"kiosk",StringName(input.definition_id)))
  if missing>0:additions[str(input.definition_id)]=missing
 var serving := batch.menu.plan(&"kebda")
 check.is_true(serving.ok)
 for input in serving.details.plan.inputs:
  var missing := maxi(0,int(input.quantity)*int(kebda.portions)-batch.inventory.stock_count(&"kiosk",StringName(input.definition_id)))
  if missing>0:additions[str(input.definition_id)]=int(additions.get(str(input.definition_id),0))+missing
 check.is_true(batch.inventory.restock_legacy(additions,"starter").ok)
 check.is_true(batch.cooking.act(&"kebda").ok)
 var job := batch.workflow.active_at(&"kebda")
 var job_id := StringName(job.id)
 before=_snapshot(batch)
 check.equal(batch.cooking.act(&"kebda").code,ActionResult.Code.TOO_EARLY)
 check.equal(_snapshot(batch),before)
 _advance(batch,float(kebda.steps[0].duration)/float(kebda.presentation_minutes_per_second))
 check.is_true(batch.cooking.act(&"kebda").ok)
 check.equal(batch.workflow.job(job_id).step_index,1)
 check.is_true(batch.workflow.act(job_id,&"heat:off").ok)
 var elapsed := float(batch.workflow.job(job_id).elapsed)
 _advance(batch,float(kebda.steps[1].duration))
 check.near(float(batch.workflow.job(job_id).elapsed),elapsed)
 check.is_true(batch.workflow.act(job_id,&"heat:medium").ok)
 _advance(batch,float(kebda.steps[1].duration))
 check.equal(batch.workflow.job(job_id).step_index,2)
 var vessel_id := StringName(batch.workflow.job(job_id).bowl_id)
 check.equal(batch.items.get_item(vessel_id).attributes.portions_remaining,int(kebda.portions))
 var served: Array[StringName]=[]
 for index in range(int(kebda.portions)):
  check.is_true(batch.cooking.act(&"kebda").ok)
  var portion := batch.cooking.held_item()
  check.is_true(portion!=null)
  if portion==null:break
  check.is_true(not served.has(portion.id));served.append(portion.id)
  check.equal(portion.batch_id,vessel_id)
  check.equal(portion.quality_score,3)
  check.is_true(batch.cooking.take_held(portion.id)!=null)
 check.equal(served.size(),int(kebda.portions))
 check.equal(batch.workflow.job(job_id).status,"completed")
 check.is_true(batch.items.get_item(vessel_id).is_empty())
 check.case("two_real_stations_cannot_reserve_the_same_last_portion")
 var limited := _session(config,tree,check);sessions.append(limited)
 check.is_true(limited.inventory.debit_legacy(&"tea",limited.cooking.stock_count(&"tea")-1).ok)
 var grant := limited.items.prepare_grants([{"id":"test_kettle","definition_id":"kettle","quantity":1,"container_id":"kiosk_furniture","attributes":{}}])
 check.is_true(grant.ok)
 check.is_true(limited.items.commit(grant.details.change).ok)
 var host := limited.spaces.placement(&"counter_2")
 var request := PlacementRequest.from_dict({"instance_id":"test_kettle","location_id":"kiosk","cell":host.cell,"rotation":0,"host_id":"counter_2","slot_id":"top"})
 check.is_true(limited.spaces.place(request).ok)
 _approach(limited,&"tea");check.is_true(limited.cooking.act(&"tea").ok)
 _approach(limited,&"test_kettle");before=_snapshot(limited)
 check.equal(limited.workflow.start(&"tea",&"kiosk",PackedStringArray(["test_kettle"])).code,ActionResult.Code.OUT_OF_STOCK)
 check.equal(_snapshot(limited),before)
 check.equal(limited.cooking.stock_count(&"tea"),0)
 check.equal(_quantity(limited,&"tea_portion"),1)
 check.case("active_job_save_restore_keeps_frozen_timing_and_sugar")
 var active := _session(config,tree,check);sessions.append(active);_approach(active,&"tea")
 check.is_true(active.cooking.cycle_sugar(&"tea").ok)
 check.is_true(active.cooking.act(&"tea").ok)
 _advance(active,1.0)
 var codec := SaveCodec.new();tree.root.add_child(codec)
 var envelope := codec.encode(active)
 var tuned := store.bundle()
 tuned.recipe_workflows.tea.steps[0].duration=float(tea.steps[0].duration)*3
 var restored := await codec.create_candidate(envelope,SessionConfig.new(tuned,store.fingerprint,store.source_root),tree.root)
 check.is_true(restored.ok)
 if restored.ok:
  var resumed: GameSession=restored.details.session;sessions.append(resumed)
  check.equal(resumed.workflow.snapshot(),active.workflow.snapshot())
  _advance(resumed,float(tea.steps[0].duration)/speed-1.0)
  check.equal(resumed.cooking.job(&"tea").stage,&"BOILED")
  check.is_true(resumed.cooking.act(&"tea").ok)
  _advance(resumed,float(tea.steps[1].duration)/speed)
  check.is_true(resumed.cooking.act(&"tea").ok)
  check.equal(resumed.cooking.held_item().sugar_id,&"extra")
  check.is_true(resumed.cooking.take_held(resumed.cooking.held_item().id)!=null)
  check.is_true(resumed.cooking.act(&"tea").ok)
  check.equal(resumed.workflow.active_at(&"tea").definition.steps[0].duration,tuned.recipe_workflows.tea.steps[0].duration)
  _advance(resumed,float(tea.steps[0].duration)/speed)
  check.equal(resumed.cooking.job(&"tea").stage,&"HEATING")
 check.case("invalid_workflow_step_and_reused_job_counter_reject_atomically")
 var valid := active.workflow.snapshot()
 var bad := valid.duplicate(true)
 var id: String=bad.jobs.keys()[0]
 bad.jobs[id].step_index=bad.jobs[id].definition.steps.size()
 check.is_true(not active.workflow.restore(bad).ok)
 check.equal(active.workflow.snapshot(),valid)
 bad=valid.duplicate(true);bad.next_id=1
 check.is_true(not active.workflow.restore(bad).ok)
 check.equal(active.workflow.snapshot(),valid)
 for current in sessions:current.queue_free()
 codec.queue_free();store.free()
 await tree.process_frame

func _session(config: SessionConfig, tree: SceneTree, check) -> GameSession:
 var session := GameSession.new();tree.root.add_child(session)
 check.is_true(session.configure(config).ok)
 session.start_new()
 return session
func _advance(session: GameSession, seconds: float) -> void:
 session.clock.advance(seconds)
 session.workflow.tick(session.clock.frame(seconds))
func _approach(session: GameSession, station: StringName) -> void:
 session.location_id=&"kiosk"
 var ground := session.spaces.ground(station)
 for direction in [Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2.UP]:
  var point: Vector2=ground+direction
  if not FootprintGeometry.blocked(point,session.spaces.solids(&"kiosk"),0.18):
   session.player_ground=point;return
 session.player_ground=ground+Vector2.DOWN
func _quantity(session: GameSession, definition: StringName) -> int:
 var quantity := 0
 for item in session.items.instances(definition):quantity+=int(item.quantity)
 return quantity
func _snapshot(session: GameSession) -> Dictionary:
 return {"items":session.items.snapshot(),"workflow":session.workflow.snapshot(),"equipment":session.equipment.snapshot(),"cooking":session.cooking.snapshot()}
