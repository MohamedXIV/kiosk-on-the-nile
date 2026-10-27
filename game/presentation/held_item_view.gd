class_name HeldItemView
extends Node2D
var _raw: Dictionary={}
var _item: PreparedItem
var facing := Vector2.DOWN
func present(item: PreparedItem) -> void:
 _item = item
 queue_redraw()
func _draw() -> void:
 if _item == null and _raw.is_empty(): return
 var tray := Vector2(facing.x*16,-34+facing.y*6)
 draw_set_transform(tray,0,Vector2(13,7))
 draw_circle(Vector2.ZERO,1,Color("c8d0d8"))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 if _item==null:
  draw_rect(Rect2(tray+Vector2(-9,-9),Vector2(18,10)),Color("#a7b0b1"))
  draw_rect(Rect2(tray+Vector2(-7,-10),Vector2(14,4)),Color("#b9804c"))
  return
 var food: String = str(_item.get("food_id"))
 if food == "tea":
  draw_rect(Rect2(tray+Vector2(-4,-10),Vector2(8,9)),Color("b8371b"))
  draw_rect(Rect2(tray+Vector2(-4,-10),Vector2(8,9)),Color.WHITE,false,1)
 else:
  draw_set_transform(tray+Vector2(0,-4),0,Vector2(9,4.5))
  draw_circle(Vector2.ZERO,1,Color("d8a657"))
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  draw_rect(Rect2(tray+Vector2(-6,-5),Vector2(12,3)),Color("5c2516"))

func present_record(record: Dictionary) -> void:
 _raw=record.duplicate(true)
 _item=PreparedItem.from_dict(record.attributes) if record.get("kind")=="prepared" else null
 queue_redraw()
