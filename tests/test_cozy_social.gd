extends RefCounted
func run(check, tree) -> void:
 var store := ContentStore.new()
 check.is_true(store.load_directory("res://content").ok)
 var locale := LocaleService.new()
 check.is_true(locale.configure(store.bundle()).ok)
 var text := UiText.new(store.section("ui"))
 var viewport := SubViewport.new();viewport.size=Vector2i(640,720);tree.root.add_child(viewport)
 var host := Control.new();host.theme=text.make_theme();viewport.add_child(host);host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var history := NotebookHistory.new();host.add_child(history);history.configure(10)
 history.position=Vector2(16,16);history.size=Vector2(580,640)
 var entries: Array[Dictionary]=[]
 for i in range(23):
  entries.append({"actor":"amgad" if i%2==0 else "player","name":"أمجد" if i%2==0 else "Me","chapter":"conversation_one" if i<12 else "conversation_two","channel":"speech" if i%2==0 else "choice","at":930+i,"text":"كلام محفوظ [b]literal[/b] "+str(i),"locale":"ar_EG"})
 history.set_entries(entries)
 await tree.process_frame
 await tree.process_frame
 check.case("history_is_literal_paged_and_source_filterable")
 check.equal(history._filtered.size(),23)
 check.is_true("[b]literal[/b]" in history._body.get_parsed_text())
 check.is_true(history._previous.disabled)
 check.is_true(not history._next.disabled)
 history._next.pressed.emit()
 check.equal(history._page,1)
 history.show_chapter("conversation_one")
 check.equal(history._page,0)
 check.equal(history._filtered.size(),12)
 history._search.text="literal[/b] 0";history._apply_filters()
 check.equal(history._filtered.size(),1)
 check.equal(entries.size(),23)
 check.case("history_controls_remain_inside_narrow_view_and_locale_switch_keeps_heard_text")
 check.is_true(history._next.get_global_rect().end.x<=640)
 check.is_true(history._next.get_global_rect().end.y<=720)
 locale.set_locale("en");history.refresh_language();UiText.refresh_tree(history)
 check.is_true("كلام محفوظ [b]literal[/b] 0" in history._body.get_parsed_text())
 check.equal(history._filtered.size(),1)
 history.hide()
 var dialogue := DialoguePanel.new();host.add_child(dialogue);dialogue.configure(text)
 var conversation := ConversationSession.new();conversation.id=&"cozy_test";conversation.current.text="A quiet conversation.";conversation.context_extra.peer_participating=true
 dialogue.present(conversation,[],"Amgad")
 await tree.process_frame
 await tree.process_frame
 check.case("dialogue_keeps_cached_controls_and_leave_outside_scroll")
 var first_child := dialogue._box.get_child(0)
 dialogue.present(conversation,[],"Amgad")
 check.is_true(first_child==dialogue._box.get_child(0))
 check.is_true(dialogue._leave.get_parent()==dialogue._layout)
 check.is_true(dialogue._leave.get_global_rect().end.x<=640)
 var left: Array[StringName]=[]
 dialogue.group_leave_requested.connect(func(id):left.append(id))
 dialogue._leave.pressed.emit()
 check.equal(left,[&"cozy_test"])
 dialogue.hide()
 check.case("payment_dismiss_releases_decision_without_settlement")
 var session := GameSession.new();tree.root.add_child(session)
 session.config=SessionConfig.new(store.bundle(),store.fingerprint,store.source_root)
 session.wallet=WalletService.new(4500)
 session.visitors=VisitorService.new();session.visitors._data=store.section("visitors")
 var visit := VisitState.new();visit.id=&"visit_test";visit.character_id=&"amgad";visit.phase=&"staying"
 session.visitors.visits[str(visit.id)]=visit
 session.location_id=visit.pose.location_id;session.player_ground=visit.pose.ground
 session.cooking=CookingService.new();session.cooking._inventory=InventoryService.new(ItemStore.new(),{})
 session.service=ServiceSystem.new()
 var order := OrderState.new();order.id=&"order_test";order.visit_id=visit.id;order.gift_promised=true;order.tips=[0,0,0,0];order.served_quality=0;order.quote={"variant_id":"tea/cup/here"}
 session.service._orders[str(order.id)]=order
 if order!=null:
  var payment := PaymentPanel.new();host.add_child(payment);payment.configure(text,session)
  var before := session.wallet.balance
  payment.present(order.id)
  await tree.process_frame
  check.equal(session.service.decision_visit(),visit.id)
  check.is_true(payment._choices.get_parent() is ScrollContainer)
  payment._choices.get_child(payment._choices.get_child_count()-1).pressed.emit()
  check.is_true(not payment.visible)
  check.equal(session.service.decision_visit(),&"")
  check.equal(session.wallet.balance,before)
  check.equal(order.status,&"pending")
  check.equal(order.settlement,&"pending")
 check.case("notebook_history_sheet_fits_both_locales_and_viewports")
 var notebook := Notebook.new();host.add_child(notebook);notebook.configure(text)
 notebook._tabs.current_tab=2;notebook._history.set_entries(entries);notebook.open()
 for locale_id in ["ar_EG","en"]:
  locale.set_locale(locale_id);UiText.refresh_tree(notebook)
  for extent in [Vector2i(1280,720),Vector2i(640,720)]:
   viewport.size=extent
   await tree.process_frame
   await tree.process_frame
   await tree.process_frame
   check.is_true(notebook.get_global_rect().end.x<=extent.x)
   check.is_true(notebook.get_global_rect().end.y<=extent.y)
   check.is_true(notebook._history._next.get_global_rect().end.y<=extent.y)
   check.is_true(notebook._history._body.size.y>=64)
 viewport.free();session.free();store.free()
 await tree.process_frame
