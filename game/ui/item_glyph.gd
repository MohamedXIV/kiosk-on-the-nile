class_name ItemGlyph
extends Control
## Small schematic thumbnails drawn from actual item definitions, not stock art.
var _definition: Dictionary={}
var _identity: String=""
const ITEM_ATLAS = preload("res://assets/ui/nile/items.svg")
const ITEM_NAMES := ["tea","liver","chicken","bottle","bread","potato","onion","pepper","sack","beans","eggs","cup","pot","plate","cheese","paper"]
const ITEM_ART := {"tea_portion":"tea","kebda_portion":"liver","chicken":"chicken","marinade":"bottle","oil":"bottle","garlic_sauce":"bottle","chili_sauce":"bottle","bread":"bread","potato":"potato","onion":"onion","green_pepper":"pepper","breadcrumbs":"sack","flour":"sack","liver_seasoning":"sack","fava_beans":"beans","eggs":"eggs","paper_cup":"cup","paper_plate":"plate","takeaway_wrap":"paper","cheese":"cheese","marinating_bowl":"pot","cooking_vessel":"pot","shawarma_filling":"pot","prepared_food":"plate"}
func _init() -> void:
 custom_minimum_size=Vector2(56,56)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
func configure(definition: Dictionary, identity: String="") -> void:
 _definition=definition
 _identity=identity if not identity.is_empty() else str(definition.get("id",""))
 tooltip_text=str(definition.get("label",""))
 queue_redraw()
func _draw() -> void:
 var scale_factor := minf(size.x,size.y)/64.0
 draw_set_transform(Vector2((size.x-64*scale_factor)/2,(size.y-64*scale_factor)/2),0,Vector2.ONE*scale_factor)
 var family := str(_definition.get("material",{}).get("family",_identity))
 var artwork := str(ITEM_ART.get(family,ITEM_ART.get(_identity,"")))
 if artwork in ITEM_NAMES:
  var index := ITEM_NAMES.find(artwork)
  draw_texture_rect_region(ITEM_ATLAS,Rect2(0,0,64,64),Rect2(index%8*64,floori(float(index)/8)*64,64,64))
  return
 var ink := CozyTheme.INK
 var tint := Color(_definition.get("color","#b69b73")).lerp(Color("#f4f1e8"),0.3)
 var id := _identity
 var kind := str(_definition.get("kind",""))
 if "fridge" in id:
  _shape(Rect2(18,8,28,48),tint,5);draw_line(Vector2(18,29),Vector2(46,29),ink,2,true)
  draw_line(Vector2(23,18),Vector2(23,23),ink,2,true);draw_line(Vector2(23,35),Vector2(23,43),ink,2,true)
 elif "chair" in id or "stool" in id or "seat" in id:
  _shape(Rect2(18,12,28,22),tint,5);_shape(Rect2(15,34,34,8),tint,3)
  draw_line(Vector2(20,42),Vector2(17,54),ink,3,true);draw_line(Vector2(44,42),Vector2(47,54),ink,3,true)
 elif "counter" in id or "table" in id or "shelf" in id:
  _shape(Rect2(10,18,44,12),tint,4)
  for x in [16,48]:draw_line(Vector2(x,30),Vector2(x,53),ink,3,true)
  if "shelf" in id:draw_line(Vector2(16,43),Vector2(48,43),ink,3,true)
 elif "kettle" in id or "tea" in id and kind!="ingredient":
  _shape(Rect2(15,25,32,24),tint,8);_shape(Rect2(19,20,25,6),ink,3)
  draw_arc(Vector2(44,33),10,-PI/2,PI/2,16,ink,3,true)
  draw_line(Vector2(16,29),Vector2(8,21),ink,4,true);draw_line(Vector2(27,16),Vector2(27,11),ink,2,true)
 elif "fan" in id:
  draw_circle(Vector2(32,27),18,Color("#f6f6ed"));draw_arc(Vector2(32,27),18,0,TAU,36,ink,2,true)
  for angle in [0,TAU/3,TAU*2/3]:draw_line(Vector2(32,27),Vector2(32,27)+Vector2.from_angle(angle)*13,ink,6,true)
  draw_line(Vector2(32,45),Vector2(32,53),ink,3,true);draw_line(Vector2(23,54),Vector2(41,54),ink,3,true)
 elif kind in ["equipment","furniture"] or "pot" in id or "fryer" in id or "oven" in id:
  _shape(Rect2(13,22,38,27),tint,5);draw_line(Vector2(10,22),Vector2(54,22),ink,3,true)
  draw_circle(Vector2(25,36),3,ink);draw_circle(Vector2(39,36),3,ink)
 else:
  _shape(Rect2(17,16,30,36),tint,5)
  draw_line(Vector2(17,23),Vector2(47,23),ink,2,true)
  draw_line(Vector2(23,43),Vector2(41,43),ink,2,true)
  draw_arc(Vector2(32,33),5,0,TAU,18,ink,2,true)
func _shape(rect: Rect2, fill: Color, radius: int) -> void:
 draw_style_box(CozyTheme.box(fill,CozyTheme.INK,radius,0),rect)
