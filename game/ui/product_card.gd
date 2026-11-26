class_name ProductCard
extends PanelContainer
signal selected(offer_id: StringName)
var _button: Button
func configure(offer: Dictionary, definition: Dictionary, text: UiText, shop_id: StringName) -> void:
 theme_type_variation="ItemSlot"
 custom_minimum_size.x=142
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation",4)
 add_child(column)
 var thumbnail := ItemGlyph.new()
 thumbnail.configure(definition,str(offer.contents[0].definition_id))
 thumbnail.custom_minimum_size=Vector2(68,68)
 thumbnail.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
 column.add_child(thumbnail)
 var name_label := SheetControls.label(OutingText.offer(shop_id,offer,"label"))
 name_label.custom_minimum_size=Vector2(114,60)
 name_label.size_flags_vertical=Control.SIZE_EXPAND_FILL
 name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 name_label.set_meta("centered",true)
 column.add_child(name_label)
 var price := SheetControls.label(text.text("shop_price",{"price":"%.2f" % (int(offer.price_minor)/100.0),"stock":offer.available}))
 price.theme_type_variation="PriceTag"
 price.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 price.set_meta("centered",true)
 column.add_child(price)
 _button=SheetControls.button(UiText.localized("cozy.inspect",{},"Details"),func():selected.emit(StringName(offer.id)))
 _button.custom_minimum_size.x=0
 _button.disabled=int(offer.available)<=0
 column.add_child(_button)
 _button.size_flags_vertical=Control.SIZE_SHRINK_END
func set_selected(value: bool) -> void:
 theme_type_variation="SelectedItemSlot" if value else "ItemSlot"
 _button.theme_type_variation="PrimaryButton" if value else "QuietButton"
 _button.button_pressed=value
