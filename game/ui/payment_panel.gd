class_name PaymentPanel
extends PanelContainer
signal completed(result: ActionResult)
var _session: GameSession
var _text: UiText
var _order_id: StringName
var _item_id: StringName
var _heading := SheetControls.label()
var _description := SheetControls.label()
var _feedback := SheetControls.label()
var _choices := VBoxContainer.new()
var _elapsed: float=0
func configure(text: UiText, session: GameSession) -> void:
 _session=session;_text=text;theme=text.make_theme()
 anchor_left=0.18;anchor_right=0.82;anchor_top=0.2;anchor_bottom=0.8
 var box := VBoxContainer.new();add_child(box)
 SheetControls.header(box,_heading,text,hide)
 box.add_child(_description);box.add_child(_choices);box.add_child(_feedback)
 visibility_changed.connect(func():if not visible:_session.service.end_decision(_order_id))
 LocaleService.current.changed.connect(func():if visible:_refresh())
 hide()
func present(order_id: StringName) -> void:
 _session.service.end_decision(_order_id)
 _order_id=order_id;_feedback.text=""
 var item := _session.cooking.held_item()
 _item_id=item.id if item!=null else &""
 if not _valid():hide();return
 _session.service.begin_decision(_order_id)
 _refresh();show()
func _process(delta: float) -> void:
 if not visible:return
 _elapsed+=delta
 if _elapsed<0.25:return
 _elapsed=0
 if not _valid():hide()
func _valid() -> bool:
 var order := _session.service.order(_order_id)
 if order==null or not order.status in [&"pending",&"delivered"] or order.settlement!=&"pending" or not _session.visitors.is_available(order.visit_id):return false
 var visit: VisitState=_session.visitors.visits[str(order.visit_id)]
 return _session.location_id==visit.pose.location_id and _session.player_ground.distance_to(visit.pose.ground)<=float(_session.config.section("visitors").interaction_radius)
func _refresh() -> void:
 if not _valid():hide();return
 var order := _session.service.order(_order_id)
 var visit: VisitState=_session.visitors.visits[str(order.visit_id)]
 var actor_name := NotebookView.name(str(visit.character_id),str(_session.visitors.character(visit.character_id).name))
 _heading.text=_text.text("payment_heading",{"name":actor_name})
 var already_served := order.status==&"delivered"
 var description := "payment_unsettled_promised" if order.gift_promised else "payment_unsettled"
 if not already_served:description="payment_promised" if order.gift_promised else "payment_choose"
 _description.text=_text.text(description,{"food":OutingText.serving(_session,order.quote)})
 SheetControls.clear(_choices)
 var item := _session.cooking.held_item()
 var quality: int=int(_session.cooking.freshness(item).grade) if order.status==&"pending" and item!=null else order.served_quality
 var amount: int=order.base_price+int(order.tips[clampi(quality,0,3)])
 if not order.gift_promised:_choices.add_child(SheetControls.button(_text.text("payment_paid_settle" if already_served else "payment_paid",{"amount":NotebookView.money(amount)}),_choose.bind(&"paid")))
 if order.gift_promised or _session.can_offer_hospitality(order.visit_id):_choices.add_child(SheetControls.button(_text.text("payment_gift_settle" if already_served else "payment_gift"),_choose.bind(&"gift")))
 _choices.add_child(SheetControls.button(_text.text("payment_later"),hide))
 UiText.refresh_tree(self)
func _choose(mode: StringName) -> void:
 if not _valid():hide();return
 var result := _session.complete_service(_order_id,mode,_item_id)
 if not result.ok:_feedback.text=_text.outcome(result);return
 hide();completed.emit(result)
