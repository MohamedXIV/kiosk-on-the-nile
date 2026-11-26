extends SceneTree
## Exercise the shipping Main scene and actual HUD signal wiring, not a mock.
## Run only with a temporary user data directory (tools/check-ui-startup.sh).
func _initialize() -> void:
 call_deferred("_run")

func _require(ok: bool, stage: String) -> bool:
 if ok:return true
 push_error("STARTUP_SMOKE_FAILED: "+stage)
 quit(1)
 return false

func _run() -> void:
 var scene := load("res://game/app/main.tscn") as PackedScene
 if not _require(scene!=null,"load main scene"):return
 var main := scene.instantiate() as Main
 if not _require(main!=null,"instantiate Main"):return
 root.add_child(main)
 current_scene=main
 for frame in range(12):await process_frame
 if not _require(is_instance_valid(main._title) and main._title.visible,"title is visible"):return
 if not _require(is_instance_valid(main._title._actions) and main._title._actions.is_inside_tree(),"title actions configured"):return
 if not _require(main._session==null,"title does not start a session"):return
 main._title.new_requested.emit()
 for frame in range(24):await process_frame
 if not _require(is_instance_valid(main._session) and main._session.running,"new game running"):return
 if not _require(main._title==null and is_instance_valid(main._hud) and main._hud.is_inside_tree(),"game HUD installed"):return
 if not _require(is_instance_valid(main._inventory_panel) and is_instance_valid(main._recipe_panel),"work panels installed"):return
 for language in ["en","ar_EG"]:
  if not _require(main._locale.set_locale(language).ok,"locale "+language):return
  await process_frame
  for id in main._supplier_panel._basket_labels:
   var label: Label=main._supplier_panel._basket_labels[id]
   if not _require(label.text==ItemText.definition(main._session,str(id)),"supplier label "+str(id)+" "+language):return
  main._hud._strip._shortcut_buttons["bag"].pressed.emit()
  await process_frame
  if not _require(main._inventory_panel.visible and main._modals.active_id()=="inventory","inventory shortcut "+language):return
  main._modals.close_active()
  await process_frame
  main._hud._strip._shortcut_buttons["notebook"].pressed.emit()
  await process_frame
  if not _require(main._hud.notebook.visible and main._modals.active_id()=="notebook","notebook shortcut "+language):return
  main._modals.close_active()
  await process_frame
 if not _require(not main._modals.blocking(),"modal close"):return
 # Stop simulation and presentation before explicitly draining session resources.
 # Keep the completion marker after cleanup; the shell also requires exit zero.
 main.set_process(false)
 main.set_physics_process(false)
 main._session.running=false
 main._session.personal.leave()
 for id in main._session.narrative.sessions.keys():main._session.narrative.cancel(StringName(id))
 await process_frame
 for player in main._session.ink_players.get_children():
  player.destroy()
  player.queue_free()
 for frame in range(3):await process_frame
 main.queue_free()
 for frame in range(4):await process_frame
 print("STARTUP_SMOKE_PASS")
 quit(0)
