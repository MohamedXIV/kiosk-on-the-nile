class_name LocationTransition
extends CanvasLayer
signal committed
var active: bool = false
var _veil: ColorRect
var _timing: Dictionary
var _message: Label
func configure(timing: Dictionary, source_theme: Theme = null) -> void:
 _timing = timing.duplicate(true)
 layer = 20
 _veil = ColorRect.new()
 _veil.color = Color.BLACK
 _veil.modulate.a = 0
 _veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(_veil)
 _message = Label.new()
 _message.theme = source_theme
 _message.text_direction = Control.TEXT_DIRECTION_RTL
 _message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 _message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 _message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _veil.add_child(_message)
func run(commit: Callable, message: String = "") -> ActionResult:
 if active: return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"transition_active")
 active = true
 _message.text = message
 _veil.mouse_filter = Control.MOUSE_FILTER_STOP
 await create_tween().tween_property(_veil,"modulate:a",1.0,float(_timing.fade_out)).finished
 var result: ActionResult = commit.call()
 committed.emit()
 await create_tween().tween_property(_veil,"modulate:a",0.0,float(_timing.fade_in)).finished
 _veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
 active = false
 return result
