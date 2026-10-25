class_name WorldFloor
extends Node2D
var _config: Dictionary
var _mapping: SpatialMapping
var _font: Font
func configure(data: Dictionary, projection: SpatialMapping, font_path: String) -> void:
 _config = data
 _mapping = projection
 _font = load(font_path)
 if LocaleService.current:LocaleService.current.changed.connect(queue_redraw)
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
  var caption := TextLine.new()
  caption.direction=TextServer.DIRECTION_RTL if LocaleService.current==null or LocaleService.current.rtl() else TextServer.DIRECTION_LTR
  caption.add_string(ItemText.source("location.rooftop.door_label",str(_config.door_label)),_font,13)
  var size := caption.get_size()
  draw_rect(Rect2(door-Vector2(size.x/2+8,16),Vector2(size.x+16,25)),Color("8c6239"))
  caption.draw(get_canvas_item(),door-Vector2(size.x/2,12),Color("f3ece1"))
func ground_rect(box: Array, color: Color) -> void:
 var start := _mapping.to_canvas(Vector2(box[0],box[1]))
 var end := _mapping.to_canvas(Vector2(box[2],box[3]))
 draw_rect(Rect2(start,end-start),color)
