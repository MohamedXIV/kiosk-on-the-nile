class_name HeldItemView
extends Node2D
var _item: Variant
var facing := Vector2.DOWN
func present(item: Variant) -> void:
 _item = item
 queue_redraw()
func _draw() -> void:
 if _item == null: return
 var tray := Vector2(facing.x*16,-34+facing.y*6)
 draw_set_transform(tray,0,Vector2(13,7))
 draw_circle(Vector2.ZERO,1,Color("c8d0d8"))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 var food: String = str(_item.get("food_id"))
 if food == "tea":
  draw_rect(Rect2(tray+Vector2(-4,-10),Vector2(8,9)),Color("b8371b"))
  draw_rect(Rect2(tray+Vector2(-4,-10),Vector2(8,9)),Color.WHITE,false,1)
 else:
  draw_set_transform(tray+Vector2(0,-4),0,Vector2(9,4.5))
  draw_circle(Vector2.ZERO,1,Color("d8a657"))
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  draw_rect(Rect2(tray+Vector2(-6,-5),Vector2(12,3)),Color("5c2516"))
