class_name ProductCard
extends PanelContainer
signal selected(offer_id: StringName)
func configure(offer: Dictionary, definition: Dictionary, text: UiText) -> void:
 var row := HBoxContainer.new()
 add_child(row)
 var thumbnail := Control.new()
 thumbnail.custom_minimum_size=Vector2(64,64)
 thumbnail.draw.connect(func():
  var color := Color(definition.get("color","#b69560"))
  thumbnail.draw_rect(Rect2(8,18,48,30),color)
  thumbnail.draw_rect(Rect2(8,10,48,8),color.lightened(0.3))
  thumbnail.draw_rect(Rect2(8,10,48,38),Color(0.2,0.15,0.1),false,2))
 row.add_child(thumbnail)
 var button := UiText.button(str(offer.label)+"\n"+text.text("shop_price",{"price":"%.2f" % (int(offer.price_minor)/100.0),"stock":offer.available}),func():selected.emit(StringName(offer.id)))
 button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button.disabled=int(offer.available)<=0
 row.add_child(button)
