class_name SpatialCaptions
extends Control
var _labels: Dictionary = {}
var _orders: Dictionary = {}
var top_inset: float = 12
func present(session: GameSession, room: LocationView, camera: Camera2D) -> void:
 _present_orders(session,room,camera)
 var active: Dictionary = {}
 var focused := session.narrative.focused_session()
 if session.location_id==&"kiosk":
  for conversation: ConversationSession in session.narrative.sessions.values():
   if conversation==focused and not session.narrative.choices(conversation).is_empty(): continue
   if conversation.finished or conversation.elapsed>=conversation.current.duration or conversation.current.text.is_empty(): continue
   for visit_id in conversation.participants:
    var visit: VisitState = session.visitors.visits.get(visit_id)
    if visit==null or visit.character_id!=conversation.current.speaker_id: continue
    if visit.pose.ground.distance_to(session.player_ground)>float(session.config.section("social").hearing_radius): continue
    var id := str(conversation.id)
    active[id] = true
    if not _labels.has(id):
     var label := UiText.label()
     label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
     label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
     label.custom_minimum_size.x = 260
     label.add_theme_font_size_override("font_size",17)
     label.add_theme_color_override("font_outline_color",Color("#17100b"))
     label.add_theme_constant_override("outline_size",8)
     label.mouse_filter = Control.MOUSE_FILTER_IGNORE
     add_child(label)
     _labels[id] = label
    var label: Label = _labels[id]
    label.text = conversation.current.text
    label.size.x = 300
    var canvas := room.global_position+room.mapping.to_canvas(visit.pose.ground)-Vector2(0,113)
    var screen: Vector2 = camera.get_canvas_transform()*canvas
    var ceiling := screen.y
    for key in _orders:
     if str(key).begins_with(str(visit_id)+":"):ceiling=minf(ceiling,_orders[key].position.y-8)
    label.position = Vector2(clampf(screen.x-150,8,get_viewport_rect().size.x-308),clampf(ceiling-label.size.y,top_inset,get_viewport_rect().size.y-180))
 for id in _labels.keys():
  if not active.has(id):
   _labels[id].queue_free()
   _labels.erase(id)

func _present_orders(session: GameSession, room: LocationView, camera: Camera2D) -> void:
 var active: Dictionary={}
 var occupied: Array[Rect2]=[]
 if session.location_id==&"kiosk":
  for visit: VisitState in session.visitors.visits.values():
   var order := session.service.pending_for(visit.id)
   if order==null or not session.visitors.is_available(visit.id) or visit.pose.ground.distance_to(session.player_ground)>float(session.config.section("social").hearing_radius):continue
   var key := str(visit.id)+":"+str(order.id)
   active[key]=true
   if not _orders.has(key):
    var badge := OrderBadge.new()
    badge.configure(UiText.new(session.config.section("ui")),session.foods.definition(order.food_id))
    add_child(badge)
    _orders[key]=badge
   var badge: OrderBadge=_orders[key]
   badge.reset_size()
   var canvas := room.global_position+room.mapping.to_canvas(visit.pose.ground)-Vector2(0,57)
   var screen: Vector2=camera.get_canvas_transform()*canvas
   badge.position=Vector2(clampf(screen.x-badge.size.x/2,8,get_viewport_rect().size.x-badge.size.x-8),clampf(screen.y-badge.size.y,top_inset,get_viewport_rect().size.y-badge.size.y-145))
   for attempt in range(8):
    var overlap := false
    for box in occupied:
     if Rect2(badge.position,badge.size).grow(3).intersects(box):
      badge.position.y=maxf(top_inset,box.position.y-badge.size.y-7)
      overlap=true
      break
    if not overlap:break
   occupied.append(Rect2(badge.position,badge.size))
 for key in _orders.keys():
  if not active.has(key):_orders[key].queue_free();_orders.erase(key)
