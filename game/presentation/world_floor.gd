class_name WorldFloor
extends Node2D
var _config: Dictionary
var _mapping: SpatialMapping
var _font: Font
func configure(data: Dictionary, projection: SpatialMapping, font_path: String) -> void:
 _config = data
 _mapping = projection
 _font = load(font_path)
 queue_redraw()
func _draw() -> void:
 if _mapping == null: return
 if _config.kind == "kiosk":
  ground_rect(_config.pavement,Color(_config.pavement_color))
  for x in range(-16,17): draw_line(_mapping.to_canvas(Vector2(x,-3.3)),_mapping.to_canvas(Vector2(x,4.5)),Color(0,0,0,0.22),1)
  for y in range(-3,5): draw_line(_mapping.to_canvas(Vector2(-16,y)),_mapping.to_canvas(Vector2(16,y)),Color(0,0,0,0.22),1)
  for tile in _config.get("building_tiles",[_config.boards]):ground_rect(tile,Color(_config.boards_color))
 else:
  ground_rect(_config.surroundings,Color(_config.surroundings_color))
  for tile in _config.get("building_tiles",[_config.room]):ground_rect(tile,Color(_config.room_color))
  ground_rect(_config.rug,Color(_config.rug_color))
  var start := _mapping.to_canvas(Vector2(_config.rug[0],_config.rug[1]))+Vector2(6,6)
  var end := _mapping.to_canvas(Vector2(_config.rug[2],_config.rug[3]))-Vector2(6,6)
  draw_rect(Rect2(start,end-start),Color("d4a359"),false,2)
  var door := _mapping.to_canvas(Vector2(_config.door[0],_config.door[1]))
  draw_rect(Rect2(door+Vector2(-42,-12),Vector2(84,22)),Color("8c6239"))
  draw_string(_font,door+Vector2(-42,3),_config.door_label,HORIZONTAL_ALIGNMENT_CENTER,84,11,Color("f3ece1"))
func ground_rect(box: Array, color: Color) -> void:
 var start := _mapping.to_canvas(Vector2(box[0],box[1]))
 var end := _mapping.to_canvas(Vector2(box[2],box[3]))
 draw_rect(Rect2(start,end-start),color)
