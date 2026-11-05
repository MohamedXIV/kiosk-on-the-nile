class_name ProductCard
extends PanelContainer
signal selected(offer_id: StringName)
var _button: Button
func configure(offer: Dictionary, definition: Dictionary, text: UiText, shop_id: StringName) -> void:
 theme_type_variation="Card"
 var row := HBoxContainer.new();add_child(row)
 var thumbnail := ItemGlyph.new();thumbnail.configure(definition);row.add_child(thumbnail)
 var column := VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(column)
 var name_label := SheetControls.label(OutingText.offer(shop_id,offer,"label"));column.add_child(name_label)
 var price := SheetControls.label(text.text("shop_price",{"price":"%.2f" % (int(offer.price_minor)/100.0),"stock":offer.available}))
 SheetControls.muted(price);column.add_child(price)
 _button=SheetControls.button(UiText.localized("cozy.inspect",{},"Details"),func():selected.emit(StringName(offer.id)))
 _button.disabled=int(offer.available)<=0
 column.add_child(_button)
func set_selected(value: bool) -> void:
 _button.theme_type_variation="PrimaryButton" if value else "QuietButton"
 _button.button_pressed=value
