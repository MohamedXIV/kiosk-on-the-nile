class_name OrderBadge
extends PanelContainer
var _glyph := OrderGlyph.new()
var _label := Label.new()
func configure(text: UiText, food: Dictionary) -> void:
 theme=text.make_theme()
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 var row := HBoxContainer.new()
 row.mouse_filter=Control.MOUSE_FILTER_IGNORE
 row.add_theme_constant_override("separation",7)
 add_child(row)
 row.add_child(_glyph)
 _glyph.kind=str(food.get("order_icon","plate"))
 _glyph.queue_redraw()
 _label.text=str(food.get("menu_label",""))
 _label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 _label.add_theme_font_size_override("font_size",16)
 row.add_child(_label)

func present(session: GameSession, food_id: StringName) -> void:
 _label.text=OutingText.order(session,food_id)
 _label.text_direction=Control.TEXT_DIRECTION_RTL if LocaleService.current.rtl() else Control.TEXT_DIRECTION_LTR
