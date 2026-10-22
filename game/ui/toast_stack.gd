class_name ToastStack
extends Label
var duration: float = 3
var _remaining: float = 0
func show_message(value: String) -> void:
 text = value
 _remaining = duration
 show()
func _process(delta: float) -> void:
 _remaining = maxf(0,_remaining-delta)
 visible = _remaining>0
