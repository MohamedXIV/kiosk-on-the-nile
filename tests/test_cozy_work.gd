extends RefCounted
func run(check, tree) -> void:
 var store := ContentStore.new()
 check.is_true(store.load_directory("res://content").ok)
 var locale := LocaleService.new()
 check.is_true(locale.configure(store.bundle()).ok)
 var text := UiText.new(store.section("ui"))
 var session := GameSession.new()
 tree.root.add_child(session)
 check.is_true(session.configure(SessionConfig.new(store.bundle(),store.fingerprint,store.source_root)).ok)
 session.location_id=&"kiosk"
 session.player_ground=session.spaces.ground(&"tea")
 var viewport := SubViewport.new();viewport.size=Vector2i(1280,720);tree.root.add_child(viewport)
 var inventory := InventoryPanel.new();viewport.add_child(inventory);inventory.configure(text,session)
 var recipes := RecipePanel.new();viewport.add_child(recipes);recipes.configure(text,session)
 var menu := MenuPanel.new();viewport.add_child(menu);menu.configure(text,session)
 check.case("work_sheets_display_real_state_without_mutating_gameplay")
 var stock_before := session.items.snapshot()
 var time_before := session.clock.world_minutes
 var prices_before := session.menu.snapshot()
 for language in ["en","ar_EG"]:
  locale.set_locale(language)
  for width in [1280,620]:
   viewport.size=Vector2i(width,720)
   for sheet in [inventory,recipes,menu]:
    if sheet==recipes:recipes.present(&"tea")
    else:sheet.open()
    UiText.refresh_tree(sheet)
    for frame in range(4):await tree.process_frame
    check.is_true(sheet.position.x>=0 and sheet.position.x+sheet.size.x<=width+1)
    check.is_true(_horizontal_bounds(sheet,sheet.get_global_rect()))
    sheet.hide()
 check.equal(session.items.snapshot(),stock_before)
 check.equal(session.menu.snapshot(),prices_before)
 check.equal(session.clock.world_minutes,time_before)
 check.case("inventory_refresh_keeps_search_and_focus_and_exact_quantity")
 locale.set_locale("en")
 inventory.open();inventory._search.text="tea";inventory._render()
 inventory._search.grab_focus()
 var search_id := inventory._search.get_instance_id()
 inventory.refresh();inventory._process(0)
 check.equal(inventory._search.get_instance_id(),search_id)
 check.equal(inventory._search.text,"tea")
 check.equal(viewport.gui_get_focus_owner(),inventory._search)
 for item in stock_before.items.values():
  if item.definition_id=="tea_portion":
   var expected := ItemText.t("quantity",{"name":ItemText.instance(session,item),"quantity":int(item.quantity)})
   check.is_true(_has_label(inventory._rows,expected))
 for button in inventory._rows.find_children("*","Button",true,false):
  var key := str(button.get_meta("inventory_focus",""))
  if key.is_empty() or button.disabled:continue
  button.grab_focus();inventory._render()
  await tree.process_frame
  var restored := viewport.gui_get_focus_owner()
  check.is_true(restored!=null and str(restored.get_meta("inventory_focus",""))==key)
  break
 inventory.hide()
 check.case("menu_keeps_price_drafts_and_applies_only_on_action")
 menu.open()
 var editors := menu._rows.find_children("*","SpinBox",true,false)
 check.is_true(not editors.is_empty())
 var editor: SpinBox=editors[0]
 var price_key := str(editor.get_line_edit().get_meta("price_focus")).trim_suffix(":edit")
 editor.value=2.75
 check.equal(session.menu.snapshot(),prices_before)
 menu._render()
 check.equal(menu._draft_prices[price_key],275)
 var applied := false
 for button in menu._rows.find_children("*","Button",true,false):
  if str(button.get_meta("price_focus",""))==price_key+":apply":button.pressed.emit();applied=true;break
 check.is_true(applied)
 check.equal(int(session.menu.snapshot().prices[price_key.trim_prefix("food:")]),275)
 menu.hide()
 check.case("cooking_progress_reads_existing_world_minute_duration")
 var started := session.workflow.start(&"tea",&"kiosk",PackedStringArray(["tea"]))
 check.is_true(started.ok)
 if started.ok:
  recipes.present(&"tea")
  check.equal(recipes._progress.size(),1)
  var entry: Dictionary=recipes._progress[0]
  var original_label_id: int=entry.label.get_instance_id()
  recipes._update_progress()
  var progress := session.workflow.progress_view(StringName(entry.job_id))
  check.near(entry.meter.max_value,float(progress.duration))
  check.near(entry.meter.value,minf(float(progress.elapsed),float(progress.duration)))
  recipes._process(0.2)
  check.equal(recipes._progress[0].label.get_instance_id(),original_label_id)
 for frame in range(3):await tree.process_frame
 viewport.free();session.free();store.free()
 await tree.process_frame
func _has_label(root: Node, value: String) -> bool:
 for control in root.find_children("*","Label",true,false):
  if control.text==value:return true
 return false
func _horizontal_bounds(root: Control, bounds: Rect2) -> bool:
 for child in root.get_children():
  if child is Control and child.is_visible_in_tree():
   var rect: Rect2=child.get_global_rect()
   if rect.position.x<bounds.position.x-1 or rect.end.x>bounds.end.x+1:return false
   if not _horizontal_bounds(child,bounds):return false
 return true
