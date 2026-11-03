extends RefCounted
func run(check, tree) -> void:
 var store := ContentStore.new()
 check.is_true(store.load_directory("res://content").ok)
 var locale := LocaleService.new()
 check.is_true(locale.configure(store.bundle()).ok)
 var text := UiText.new(store.section("ui"))
 var session := GameSession.new();tree.root.add_child(session)
 check.is_true(session.configure(SessionConfig.new(store.bundle(),store.fingerprint,store.source_root)).ok)
 session.start_new()
 check.case("shop_real_outbound_journey_enables_browse_without_purchase")
 check.is_true(session.travel.depart(&"market").ok)
 check.equal(session.travel.journey.data.phase,"outbound")
 var balance := session.wallet.balance
 for tick in range(30):
  if session.travel.can_shop(&"market"):break
  session.tick(0.5)
 check.is_true(session.travel.can_shop(&"market"))
 check.equal(session.location_id,&"market")
 check.equal(session.wallet.balance,balance)
 var viewport := SubViewport.new();viewport.size=Vector2i(1280,720);tree.root.add_child(viewport)
 var host := Control.new();viewport.add_child(host);host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var hud := Hud.new();host.add_child(hud);hud.configure(text);hud.bind(session);hud.present(null)
 var shop := ShopPanel.new();host.add_child(shop);shop.configure(text,session);shop.present()
 check.case("shop_and_hud_fit_both_locales_and_widths_with_reachable_controls")
 for language in ["en","ar_EG"]:
  locale.set_locale(language)
  for width in [1280,640]:
   viewport.size=Vector2i(width,720)
   shop.present();hud.present(null);UiText.refresh_tree(host)
   await _settle(tree)
   check.is_true(_root_bounds(shop,viewport.size))
   check.is_true(_horizontal_bounds(shop,shop.get_global_rect()))
   check.is_true(_root_bounds(hud._strip,viewport.size))
   check.is_true(_horizontal_bounds(hud._strip,hud._strip.get_global_rect()))
   check.is_true(_reachable(shop._quantity,shop))
   check.is_true(_reachable(shop._confirm,shop))
   check.is_true(_reachable(_key_button(shop,"shop_review"),shop))
   check.is_true(_reachable(_key_button(shop,"journey_return"),shop))
   check.is_true(shop._cards.get_child_count()>0)
   for card in shop._cards.get_children():
    if card is ProductCard:
     check.equal(card._button.focus_mode,Control.FOCUS_ALL)
     check.is_true(_reachable(card._button,shop))
   check.near(hud._strip._bars.hunger.value,session.needs.hunger,0.01)
   check.near(hud._strip._bars.rest.value,session.needs.rest,0.01)
   check.near(hud._strip._bars.mood.value,session.needs.mood,0.01)
   check.equal(hud._strip._money.text,text.text("money",{"amount":"%.2f" % (session.wallet.balance/100.0)}))
   for tab in range(3):check.equal(hud._menu_tabs.get_tab_title(tab),UiText.localized(["cozy.daily","cozy.outings","cozy.settings"][tab]))
 check.case("shop_selection_review_and_quantity_edit_do_not_buy")
 var stock: Dictionary=session.shops.snapshot().stock
 var items := session.items.snapshot()
 var first_card: ProductCard=shop._cards.get_child(0)
 var selected_id := str(first_card.get_meta("offer_id"))
 first_card._button.grab_focus();first_card._button.pressed.emit()
 check.equal(str(shop._selected.id),selected_id)
 check.equal(viewport.gui_get_focus_owner(),first_card._button)
 _key_button(shop,"shop_review").pressed.emit()
 check.is_true(shop._quote!=null)
 check.is_true(not shop._confirm.disabled)
 check.equal(session.wallet.balance,balance)
 check.equal(session.shops.snapshot().stock,stock)
 check.equal(session.items.snapshot(),items)
 shop._quantity.value=2
 check.is_true(shop._quote==null)
 check.is_true(shop._confirm.disabled)
 check.equal(session.wallet.balance,balance)
 _key_button(shop,"shop_review").pressed.emit()
 check.is_true(shop._quote!=null)
 shop._quantity.get_line_edit().text="3"
 shop._quantity.get_line_edit().text_changed.emit("3")
 check.is_true(shop._quote==null)
 check.is_true(shop._confirm.disabled)
 _key_button(shop,"shop_review").pressed.emit()
 check.case("shop_confirm_debits_and_grants_once")
 var quote: ShopQuote=shop._quote
 check.is_true(quote!=null)
 check.equal(int(quote.lines[0].quantity),3)
 var bag_id := StringName(str(session.travel.journey.data.purchase_container_id))
 var bag_before := _units(session.items.items_in(bag_id))
 shop._confirm.pressed.emit()
 check.equal(session.wallet.balance,balance-quote.total_minor)
 var expected_units := 0
 for part in shop._selected.contents:expected_units+=int(part.quantity)*int(quote.lines[0].quantity)
 check.equal(_units(session.items.items_in(bag_id)),bag_before+expected_units)
 check.equal(int(session.shops.snapshot().stock.market[shop._selected.contents[0].definition_id]),int(stock.market[shop._selected.contents[0].definition_id])-expected_units)
 var after_purchase := session.items.snapshot()
 var paid_balance := session.wallet.balance
 shop._confirm.pressed.emit()
 check.equal(session.wallet.balance,paid_balance)
 check.equal(session.items.snapshot(),after_purchase)
 check.equal(session.shops.snapshot().receipts.size(),1)
 check.case("modal_replacement_and_dismiss_restore_origin_without_payment")
 shop.hide();hud._strip._menu_button.grab_focus()
 var coordinator := ModalCoordinator.new()
 coordinator.register("shop",shop)
 var other := PanelContainer.new();host.add_child(other);other.hide()
 other.add_child(UiText.button("Close",other.hide));coordinator.register("other",other)
 shop.show();await _settle(tree)
 _key_button(shop,"shop_review").pressed.emit()
 check.is_true(shop._quote!=null)
 check.equal(coordinator.active_id(),"shop")
 check.is_true(coordinator.blocking())
 check.is_true(shop.is_ancestor_of(viewport.gui_get_focus_owner()))
 other.show();await _settle(tree)
 check.is_true(not shop.visible)
 check.equal(coordinator.active_id(),"other")
 coordinator.close_active()
 check.is_true(not coordinator.blocking())
 check.equal(viewport.gui_get_focus_owner(),hud._strip._menu_button)
 check.equal(session.wallet.balance,paid_balance)
 check.equal(session.items.snapshot(),after_purchase)
 check.case("shop_return_leaves_review_unpaid")
 shop.present();_key_button(shop,"shop_review").pressed.emit()
 check.is_true(shop._quote!=null)
 _key_button(shop,"journey_return").pressed.emit()
 check.equal(session.travel.journey.data.phase,"returning")
 shop.present();check.is_true(not shop.visible)
 shop._confirm.pressed.emit()
 check.equal(session.wallet.balance,paid_balance)
 check.equal(session.items.snapshot(),after_purchase)
 check.equal(session.shops.snapshot().receipts.size(),1)
 hud.hide()
 check.case("title_continue_availability_controls_primary_focus_without_action")
 var emitted: Array[String]=[]
 for language in ["en","ar_EG"]:
  locale.set_locale(language)
  for width in [1280,640]:
   viewport.size=Vector2i(width,720)
   for can_continue in [false,true]:
    var title := TitleScreen.new();host.add_child(title);title.configure(text,can_continue)
    title.new_requested.connect(func():emitted.append("new"));title.continue_requested.connect(func():emitted.append("continue"))
    UiText.refresh_tree(title);await _settle(tree)
    check.is_true(_root_bounds(title,viewport.size))
    check.is_true(_horizontal_bounds(title,title.get_global_rect()))
    var continue_button := _key_button(title,"continue")
    var primary := continue_button if can_continue else _key_button(title,"new_game")
    check.equal(continue_button.disabled,not can_continue)
    check.equal(primary.theme_type_variation,"PrimaryButton")
    check.equal(viewport.gui_get_focus_owner(),primary)
    check.is_true(_reachable(primary,title))
    for child in title.get_children():
     if child is PanelContainer:check.is_true(_root_bounds(child,viewport.size))
    title.free()
 check.equal(emitted,[])
 await _settle(tree)
 viewport.queue_free();session.queue_free();store.free()
 await tree.process_frame
func _settle(tree) -> void:
 for frame in range(8):await tree.process_frame
func _key_button(root: Node, key: String) -> Button:
 for button in root.find_children("*","Button",true,false):
  if button.get_meta("text_ref","")=="ui."+key:return button
 return null
func _root_bounds(root: Control, extent: Vector2i) -> bool:
 var bounds := root.get_global_rect()
 var fits := bounds.position.x>=-1 and bounds.position.y>=-1 and bounds.end.x<=extent.x+1 and bounds.end.y<=extent.y+1
 if not fits:print("BOUND root ",root.get_class(),": ",bounds," viewport ",extent)
 return fits
func _horizontal_bounds(root: Control, bounds: Rect2) -> bool:
 for child in root.get_children():
  if child is Control and child.is_visible_in_tree():
   var rect: Rect2=child.get_global_rect()
   if rect.position.x<bounds.position.x-1 or rect.end.x>bounds.end.x+1:
    print("BOUND child ",child.get_path(),": ",rect," root ",bounds);return false
   if not _horizontal_bounds(child,bounds):return false
 return true
func _reachable(control: Control, root: Control) -> bool:
 if control==null or not control.is_visible_in_tree():return false
 var current := control.get_parent()
 while current!=null and current!=root:
  if current is ScrollContainer:return current.size.y>=44
  current=current.get_parent()
 return control.get_global_rect().end.y<=root.get_global_rect().end.y+1
func _units(items: Array[Dictionary]) -> int:
 var count := 0
 for item in items:count+=int(item.quantity)
 return count
