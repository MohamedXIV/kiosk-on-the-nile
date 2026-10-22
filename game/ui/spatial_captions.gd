class_name SpatialCaptions
extends Control
var _labels: Dictionary = {}
func present(session: GameSession, room: LocationView, camera: Camera2D) -> void:
 var active: Dictionary = {}
 if session.location_id==&"kiosk":
  for conversation: ConversationSession in session.narrative.sessions.values():
   if conversation.finished or conversation.elapsed>=conversation.current.duration or conversation.current.text.is_empty(): continue
   for visit_id in conversation.participants:
    var visit: VisitState = session.visitors.visits.get(visit_id)
    if visit==null or visit.character_id!=conversation.current.speaker_id: continue
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
    var canvas := room.global_position+room.mapping.to_canvas(visit.pose.ground)-Vector2(0,92)
    var screen: Vector2 = camera.get_canvas_transform()*canvas
    label.position = Vector2(clampf(screen.x-150,8,get_viewport_rect().size.x-308),clampf(screen.y-label.size.y,12,get_viewport_rect().size.y-180))
 for id in _labels.keys():
  if not active.has(id):
   _labels[id].queue_free()
   _labels.erase(id)
