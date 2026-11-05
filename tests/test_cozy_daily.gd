extends RefCounted
func run(check, tree) -> void:
 var store := ContentStore.new()
 check.is_true(store.load_directory("res://content").ok)
 var locale := LocaleService.new()
 check.is_true(locale.configure(store.bundle()).ok)
 locale.set_locale("ar_EG")
 var text := UiText.new(store.section("ui"))
 var session := GameSession.new();tree.root.add_child(session)
 check.is_true(session.configure(SessionConfig.new(store.bundle(),store.fingerprint,store.source_root)).ok)
 var initial_balance := session.wallet.balance
 var viewport := SubViewport.new();viewport.size=Vector2i(1280,720);tree.root.add_child(viewport)
 var supplier := SupplierPanel.new();viewport.add_child(supplier);supplier.configure(text,session)
 var district := DistrictPanel.new();viewport.add_child(district);district.configure(text,session)
 var journey := JourneyPanel.new();viewport.add_child(journey);journey.configure(text,session)
 var sleep := SleepPanel.new();viewport.add_child(sleep);sleep.configure(text)
 var build := BuildPanel.new();viewport.add_child(build);build.configure(text,session.build,session)
 var tuning := TuningPanel.new();viewport.add_child(tuning);tuning.configure(session)
 build.open();tuning.open()
 var point: Dictionary=session.contact.points()[0]
 session.location_id=StringName(point.location_id);session.player_ground=point.ground
 session.contact.host_id=str(point.host_id);session.contact.current=ResidentialRecord.new()
 session.contact.current.pose.location_id=session.location_id;session.contact.current.pose.ground=point.ground
 supplier._quote()
 var panels: Array[Control]=[supplier,district,journey,sleep,build,tuning]
 check.case("daily_sheets_fit_both_locales_and_narrow_viewport")
 for language in ["ar_EG","en"]:
  locale.set_locale(language)
  for extent in [Vector2i(1280,720),Vector2i(640,720)]:
   viewport.size=extent
   for panel in panels:
    panel.show();UiText.refresh_tree(panel)
   for frame in range(6):await tree.process_frame
   for panel in panels:
    if panel.position.x+panel.size.x>extent.x+1 or panel.position.y+panel.size.y>extent.y+1:print("PANEL BOUNDS ",panel.get_class()," ",panel.get_script().resource_path," ",panel.get_rect()," ",extent)
    check.is_true(panel.position.x>=0)
    check.is_true(panel.position.x+panel.size.x<=extent.x+1)
    check.is_true(panel.position.y+panel.size.y<=extent.y+1)
    check.is_true(_horizontal_fits(panel,panel.get_global_rect()))
    if panel==build:check.is_true(panel.size.x<extent.x-60)
 check.case("supplier_terms_have_one_page_scroll_and_touch_weekdays")
 check.is_true(supplier._summary.fit_content and not supplier._summary.scroll_active)
 check.is_true(supplier._preview.fit_content and not supplier._preview.scroll_active)
 for day in supplier._days:check.is_true(day.size.y>=44)
 check.is_true(not supplier._accept.disabled)
 check.is_true(not supplier._preview.text.is_empty())
 check.is_true(session.contracts.state.versions.is_empty())
 check.equal(session.wallet.balance,initial_balance)
 check.case("district_quote_becomes_receipt_without_repeated_payment")
 session.contact.close()
 session.location_id=&"district"
 session.travel.journey.data={"id":"journey_ui","route_id":"district","phase":"browsing"}
 session.running=true
 session.wallet.credit(100000)
 district._quote(str(session.config.section("accounts").advance_offers.keys()[0]))
 check.is_true(not district._pay.disabled)
 var quote: Dictionary=session.accounts.state.quotes[district._quote_id]
 check.equal(district._document.text,UiText.localized("district.expires",{"date":SupplierText.date(float(quote.expires))}))
 district._pay.pressed.emit()
 check.is_true(district._pay.disabled)
 check.is_true(not session.district.state.last_receipt.is_empty())
 check.equal(district._document.theme_type_variation,&"Heading")
 var paid_balance := session.wallet.balance
 district._pay.pressed.emit()
 check.equal(session.wallet.balance,paid_balance)
 check.case("sleep_presentation_and_cancel_do_not_advance_time")
 var tick := session.clock.tick
 var balance := session.wallet.balance
 sleep.present(session.routine)
 await tree.process_frame
 check.is_true(not sleep._preview.text.is_empty())
 check.equal(sleep._hours.get_line_edit().text_direction,Control.TEXT_DIRECTION_LTR)
 check.is_true(viewport.gui_get_focus_owner()==sleep._cancel)
 sleep._cancel.pressed.emit()
 check.is_true(not sleep.visible)
 check.equal(session.clock.tick,tick)
 check.equal(session.wallet.balance,balance)
 check.case("journey_progress_uses_actual_leg_timing")
 session.location_id=&"transit"
 var now := session.clock.world_minutes
 session.travel.journey.data={"phase":"outbound","started_at":now-3,"due_at":now+9}
 journey.present()
 check.near(journey._progress.value,25.0)
 check.is_true(not journey._return.visible)
 session.travel.journey.data.phase="browsing"
 journey.present()
 check.is_true(not journey._progress.visible)
 check.is_true(journey._return.visible)
 check.equal(session.clock.tick,tick)
 check.equal(session.wallet.balance,balance)
 for panel in panels:panel.queue_free()
 viewport.queue_free();session.queue_free();store.free()
 await tree.process_frame

func _horizontal_fits(node: Node, bounds: Rect2) -> bool:
 var fits := true
 if node is Control and node.is_visible_in_tree():
  var rect: Rect2=node.get_global_rect()
  if rect.position.x<bounds.position.x-1 or rect.end.x>bounds.end.x+1:
   print("DAILY UI OVERFLOW ",node.get_path()," ",rect," outside ",bounds)
   fits=false
 for child in node.get_children():
  if not _horizontal_fits(child,bounds):fits=false
 return fits
