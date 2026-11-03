class_name ToastStack
extends Label
var duration: float = 3
var _remaining: float = 0
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_theme_stylebox_override("normal",CozyTheme.box(CozyTheme.IVORY,CozyTheme.LINE,14,16,true))
 hide()
func show_message(value: String) -> void:
 text = value
 _remaining = duration
 show()
func _process(delta: float) -> void:
 _remaining = maxf(0,_remaining-delta)
 visible = _remaining>0
